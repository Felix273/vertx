"""
VERTX Payments — Provider Abstraction
Adding a new payment provider = implement BasePaymentProvider + register here.
Zero changes to core views or models.
"""

from abc import ABC, abstractmethod
from decimal import Decimal


class BasePaymentProvider(ABC):
    """
    Interface every payment provider must implement.
    """

    @abstractmethod
    def initiate_payment(self, amount: Decimal, currency: str, metadata: dict) -> dict:
        """
        Start a payment flow.
        Returns: {'reference': str, 'redirect_url': str|None, 'instructions': str|None}
        """
        pass

    @abstractmethod
    def verify_payment(self, reference: str) -> dict:
        """
        Verify a completed payment by provider reference.
        Returns: {'success': bool, 'amount': Decimal, 'currency': str}
        """
        pass

    @abstractmethod
    def handle_webhook(self, payload: dict, headers: dict) -> dict:
        """
        Process an incoming webhook from the provider.
        Returns: {'reference': str, 'status': 'success'|'failed'}
        """
        pass


# ──────────────────────────────────────────────────────────────
# STRIPE ADAPTER
# ──────────────────────────────────────────────────────────────
class StripeProvider(BasePaymentProvider):
    def __init__(self):
        import stripe
        from django.conf import settings
        stripe.api_key = settings.STRIPE_SECRET_KEY
        self.stripe = stripe

    def initiate_payment(self, amount: Decimal, currency: str, metadata: dict) -> dict:
        session = self.stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[{
                'price_data': {
                    'currency': currency.lower(),
                    'unit_amount': int(amount * 100),  # Stripe uses cents
                    'product_data': {'name': metadata.get('description', 'VERTX')},
                },
                'quantity': 1,
            }],
            mode='payment',
            success_url=metadata.get('success_url', ''),
            cancel_url=metadata.get('cancel_url', ''),
            metadata=metadata,
        )
        return {
            'reference':    session.id,
            'redirect_url': session.url,
            'instructions': None,
        }

    def verify_payment(self, reference: str) -> dict:
        session = self.stripe.checkout.Session.retrieve(reference)
        return {
            'success':  session.payment_status == 'paid',
            'amount':   Decimal(session.amount_total) / 100,
            'currency': session.currency.upper(),
        }

    def handle_webhook(self, payload: dict, headers: dict) -> dict:
        from django.conf import settings
        event = self.stripe.Webhook.construct_event(
            payload, headers.get('HTTP_STRIPE_SIGNATURE'), settings.STRIPE_WEBHOOK_SECRET
        )
        if event['type'] == 'checkout.session.completed':
            session = event['data']['object']
            return {'reference': session['id'], 'status': 'success'}
        return {'reference': '', 'status': 'ignored'}


# ──────────────────────────────────────────────────────────────
# M-PESA ADAPTER (Safaricom Daraja)
# ──────────────────────────────────────────────────────────────
class MpesaProvider(BasePaymentProvider):
    def __init__(self):
        from django.conf import settings
        self.consumer_key    = settings.MPESA_CONSUMER_KEY
        self.consumer_secret = settings.MPESA_CONSUMER_SECRET
        self.shortcode       = settings.MPESA_SHORTCODE
        self.passkey         = settings.MPESA_PASSKEY
        self.callback_url    = settings.MPESA_CALLBACK_URL
        self.api_base_url    = settings.MPESA_API_BASE_URL.rstrip('/')

    def initiate_payment(self, amount: Decimal, currency: str, metadata: dict) -> dict:
        # STK Push — sends a payment prompt to the user's phone
        token     = self._get_access_token()
        timestamp = self._get_timestamp()
        password  = self._get_password(timestamp)
        phone     = self._normalize_phone(metadata.get('phone'))
        if not phone:
            raise ValueError('A valid Kenyan phone number is required for M-Pesa.')

        import requests
        response = requests.post(
            f'{self.api_base_url}/mpesa/stkpush/v1/processrequest',
            headers={'Authorization': f'Bearer {token}'},
            json={
                'BusinessShortCode': self.shortcode,
                'Password':         password,
                'Timestamp':        timestamp,
                'TransactionType':  'CustomerPayBillOnline',
                'Amount':           int(amount),
                'PartyA':           phone,
                'PartyB':           self.shortcode,
                'PhoneNumber':      phone,
                'CallBackURL':      self.callback_url,
                'AccountReference': metadata.get('reference', 'VERTX'),
                'TransactionDesc':  metadata.get('description', 'VERTX Payment'),
            },
            timeout=15,
        )
        response.raise_for_status()
        response = response.json()
        reference = response.get('CheckoutRequestID')
        if not reference:
            raise ValueError(
                response.get('errorMessage')
                or response.get('ResponseDescription')
                or 'M-Pesa request was not accepted.'
            )

        return {
            'reference':    reference,
            'redirect_url': None,
            'instructions': 'Check your phone for the M-Pesa payment prompt.',
        }

    def verify_payment(self, reference: str) -> dict:
        # In production: query Daraja API for STK query
        raise NotImplementedError('Use M-Pesa webhook for payment verification.')

    def handle_webhook(self, payload: dict, headers: dict) -> dict:
        result = payload.get('Body', {}).get('stkCallback', {})
        ref    = result.get('CheckoutRequestID', '')
        code   = result.get('ResultCode', 1)
        return {'reference': ref, 'status': 'success' if code == 0 else 'failed'}

    def _get_access_token(self):
        import requests, base64
        credentials = base64.b64encode(
            f'{self.consumer_key}:{self.consumer_secret}'.encode()
        ).decode()
        r = requests.get(
            f'{self.api_base_url}/oauth/v1/generate?grant_type=client_credentials',
            headers={'Authorization': f'Basic {credentials}'},
            timeout=15,
        )
        r.raise_for_status()
        return r.json()['access_token']

    @staticmethod
    def _normalize_phone(phone):
        digits = ''.join(ch for ch in str(phone or '') if ch.isdigit())
        if digits.startswith('0') and len(digits) == 10:
            return f'254{digits[1:]}'
        if digits.startswith('7') and len(digits) == 9:
            return f'254{digits}'
        if digits.startswith('254') and len(digits) == 12:
            return digits
        return None

    def _get_timestamp(self):
        from datetime import datetime
        return datetime.now().strftime('%Y%m%d%H%M%S')

    def _get_password(self, timestamp):
        import base64
        raw = f'{self.shortcode}{self.passkey}{timestamp}'
        return base64.b64encode(raw.encode()).decode()


# ──────────────────────────────────────────────────────────────
# PROVIDER REGISTRY
# ──────────────────────────────────────────────────────────────
PROVIDER_REGISTRY = {
    'stripe': StripeProvider,
    'mpesa':  MpesaProvider,
}


def get_provider(name: str) -> BasePaymentProvider:
    """
    Factory function — returns the correct provider instance.
    Usage: provider = get_provider('stripe')
    """
    cls = PROVIDER_REGISTRY.get(name)
    if not cls:
        raise ValueError(f'Unknown payment provider: {name}. Available: {list(PROVIDER_REGISTRY.keys())}')
    return cls()
