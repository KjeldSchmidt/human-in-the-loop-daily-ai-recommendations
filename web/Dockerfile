# Container image for AWS Lambda (Mangum) — build context: web/
FROM public.ecr.aws/lambda/python:3.12 AS builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /build
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY . .
ENV SECRET_KEY=build-only \
    DJANGO_SETTINGS_MODULE=config.settings
RUN uv sync --frozen --no-dev \
    && uv run python manage.py collectstatic --noinput

# --- runtime ---
FROM public.ecr.aws/lambda/python:3.12

COPY --from=builder /build/.venv/lib/python3.12/site-packages /var/lang/lib/python3.12/site-packages
COPY --from=builder /build /var/task

# Ensure Django finds the project on PYTHONPATH
ENV PYTHONPATH=/var/task

CMD ["config.lambda_handler.handler"]
