#!/bin/sh
# Local/container HTTP only (not used by Lambda — migrates run via lambda invoke).
set -e
exec uv run gunicorn config.wsgi:application --bind "0.0.0.0:${PORT:-8000}"
