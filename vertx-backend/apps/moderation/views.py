"""
VERTX Moderation — Views
Admin-only endpoints for reviewing and publishing content.
"""

from django.utils import timezone
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import serializers

from apps.content.models import Series, ContentStatus
from apps.content.serializers import SeriesDetailSerializer
from apps.users.models import User
from apps.users.permissions import IsAdmin
from apps.users.serializers import UserProfileSerializer
from .models import ModerationLog, ModerationAction


# ── Serializers (inline — moderation is simple) ──────────────
class ModerationActionSerializer(serializers.Serializer):
    note = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        # Note is required for rejections
        if self.context.get('action') == ModerationAction.REJECTED:
            if not attrs.get('note', '').strip():
                raise serializers.ValidationError({'note': 'A rejection note is required.'})
        return attrs


class ModerationLogSerializer(serializers.ModelSerializer):
    reviewed_by_email = serializers.CharField(source='reviewed_by.email', read_only=True)
    series_title      = serializers.CharField(source='series.title', read_only=True)

    class Meta:
        model  = ModerationLog
        fields = ('id', 'series_title', 'action', 'note', 'reviewed_by_email', 'reviewed_at')


class AdminSeriesSerializer(serializers.ModelSerializer):
    """Series view for admin — includes full data + producer info."""
    producer_name  = serializers.CharField(source='producer.studio_name', read_only=True)
    producer_email = serializers.CharField(source='producer.user.email', read_only=True)
    episode_count  = serializers.ReadOnlyField()

    class Meta:
        model  = Series
        fields = (
            'id', 'title', 'description', 'genre',
            'thumbnail_url', 'trailer_url',
            'price', 'is_free', 'status',
            'producer_name', 'producer_email',
            'episode_count', 'created_at', 'updated_at',
        )


# ── Views ─────────────────────────────────────────────────────
class ModerationQueueView(generics.ListAPIView):
    """
    GET /api/admin/queue/
    All series pending review, newest first.
    """
    serializer_class   = AdminSeriesSerializer
    permission_classes = [IsAdmin]

    def get_queryset(self):
        return Series.objects.filter(
            status=ContentStatus.PENDING_REVIEW
        ).select_related('producer', 'producer__user').prefetch_related('episodes')


class ApproveSeriesView(APIView):
    """
    POST /api/admin/series/{id}/approve/
    Approves and immediately publishes the series.
    """
    permission_classes = [IsAdmin]

    def post(self, request, pk):
        series = get_object_or_404(Series, id=pk)

        if series.status != ContentStatus.PENDING_REVIEW:
            return Response(
                {'error': f'Series is not pending review (current: {series.status}).'},
                status=status.HTTP_400_BAD_REQUEST
            )

        series.status       = ContentStatus.PUBLISHED
        series.published_at = timezone.now()
        series.save(update_fields=['status', 'published_at', 'updated_at'])

        ModerationLog.objects.create(
            series=series,
            reviewed_by=request.user,
            action=ModerationAction.APPROVED,
            note=request.data.get('note', ''),
        )

        return Response({
            'message': f'"{series.title}" is now published.',
            'status':  series.status,
        })


class RejectSeriesView(APIView):
    """
    POST /api/admin/series/{id}/reject/
    Rejects a series and requires a note explaining why.
    """
    permission_classes = [IsAdmin]

    def post(self, request, pk):
        series = get_object_or_404(Series, id=pk)

        if series.status != ContentStatus.PENDING_REVIEW:
            return Response(
                {'error': f'Series is not pending review (current: {series.status}).'},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = ModerationActionSerializer(
            data=request.data,
            context={'action': ModerationAction.REJECTED}
        )
        serializer.is_valid(raise_exception=True)

        series.status = ContentStatus.REJECTED
        series.save(update_fields=['status', 'updated_at'])

        ModerationLog.objects.create(
            series=series,
            reviewed_by=request.user,
            action=ModerationAction.REJECTED,
            note=serializer.validated_data['note'],
        )

        return Response({
            'message': f'"{series.title}" has been rejected.',
            'status':  series.status,
            'note':    serializer.validated_data['note'],
        })


class AdminSeriesListView(generics.ListAPIView):
    """
    GET /api/admin/series/
    All series (any status) — for full admin oversight.
    """
    serializer_class   = AdminSeriesSerializer
    permission_classes = [IsAdmin]

    def get_queryset(self):
        qs     = Series.objects.select_related('producer', 'producer__user')
        status_filter = self.request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter)
        return qs.order_by('-created_at')


class AdminUserListView(generics.ListAPIView):
    """
    GET /api/admin/users/
    All platform users with optional role filter.
    """
    serializer_class   = UserProfileSerializer
    permission_classes = [IsAdmin]

    def get_queryset(self):
        qs   = User.objects.all()
        role = self.request.query_params.get('role')
        if role:
            qs = qs.filter(role=role)
        return qs.order_by('-created_at')


class AdminUserToggleView(APIView):
    """
    POST /api/admin/users/{id}/toggle/
    Activate or deactivate a user account.
    """
    permission_classes = [IsAdmin]

    def post(self, request, pk):
        user = get_object_or_404(User, id=pk)
        if user.is_platform_admin:
            return Response(
                {'error': 'Cannot deactivate an admin account.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        user.is_active = not user.is_active
        user.save(update_fields=['is_active'])
        state = 'activated' if user.is_active else 'deactivated'
        return Response({'message': f'User {state}.', 'is_active': user.is_active})


class ModerationLogView(generics.ListAPIView):
    """
    GET /api/admin/log/
    Full audit trail of moderation decisions.
    """
    serializer_class   = ModerationLogSerializer
    permission_classes = [IsAdmin]

    def get_queryset(self):
        return ModerationLog.objects.select_related(
            'series', 'reviewed_by'
        ).order_by('-reviewed_at')
