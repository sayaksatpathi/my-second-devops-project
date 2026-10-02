"""User API tests. Run with: pytest (from app/user-api).

These run against the in-memory store + disabled cache (no external deps), so
they are fast and hermetic. Integration against real Postgres/Redis is covered
by scripts/integration-test.sh.
"""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    assert client.get("/health").json() == {"status": "healthy"}


def test_ready():
    r = client.get("/ready")
    assert r.status_code == 200
    assert r.json()["status"] == "ready"


def test_create_get_list_user():
    r = client.post("/users", json={"name": "Ada", "email": "ada@example.com"})
    assert r.status_code == 201
    uid = r.json()["id"]

    r = client.get(f"/users/{uid}")
    assert r.status_code == 200
    assert r.json()["name"] == "Ada"

    assert client.get("/users").json()["count"] >= 1


def test_get_missing_user_404():
    assert client.get("/users/999999").status_code == 404


def test_invalid_email_rejected():
    r = client.post("/users", json={"name": "x", "email": "not-an-email"})
    assert r.status_code == 422


def test_metrics_exposed():
    client.get("/")
    body = client.get("/metrics").text
    assert "http_requests_total" in body
    assert "http_request_duration_seconds" in body
