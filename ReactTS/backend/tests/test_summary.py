import csv
import pytest


async def test_save_summary_returns_ok(client):
    resp = await client.post("/api/save-summary", json={
        "transcript": "Doctor: How are you?\nPatient: I feel tired.",
        "summary": "Patient reports fatigue.",
        "uid": "ABC123",
        "doctor_name": "Carol",
        "user_name": "Alice"
    })
    assert resp.status_code == 200
    assert resp.json()["ok"] is True


async def test_save_summary_persists_to_csv(client, tmp_path, monkeypatch):
    import app as backend
    csv_path = str(tmp_path / "convos.csv")
    monkeypatch.setattr(backend, "CONVOS_CSV_FILE_PATH", csv_path)

    await client.post("/api/save-summary", json={
        "transcript": "Patient: My head hurts.",
        "summary": "Headache reported.",
        "uid": "UID999",
        "doctor_name": "Karen",
        "user_name": "Bob"
    })

    with open(csv_path, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    assert len(rows) == 1
    assert rows[0]["uid"] == "UID999"
    assert rows[0]["summary"] == "Headache reported."
    assert rows[0]["user_name"] == "Bob"


async def test_save_multiple_summaries(client, tmp_path, monkeypatch):
    import app as backend
    csv_path = str(tmp_path / "convos2.csv")
    monkeypatch.setattr(backend, "CONVOS_CSV_FILE_PATH", csv_path)

    for i in range(3):
        await client.post("/api/save-summary", json={
            "transcript": f"Session {i}",
            "summary": f"Summary {i}",
            "uid": f"UID00{i}",
            "doctor_name": "Carol",
            "user_name": f"Patient{i}"
        })

    with open(csv_path, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    assert len(rows) == 3
