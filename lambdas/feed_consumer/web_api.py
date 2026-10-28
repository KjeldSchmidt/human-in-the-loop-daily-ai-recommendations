"""Thin client for the Django /api/internal/* routes."""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from typing import Any


def list_feeds(
    *,
    base_url: str | None = None,
    token: str | None = None,
) -> list[dict[str, Any]]:
    """GET /api/internal/feeds/ with the shared INTERNAL_API_TOKEN."""
    base = (base_url or os.environ.get("WEB_API_BASE_URL", "")).rstrip("/")
    auth = token or os.environ.get("INTERNAL_API_TOKEN", "")
    if not base:
        raise ValueError("WEB_API_BASE_URL is required")
    if not auth:
        raise ValueError("INTERNAL_API_TOKEN is required")

    request = urllib.request.Request(
        f"{base}/api/internal/feeds/",
        headers={
            "Authorization": f"Bearer {auth}",
            "Accept": "application/json",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"list_feeds failed ({exc.code}): {body}") from exc

    return list(payload.get("feeds") or [])
