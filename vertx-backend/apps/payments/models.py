"""
VERTX Payments — Models
All transaction records. Modular provider design.
"""

import uuid
from django.db import models
from apps.users.models import User
from apps.content.models import Series


class SubscriptionPlan(models.TextChoices):
    WEEKLY  = 'weekly',  'Weekly'
    MONTHLY = 'monthly', 'Monthly'


class SubscriptionStatus(models.TextChoices):
    ACTIVE    = 'active',    'Active'
    EXPIRED   = 'expired',   'Expired'
    CANCELLED = 'cancelled', 'Cancelled'


class PaymentStatus(models.TextChoices):
    PENDING = 'pending', 'Pending'
    SUCCESS = 'success', 'Success'
    FAILED  = 'failed',  'Failed'
    REFUNDED= 'refunded','Refunded'


class Payment(models.Model):
    """
    Base record for every financial transaction on the platform.
    provider_reference = the transaction ID from the payment provider.
    """
    id                 = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user               = models.ForeignKey(User, on_delete=models.CASCADE, related_name='payments')
    provider           = models.CharField(max_length=50, help_text='e.g. stripe, mpesa, flutterwave')
    amount             = models.DecimalField(max_digits=10, decimal_places=2)
    currency           = models.CharField(max_length=10, default='USD')
    status             = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING)
    provider_reference = models.CharField(max_length=255, blank=True, db_index=True)
    metadata           = models.JSONField(default=dict, blank=True)
    created_at         = models.DateTimeField(auto_now_add=True)
    updated_at         = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'payments'
        ordering = ['-created_at']
        indexes  = [models.Index(fields=['user', 'status'])]

    def __str__(self):
        return f'{self.user.email} — {self.provider} — {self.amount} {self.currency} [{self.status}]'


class Subscription(models.Model):
    id         = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user       = models.ForeignKey(User, on_delete=models.CASCADE, related_name='subscriptions')
    plan       = models.CharField(max_length=20, choices=SubscriptionPlan.choices)
    status     = models.CharField(max_length=20, choices=SubscriptionStatus.choices, default=SubscriptionStatus.ACTIVE)
    payment    = models.ForeignKey(Payment, on_delete=models.SET_NULL, null=True, related_name='subscriptions')
    starts_at  = models.DateTimeField()
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'subscriptions'
        ordering = ['-created_at']
        indexes  = [models.Index(fields=['user', 'status', 'expires_at'])]

    def __str__(self):
        return f'{self.user.email} — {self.plan} [{self.status}]'


class SeriesPurchase(models.Model):
    id           = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user         = models.ForeignKey(User, on_delete=models.CASCADE, related_name='series_purchases')
    series       = models.ForeignKey(Series, on_delete=models.CASCADE, related_name='purchases')
    payment      = models.ForeignKey(Payment, on_delete=models.SET_NULL, null=True)
    purchased_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table        = 'series_purchases'
        unique_together = [('user', 'series')]

    def __str__(self):
        return f'{self.user.email} purchased {self.series.title}'
