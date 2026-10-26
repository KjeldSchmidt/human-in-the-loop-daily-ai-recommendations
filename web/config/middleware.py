"""Request tweaks for CloudFront → Lambda Function URL."""

from __future__ import annotations

from django.http import HttpRequest


class ViewerHostMiddleware:
    """Promote CloudFront ``X-Viewer-Host`` so absolute URLs / CSRF use the public host.

    CloudFront Functions cannot set ``X-Forwarded-Host`` (disallowed → 502), so the
    distribution copies the viewer Host into ``X-Viewer-Host`` instead. Origin Host
    remains the Lambda Function URL hostname.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request: HttpRequest):
        viewer_host = request.headers.get("X-Viewer-Host", "").strip()
        if viewer_host:
            request.META["HTTP_X_FORWARDED_HOST"] = viewer_host
            request.META["HTTP_X_FORWARDED_PROTO"] = "https"
        return self.get_response(request)
