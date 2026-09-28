import pytest

from app import create_app
from models import db


@pytest.fixture
def app():
    app = create_app(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
        }
    )

    with app.app_context():
        db.create_all()

    yield app

    with app.app_context():
        db.drop_all()


@pytest.fixture
def client(app):
    return app.test_client()


def test_create_task_with_priority(client):
    response = client.post(
        "/api/tasks",
        json={
            "title": "Finish project",
            "priority": "high",
        },
    )

    assert response.status_code == 201

    data = response.get_json()

    assert data["title"] == "Finish project"
    assert data["priority"] == "high"
    assert data["completed"] is False


def test_default_priority_is_medium(client):
    response = client.post(
        "/api/tasks",
        json={
            "title": "Read documentation",
        },
    )

    assert response.status_code == 201

    data = response.get_json()

    assert data["priority"] == "medium"


def test_invalid_priority_is_rejected(client):
    response = client.post(
        "/api/tasks",
        json={
            "title": "Invalid task",
            "priority": "urgent",
        },
    )

    assert response.status_code == 400

    data = response.get_json()

    assert "error" in data


def test_get_tasks(client):
    client.post(
        "/api/tasks",
        json={
            "title": "Task one",
            "priority": "low",
        },
    )

    response = client.get("/api/tasks")

    assert response.status_code == 200

    data = response.get_json()

    assert len(data) == 1
    assert data[0]["title"] == "Task one"
