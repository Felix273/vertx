"""
VERTX Moderation — Models
Full audit log of every moderation action.
"""

import uuid
from django.db import models
from apps.users.models import User
from apps.content.models import Series


class ModerationAction(models.TextChoices):
    APPROVED = 'approved', 'Approved'
    REJECTED = 'rejected', 'Rejected'


class ModerationLog(models.Model):
    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    series      = models.ForeignKey(
                    Series, on_delete=models.CASCADE,
                    related_name='moderation_logs'
                  )
    reviewed_by = models.ForeignKey(
                    User, on_delete=models.SET_NULL,
                    null=True, related_name='moderation_actions'
                  )
    action      = models.CharField(max_length=20, choices=ModerationAction.choices)
    note        = models.TextField(blank=True, help_text='Required when rejecting.')
    reviewed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'moderation_log'
        ordering = ['-reviewed_at']

    def __str__(self):
        return f'{self.series.title} — {self.action} by {self.reviewed_by}'
