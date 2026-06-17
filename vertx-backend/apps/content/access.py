"""
VERTX Content — Access Control
Central function that determines if a user can watch a series.
This is the core gating logic — always enforced server-side.
"""

from django.utils import timezone


def user_can_watch(user, series) -> bool:
    """
    Returns True if the user has access to watch the given series.

    Access is granted if ANY of the following is true:
    1. The series is marked as free
    2. The user has an active subscription
    3. The user has purchased this specific series
    """
    if not user or not user.is_authenticated:
        return False

    # Free content — no gate
    if series.is_free:
        return True

    # Check active subscription
    if _has_active_subscription(user):
        return True

    # Check individual series purchase
    if _has_purchased_series(user, series):
        return True

    return False


def _has_active_subscription(user) -> bool:
    """Check if user has a currently active subscription."""
    from apps.payments.models import Subscription, SubscriptionStatus
    return Subscription.objects.filter(
        user=user,
        status=SubscriptionStatus.ACTIVE,
        expires_at__gt=timezone.now()
    ).exists()


def _has_purchased_series(user, series) -> bool:
    """Check if user has purchased this specific series."""
    from apps.payments.models import SeriesPurchase
    return SeriesPurchase.objects.filter(
        user=user,
        series=series
    ).exists()


def get_access_status(user, series) -> dict:
    """
    Returns a dict describing access state — used by frontend
    to decide which paywall to show.
    """
    if not user.is_authenticated:
        return {'has_access': False, 'reason': 'unauthenticated'}

    if series.is_free:
        return {'has_access': True, 'reason': 'free'}

    if _has_active_subscription(user):
        return {'has_access': True, 'reason': 'subscription'}

    if _has_purchased_series(user, series):
        return {'has_access': True, 'reason': 'purchased'}

    # No access — tell frontend what options exist
    return {
        'has_access': False,
        'reason': 'no_access',
        'options': {
            'subscribe': True,
            'purchase': series.price > 0,
            'price': str(series.price),
        }
    }
