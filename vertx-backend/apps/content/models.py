"""
VERTX Content — Models
Series and Episode models with full moderation status lifecycle.
"""

import uuid
from django.db import models
from django.core.validators import MinValueValidator
from apps.users.models import ProducerProfile


class ContentStatus(models.TextChoices):
    DRAFT          = 'draft',          'Draft'
    PENDING_REVIEW = 'pending_review', 'Pending Review'
    APPROVED       = 'approved',       'Approved'
    REJECTED       = 'rejected',       'Rejected'
    PUBLISHED      = 'published',      'Published'


class Genre(models.TextChoices):
    DRAMA      = 'drama',      'Drama'
    THRILLER   = 'thriller',   'Thriller'
    ROMANCE    = 'romance',    'Romance'
    COMEDY     = 'comedy',     'Comedy'
    ACTION     = 'action',     'Action'
    HORROR     = 'horror',     'Horror'
    DOCUMENTARY= 'documentary','Documentary'
    SCIFI      = 'scifi',      'Sci-Fi'
    OTHER      = 'other',      'Other'


class Series(models.Model):
    id           = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    producer     = models.ForeignKey(
                     ProducerProfile, on_delete=models.CASCADE,
                     related_name='series'
                   )
    title        = models.CharField(max_length=255, db_index=True)
    description  = models.TextField()
    genre        = models.CharField(max_length=50, choices=Genre.choices, default=Genre.OTHER)
    thumbnail_url= models.URLField(blank=True)
    trailer_url  = models.URLField(blank=True)

    # Monetization
    is_free      = models.BooleanField(default=False, help_text='Free to watch without subscription or purchase')
    price        = models.DecimalField(
                     max_digits=8, decimal_places=2,
                     default=0.00,
                     validators=[MinValueValidator(0)],
                     help_text='Price for pay-per-series. 0 = subscription only.'
                   )

    # Moderation lifecycle
    status       = models.CharField(
                     max_length=20, choices=ContentStatus.choices,
                     default=ContentStatus.DRAFT, db_index=True
                   )

    # Timestamps
    created_at   = models.DateTimeField(auto_now_add=True)
    updated_at   = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table  = 'series'
        ordering  = ['-created_at']
        indexes   = [
            models.Index(fields=['status', 'genre']),
            models.Index(fields=['producer', 'status']),
        ]
        verbose_name_plural = 'series'

    def __str__(self):
        return f'{self.title} [{self.status}]'

    @property
    def episode_count(self):
        return self.episodes.count()

    @property
    def is_published(self):
        return self.status == ContentStatus.PUBLISHED

    def can_be_watched_free(self):
        return self.is_free

    def requires_purchase(self):
        return self.price > 0 and not self.is_free


class Episode(models.Model):
    id             = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    series         = models.ForeignKey(
                       Series, on_delete=models.CASCADE,
                       related_name='episodes'
                     )
    episode_number = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    title          = models.CharField(max_length=255)
    description    = models.TextField(blank=True)

    # Video — stored as CDN URL, not binary
    video_url      = models.URLField(help_text='Cloudflare Stream / CDN URL')
    video_id       = models.CharField(
                       max_length=255, blank=True,
                       help_text='Provider video ID (e.g. Cloudflare Stream UID)'
                     )
    duration_secs  = models.PositiveIntegerField(
                       default=0,
                       help_text='Duration in seconds'
                     )
    thumbnail_url  = models.URLField(blank=True)

    created_at     = models.DateTimeField(auto_now_add=True)
    updated_at     = models.DateTimeField(auto_now=True)

    class Meta:
        db_table        = 'episodes'
        ordering        = ['episode_number']
        unique_together = [('series', 'episode_number')]
        indexes         = [models.Index(fields=['series', 'episode_number'])]

    def __str__(self):
        return f'{self.series.title} — E{self.episode_number}: {self.title}'

    @property
    def duration_display(self):
        mins = self.duration_secs // 60
        secs = self.duration_secs % 60
        return f'{mins}:{secs:02d}'


class WatchHistory(models.Model):
    """Tracks per-user, per-episode watch progress for Continue Watching."""
    id            = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user          = models.ForeignKey(
                      'users.User', on_delete=models.CASCADE,
                      related_name='watch_history'
                    )
    episode       = models.ForeignKey(
                      Episode, on_delete=models.CASCADE,
                      related_name='watch_records'
                    )
    progress_secs = models.PositiveIntegerField(default=0)
    completed     = models.BooleanField(default=False)
    watched_at    = models.DateTimeField(auto_now=True)

    class Meta:
        db_table        = 'watch_history'
        unique_together = [('user', 'episode')]
        ordering        = ['-watched_at']
        indexes         = [models.Index(fields=['user', 'watched_at'])]

    def __str__(self):
        return f'{self.user.email} — {self.episode}'
