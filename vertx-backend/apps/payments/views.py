"""
VERTX Payments — Views
Subscription, series purchase, provider webhooks, payment status, history,
and producer earnings.
"""

from datetime import timedelta
from decimal import Decimal

from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, permissions, serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.content.models import ContentStatus, Series
from .models import (
    Payment,
    PaymentStatus,
    SeriesPurchase,
    Subscription,
    SubscriptionPlan,
    SubscriptionStatus,
)
from .providers import get_provider


PLAN_DURATIONS = {
    SubscriptionPlan.WEEKLY: timedelta(days=7),
    SubscriptionPlan.MONTHLY: timedelta(days=30),
}

# VERTX is Kenya-first; all client surfaces display these KES prices.
PLAN_PRICES = {
    SubscriptionPlan.WEEKLY: {'amount': Decimal('99.00'), 'currency': 'KES'},
    SubscriptionPlan.MONTHLY: {'amount': Decimal('299.00'), 'currency': 'KES'},
}
SUPPORTED_PROVIDERS = ('stripe', 'mpesa')


class ProviderSerializer(serializers.Serializer):
    provider = serializers.ChoiceField(choices=SUPPORTED_PROVIDERS, default='stripe')
    metadata = serializers.DictField(required=False, default=dict)


class SubscribeSerializer(ProviderSerializer):
    plan = serializers.ChoiceField(choices=SubscriptionPlan.choices)


class PurchaseSerializer(ProviderSerializer):
    pass


class PaymentSerializer(serializers.ModelSerializer):
    payment_type = serializers.SerializerMethodField()
    series_title = serializers.SerializerMethodField()

    class Meta:
        model = Payment
        fields = (
            'id', 'provider', 'amount', 'currency', 'status',
            'payment_type', 'series_title', 'created_at',
        )

    def get_payment_type(self, obj):
        if obj.metadata.get('plan'):
            return f"{obj.metadata['plan']} subscription"
        if obj.metadata.get('series_id'):
            return 'series purchase'
        return 'payment'

    def get_series_title(self, obj):
        return obj.metadata.get('series_title')


class SubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subscription
        fields = ('id', 'plan', 'status', 'starts_at', 'expires_at')


class SeriesPurchaseSerializer(serializers.ModelSerializer):
    series_title = serializers.CharField(source='series.title', read_only=True)

    class Meta:
        model = SeriesPurchase
        fields = ('id', 'series_title', 'purchased_at')


class SubscribeView(APIView):
    """POST /api/payments/subscribe/ — initiate a subscription payment."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = SubscribeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        plan_info = PLAN_PRICES[data['plan']]
        provider_name = data['provider']
        provider = get_provider(provider_name)

        payment = Payment.objects.create(
            user=request.user,
            provider=provider_name,
            amount=plan_info['amount'],
            currency=plan_info['currency'],
            status=PaymentStatus.PENDING,
            metadata={'plan': data['plan'], **data['metadata']},
        )
        try:
            result = provider.initiate_payment(
                amount=payment.amount,
                currency=payment.currency,
                metadata={
                    'reference': str(payment.id),
                    'description': f'VERTX {data["plan"]} subscription',
                    **data['metadata'],
                },
            )
        except Exception:
            payment.status = PaymentStatus.FAILED
            payment.save(update_fields=['status', 'updated_at'])
            raise

        payment.provider_reference = result.get('reference') or str(payment.id)
        payment.save(update_fields=['provider_reference', 'updated_at'])
        return Response({
            'payment_id': str(payment.id),
            'redirect_url': result.get('redirect_url'),
            'instructions': result.get('instructions'),
            'status': payment.status,
        }, status=status.HTTP_201_CREATED)


class PurchaseSeriesView(APIView):
    """POST /api/payments/purchase/{series_id}/ — buy one published series."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, series_id):
        series = get_object_or_404(Series, id=series_id, status=ContentStatus.PUBLISHED)
        if SeriesPurchase.objects.filter(user=request.user, series=series).exists():
            return Response(
                {'error': 'You already own this series.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if series.price <= 0:
            return Response(
                {'error': 'This series is not available for individual purchase.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = PurchaseSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        provider_name = data['provider']
        provider = get_provider(provider_name)
        payment = Payment.objects.create(
            user=request.user,
            provider=provider_name,
            amount=series.price,
            currency='KES',
            status=PaymentStatus.PENDING,
            metadata={
                'series_id': str(series.id),
                'series_title': series.title,
                **data['metadata'],
            },
        )
        try:
            result = provider.initiate_payment(
                amount=payment.amount,
                currency=payment.currency,
                metadata={
                    'reference': str(payment.id),
                    'description': f'Purchase: {series.title}',
                    **data['metadata'],
                },
            )
        except Exception:
            payment.status = PaymentStatus.FAILED
            payment.save(update_fields=['status', 'updated_at'])
            raise

        payment.provider_reference = result.get('reference') or str(payment.id)
        payment.save(update_fields=['provider_reference', 'updated_at'])
        return Response({
            'payment_id': str(payment.id),
            'redirect_url': result.get('redirect_url'),
            'instructions': result.get('instructions'),
            'status': payment.status,
        }, status=status.HTTP_201_CREATED)


class PaymentWebhookView(APIView):
    """POST /api/payments/webhook/{provider}/ — provider callback."""
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request, provider_name):
        try:
            provider = get_provider(provider_name)
            payload = request.body if provider_name == 'stripe' else request.data
            result = provider.handle_webhook(payload, request.META)
        except Exception as exc:
            return Response({'error': str(exc)}, status=status.HTTP_400_BAD_REQUEST)

        callback_status = result.get('status')
        reference = result.get('reference')
        if callback_status == 'ignored':
            return Response({'received': True})
        if not reference:
            return Response({'error': 'Webhook did not include a payment reference.'}, status=400)

        with transaction.atomic():
            try:
                payment = Payment.objects.select_for_update().get(
                    provider=provider_name,
                    provider_reference=reference,
                )
            except Payment.DoesNotExist:
                return Response({'error': 'Payment not found.'}, status=status.HTTP_404_NOT_FOUND)

            if payment.status == PaymentStatus.SUCCESS:
                return Response({'received': True, 'status': payment.status})

            if callback_status != 'success':
                payment.status = PaymentStatus.FAILED
                payment.save(update_fields=['status', 'updated_at'])
                return Response({'received': True, 'status': payment.status})

            payment.status = PaymentStatus.SUCCESS
            payment.save(update_fields=['status', 'updated_at'])
            _fulfil_payment(payment)

        return Response({'received': True, 'status': payment.status})


def _fulfil_payment(payment):
    metadata = payment.metadata or {}
    if metadata.get('plan'):
        _fulfil_subscription(payment, metadata['plan'])
    elif metadata.get('series_id'):
        _fulfil_series_purchase(payment, metadata['series_id'])


def _fulfil_subscription(payment, plan):
    duration = PLAN_DURATIONS.get(plan)
    if duration is None:
        return
    now = timezone.now()
    Subscription.objects.get_or_create(
        payment=payment,
        defaults={
            'user': payment.user,
            'plan': plan,
            'status': SubscriptionStatus.ACTIVE,
            'starts_at': now,
            'expires_at': now + duration,
        },
    )


def _fulfil_series_purchase(payment, series_id):
    try:
        series = Series.objects.get(id=series_id)
    except Series.DoesNotExist:
        return
    SeriesPurchase.objects.get_or_create(
        user=payment.user,
        series=series,
        defaults={'payment': payment},
    )


class PaymentHistoryView(generics.ListAPIView):
    """GET /api/payments/history/ — current user's payments."""
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Payment.objects.filter(user=self.request.user).order_by('-created_at')


class ProducerEarningsView(generics.ListAPIView):
    """GET /api/payments/earnings/ — successful purchases of own series."""
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        profile = getattr(self.request.user, 'producer_profile', None)
        if profile is None:
            return Payment.objects.none()
        series_ids = Series.objects.filter(producer=profile).values_list('id', flat=True)
        return Payment.objects.filter(
            status=PaymentStatus.SUCCESS,
            metadata__series_id__in=[str(series_id) for series_id in series_ids],
        ).order_by('-created_at')


class PaymentStatusView(APIView):
    """GET /api/payments/status/{payment_id}/ — owner-only payment state."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, payment_id):
        payment = get_object_or_404(Payment, id=payment_id, user=request.user)
        fulfilled = (
            payment.status == PaymentStatus.SUCCESS and
            (
                payment.subscriptions.exists() or
                SeriesPurchase.objects.filter(payment=payment).exists() or
                (not payment.metadata.get('plan') and not payment.metadata.get('series_id'))
            )
        )
        return Response({
            'payment_id': str(payment.id),
            'status': payment.status,
            'fulfilled': fulfilled,
            'provider_reference': payment.provider_reference,
        })


class SubscriptionStatusView(APIView):
    """GET /api/payments/subscription/ — current user's active subscription."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        sub = Subscription.objects.filter(
            user=request.user,
            status=SubscriptionStatus.ACTIVE,
            expires_at__gt=timezone.now(),
        ).first()
        if not sub:
            return Response({'active': False})
        return Response({
            'active': True,
            'plan': sub.plan,
            'expires_at': sub.expires_at,
        })
