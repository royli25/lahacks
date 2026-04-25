import pytest


async def test_new_patient_creates_record(client):
    resp = await client.post("/api/new-patient", json={
        "name": "Alice Smith",
        "phone_number": "5551234567",
        "agent_name": "Dr. Carol Lee"
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "Alice Smith"
    assert data["phone_number"] == "5551234567"
    assert len(data["uid"]) == 6


async def test_get_patient_returns_name_and_doctor(client):
    # Create patient first
    create = await client.post("/api/new-patient", json={
        "name": "Bob Jones",
        "phone_number": "5559876543",
        "agent_name": "Dr. Karen Roberts"
    })
    uid = create.json()["uid"]

    resp = await client.get(f"/api/patient/{uid}")
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "Bob Jones"
    assert data["doctor"] == "Karen"


async def test_get_patient_unknown_uid_returns_404(client):
    resp = await client.get("/api/patient/XXXXXX")
    assert resp.status_code == 404


async def test_duplicate_phone_updates_existing(client):
    phone = "5550001111"
    await client.post("/api/new-patient", json={
        "name": "Original Name",
        "phone_number": phone,
        "agent_name": "Dr. Carol Lee"
    })
    resp = await client.post("/api/new-patient", json={
        "name": "Updated Name",
        "phone_number": phone,
        "agent_name": "Dr. Karen Roberts"
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "Updated Name"
    assert "Updated" in data["message"]
