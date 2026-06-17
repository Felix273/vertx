"""
VERTX Users — Serializers
Handles registration, JWT customisation, and profile serialization.
"""

from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import User, ProducerProfile, UserRole


# ──────────────────────────────────────────────────────────────
# JWT — embed role in token payload
# ──────────────────────────────────────────────────────────────
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Custom claims — available on every decoded token
        token['role']      = user.role
        token['full_name'] = user.full_name
        token['email']     = user.email
        return token


# ──────────────────────────────────────────────────────────────
# REGISTRATION
# ──────────────────────────────────────────────────────────────
class ViewerRegisterSerializer(serializers.ModelSerializer):
    password  = serializers.CharField(write_only=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, label='Confirm password')

    class Meta:
        model  = User
        fields = ('email', 'full_name', 'password', 'password2')

    def validate(self, attrs):
        if attrs['password'] != attrs.pop('password2'):
            raise serializers.ValidationError({'password': 'Passwords do not match.'})
        return attrs

    def create(self, validated_data):
        return User.objects.create_user(**validated_data, role=UserRole.VIEWER)


class ProducerRegisterSerializer(serializers.ModelSerializer):
    password    = serializers.CharField(write_only=True, validators=[validate_password])
    password2   = serializers.CharField(write_only=True, label='Confirm password')
    studio_name = serializers.CharField(write_only=True)

    class Meta:
        model  = User
        fields = ('email', 'full_name', 'password', 'password2', 'studio_name')

    def validate(self, attrs):
        if attrs['password'] != attrs.pop('password2'):
            raise serializers.ValidationError({'password': 'Passwords do not match.'})
        return attrs

    def create(self, validated_data):
        studio_name = validated_data.pop('studio_name')
        user = User.objects.create_producer(**validated_data)
        ProducerProfile.objects.create(user=user, studio_name=studio_name)
        return user


# ──────────────────────────────────────────────────────────────
# USER PROFILE
# ──────────────────────────────────────────────────────────────
class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model  = User
        fields = ('id', 'email', 'full_name', 'role', 'created_at')
        read_only_fields = ('id', 'email', 'role', 'created_at')


class ProducerProfileSerializer(serializers.ModelSerializer):
    user = UserProfileSerializer(read_only=True)

    class Meta:
        model  = ProducerProfile
        fields = (
            'id', 'user', 'studio_name', 'bio',
            'avatar_url', 'website', 'verified', 'created_at'
        )
        read_only_fields = ('id', 'user', 'verified', 'created_at')


class ProducerProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model  = ProducerProfile
        fields = ('studio_name', 'bio', 'avatar_url', 'website')


# ──────────────────────────────────────────────────────────────
# PASSWORD CHANGE
# ──────────────────────────────────────────────────────────────
class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Current password is incorrect.')
        return value
