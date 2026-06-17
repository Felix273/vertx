"""
VERTX Content — Views
Series browsing, episode management, streaming, and watch progress.
"""

from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, status, permissions, filters
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import PermissionDenied

from .models import Series, Episode, WatchHistory, ContentStatus
from .serializers import (
    SeriesListSerializer,
    SeriesDetailSerializer,
    SeriesWriteSerializer,
    SeriesProducerSerializer,
    EpisodeSerializer,
    EpisodeWriteSerializer,
    EpisodeDetailSerializer,
    WatchHistorySerializer,
    ProgressUpdateSerializer,
)
from .access import user_can_watch, get_access_status
from apps.users.permissions import IsProducer, IsAdmin, IsProducerOrAdmin


# ──────────────────────────────────────────────────────────────
# SERIES — Public Browse
# ──────────────────────────────────────────────────────────────
class SeriesListView(generics.ListAPIView):
    """
    GET /api/series/
    Browse all published series. Public — no auth required.
    """
    serializer_class   = SeriesListSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends    = [filters.SearchFilter, filters.OrderingFilter]
    search_fields      = ['title', 'description', 'genre']
    ordering_fields    = ['published_at', 'title']
    ordering           = ['-published_at']

    def get_queryset(self):
        qs = Series.objects.filter(status=ContentStatus.PUBLISHED).select_related('producer')
        genre = self.request.query_params.get('genre')
        if genre:
            qs = qs.filter(genre=genre)
        return qs


class SeriesDetailView(generics.RetrieveAPIView):
    """
    GET /api/series/{id}/
    Series detail with episodes list. Episodes don't include video_url here.
    """
    serializer_class   = SeriesDetailSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Series.objects.filter(
            status=ContentStatus.PUBLISHED
        ).select_related('producer').prefetch_related('episodes')


class AccessCheckView(APIView):
    """
    GET /api/series/{series_id}/access/
    Returns whether the current user can watch this series + paywall options.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, series_id):
        series = get_object_or_404(Series, id=series_id, status=ContentStatus.PUBLISHED)
        result = get_access_status(request.user, series)
        return Response(result)


# ──────────────────────────────────────────────────────────────
# SERIES — Producer Management
# ──────────────────────────────────────────────────────────────
class ProducerSeriesListCreateView(generics.ListCreateAPIView):
    """
    GET  /api/producer/series/     — list own series (all statuses)
    POST /api/producer/series/     — create new series
    """
    permission_classes = [IsProducer]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return SeriesWriteSerializer
        return SeriesProducerSerializer

    def get_queryset(self):
        return Series.objects.filter(
            producer=self.request.user.producer_profile
        ).prefetch_related('episodes')

    def perform_create(self, serializer):
        serializer.save(producer=self.request.user.producer_profile)


class ProducerSeriesDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/producer/series/{id}/  — series detail
    PATCH  /api/producer/series/{id}/  — update (only allowed in draft/rejected)
    DELETE /api/producer/series/{id}/  — delete (only draft)
    """
    permission_classes = [IsProducer]

    def get_serializer_class(self):
        if self.request.method in ('PUT', 'PATCH'):
            return SeriesWriteSerializer
        return SeriesProducerSerializer

    def get_queryset(self):
        return Series.objects.filter(producer=self.request.user.producer_profile)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.status == ContentStatus.PUBLISHED:
            raise PermissionDenied('Published series cannot be edited. Contact admin.')
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.status != ContentStatus.DRAFT:
            raise PermissionDenied('Only draft series can be deleted.')
        return super().destroy(request, *args, **kwargs)


class SubmitForReviewView(APIView):
    """
    POST /api/producer/series/{id}/submit/
    Moves series from draft/rejected → pending_review.
    Validates that at least one episode exists.
    """
    permission_classes = [IsProducer]

    def post(self, request, pk):
        series = get_object_or_404(
            Series,
            id=pk,
            producer=request.user.producer_profile
        )

        if series.status not in (ContentStatus.DRAFT, ContentStatus.REJECTED):
            return Response(
                {'error': f'Cannot submit series with status: {series.status}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not series.episodes.exists():
            return Response(
                {'error': 'Series must have at least one episode before submission.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        series.status = ContentStatus.PENDING_REVIEW
        series.save(update_fields=['status', 'updated_at'])

        return Response({
            'message': 'Series submitted for review. You will be notified once reviewed.',
            'status': series.status,
        })


# ──────────────────────────────────────────────────────────────
# EPISODES — Producer Management
# ──────────────────────────────────────────────────────────────
class EpisodeListCreateView(generics.ListCreateAPIView):
    """
    GET  /api/producer/series/{series_id}/episodes/  — list episodes
    POST /api/producer/series/{series_id}/episodes/  — add episode
    """
    permission_classes = [IsProducer]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return EpisodeWriteSerializer
        return EpisodeSerializer

    def _get_series(self):
        return get_object_or_404(
            Series,
            id=self.kwargs['series_id'],
            producer=self.request.user.producer_profile
        )

    def get_queryset(self):
        return Episode.objects.filter(series=self._get_series())

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['series'] = self._get_series()
        return ctx

    def perform_create(self, serializer):
        series = self._get_series()
        if series.status == ContentStatus.PUBLISHED:
            raise PermissionDenied('Cannot add episodes to a published series.')
        serializer.save(series=series)


class EpisodeDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/producer/episodes/{id}/  — episode detail
    PATCH  /api/producer/episodes/{id}/  — update episode
    DELETE /api/producer/episodes/{id}/  — delete episode
    """
    permission_classes = [IsProducer]

    def get_serializer_class(self):
        if self.request.method in ('PUT', 'PATCH'):
            return EpisodeWriteSerializer
        return EpisodeSerializer

    def get_queryset(self):
        return Episode.objects.filter(
            series__producer=self.request.user.producer_profile
        )


# ──────────────────────────────────────────────────────────────
# STREAMING — Viewer Access
# ──────────────────────────────────────────────────────────────
class EpisodeStreamView(APIView):
    """
    GET /api/episodes/{id}/stream/
    Returns the video stream URL if user has access.
    This is the gate — never expose video_url without this check.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, episode_id):
        episode = get_object_or_404(
            Episode,
            id=episode_id,
            series__status=ContentStatus.PUBLISHED
        )

        if not user_can_watch(request.user, episode.series):
            access = get_access_status(request.user, episode.series)
            return Response(
                {'error': 'Access denied.', 'paywall': access},
                status=status.HTTP_403_FORBIDDEN
            )

        return Response({
            'episode_id':    str(episode.id),
            'video_url':     episode.video_url,
            'duration_secs': episode.duration_secs,
            'title':         episode.title,
        })


# ──────────────────────────────────────────────────────────────
# WATCH PROGRESS
# ──────────────────────────────────────────────────────────────
class WatchProgressView(APIView):
    """
    POST /api/episodes/{id}/progress/
    Save or update watch progress for the current user.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, episode_id):
        episode = get_object_or_404(
            Episode, id=episode_id,
            series__status=ContentStatus.PUBLISHED
        )

        serializer = ProgressUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        record, _ = WatchHistory.objects.update_or_create(
            user=request.user,
            episode=episode,
            defaults=serializer.validated_data
        )

        return Response({'message': 'Progress saved.', 'completed': record.completed})


class ContinueWatchingView(generics.ListAPIView):
    """
    GET /api/continue-watching/
    Returns user's most recently watched incomplete episodes.
    """
    serializer_class   = WatchHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return WatchHistory.objects.filter(
            user=self.request.user,
            completed=False,
            episode__series__status=ContentStatus.PUBLISHED
        ).select_related(
            'episode', 'episode__series'
        )[:20]


# ──────────────────────────────────────────────────────────────
# HOME FEED
# ──────────────────────────────────────────────────────────────
class HomeFeedView(APIView):
    """
    GET /api/home/
    Returns curated home feed sections.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        published = Series.objects.filter(
            status=ContentStatus.PUBLISHED
        ).select_related('producer')

        return Response({
            'featured':  SeriesListSerializer(published.order_by('-published_at')[:5],  many=True).data,
            'new':       SeriesListSerializer(published.order_by('-published_at')[:10], many=True).data,
            'free':      SeriesListSerializer(published.filter(is_free=True)[:10],      many=True).data,
        })
