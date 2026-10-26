# noise-to-signal (web)

Django frontend for the personal news aggregator MVP. Placeholder ranking and follow-up questions — the LangGraph core in `../runner` is intentionally untouched.

Auth is **Google-only** (django-allauth). Django still has a `User` row per person; passwords are not used for end users.

## Google OAuth setup (where to put credentials)

1. In [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials), create an **OAuth 2.0 Client ID** of type **Web application**.
2. Authorized JavaScript origins:
   - Local: `http://127.0.0.1:8000`
   - AWS Lambda Function URL: `https://<id>.lambda-url.eu-central-1.on.aws`
3. Authorized redirect URIs (exact):
   - Local: `http://127.0.0.1:8000/accounts/google/login/callback/`
   - AWS: `https://<id>.lambda-url.eu-central-1.on.aws/accounts/google/login/callback/`
4. Put the client ID and secret in **`web/.env`** (local) or Secrets Manager (AWS):

```
GOOGLE_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=....
```

Do not commit `.env`. A template is in [`.env.example`](.env.example).

**Important:** after editing `.env`, fully stop and start `runserver` (Ctrl+C, then start again). Django’s auto-reloader does **not** reload environment variables.

Also set `SITE_DOMAIN` to match the host (no scheme):

```
SITE_DOMAIN=127.0.0.1:8000
# Lambda Function URL:
SITE_DOMAIN=xxxxxxxx.lambda-url.eu-central-1.on.aws
```

## Local development

From `web/`, `just` lists recipes:

```bash
cd web
cp .env.example .env   # then fill GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET
just sync
just setup             # migrate + seed
just run
```

Open http://127.0.0.1:8000 → **Continue with Google**.

Without `DATABASE_URL`, SQLite (`db.sqlite3`) is used. To use the shared AWS RDS lab DB:

```
DATABASE_URL=postgresql://tckadmin:…@tck-labs-shared.cjmwyu84sg6w.eu-central-1.rds.amazonaws.com:5432/noise_to_signal_dev?sslmode=require
DATABASE_SSL=true
```

## Deploy on AWS (Lambda container + shared RDS)

See [`../infrastructure/README.md`](../infrastructure/README.md).

Summary:

1. `cd infrastructure && just create-databases` → `CREATE DATABASE noise_to_signal_dev` / `noise_to_signal_prod`
2. Terraform apply with `enable_lambda=false` → ECR + app secret
3. `push-image` → Docker build/push (Lambda Python 3.12 + Mangum)
4. Terraform apply with `enable_lambda=true`
5. Set `public_hostname` from Function URL; update Google OAuth redirects
6. `aws lambda invoke` with `{"manage":["migrate","--noinput"]}` (and seed) — not on every cold start

### Caveats

- Seeded articles are demo content until real RSS ingestion lands.
- Cold starts are expected; idle compute cost is ~$0.
