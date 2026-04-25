# app.py — Amiya Health backend with LiveAvatar LITE mode + local TTS
import asyncio
import base64
import csv
import json
import os
import random
import string
import tempfile
import wave
from typing import Dict, List, Literal, Optional
from uuid import uuid4

import numpy as np
import pyttsx3

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from dotenv import load_dotenv
from twilio.rest import Client
import websockets

load_dotenv()

LIVEAVATAR_API_KEY = (os.environ.get("LIVEAVATAR_API_KEY") or os.environ.get("HEYGEN_API_KEY", "")).strip()
LIVEAVATAR_API_BASE = "https://api.liveavatar.com/v1"
LIVEAVATAR_SANDBOX = os.environ.get("LIVEAVATAR_SANDBOX", "false").lower() == "true"
AVATAR_ID = os.environ.get("LIVEAVATAR_AVATAR_ID", "567e8371-f69f-49ec-9f2d-054083431165")

TWILIO_ACCOUNT_SID = os.environ.get("TWILIO_ACCOUNT_SID", "")
TWILIO_AUTH_TOKEN = os.environ.get("TWILIO_AUTH_TOKEN")
TWILIO_PHONE_NUMBER = os.environ.get("TWILIO_PHONE_NUMBER", "+18775897184")

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
CSV_FILE_PATH = os.path.join(DATA_DIR, "db.csv")
CONVOS_CSV_FILE_PATH = os.path.join(DATA_DIR, "convos.csv")

PROFILES = {
    "alpha": {"agent_name": os.environ.get("PROFILE_ALPHA_AGENT_NAME", "Carol Lee"),
              "avatar_id": os.environ.get("PROFILE_ALPHA_AVATAR_ID", AVATAR_ID)},
    "beta":  {"agent_name": os.environ.get("PROFILE_BETA_AGENT_NAME", "Dexter Sins"),
              "avatar_id": os.environ.get("PROFILE_BETA_AVATAR_ID", AVATAR_ID)},
    "gamma": {"agent_name": os.environ.get("PROFILE_GAMMA_AGENT_NAME", "Karen Roberts"),
              "avatar_id": os.environ.get("PROFILE_GAMMA_AVATAR_ID", AVATAR_ID)},
}

# In-memory session store: session_id -> {ws_url, session_token}
_sessions: Dict[str, Dict] = {}

app = FastAPI(title="Amiya Health — LiveAvatar LITE")
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.environ.get("CORS_ALLOW_ORIGINS", "*").split(","),
    allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)

# ── Pydantic models ──────────────────────────────────────────────────────────

class StartRequest(BaseModel):
    profile_id: Literal["alpha", "beta", "gamma"]
    user_name: str
    deterministic_greeting: bool = True

class SessionResponse(BaseModel):
    session_id: str
    livekit_url: str
    livekit_client_token: str
    ws_url: str
    greeting: str = ""

class SpeakRequest(BaseModel):
    session_id: str
    text: str

class SpeakResponse(BaseModel):
    ok: bool

class ProfileOut(BaseModel):
    id: str
    agent_name: str
    avatar_id: str

class NewPatientRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    phone_number: str = Field(..., min_length=10, max_length=15)
    agent_name: str = Field(..., min_length=1, max_length=50)

class PatientResponse(BaseModel):
    uid: str
    name: str
    phone_number: str
    agent_name: str
    message: str

class PatientLookupResponse(BaseModel):
    name: str
    doctor: str

class SaveSummaryRequest(BaseModel):
    transcript: str
    summary: str
    uid: str
    doctor_name: str
    user_name: str

# ── Helpers ──────────────────────────────────────────────────────────────────

def _generate_uid() -> str:
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

def _get_profile(pid: str) -> Dict[str, str]:
    p = PROFILES.get(pid)
    if not p:
        raise HTTPException(404, f"Unknown profile '{pid}'")
    return p

def _ensure_csv(path: str, fieldnames: list):
    if not os.path.exists(path):
        os.makedirs(DATA_DIR, exist_ok=True)
        with open(path, 'w', newline='', encoding='utf-8') as f:
            csv.DictWriter(f, fieldnames=fieldnames).writeheader()

def _read_patients() -> List[Dict[str, str]]:
    _ensure_csv(CSV_FILE_PATH, ['uid', 'name', 'phone_number', 'agent_name'])
    try:
        with open(CSV_FILE_PATH, 'r', newline='', encoding='utf-8') as f:
            return list(csv.DictReader(f))
    except Exception:
        return []

def _write_patients(patients: List[Dict[str, str]]):
    _ensure_csv(CSV_FILE_PATH, ['uid', 'name', 'phone_number', 'agent_name'])
    with open(CSV_FILE_PATH, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['uid', 'name', 'phone_number', 'agent_name'])
        w.writeheader()
        w.writerows(patients)

async def _send_sms(phone: str, name: str, agent_name: str, uid: str) -> bool:
    if not TWILIO_AUTH_TOKEN:
        return False
    try:
        client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        if not phone.startswith('+'):
            phone = '+' + phone
        client.messages.create(
            body=f"Hi {name}. You were invited to a checkup with Dr. {agent_name}. Join: localhost:3000/u/{uid}",
            from_=TWILIO_PHONE_NUMBER,
            to=phone
        )
        return True
    except Exception as e:
        print(f"SMS error: {e}")
        return False

def _tts_sync(text: str, path: str):
    engine = pyttsx3.init()
    engine.save_to_file(text, path)
    engine.runAndWait()

async def _text_to_pcm_24khz(text: str) -> bytes:
    """Convert text to raw PCM 16-bit 24KHz using pyttsx3 (local, no API)."""
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
        tmp_path = f.name
    try:
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, _tts_sync, text, tmp_path)

        with wave.open(tmp_path, 'rb') as wav:
            orig_rate = wav.getframerate()
            raw = wav.readframes(wav.getnframes())

        samples = np.frombuffer(raw, dtype=np.int16).astype(np.float64)
        if orig_rate != 24000:
            new_len = int(len(samples) * 24000 / orig_rate)
            indices = np.linspace(0, len(samples) - 1, new_len)
            samples = np.interp(indices, np.arange(len(samples)), samples)

        return np.clip(samples, -32768, 32767).astype(np.int16).tobytes()
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)

async def _speak_via_ws(ws_url: str, pcm_bytes: bytes):
    """Send PCM audio to LiveAvatar WebSocket using the LITE protocol."""
    BYTES_PER_SEC = 48_000  # 24KHz × 16-bit mono = 48,000 bytes/sec
    FIRST_CHUNK = int(BYTES_PER_SEC * 0.6)
    CHUNK = BYTES_PER_SEC

    async with websockets.connect(ws_url, ping_interval=None) as ws:
        # Wait for session to be connected
        async for raw in ws:
            msg = json.loads(raw)
            if msg.get("type") == "session.state_updated" and msg.get("state") == "connected":
                break

        event_id = f"speak-{uuid4()}"
        buf = pcm_bytes
        first = True

        while buf:
            size = FIRST_CHUNK if first else CHUNK
            chunk, buf = buf[:size], buf[size:]
            await ws.send(json.dumps({
                "type": "agent.speak",
                "event_id": event_id,
                "audio": base64.b64encode(chunk).decode()
            }))
            first = False

        await ws.send(json.dumps({"type": "agent.speak_end", "event_id": event_id}))

        # Wait for avatar to finish speaking
        async for raw in ws:
            msg = json.loads(raw)
            if msg.get("type") == "agent.speak_ended":
                break

async def _speak_greeting(ws_url: str, greeting: str):
    try:
        pcm = await _text_to_pcm_24khz(greeting)
        if pcm:
            await _speak_via_ws(ws_url, pcm)
    except Exception as e:
        print(f"Greeting speak error: {e}")

async def _create_liveavatar_session(avatar_id: str) -> Dict:
    """Create a LiveAvatar LITE session and return all credentials."""
    if not LIVEAVATAR_API_KEY:
        raise HTTPException(503, "Missing LIVEAVATAR_API_KEY or HEYGEN_API_KEY in .env")

    print(f"[LiveAvatar] Creating session for avatar_id={avatar_id}")
    headers = {"X-API-KEY": LIVEAVATAR_API_KEY, "Content-Type": "application/json"}
    token_body: Dict = {"mode": "LITE", "avatar_id": avatar_id}
    if LIVEAVATAR_SANDBOX:
        token_body["is_sandbox"] = True

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(f"{LIVEAVATAR_API_BASE}/sessions/token", headers=headers, json=token_body)
        if not r.is_success:
            print(f"[LiveAvatar] Token error {r.status_code}: {r.text}")
            raise HTTPException(502, f"LiveAvatar token error ({r.status_code}): {r.text}")
        data = r.json().get("data", {})
        session_id = data["session_id"]
        session_token = data["session_token"]

        r2 = await client.post(
            f"{LIVEAVATAR_API_BASE}/sessions/start",
            headers={"Authorization": f"Bearer {session_token}", "Content-Type": "application/json"}
        )
        if not r2.is_success:
            print(f"[LiveAvatar] Start error {r2.status_code}: {r2.text}")
            raise HTTPException(502, f"LiveAvatar start error ({r2.status_code}): {r2.text}")
        d2 = r2.json().get("data", {})
        print(f"[LiveAvatar] Session created: {d2.get('livekit_url', 'NO_URL')}")

    return {
        "session_id": session_id,
        "session_token": session_token,
        "livekit_url": d2["livekit_url"],
        "livekit_client_token": d2["livekit_client_token"],
        "ws_url": d2["ws_url"],
    }

# ── Routes ───────────────────────────────────────────────────────────────────

@app.get("/api/health")
async def health():
    return {
        "ok": True,
        "has_api_key": bool(LIVEAVATAR_API_KEY),
        "sandbox": LIVEAVATAR_SANDBOX,
        "profiles": list(PROFILES.keys()),
    }

@app.get("/api/profiles", response_model=List[ProfileOut])
async def profiles():
    return [ProfileOut(id=k, agent_name=v["agent_name"], avatar_id=v["avatar_id"]) for k, v in PROFILES.items()]

@app.post("/api/session", response_model=SessionResponse)
async def create_session(req: StartRequest):
    profile = _get_profile(req.profile_id)
    sess = await _create_liveavatar_session(profile["avatar_id"])

    _sessions[sess["session_id"]] = {
        "ws_url": sess["ws_url"],
        "session_token": sess["session_token"],
    }

    greeting = f"Hi {req.user_name}, I'm Dr. {profile['agent_name']}. It's wonderful to see you today. How have you been feeling lately?"

    # Speak greeting in background so HTTP response returns immediately
    asyncio.create_task(_speak_greeting(sess["ws_url"], greeting))

    return SessionResponse(
        session_id=sess["session_id"],
        livekit_url=sess["livekit_url"],
        livekit_client_token=sess["livekit_client_token"],
        ws_url=sess["ws_url"],
        greeting=greeting,
    )

@app.post("/api/speak", response_model=SpeakResponse)
async def speak(req: SpeakRequest):
    sess = _sessions.get(req.session_id)
    if not sess:
        raise HTTPException(404, f"Session '{req.session_id}' not found or expired")

    pcm = await _text_to_pcm_24khz(req.text)
    if not pcm:
        raise HTTPException(500, "TTS failed to produce audio")

    await _speak_via_ws(sess["ws_url"], pcm)
    return SpeakResponse(ok=True)

@app.delete("/api/session/{session_id}")
async def end_session(session_id: str):
    sess = _sessions.pop(session_id, None)
    if sess:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                await client.delete(
                    f"{LIVEAVATAR_API_BASE}/sessions",
                    headers={"Authorization": f"Bearer {sess['session_token']}"}
                )
        except Exception:
            pass
    return {"ok": True}

@app.post("/api/new-patient", response_model=PatientResponse)
async def new_patient(req: NewPatientRequest):
    patients = _read_patients()
    existing_idx = next((i for i, p in enumerate(patients) if p['phone_number'] == req.phone_number), None)
    uid = _generate_uid()
    doctor_first = req.agent_name.replace('Dr. ', '').split()[0] if 'Dr. ' in req.agent_name else req.agent_name
    new_p = {'uid': uid, 'name': req.name, 'phone_number': req.phone_number, 'agent_name': doctor_first}

    if existing_idx is not None:
        old_uid = patients[existing_idx]['uid']
        patients[existing_idx] = new_p
        message = f"Updated existing patient with UID {old_uid}"
    else:
        patients.append(new_p)
        message = "Added new patient"

    _write_patients(patients)
    await _send_sms(req.phone_number, req.name, req.agent_name, uid)

    return PatientResponse(uid=uid, name=req.name, phone_number=req.phone_number, agent_name=req.agent_name, message=message)

@app.get("/api/patient/{uid}", response_model=PatientLookupResponse)
async def get_patient(uid: str):
    patient = next((p for p in _read_patients() if p.get('uid') == uid), None)
    if not patient:
        raise HTTPException(404, f"No patient found for uid '{uid}'")
    return PatientLookupResponse(name=patient.get('name', ''), doctor=patient.get('agent_name', ''))

@app.post("/api/save-summary")
async def save_summary(req: SaveSummaryRequest):
    """Save a consultation summary generated by on-device TinyLlama."""
    fields = ['uid', 'summary', 'doctor_name', 'user_name', 'transcript']
    _ensure_csv(CONVOS_CSV_FILE_PATH, fields)
    try:
        with open(CONVOS_CSV_FILE_PATH, 'a', newline='', encoding='utf-8') as f:
            csv.DictWriter(f, fieldnames=fields).writerow({
                'uid': req.uid,
                'summary': req.summary,
                'doctor_name': req.doctor_name,
                'user_name': req.user_name,
                'transcript': req.transcript,
            })
        return {"ok": True}
    except Exception as e:
        raise HTTPException(500, f"Failed to save summary: {e}")
