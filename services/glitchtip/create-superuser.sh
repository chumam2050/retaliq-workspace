#!/usr/bin/env bash
set -e

# Use environment values, with defaults for safe fallback.
email="${GLITCHTIP_SUPERUSER_EMAIL:-admin@example.com}"
username="${GLITCHTIP_SUPERUSER_USERNAME:-admin}"
password="${GLITCHTIP_SUPERUSER_PASSWORD:-password}"

echo "GlitchTip superuser setup:"

python manage.py shell <<PY
import os
from django.contrib.auth import get_user_model

User = get_user_model()

email = os.environ.get('GLITCHTIP_SUPERUSER_EMAIL', '${email}')
password = os.environ.get('GLITCHTIP_SUPERUSER_PASSWORD', '${password}')

user, created = User.objects.get_or_create(
    email=email,
    defaults={
        'is_superuser': True,
        'is_staff': True,
        'is_active': True,
        'name': 'Admin',
        'subscribe_by_default': True,
        'analytics': {},
        'options': {},
    },
)

if created:
    user.set_password(password)
    user.save()
    print('GlitchTip superuser created:', email)
else:
    changed = False
    if not user.is_superuser:
        user.is_superuser = True
        changed = True
    if not user.is_staff:
        user.is_staff = True
        changed = True
    if not user.is_active:
        user.is_active = True
        changed = True
    if changed:
        user.save()
    print('GlitchTip superuser already exists (checked/updated):', email)
    print('If you need to change the password, please do so manually.')
PY

echo "GlitchTip superuser setup complete."
