#!/usr/bin/env bash
# Create dedicated Postgres databases on the tck-labs shared RDS host.
# Isolation = separate DATABASE catalogs (CREATE DATABASE), not table prefixes.
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-AdministratorAccess-465836752303}"
SECRET_ID="${SECRET_ID:-tck-labs/shared/rds}"
DATABASES=("signalfold_dev" "signalfold_prod")

echo "Fetching credentials from Secrets Manager (${SECRET_ID})..."
SECRET_JSON="$(aws secretsmanager get-secret-value \
  --profile "$AWS_PROFILE" \
  --region eu-central-1 \
  --secret-id "$SECRET_ID" \
  --query SecretString \
  --output text)"
export SECRET_JSON

HOST="$(python3 -c 'import json,os; print(json.loads(os.environ["SECRET_JSON"])["host"])')"
PORT="$(python3 -c 'import json,os; print(json.loads(os.environ["SECRET_JSON"])["port"])')"
USER="$(python3 -c 'import json,os; print(json.loads(os.environ["SECRET_JSON"])["username"])')"
PASS="$(python3 -c 'import json,os; print(json.loads(os.environ["SECRET_JSON"])["password"])')"

if ! command -v psql >/dev/null 2>&1; then
  echo "psql not found. Install PostgreSQL client, then re-run."
  echo "Or connect manually as tckadmin and run:"
  for db in "${DATABASES[@]}"; do
    echo "  CREATE DATABASE ${db};"
  done
  exit 1
fi

export PGPASSWORD="$PASS"
CONN="host=${HOST} port=${PORT} user=${USER} dbname=tcklabs sslmode=require"

for db in "${DATABASES[@]}"; do
  exists="$(psql "$CONN" -tAc "SELECT 1 FROM pg_database WHERE datname='${db}'")"
  if [[ "$exists" == "1" ]]; then
    echo "Database ${db} already exists — skip"
  else
    echo "Creating database ${db}..."
    psql "$CONN" -v ON_ERROR_STOP=1 -c "CREATE DATABASE ${db};"
    echo "Created ${db}"
  fi
done

echo "Done. App DATABASE_URL path must be /signalfold_dev or /signalfold_prod."
