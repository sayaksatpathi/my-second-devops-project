FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY worker.py .
RUN useradd --create-home appuser
USER appuser
CMD ["python", "worker.py"]
