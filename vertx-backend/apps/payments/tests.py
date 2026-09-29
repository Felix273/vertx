from unittest.mock import patch

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.payments.models import Payment, PaymentStatus, Subscription
from apps.payments.views import PurchaseSerializer, SubscribeSerializer
from apps.users.models import User


class FakeProvider:
    def handle_webhook(self, payload, headers):
        return {'reference': 'callback-1', 'status': 'success'}


class PaymentApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='viewer@example.com', password='Passw0rd!123', full_name='Viewer'
        )
        self.payment = Payment.objects.create(
            user=self.user,
            provider='mpesa',
            amount='99.00',
            currency='KES',
            status=PaymentStatus.PENDING,
            provider_reference='callback-1',
            metadata={'plan': 'weekly'},
        )

    def test_payment_request_serializers_validate_provider_and_metadata(self):
        self.assertEqual(
            set(SubscribeSerializer().fields), {'plan', 'provider', 'metadata'}
        )
        self.assertEqual(
            set(PurchaseSerializer().fields), {'provider', 'metadata'}
        )
        self.assertFalse(SubscribeSerializer(data={'plan': 'weekly', 'provider': 'bogus'}).is_valid())

    @patch('apps.payments.views.get_provider', return_value=FakeProvider())
    def test_success_webhook_is_idempotent_and_fulfills_subscription_once(self, _provider):
        url = reverse('payment-webhook', kwargs={'provider_name': 'mpesa'})
        first = self.client.post(url, {'Body': {'stkCallback': {}}}, format='json')
        second = self.client.post(url, {'Body': {'stkCallback': {}}}, format='json')

        self.assertEqual(first.status_code, status.HTTP_200_OK)
        self.assertEqual(second.status_code, status.HTTP_200_OK)
        self.assertEqual(Payment.objects.get(pk=self.payment.pk).status, PaymentStatus.SUCCESS)
        self.assertEqual(Subscription.objects.filter(payment=self.payment).count(), 1)

    def test_payment_status_is_owner_only(self):
        self.client.force_authenticate(self.user)
        response = self.client.get(
            reverse('payment-status', kwargs={'payment_id': self.payment.id})
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], PaymentStatus.PENDING)
