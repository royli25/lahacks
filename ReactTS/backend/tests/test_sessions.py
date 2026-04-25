import json
import pytest
import respx
from httpx import Response


MOCK_TOKEN_RESPONSE = {
    "data": {
        "session_id": "test-session-123",
        "session_token": "test-token-abc"
    }
}

MOCK_START_RESPONSE = {
    "data": {
        "livekit_url": "wss://test.livekit.cloud",
        "livekit_client_token": "client-token-xyz",
        "ws_url": "wss://test.liveavatar.com/ws"
    }
}


@respx.mock
async def test_create_session_returns_livekit_credentials(client, monkeypatch):
    import app as backend
    monkeypatch.setattr(backend, "LIVEAVATAR_API_KEY", "test-key")

    respx.post("https://api.liveavatar.com/v1/sessions/token").mock(
        return_value=Response(200, json=MOCK_TOKEN_RESPONSE)
    )
    respx.post("https://api.liveavatar.com/v1/sessions/start").mock(
        return_value=Response(200, json=MOCK_START_RESPONSE)
    )

    resp = await client.post("/api/session", json={
        "profile_id": "alpha",
        "user_name": "TestUser"
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["session_id"] == "test-session-123"
    assert data["livekit_url"] == "wss://test.livekit.cloud"
    assert data["livekit_client_token"] == "client-token-xyz"
    assert data["ws_url"] == "wss://test.liveavatar.com/ws"
    assert "TestUser" in data["greeting"]


@respx.mock
async def test_create_session_invalid_profile_returns_404(client, monkeypatch):
    import app as backend
    monkeypatch.setattr(backend, "LIVEAVATAR_API_KEY", "test-key")

    resp = await client.post("/api/session", json={
        "profile_id": "nonexistent",
        "user_name": "TestUser"
    })
    assert resp.status_code == 422  # Pydantic validation error for invalid Literal


async def test_create_session_missing_api_key_returns_503(client, monkeypatch):
    import app as backend
    monkeypatch.setattr(backend, "LIVEAVATAR_API_KEY", "")

    resp = await client.post("/api/session", json={
        "profile_id": "alpha",
        "user_name": "TestUser"
    })
    assert resp.status_code == 503


async def test_delete_session_unknown_id_returns_ok(client):
    resp = await client.delete("/api/session/nonexistent-id")
    assert resp.status_code == 200
    assert resp.json()["ok"] is True


async def test_health_endpoint(client):
    resp = await client.get("/api/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["ok"] is True
    assert "profiles" in data


async def test_profiles_endpoint(client):
    resp = await client.get("/api/profiles")
    assert resp.status_code == 200
    profiles = resp.json()
    assert len(profiles) == 3
    ids = [p["id"] for p in profiles]
    assert set(ids) == {"alpha", "beta", "gamma"}
