# syntax=docker/dockerfile:1
FROM python:3.12-slim AS builder
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    PATH=/install/bin:$PATH PYTHONPATH=/install/lib/python3.12/site-packages
COPY --from=builder /install /install
WORKDIR /app
COPY worker.py .
RUN useradd --create-home --uid 10001 appuser
USER appuser
EXPOSE 9100
CMD ["python", "worker.py"]
