import os
import tempfile
import pytest
from httpx import AsyncClient, ASGITransport

# Point CSV files to temp directory so tests don't touch real data
@pytest.fixture(autouse=True)
def temp_data_dir(monkeypatch, tmp_path):
    monkeypatch.setenv("TWILIO_AUTH_TOKEN", "")  # disable SMS
    import app as backend
    monkeypatch.setattr(backend, "CSV_FILE_PATH", str(tmp_path / "db.csv"))
    monkeypatch.setattr(backend, "CONVOS_CSV_FILE_PATH", str(tmp_path / "convos.csv"))
    monkeypatch.setattr(backend, "DATA_DIR", str(tmp_path))

@pytest.fixture
async def client():
    import app as backend
    async with AsyncClient(transport=ASGITransport(app=backend.app), base_url="http://test") as c:
        yield c
