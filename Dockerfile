FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first so this layer is cached on rebuilds
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy the rest of the app (app.py, templates/, *.3mf, etc.)
COPY . .

# Run as a non-root user
RUN useradd -m appuser \
    && mkdir -p /app/uploads \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/')" || exit 1

# NOTE: app.py's own `app.run()` defaults to binding 127.0.0.1, which is not
# reachable from outside the container. Running via gunicorn instead imports
# the Flask `app` object directly and binds it to 0.0.0.0 ourselves, so the
# service is reachable from other devices on your network.
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--timeout", "120", "app:app"]
