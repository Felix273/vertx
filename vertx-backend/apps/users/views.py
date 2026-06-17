"""
VERTX Users — Views
Authentication, registration, and profile management.
"""

from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User, ProducerProfile
from .serializers import (
    CustomTokenObtainPairSerializer,
    ViewerRegisterSerializer,
    ProducerRegisterSerializer,
    UserProfileSerializer,
    ProducerProfileSerializer,
    ProducerProfileUpdateSerializer,
    ChangePasswordSerializer,
)
from .permissions import IsProducer


# ──────────────────────────────────────────────────────────────
# AUTH
# ──────────────────────────────────────────────────────────────
class LoginView(TokenObtainPairView):
    """
    POST /api/auth/login/
    Returns access + refresh JWT tokens with role claim embedded.
    """
    serializer_class = CustomTokenObtainPairSerializer


class ViewerRegisterView(generics.CreateAPIView):
    """
    POST /api/auth/register/viewer/
    Public endpoint — creates a viewer account.
    """
    serializer_class   = ViewerRegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Issue tokens immediately on registration
        refresh = RefreshToken.for_user(user)
        return Response({
            'message': 'Account created successfully.',
            'user': UserProfileSerializer(user).data,
            'tokens': {
                'access':  str(refresh.access_token),
                'refresh': str(refresh),
            }
        }, status=status.HTTP_201_CREATED)


class ProducerRegisterView(generics.CreateAPIView):
    """
    POST /api/auth/register/producer/
    Public endpoint — creates a producer account + studio profile.
    """
    serializer_class   = ProducerRegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        refresh = RefreshToken.for_user(user)
        return Response({
            'message': 'Producer account created. Welcome to VERTX.',
            'user': UserProfileSerializer(user).data,
            'tokens': {
                'access':  str(refresh.access_token),
                'refresh': str(refresh),
            }
        }, status=status.HTTP_201_CREATED)


class LogoutView(APIView):
    """
    POST /api/auth/logout/
    Blacklists the refresh token.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data['refresh']
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'message': 'Logged out successfully.'}, status=status.HTTP_200_OK)
        except Exception:
            return Response({'error': 'Invalid or expired token.'}, status=status.HTTP_400_BAD_REQUEST)


# ──────────────────────────────────────────────────────────────
# PROFILE
# ──────────────────────────────────────────────────────────────
class MeView(generics.RetrieveUpdateAPIView):
    """
    GET  /api/auth/me/   — current user profile
    PATCH /api/auth/me/  — update full_name
    """
    serializer_class   = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class ProducerProfileView(generics.RetrieveUpdateAPIView):
    """
    GET   /api/auth/producer/profile/  — get studio profile
    PATCH /api/auth/producer/profile/  — update studio profile
    """
    permission_classes = [IsProducer]

    def get_serializer_class(self):
        if self.request.method in ('PUT', 'PATCH'):
            return ProducerProfileUpdateSerializer
        return ProducerProfileSerializer

    def get_object(self):
        try:
            return self.request.user.producer_profile
        except ProducerProfile.DoesNotExist:
            from rest_framework.exceptions import NotFound
            raise NotFound('Producer profile not found.')


class ChangePasswordView(APIView):
    """
    POST /api/auth/change-password/
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        request.user.set_password(serializer.validated_data['new_password'])
        request.user.save()
        return Response({'message': 'Password updated successfully.'})
