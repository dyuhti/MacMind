# PostgreSQL Setup Guide

This guide helps you configure PostgreSQL for the MacMind backend using SQLAlchemy.

## 1. DATABASE_URL format

Use one of these formats in `.env`:

- `postgresql://username:password@host:5432/database`
- `postgresql+psycopg://username:password@host:5432/database`

The backend normalizes `postgres://` and `postgresql://` to a SQLAlchemy-compatible psycopg URL.

## 2. Local setup example

1. Install PostgreSQL.
2. Create database and user.
3. Set `.env`:

```env
DATABASE_URL=postgresql+psycopg://postgres:password@localhost:5432/macmind
```

## 3. Render setup

1. Provision a PostgreSQL database in Render.
2. Copy the provided `DATABASE_URL`.
3. Set it in Render environment variables for the backend service.

## 4. Validate connection

Run:

```bash
python -c "from config.config import _normalize_database_url; import os; print(_normalize_database_url(os.getenv('DATABASE_URL','')))"
python -c "from app import create_app; app=create_app('production'); print(app.config['SQLALCHEMY_DATABASE_URI'])"
```

## 5. Notes

- Backend persistence is SQLAlchemy-only.
- No legacy direct DB connector usage is required.
- Driver requirement is in `requirements.txt`: `psycopg[binary]>=3.1.18`.

