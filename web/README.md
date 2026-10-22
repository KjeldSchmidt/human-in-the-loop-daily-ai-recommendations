# Signalfold (web)

Django frontend for the personal news aggregator MVP. Placeholder ranking and follow-up questions — the LangGraph core in `../runner` is intentionally untouched.

Auth is **Google-only** (django-allauth). Django still has a `User` row per person; passwords are not used for end users.

## Google OAuth setup (where to put credentials)

1. In [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials), create an **OAuth 2.0 Client ID** of type **Web application**.
2. Authorized JavaScript origins:
   - Local: `http://127.0.0.1:8000`
   - AWS App Runner: `https://<service-id>.eu-central-1.awsapprunner.com`
3. Authorized redirect URIs (exact):
   - Local: `http://127.0.0.1:8000/accounts/google/login/callback/`
   - AWS: `https://<service-id>.eu-central-1.awsapprunner.com/accounts/google/login/callback/`
4. Put the client ID and secret in **`web/.env`** (local) or Terraform `terraform.tfvars` / Secrets Manager (AWS):

```
GOOGLE_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=....
```

Do not commit `.env`. A template is in [`.env.example`](.env.example).

**Important:** after editing `.env`, fully stop and start `runserver` (Ctrl+C, then start again). Django’s auto-reloader does **not** reload environment variables.

Also set `SITE_DOMAIN` to match the host (no scheme):

```
SITE_DOMAIN=127.0.0.1:8000
# App Runner:
SITE_DOMAIN=xxxxx.eu-central-1.awsapprunner.com
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
DATABASE_URL=postgresql://tckadmin:…@tck-labs-shared.cjmwyu84sg6w.eu-central-1.rds.amazonaws.com:5432/signalfold_dev?sslmode=require
DATABASE_SSL=true
```

## Deploy on AWS (App Runner + shared RDS)

See [`../infrastructure/README.md`](../infrastructure/README.md).

Summary:

1. `wsl bash infrastructure/run-wsl.sh create-databases` → `CREATE DATABASE signalfold_dev` / `signalfold_prod`
2. Terraform apply with `enable_apprunner=false` → ECR + app secret
3. `push-image` → Docker build/push
4. Terraform apply with `enable_apprunner=true`
5. Set `public_hostname` from `service_url`; update Google OAuth redirects

Container entrypoint runs `migrate` + `seed_demo` then Gunicorn on `$PORT` (8000 for App Runner).

### Caveats

- Seeded articles are demo content until real RSS ingestion lands.
- App Runner MinSize is 1 (idle memory cost); closed to some new AWS accounts — see infra README.
