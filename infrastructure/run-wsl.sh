#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$ROOT/do" "$ROOT/scripts/"*.sh 2>/dev/null || true
export PATH="$HOME/bin:/snap/bin:/usr/local/bin:$PATH"
export AWS_PROFILE="${AWS_PROFILE:-AdministratorAccess-465836752303}"
cd "$ROOT"
exec ./do "$@"
