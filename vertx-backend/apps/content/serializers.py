"""
VERTX Content — Serializers
Handles series and episode read/write with role-aware field exposure.
"""

from rest_framework import serializers
from .models import Series, Episode, WatchHistory


class EpisodeSerializer(serializers.ModelSerializer):
    """Public episode metadata; the stream URL is always gated separately."""
    duration_display = serializers.ReadOnlyField()

    class Meta:
        model = Episode
        fields = (
            'id', 'episode_number', 'title', 'description',
            'thumbnail_url', 'duration_secs', 'duration_display',
            'created_at',
        )


class EpisodeDetailSerializer(EpisodeSerializer):
    """Full episode data including stream URL after access is verified."""
    class Meta(EpisodeSerializer.Meta):
        fields = EpisodeSerializer.Meta.fields + ('video_url',)


class EpisodeProducerSerializer(EpisodeSerializer):
    """Producer-facing episode data, including editable video metadata."""
    class Meta(EpisodeSerializer.Meta):
        fields = EpisodeSerializer.Meta.fields + ('video_url', 'video_id', 'updated_at')


class EpisodeWriteSerializer(serializers.ModelSerializer):
    """Used by producers to create or update episodes."""
    class Meta:
        model = Episode
        fields = (
            'episode_number', 'title', 'description',
            'video_url', 'video_id', 'duration_secs', 'thumbnail_url',
        )

    def validate_episode_number(self, value):
        series = self.context.get('series')
        qs = Episode.objects.filter(series=series, episode_number=value)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError(
                f'Episode number {value} already exists in this series.'
            )
        return value


class SeriesListSerializer(serializers.ModelSerializer):
    """Compact serializer for browse/search lists."""
    producer_name = serializers.CharField(source='producer.studio_name', read_only=True)
    episode_count = serializers.ReadOnlyField()

    class Meta:
        model = Series
        fields = (
            'id', 'title', 'description', 'genre',
            'thumbnail_url', 'price', 'is_free',
            'producer_name', 'episode_count', 'published_at',
        )


class SeriesDetailSerializer(serializers.ModelSerializer):
    """Full published series with public episode metadata."""
    producer_name = serializers.CharField(source='producer.studio_name', read_only=True)
    episode_count = serializers.ReadOnlyField()
    episodes = EpisodeSerializer(many=True, read_only=True)

    class Meta:
        model = Series
        fields = (
            'id', 'title', 'description', 'genre',
            'thumbnail_url', 'trailer_url',
            'price', 'is_free',
            'producer_name', 'episode_count',
            'episodes', 'published_at',
        )


class SeriesWriteSerializer(serializers.ModelSerializer):
    """Used by producers to create/update series."""
    class Meta:
        model = Series
        fields = (
            'title', 'description', 'genre',
            'thumbnail_url', 'trailer_url',
            'price', 'is_free',
        )

    def validate(self, attrs):
        # Free content should never carry a second, conflicting purchase price.
        if attrs.get('is_free') is True:
            attrs['price'] = 0
        return attrs


class SeriesProducerSerializer(serializers.ModelSerializer):
    """Producer's own view — includes status and editable episode metadata."""
    episode_count = serializers.ReadOnlyField()
    episodes = EpisodeProducerSerializer(many=True, read_only=True)

    class Meta:
        model = Series
        fields = (
            'id', 'title', 'description', 'genre',
            'thumbnail_url', 'trailer_url',
            'price', 'is_free', 'status',
            'episode_count', 'episodes',
            'created_at', 'updated_at',
        )
        read_only_fields = ('id', 'status', 'created_at', 'updated_at')


class WatchHistorySerializer(serializers.ModelSerializer):
    series_id = serializers.UUIDField(source='episode.series.id', read_only=True)
    series_title = serializers.CharField(source='episode.series.title', read_only=True)
    episode_num = serializers.IntegerField(source='episode.episode_number', read_only=True)
    episode_title = serializers.CharField(source='episode.title', read_only=True)
    thumbnail = serializers.URLField(source='episode.thumbnail_url', read_only=True)
    episode_duration_secs = serializers.IntegerField(source='episode.duration_secs', read_only=True)

    class Meta:
        model = WatchHistory
        fields = (
            'id', 'series_id', 'series_title',
            'episode_num', 'episode_title', 'thumbnail',
            'episode_duration_secs', 'progress_secs', 'completed', 'watched_at',
        )


class ProgressUpdateSerializer(serializers.Serializer):
    progress_secs = serializers.IntegerField(min_value=0)
    completed = serializers.BooleanField(default=False)
