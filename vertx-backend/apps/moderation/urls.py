from django.urls import path
from .views import (
    ModerationQueueView,
    ApproveSeriesView,
    RejectSeriesView,
    AdminSeriesListView,
    AdminUserListView,
    AdminUserToggleView,
    ModerationLogView,
    AdminStatsView,
    AdminPaymentListView,
)

urlpatterns = [
    path('stats/',                     AdminStatsView.as_view(),          name='admin-stats'),
    path('payments/',                  AdminPaymentListView.as_view(),   name='admin-payments'),
    path('queue/',                    ModerationQueueView.as_view(),    name='mod-queue'),
    path('series/',                   AdminSeriesListView.as_view(),     name='admin-series-list'),
    path('series/<uuid:pk>/approve/', ApproveSeriesView.as_view(),      name='series-approve'),
    path('series/<uuid:pk>/reject/',  RejectSeriesView.as_view(),       name='series-reject'),
    path('users/',                    AdminUserListView.as_view(),       name='admin-users'),
    path('users/<uuid:pk>/toggle/',   AdminUserToggleView.as_view(),     name='user-toggle'),
    path('log/',                      ModerationLogView.as_view(),       name='mod-log'),
]
