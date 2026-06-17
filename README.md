# VERTX

VERTX is a vertical streaming platform split into three projects:

```text
VERTX/
  vertx-backend/
  vertx-producer/
  vertx-flutter/
  README.md
  .gitignore
```

## Projects

- `vertx-backend/` - Django REST API for users, content, moderation, and payments.
- `vertx-producer/` - Next.js dashboard for producers and admins.
- `vertx-flutter/` - Flutter viewer app for mobile and desktop targets.

## Common Commands

Backend:

```bash
cd vertx-backend
pip install -r requirements/base.txt
python manage.py migrate
python manage.py runserver
```

Producer dashboard:

```bash
cd vertx-producer
npm install
npm run dev
```

Flutter app:

```bash
cd vertx-flutter
flutter pub get
flutter run
```
# vertx
