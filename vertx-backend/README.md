# VERTX Platform — Setup Guide

## Prerequisites
- Python 3.12+
- PostgreSQL 16+
- Redis 7+
- Docker + Docker Compose (recommended)

---

## Quick Start (Docker — Recommended)

```bash
# 1. Enter backend project
cd vertx-backend

# 2. Copy environment file
cp .env.example .env
# Edit .env with your values (at minimum set SECRET_KEY and DB_PASSWORD)

# 3. Start all services
docker-compose up --build

# 4. Create admin user (in a new terminal)
docker-compose exec api python manage.py createsuperuser
```

API is live at: http://localhost:8000
API Docs at:    http://localhost:8000/api/docs/
Health probe:   http://localhost:8000/health/

### Seed local demo data

After migrations, create three published demo series with episodes and reusable
local accounts:

```bash
python manage.py seed_demo
```

Default credentials are `producer@vertx.local`, `viewer@vertx.local`, and
`admin@vertx.local`, all using `DemoPass123!`. Override the password with
`python manage.py seed_demo --password 'YourLocalPassword'`. The command is
idempotent and does not delete existing content unless `--reset` is supplied.

---

## Manual Setup (without Docker)

```bash
# 1. Enter backend project
cd vertx-backend

# 2. Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate

# 3. Install dependencies
pip install -r requirements/base.txt

# 4. Configure environment
cp .env.example .env
# Edit .env — set all required values
# For quick local development without PostgreSQL, set DB_ENGINE=sqlite.

# 5. Create PostgreSQL database
# Skip this step if DB_ENGINE=sqlite.
psql -U postgres -c "CREATE DATABASE vertx_db;"
psql -U postgres -c "CREATE USER vertx_user WITH PASSWORD 'yourpassword';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE vertx_db TO vertx_user;"

# 6. Create and run migrations
python manage.py makemigrations
python manage.py migrate

# 7. Create admin user
python manage.py createsuperuser

# 8. Start development server
python manage.py runserver
```

Do not use `cd vertx-backend/vertx`; the backend files now live directly in
`vertx-backend/`.

---

## API Endpoints Reference

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/register/viewer/ | Register viewer |
| POST | /api/auth/register/producer/ | Register producer |
| POST | /api/auth/login/ | Login → JWT tokens |
| POST | /api/auth/token/refresh/ | Refresh access token |
| POST | /api/auth/logout/ | Blacklist token |
| GET  | /api/auth/me/ | Current user |

### Content (Public)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/home/ | Home feed |
| GET | /api/series/ | Browse published series |
| GET | /api/series/{id}/ | Series detail |

### Content (Producer)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET/POST | /api/producer/series/ | List/create series |
| GET/PATCH | /api/producer/series/{id}/ | Manage series |
| POST | /api/producer/series/{id}/submit/ | Submit for review |
| GET/POST | /api/producer/series/{id}/episodes/ | Manage episodes |

### Moderation (Admin)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/admin/queue/ | Pending review queue |
| POST | /api/admin/series/{id}/approve/ | Approve → publish |
| POST | /api/admin/series/{id}/reject/ | Reject with note |
| GET | /api/admin/users/ | Manage users |

### Payments
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/payments/subscribe/ | Start subscription |
| POST | /api/payments/purchase/{series_id}/ | Buy series |
| POST | /api/payments/webhook/{provider}/ | Provider callback |
| GET  | /api/payments/subscription/ | Check sub status |
| GET  | /api/payments/status/{payment_id}/ | Check payment status |

Payment plans and series purchases are denominated in **KES**. Configure
`MPESA_API_BASE_URL=https://sandbox.safaricom.co.ke` for sandbox or
`https://api.safaricom.co.ke` for production.

---

## Project Structure

```
vertx/
├── config/
│   ├── settings.py       # All configuration
│   ├── urls.py           # Root URL routing
│   ├── celery.py         # Async task queue
│   └── wsgi.py
├── apps/
│   ├── users/            # Auth, roles, producer profiles
│   ├── content/          # Series, episodes, streaming, progress
│   ├── moderation/       # Admin review workflow + audit log
│   └── payments/         # Subscriptions, purchases, providers
├── requirements/
│   └── base.txt
├── .env.example
├── docker-compose.yml
├── Dockerfile
└── manage.py
```

---

## Adding a New Payment Provider

1. Create a class in `apps/payments/providers.py` extending `BasePaymentProvider`
2. Implement `initiate_payment()`, `verify_payment()`, `handle_webhook()`
3. Add to `PROVIDER_REGISTRY`
4. Add provider credentials to `.env`

That's it. No other files change.

---

## Environment Variables (Required)

| Variable | Description |
|----------|-------------|
| SECRET_KEY | Django secret key (50+ chars) |
| DB_PASSWORD | PostgreSQL password |
| DJANGO_DEBUG | True for dev, False for prod |

See `.env.example` for full list.
