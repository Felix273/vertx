"""
VERTX Content — URL Patterns
"""

from django.urls import path
from .views import (
    # Public
    SeriesListView,
    SeriesDetailView,
    AccessCheckView,
    HomeFeedView,
    # Viewer
    EpisodeStreamView,
    WatchProgressView,
    ContinueWatchingView,
    # Producer
    ProducerSeriesListCreateView,
    ProducerSeriesDetailView,
    SubmitForReviewView,
    EpisodeListCreateView,
    EpisodeDetailView,
)

urlpatterns = [
    # ── Public ──────────────────────────────────
    path('home/',                                        HomeFeedView.as_view(),                 name='home-feed'),
    path('series/',                                      SeriesListView.as_view(),               name='series-list'),
    path('series/<uuid:pk>/',                            SeriesDetailView.as_view(),             name='series-detail'),
    path('series/<uuid:series_id>/access/',              AccessCheckView.as_view(),              name='series-access'),

    # ── Viewer ───────────────────────────────────
    path('episodes/<uuid:episode_id>/stream/',           EpisodeStreamView.as_view(),            name='episode-stream'),
    path('episodes/<uuid:episode_id>/progress/',         WatchProgressView.as_view(),            name='episode-progress'),
    path('continue-watching/',                           ContinueWatchingView.as_view(),         name='continue-watching'),

    # ── Producer ─────────────────────────────────
    path('producer/series/',                             ProducerSeriesListCreateView.as_view(), name='producer-series-list'),
    path('producer/series/<uuid:pk>/',                   ProducerSeriesDetailView.as_view(),     name='producer-series-detail'),
    path('producer/series/<uuid:pk>/submit/',            SubmitForReviewView.as_view(),          name='series-submit'),
    path('producer/series/<uuid:series_id>/episodes/',   EpisodeListCreateView.as_view(),        name='episode-list'),
    path('producer/episodes/<uuid:pk>/',                 EpisodeDetailView.as_view(),            name='episode-detail'),
]
