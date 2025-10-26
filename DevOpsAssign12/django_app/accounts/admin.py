from django.contrib import admin
from .models import Login

@admin.register(Login)
class LoginAdmin(admin.ModelAdmin):
    list_display = ('username', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('username',)
    readonly_fields = ('created_at',)
