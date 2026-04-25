"""
End-to-end patient journey:
register → lookup → session (mocked) → speak (mocked) → summary → end session
"""
import pytest
import respx
from httpx import Response


MOCK_TOKEN = {"data": {"session_id": "e2e-session", "session_token": "e2e-token"}}
MOCK_START = {"data": {
    "livekit_url": "wss://e2e.livekit.cloud",
    "livekit_client_token": "e2e-client-token",
    "ws_url": "wss://e2e.liveavatar.com/ws"
}}


@respx.mock
async def test_full_patient_journey(client, monkeypatch):
    import app as backend
    monkeypatch.setattr(backend, "LIVEAVATAR_API_KEY", "test-key")

    # 1. Register patient
    reg = await client.post("/api/new-patient", json={
        "name": "Jane Doe",
        "phone_number": "5550009999",
        "agent_name": "Dr. Carol Lee"
    })
    assert reg.status_code == 200
    uid = reg.json()["uid"]
    assert len(uid) == 6

    # 2. Lookup patient
    lookup = await client.get(f"/api/patient/{uid}")
    assert lookup.status_code == 200
    assert lookup.json()["name"] == "Jane Doe"

    # 3. Create session (mock LiveAvatar)
    respx.post("https://api.liveavatar.com/v1/sessions/token").mock(
        return_value=Response(200, json=MOCK_TOKEN)
    )
    respx.post("https://api.liveavatar.com/v1/sessions/start").mock(
        return_value=Response(200, json=MOCK_START)
    )
    session = await client.post("/api/session", json={
        "profile_id": "alpha",
        "user_name": "Jane Doe"
    })
    assert session.status_code == 200
    session_id = session.json()["session_id"]
    assert session_id == "e2e-session"

    # 4. Save summary
    summary = await client.post("/api/save-summary", json={
        "transcript": "Doctor: How are you?\nPatient: I feel better.",
        "summary": "Patient reports improvement.",
        "uid": uid,
        "doctor_name": "Carol",
        "user_name": "Jane Doe"
    })
    assert summary.status_code == 200
    assert summary.json()["ok"] is True

    # 5. End session
    end = await client.delete(f"/api/session/{session_id}")
    assert end.status_code == 200
    assert end.json()["ok"] is True
