# noise-to-signal infrastructure (AWS)

Django on **Lambda (container image) → Function URL → CloudFront**, image in **shared ECR**, data on shared [tck-labs-base](../../tck-labs-base) RDS.

## Stacks

| Stack | Path | State key | Contains |
|-------|------|-----------|----------|
| **shared** | [`env/shared`](env/shared) | `noise-to-signal.shared.tfstate` | ECR + Route 53 (`signal-to-noise.fyi`) + ACM wildcard |
| **app (dev)** | [`env/dev/app`](env/dev/app) | `noise-to-signal.dev.app.tfstate` | Lambda, Function URL, CloudFront, `beta.signal-to-noise.fyi` |

Environments share ECR + DNS; distinguish releases with **image tags**. Dev public URL: **https://beta.signal-to-noise.fyi/**

Deploy order: **shared → push image → app**.

## Cost model

- Scale to zero on compute (Lambda). Idle ≈ shared RDS + Secrets Manager (+ CloudFront when requested).
- Public URL is stable CloudFront `d….cloudfront.net` (Google OAuth). Raw `*.lambda-url.*` is origin-only.

## Isolation model

```sql
CREATE DATABASE noise_to_signal_dev;
CREATE DATABASE noise_to_signal_prod;
```

## Prerequisites

- WSL + AWS SSO: `AWS_PROFILE=AdministratorAccess-465836752303`
- [`just`](https://github.com/casey/just), Docker, `psql`, Google OAuth client
- Shared RDS via tck-labs-base

```bash
cd infrastructure
export AWS_PROFILE=AdministratorAccess-465836752303
just
```

## Layout

| Path | Role |
|------|------|
| [`justfile`](justfile) | `apply-shared`, `apply-app`, `deploy`, … |
| [`modules/ecr`](modules/ecr) | Shared ECR |
| [`modules/dns`](modules/dns) | Route 53 zone + ACM (us-east-1) |
| [`modules/web_app`](modules/web_app) | Per-env compute + CloudFront alias |
| [`env/shared`](env/shared) | Shared stack root |
| [`env/dev/app`](env/dev/app) | Dev app → `beta.signal-to-noise.fyi` |

## GitHub Actions

[`.github/workflows/deploy-infra.yml`](../.github/workflows/deploy-infra.yml) — OIDC + `just deploy <sha>`.

**Repo secret:** `AWS_ROLE_ARN` only.

## State / existing AWS resources

**No `moved` blocks** were added when splitting stacks. New state keys start empty, so the next apply will **try to create** resources. If `noise-to-signal-dev` ECR / old Lambda / etc. already exist from earlier deploys, either:

1. Delete/orphan the old resources and let Terraform create the new names (`noise-to-signal` ECR, etc.), or
2. `terraform import` into the new shared/app states.

Older state keys (`noise-to-signal.dev.tfstate`, `….dev.base.tfstate`) are unused by this layout.
