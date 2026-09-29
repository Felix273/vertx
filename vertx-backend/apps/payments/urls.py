from django.urls import path
from .views import (
    SubscribeView,
    PurchaseSeriesView,
    PaymentWebhookView,
    PaymentHistoryView,
    ProducerEarningsView,
    PaymentStatusView,
    SubscriptionStatusView,
)

urlpatterns = [
    path('subscribe/',                          SubscribeView.as_view(),          name='subscribe'),
    path('purchase/<uuid:series_id>/',          PurchaseSeriesView.as_view(),     name='purchase-series'),
    path('webhook/<str:provider_name>/',        PaymentWebhookView.as_view(),     name='payment-webhook'),
    path('history/',                             PaymentHistoryView.as_view(),     name='payment-history'),
    path('earnings/',                            ProducerEarningsView.as_view(),   name='producer-earnings'),
    path('status/<uuid:payment_id>/',            PaymentStatusView.as_view(),      name='payment-status'),
    path('subscription/',                       SubscriptionStatusView.as_view(), name='subscription-status'),
]
