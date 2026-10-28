"""Shared-secret auth for machine callers (Lambdas) hitting /api/internal/."""

from __future__ import annotations

import hmac
from collections.abc import Callable
from functools import wraps
from typing import TypeVar

from django.conf import settings
from django.http import HttpRequest, HttpResponse, JsonResponse

F = TypeVar("F", bound=Callable[..., HttpResponse])


def _extract_bearer_token(request: HttpRequest) -> str:
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        return auth[7:].strip()
    return request.headers.get("X-Internal-Token", "").strip()


def require_internal_token(view: F) -> F:
    """Reject requests that lack a valid INTERNAL_API_TOKEN bearer/header."""

    @wraps(view)
    def wrapped(request: HttpRequest, *args, **kwargs) -> HttpResponse:
        expected = (getattr(settings, "INTERNAL_API_TOKEN", None) or "").strip()
        if not expected:
            return JsonResponse({"error": "internal API not configured"}, status=503)

        provided = _extract_bearer_token(request)
        if not provided or not hmac.compare_digest(provided, expected):
            return JsonResponse({"error": "unauthorized"}, status=401)

        return view(request, *args, **kwargs)

    return wrapped  # type: ignore[return-value]
