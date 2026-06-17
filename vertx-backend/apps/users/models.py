"""
VERTX Users — Models
Custom User model with role-based access.
Extends AbstractBaseUser for full control.
"""

import uuid
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.utils import timezone


class UserRole(models.TextChoices):
    VIEWER   = 'viewer',   'Viewer'
    PRODUCER = 'producer', 'Producer'
    ADMIN    = 'admin',    'Admin'


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')
        email = self.normalize_email(email)
        extra_fields.setdefault('role', UserRole.VIEWER)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_producer(self, email, password=None, **extra_fields):
        extra_fields['role'] = UserRole.PRODUCER
        return self.create_user(email, password, **extra_fields)

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields['role'] = UserRole.ADMIN
        extra_fields['is_staff'] = True
        extra_fields['is_superuser'] = True
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    id         = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email      = models.EmailField(unique=True, db_index=True)
    full_name  = models.CharField(max_length=255, blank=True)
    role       = models.CharField(max_length=20, choices=UserRole.choices, default=UserRole.VIEWER)
    is_active  = models.BooleanField(default=True)
    is_staff   = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD  = 'email'
    REQUIRED_FIELDS = ['full_name']

    class Meta:
        db_table = 'users'
        indexes  = [models.Index(fields=['email', 'role'])]

    def __str__(self):
        return f'{self.email} ({self.role})'

    # ── Role helpers ──────────────────────────
    @property
    def is_viewer(self):
        return self.role == UserRole.VIEWER

    @property
    def is_producer(self):
        return self.role == UserRole.PRODUCER

    @property
    def is_platform_admin(self):
        return self.role == UserRole.ADMIN


class ProducerProfile(models.Model):
    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user        = models.OneToOneField(
                    User, on_delete=models.CASCADE,
                    related_name='producer_profile',
                    limit_choices_to={'role': UserRole.PRODUCER}
                  )
    studio_name = models.CharField(max_length=255)
    bio         = models.TextField(blank=True)
    avatar_url  = models.URLField(blank=True)
    website     = models.URLField(blank=True)
    verified    = models.BooleanField(default=False)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'producer_profiles'

    def __str__(self):
        return self.studio_name
