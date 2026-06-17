"""
VERTX Users — URL Patterns
All routes prefixed with /api/auth/
"""

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    LoginView,
    ViewerRegisterView,
    ProducerRegisterView,
    LogoutView,
    MeView,
    ProducerProfileView,
    ChangePasswordView,
)

urlpatterns = [
    # Authentication
    path('login/',              LoginView.as_view(),            name='auth-login'),
    path('token/refresh/',      TokenRefreshView.as_view(),     name='token-refresh'),
    path('logout/',             LogoutView.as_view(),           name='auth-logout'),

    # Registration
    path('register/viewer/',    ViewerRegisterView.as_view(),   name='register-viewer'),
    path('register/producer/',  ProducerRegisterView.as_view(), name='register-producer'),

    # Profile
    path('me/',                 MeView.as_view(),               name='auth-me'),
    path('producer/profile/',   ProducerProfileView.as_view(),  name='producer-profile'),
    path('change-password/',    ChangePasswordView.as_view(),   name='change-password'),
]
