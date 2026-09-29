"""
VERTX Platform — Root URL Configuration
"""

from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path('health/', lambda request: JsonResponse({'status': 'ok'}), name='health'),
    # Django admin (internal use only)
    path('django-admin/', admin.site.urls),

    # API v1
    path('api/auth/',      include('apps.users.urls')),
    path('api/',           include('apps.content.urls')),
    path('api/admin/',     include('apps.moderation.urls')),
    path('api/payments/',  include('apps.payments.urls')),

    # API Schema & Docs
    path('api/schema/',    SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/',      SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
