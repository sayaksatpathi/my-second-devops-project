"""Tests for the User API. Run with: pytest"""
from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "healthy"}


def test_index():
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["service"] == "user-api"


def test_create_and_list_user():
    r = client.post("/users", json={"name": "Ada", "email": "ada@example.com"})
    assert r.status_code == 201
    assert r.json()["name"] == "Ada"

    r = client.get("/users")
    assert r.status_code == 200
    assert r.json()["count"] >= 1


def test_metrics_exposed():
    client.get("/")
    r = client.get("/metrics")
    assert r.status_code == 200
    assert "http_requests_total" in r.text
