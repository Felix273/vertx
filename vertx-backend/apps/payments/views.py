"""
VERTX Payments — Views
Subscription, series purchase, webhook handling, history.
"""

from django.utils import timezone
from django.shortcuts import get_object_or_404
from datetime import timedelta
from rest_framework import status, permissions, generics
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import serializers

from .models import Payment, Subscription, SeriesPurchase, SubscriptionPlan, SubscriptionStatus, PaymentStatus
from .providers import get_provider
from apps.content.models import Series, ContentStatus


# ── Plan config ───────────────────────────────────────────────
PLAN_DURATIONS = {
    SubscriptionPlan.WEEKLY:  timedelta(days=7),
    SubscriptionPlan.MONTHLY: timedelta(days=30),
}

PLAN_PRICES = {
    SubscriptionPlan.WEEKLY:  {'amount': '2.99', 'currency': 'USD'},
    SubscriptionPlan.MONTHLY: {'amount': '9.99', 'currency': 'USD'},
}


# ── Serializers ───────────────────────────────────────────────
class SubscribeSerializer(serializers.Serializer):
    plan     = serializers.ChoiceField(choices=SubscriptionPlan.choices)
    provider = serializers.CharField(default='stripe')
    metadata = serializers.DictField(default=dict)


class PurchaseSerializer(serializers.Serializer):
    provider = serializers.CharField(default='stripe')
    metadata = serializers.DictField(default=dict)


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Payment
        fields = ('id', 'provider', 'amount', 'currency', 'status', 'created_at')


class SubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Subscription
        fields = ('id', 'plan', 'status', 'starts_at', 'expires_at')


class SeriesPurchaseSerializer(serializers.ModelSerializer):
    series_title = serializers.CharField(source='series.title', read_only=True)

    class Meta:
        model  = SeriesPurchase
        fields = ('id', 'series_title', 'purchased_at')


# ── Views ─────────────────────────────────────────────────────
class SubscribeView(APIView):
    """
    POST /api/payments/subscribe/
    Initiate a subscription payment.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = SubscribeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        plan_info = PLAN_PRICES[data['plan']]
        provider  = get_provider(data['provider'])

        # Create pending payment record
        payment = Payment.objects.create(
            user=request.user,
            provider=data['provider'],
            amount=plan_info['amount'],
            currency=plan_info['currency'],
            status=PaymentStatus.PENDING,
            metadata={'plan': data['plan'], **data['metadata']},
        )

        result = provider.initiate_payment(
            amount=payment.amount,
            currency=payment.currency,
            metadata={'reference': str(payment.id), 'description': f'VERTX {data["plan"]} subscription', **data['metadata']},
        )

        payment.provider_reference = result.get('reference', '')
        payment.save(update_fields=['provider_reference'])

        return Response({
            'payment_id':   str(payment.id),
            'redirect_url': result.get('redirect_url'),
            'instructions': result.get('instructions'),
        })


class PurchaseSeriesView(APIView):
    """
    POST /api/payments/purchase/{series_id}/
    Buy a single series.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, series_id):
        series = get_object_or_404(Series, id=series_id, status=ContentStatus.PUBLISHED)

        if SeriesPurchase.objects.filter(user=request.user, series=series).exists():
            return Response({'error': 'You already own this series.'}, status=status.HTTP_400_BAD_REQUEST)

        if series.price <= 0:
            return Response({'error': 'This series is not available for individual purchase.'}, status=status.HTTP_400_BAD_REQUEST)

        serializer = PurchaseSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        provider = get_provider(data['provider'])
        payment  = Payment.objects.create(
            user=request.user,
            provider=data['provider'],
            amount=series.price,
            currency='USD',
            status=PaymentStatus.PENDING,
            metadata={'series_id': str(series.id), 'series_title': series.title},
        )

        result = provider.initiate_payment(
            amount=payment.amount,
            currency=payment.currency,
            metadata={'reference': str(payment.id), 'description': f'Purchase: {series.title}', **data['metadata']},
        )

        payment.provider_reference = result.get('reference', '')
        payment.save(update_fields=['provider_reference'])

        return Response({
            'payment_id':   str(payment.id),
            'redirect_url': result.get('redirect_url'),
            'instructions': result.get('instructions'),
        })


class PaymentWebhookView(APIView):
    """
    POST /api/payments/webhook/{provider}/
    Called by payment provider on payment completion.
    Fulfils subscriptions and purchases.
    """
    permission_classes = [permissions.AllowAny]  # Webhook must be open

    def post(self, request, provider_name):
        try:
            provider = get_provider(provider_name)
            result   = provider.handle_webhook(request.data, request.META)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        if result['status'] != 'success':
            return Response({'received': True})

        try:
            payment = Payment.objects.get(provider_reference=result['reference'])
        except Payment.DoesNotExist:
            return Response({'error': 'Payment not found.'}, status=status.HTTP_404_NOT_FOUND)

        if payment.status == PaymentStatus.SUCCESS:
            return Response({'received': True})  # Idempotent

        payment.status = PaymentStatus.SUCCESS
        payment.save(update_fields=['status', 'updated_at'])

        # Fulfil based on metadata
        meta = payment.metadata

        if 'plan' in meta:
            _fulfil_subscription(payment, meta['plan'])
        elif 'series_id' in meta:
            _fulfil_series_purchase(payment, meta['series_id'])

        return Response({'received': True})


def _fulfil_subscription(payment, plan):
    duration = PLAN_DURATIONS[plan]
    now = timezone.now()
    Subscription.objects.create(
        user=payment.user,
        plan=plan,
        status=SubscriptionStatus.ACTIVE,
        payment=payment,
        starts_at=now,
        expires_at=now + duration,
    )


def _fulfil_series_purchase(payment, series_id):
    try:
        series = Series.objects.get(id=series_id)
        SeriesPurchase.objects.get_or_create(
            user=payment.user,
            series=series,
            defaults={'payment': payment}
        )
    except Series.DoesNotExist:
        pass


class PaymentHistoryView(generics.ListAPIView):
    """
    GET /api/payments/history/
    """
    serializer_class   = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Payment.objects.filter(user=self.request.user)


class SubscriptionStatusView(APIView):
    """
    GET /api/payments/subscription/
    Current user's active subscription.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        sub = Subscription.objects.filter(
            user=request.user,
            status=SubscriptionStatus.ACTIVE,
            expires_at__gt=timezone.now()
        ).first()

        if not sub:
            return Response({'active': False})

        return Response({
            'active':     True,
            'plan':       sub.plan,
            'expires_at': sub.expires_at,
        })
