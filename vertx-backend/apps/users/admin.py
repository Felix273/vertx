from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, ProducerProfile


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display   = ('email', 'full_name', 'role', 'is_active', 'created_at')
    list_filter    = ('role', 'is_active')
    search_fields  = ('email', 'full_name')
    ordering       = ('-created_at',)
    fieldsets = (
        (None,            {'fields': ('email', 'password')}),
        ('Personal info', {'fields': ('full_name',)}),
        ('Role & Access', {'fields': ('role', 'is_active', 'is_staff', 'is_superuser')}),
        ('Permissions',   {'fields': ('groups', 'user_permissions')}),
        ('Dates',         {'fields': ('last_login', 'created_at')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'full_name', 'role', 'password1', 'password2'),
        }),
    )
    readonly_fields = ('created_at',)


@admin.register(ProducerProfile)
class ProducerProfileAdmin(admin.ModelAdmin):
    list_display  = ('studio_name', 'user', 'verified', 'created_at')
    list_filter   = ('verified',)
    search_fields = ('studio_name', 'user__email')
