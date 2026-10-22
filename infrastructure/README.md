# Signalfold infrastructure (AWS)

Host Django on **App Runner** + **ECR**, with a **dedicated Postgres database** on the shared [tck-labs-base](../../tck-labs-base) RDS instance.

## Important AWS notes

- **App Runner is closed to new AWS customers** (as of AWS announcements recommending ECS Express Mode). If `terraform apply` fails creating an App Runner service, this account cannot use App Runner — switch compute later; ECR + Secrets + DB scripts still apply.
- App Runner **MinSize ≥ 1**: you pay for **memory** of one provisioned instance when idle; CPU is billed when handling requests. This is not Cloud Run–style absolute $0 compute.

## Isolation model

Same RDS **host**, separate Postgres **databases**:

```sql
CREATE DATABASE signalfold_dev;
CREATE DATABASE signalfold_prod;
```

Not table prefixes. Not schemas-as-isolation. Bootstrap DB `tcklabs` is never used for app data.

## Prerequisites

- WSL + AWS SSO: `AWS_PROFILE=AdministratorAccess-465836752303`
- Shared RDS already applied via tck-labs-base
- Docker (for image push)
- `psql` client (for `create-databases`)
- Google OAuth web client (callback will be the App Runner URL)

## Deploy sequence

From Windows (repo root):

```bash
# 1) Dedicated DBs on shared RDS (CREATE DATABASE — not table prefixes)
wsl bash infrastructure/run-wsl.sh create-databases

# 1b) Google OAuth into Secrets Manager (from web/.env); edit later in Console
wsl bash infrastructure/run-wsl.sh upsert-google-oauth

# 2) Tfvars
cp infrastructure/env/dev/terraform.tfvars.example infrastructure/env/dev/terraform.tfvars
# leave enable_apprunner = false

# 3) ECR + Secrets Manager app secret (no App Runner yet)
wsl bash infrastructure/run-wsl.sh apply dev

# 4) Build/push image
wsl bash infrastructure/run-wsl.sh push-image

# 5) Enable App Runner
# set enable_apprunner = true in terraform.tfvars
wsl bash infrastructure/run-wsl.sh apply dev

# 6) CSRF / Site
# terraform output -raw service_url → strip https:// into public_hostname
wsl bash infrastructure/run-wsl.sh apply dev
```

Google Cloud Console — add:

- Origin: `https://<hostname>`
- Redirect: `https://<hostname>/accounts/google/login/callback/`

## Layout

| Path | Role |
|------|------|
| [`modules/apprunner_web`](modules/apprunner_web) | ECR, Secrets Manager app secret, App Runner, IAM |
| [`env/dev`](env/dev) | Dev wiring → DB `signalfold_dev` |
| [`scripts/create_databases.sh`](scripts/create_databases.sh) | `CREATE DATABASE` on shared RDS |
| [`scripts/push_image.sh`](scripts/push_image.sh) | `docker build` + ECR push |

Remote state: `s3://tck-labs-tfstate-6fd94603/signalfold.dev.tfstate`

## App URL

```bash
wsl bash infrastructure/run-wsl.sh outputs dev
# prints APP_URL=https://….awsapprunner.com
```

## Google OAuth (AWS Secrets Manager, not GitHub)

Secret name: `signalfold/dev/google-oauth`  
Keys: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`  
Managed in the AWS Console (or seed once from `web/.env`):

```bash
wsl bash infrastructure/run-wsl.sh upsert-google-oauth
```

Terraform only **reads** this secret; it does not own the value.

## GitHub Actions deploy (lexloop-style)

Workflow: [`.github/workflows/deploy-infra.yml`](../.github/workflows/deploy-infra.yml)

- Assumes `${{ secrets.AWS_ROLE_ARN }}` via OIDC
- Runs `fmt-check` / `lint`, applies Terraform, builds/pushes the image, enables App Runner, posts **App URL** as a job summary + `::notice`

**Repo secret:** `AWS_ROLE_ARN` only (Google stays in AWS Secrets Manager).

## Local vs AWS DB

Local default remains SQLite. To hit shared RDS from a laptop:

```
DATABASE_URL=postgresql://tckadmin:...@tck-labs-shared.cjmwyu84sg6w.eu-central-1.rds.amazonaws.com:5432/signalfold_dev?sslmode=require
DATABASE_SSL=true
```

(Pull password from Secrets Manager `tck-labs/shared/rds`.)
