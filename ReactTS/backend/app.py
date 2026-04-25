# app.py
import os
import csv
import random
import string
import base64
import tempfile
from typing import Dict, Any, Optional, List, Literal
from textwrap import dedent

import httpx
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, model_validator
from dotenv import load_dotenv
from twilio.rest import Client
import openai

load_dotenv()  # load .env before reading env vars

HEYGEN_API_KEY = os.environ.get("HEYGEN_API_KEY")
HEYGEN_API_BASE = os.environ.get("HEYGEN_API_BASE", "https://api.heygen.com/v1")
DEFAULT_LANGUAGE = os.environ.get("HEYGEN_LANGUAGE", "en")
DEFAULT_QUALITY = os.environ.get("HEYGEN_QUALITY", "low")  # low|medium|high
DEFAULT_ACTIVITY_IDLE_TIMEOUT = int(os.environ.get("HEYGEN_ACTIVITY_IDLE_TIMEOUT", "180"))
DEFAULT_TRANSPORT = os.environ.get("HEYGEN_VOICE_CHAT_TRANSPORT", "WEBSOCKET")  # or LIVEKIT
DEBUG_EFFECTIVE_KNOWLEDGE = os.environ.get("DEBUG_EFFECTIVE_KNOWLEDGE", "0") == "1"

# Twilio configuration
TWILIO_ACCOUNT_SID = os.environ.get("TWILIO_ACCOUNT_SID", "REDACTED_TWILIO_SID")
TWILIO_AUTH_TOKEN = os.environ.get("TWILIO_AUTH_TOKEN")
TWILIO_PHONE_NUMBER = os.environ.get("TWILIO_PHONE_NUMBER", "+18775897184")

# OpenAI configuration
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")

# Data storage configuration
DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
CSV_FILE_PATH = os.path.join(DATA_DIR, "db.csv")
CONVOS_CSV_FILE_PATH = os.path.join(DATA_DIR, "convos.csv")
MEDICAL_DATA_FILE_PATH = os.path.join(DATA_DIR, "medical_data.txt")

# Initialize OpenAI client
openai.api_key = OPENAI_API_KEY

PROFILES = {
    "alpha": {"agent_name": os.environ.get("PROFILE_ALPHA_AGENT_NAME", "Dexter"),
              "avatar_id": os.environ.get("PROFILE_ALPHA_AVATAR_ID", "Dexter_Doctor_Sitting2_public")},
    "beta":  {"agent_name": os.environ.get("PROFILE_BETA_AGENT_NAME", "Ann"),
              "avatar_id": os.environ.get("PROFILE_BETA_AVATAR_ID", "Ann_Doctor_Sitting_public")},
    "gamma": {"agent_name": os.environ.get("PROFILE_GAMMA_AGENT_NAME", "Judy"),
              "avatar_id": os.environ.get("PROFILE_GAMMA_AVATAR_ID", "Judy_Doctor_Sitting2_public")},
}

app = FastAPI(title="HeyGen SDK Backend (token + session)")
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.environ.get("CORS_ALLOW_ORIGINS", "*").split(","),
    allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)

# ---- models ----
class KnowledgeConfig(BaseModel):
    knowledge_base: Optional[str] = None
    merge_strategy: Literal["append", "replace"] = "append"
    inject_user_name: bool = True

class StartRequest(BaseModel):
    profile_id: Literal["alpha", "beta", "gamma"]
    user_name: str
    language: Optional[str] = None
    deterministic_greeting: bool = True
    greeting_template: Optional[str] = None
    knowledge: Optional[KnowledgeConfig] = None

    @model_validator(mode="after")
    def _check_template(self):
        if self.greeting_template is not None:
            _ = self.greeting_template.format(user_name=self.user_name)
        return self

class SessionPayload(BaseModel):
    avatarName: str
    language: str
    knowledgeBase: str
    quality: str
    activityIdleTimeout: int
    voiceChatTransport: str

class SessionResponse(BaseModel):
    token: str
    session: SessionPayload
    greeting: Optional[str] = None
    effective_knowledge: Optional[str] = None  # shown if DEBUG_EFFECTIVE_KNOWLEDGE=1

class ProfileOut(BaseModel):
    id: str
    agent_name: str
    avatar_id: str

class NewPatientRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Patient's full name")
    phone_number: str = Field(..., min_length=10, max_length=15, description="Patient's phone number")
    agent_name: str = Field(..., min_length=1, max_length=50, description="Assigned agent name")

class PatientResponse(BaseModel):
    uid: str
    name: str
    phone_number: str
    agent_name: str
    message: str

class PatientLookupResponse(BaseModel):
    name: str
    doctor: str

class TranscriptSummaryRequest(BaseModel):
    transcript: str = Field(..., min_length=1, max_length=50000, description="The full transcript text to summarize")
    start_time: str = Field(..., description="Start time of the call (ISO format)")
    current_time: str = Field(..., description="Current/end time of the call (ISO format)")
    phone_number: str = Field(..., description="Phone number of the patient")
    uid: str = Field(..., description="Patient's UID")
    doctor_name: str = Field(..., description="Name of the doctor")
    user_name: str = Field(..., description="Name of the patient")

class TranscriptSummaryResponse(BaseModel):
    summary: str

class AudioProcessRequest(BaseModel):
    audio_data: str = Field(..., description="Base64 encoded audio data")
    patient_context: Optional[str] = Field(None, description="Additional patient context")

class AudioProcessResponse(BaseModel):
    transcribed_text: str
    processed_text: str
    success: bool

# ---- helpers ----
def _generate_uid() -> str:
    """Generate a random 6-character UID"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

def _extract_doctor_first_name(doctor_name: str) -> str:
    """Extract first name from doctor name like 'Dr. Michael Rodriguez' -> 'Michael'"""
    if doctor_name.startswith('Dr. '):
        # Remove 'Dr. ' and take the first word after it
        name_parts = doctor_name[4:].strip().split()
        if name_parts:
            return name_parts[0]
    # If it doesn't start with 'Dr. ', return as is
    return doctor_name

def _ensure_csv_file_exists():
    """Ensure the CSV file exists with proper headers"""
    if not os.path.exists(CSV_FILE_PATH):
        os.makedirs(DATA_DIR, exist_ok=True)
        with open(CSV_FILE_PATH, 'w', newline='', encoding='utf-8') as file:
            writer = csv.writer(file)
            writer.writerow(['uid', 'name', 'phone_number', 'agent_name'])

def _read_patients() -> List[Dict[str, str]]:
    """Read all patients from CSV file"""
    _ensure_csv_file_exists()
    patients = []
    try:
        with open(CSV_FILE_PATH, 'r', newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            patients = list(reader)
    except Exception as e:
        print(f"Error reading CSV file: {e}")
    return patients

def _write_patients(patients: List[Dict[str, str]]):
    """Write all patients to CSV file"""
    _ensure_csv_file_exists()
    try:
        with open(CSV_FILE_PATH, 'w', newline='', encoding='utf-8') as file:
            if patients:
                writer = csv.DictWriter(file, fieldnames=['uid', 'name', 'phone_number', 'agent_name'])
                writer.writeheader()
                writer.writerows(patients)
            else:
                # Write header even if no patients
                writer = csv.DictWriter(file, fieldnames=['uid', 'name', 'phone_number', 'agent_name'])
                writer.writeheader()
    except Exception as e:
        print(f"Error writing CSV file: {e}")
        raise HTTPException(500, "Failed to save patient data")

def _add_or_update_patient(name: str, phone_number: str, agent_name: str) -> PatientResponse:
    """Add new patient or update existing one by phone number"""
    patients = _read_patients()
    
    # Extract first name from doctor name (e.g., "Dr. Michael Rodriguez" -> "Michael")
    doctor_first_name = _extract_doctor_first_name(agent_name)
    
    # Check if patient with this phone number already exists
    existing_index = None
    for i, patient in enumerate(patients):
        if patient['phone_number'] == phone_number:
            existing_index = i
            break
    
    uid = _generate_uid()
    new_patient = {
        'uid': uid,
        'name': name,
        'phone_number': phone_number,
        'agent_name': doctor_first_name  # Store the extracted first name
    }
    
    if existing_index is not None:
        # Update existing patient
        old_uid = patients[existing_index]['uid']
        patients[existing_index] = new_patient
        message = f"Updated existing patient with UID {old_uid}"
    else:
        # Add new patient
        patients.append(new_patient)
        message = "Added new patient"
    
    _write_patients(patients)
    
    return PatientResponse(
        uid=uid,
        name=name,
        phone_number=phone_number,
        agent_name=agent_name,
        message=message
    )

def _find_patient_by_uid(uid: str) -> Optional[Dict[str, str]]:
    """Find a patient by UID; returns dict or None if not found."""
    patients = _read_patients()
    for patient in patients:
        if patient.get('uid') == uid:
            return patient
    return None

async def _send_sms(phone_number: str, name: str, agent_name: str, uid: str) -> bool:
    """Send SMS notification to patient with meeting link"""
    try:
        if not TWILIO_AUTH_TOKEN:
            print("Warning: TWILIO_AUTH_TOKEN not set, skipping SMS")
            return False
            
        client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        
        # Format phone number to ensure it starts with +
        if not phone_number.startswith('+'):
            phone_number = '+' + phone_number
        
        # Create the meeting link
        meeting_link = f"localhost:3000/u/{uid}"
        
        # Create the message body
        message_body = f"Hi {name}. You were invited to a checkup with Dr. {agent_name}. Click this to join the meeting: {meeting_link}"
        
        # Send the SMS
        message = client.messages.create(
            body=message_body,
            from_=TWILIO_PHONE_NUMBER,
            to=phone_number
        )
        
        print(f"SMS sent successfully to {phone_number}, SID: {message.sid}")
        return True
        
    except Exception as e:
        print(f"Failed to send SMS to {phone_number}: {str(e)}")
        return False

def _ensure_convos_csv_exists():
    """Ensure the conversations CSV file exists with proper headers"""
    if not os.path.exists(CONVOS_CSV_FILE_PATH):
        os.makedirs(DATA_DIR, exist_ok=True)
        with open(CONVOS_CSV_FILE_PATH, 'w', newline='', encoding='utf-8') as file:
            writer = csv.DictWriter(file, fieldnames=[
                'start_time', 'duration_minutes', 'phone_number', 'uid', 
                'summary', 'doctor_name', 'user_name'
            ])
            writer.writeheader()

async def _summarize_transcript_with_openai(transcript: str) -> str:
    """Summarize transcript using GPT-5 nano"""
    try:
        if not OPENAI_API_KEY:
            raise HTTPException(503, "Server missing OPENAI_API_KEY")
        
        prompt = """Summarize the important information for healthcare providers from this patient-doctor conversation transcript in 1-4 sentences. Focus on:
- Patient's main symptoms or concerns
- Doctor's recommendations or diagnosis
- Any follow-up actions needed
- Key medical information discussed

Transcript:"""
        
        headers = {
            "Authorization": f"Bearer {OPENAI_API_KEY}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": "gpt-4o-mini",
            "messages": [
                {
                    "role": "system",
                    "content": "You are a medical assistant helping to summarize patient-doctor conversations for healthcare records."
                },
                {
                    "role": "user", 
                    "content": f"{prompt}\n\n{transcript}"
                }
            ],
            "max_tokens": 200,
            "temperature": 0.3
        }
        
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers=headers,
                json=payload
            )
        
        response.raise_for_status()
        data = response.json()
        
        summary = data['choices'][0]['message']['content'].strip()
        return summary
        
    except httpx.HTTPError as e:
        raise HTTPException(502, f"OpenAI API error: {e}")
    except Exception as e:
        raise HTTPException(500, f"Failed to summarize transcript: {str(e)}")

def _calculate_duration_minutes(start_time: str, current_time: str) -> float:
    """Calculate duration in minutes between two ISO timestamps"""
    try:
        from datetime import datetime
        start = datetime.fromisoformat(start_time.replace('Z', '+00:00'))
        end = datetime.fromisoformat(current_time.replace('Z', '+00:00'))
        duration = (end - start).total_seconds() / 60
        return round(duration, 2)
    except Exception as e:
        print(f"Error calculating duration: {e}")
        return 0.0

def _save_conversation_summary(
    start_time: str, 
    duration_minutes: float, 
    phone_number: str, 
    uid: str, 
    summary: str, 
    doctor_name: str, 
    user_name: str
) -> bool:
    """Save conversation summary to CSV"""
    try:
        _ensure_convos_csv_exists()
        
        with open(CONVOS_CSV_FILE_PATH, 'a', newline='', encoding='utf-8') as file:
            writer = csv.DictWriter(file, fieldnames=[
                'start_time', 'duration_minutes', 'phone_number', 'uid', 
                'summary', 'doctor_name', 'user_name'
            ])
            writer.writerow({
                'start_time': start_time,
                'duration_minutes': duration_minutes,
                'phone_number': phone_number,
                'uid': uid,
                'summary': summary,
                'doctor_name': doctor_name,
                'user_name': user_name
            })
        
        return True
    except Exception as e:
        print(f"Error saving conversation summary: {e}")
        return False

def _get_profile(pid: str) -> Dict[str, str]:
    p = PROFILES.get(pid)
    if not p:
        raise HTTPException(404, f"Unknown profile '{pid}'. Use one of {list(PROFILES.keys())}.")
    return p

def _load_medical_data() -> str:
    """Load medical knowledge base from file"""
    try:
        if os.path.exists(MEDICAL_DATA_FILE_PATH):
            with open(MEDICAL_DATA_FILE_PATH, 'r', encoding='utf-8') as file:
                return file.read()
        else:
            return "Medical knowledge base not available."
    except Exception as e:
        print(f"Error loading medical data: {e}")
        return "Medical knowledge base not available."

async def _transcribe_audio_with_whisper(audio_data: bytes) -> str:
    """Transcribe audio using OpenAI Whisper"""
    try:
        if not OPENAI_API_KEY:
            raise HTTPException(503, "Server missing OPENAI_API_KEY")
        
        # Create a temporary file for the audio data
        with tempfile.NamedTemporaryFile(delete=False, suffix=".webm") as temp_file:
            temp_file.write(audio_data)
            temp_file_path = temp_file.name
        
        try:
            # Use OpenAI Whisper API to transcribe
            with open(temp_file_path, "rb") as audio_file:
                transcript = openai.Audio.transcribe(
                    model="whisper-1",
                    file=audio_file,
                    response_format="text"
                )
            
            return transcript.strip()
        finally:
            # Clean up temporary file
            os.unlink(temp_file_path)
            
    except Exception as e:
        print(f"Error transcribing audio: {e}")
        raise HTTPException(500, f"Failed to transcribe audio: {str(e)}")

async def _process_text_with_openai(text: str, medical_context: str) -> str:
    """Process and clean up transcribed text using GPT-4o-mini with medical context"""
    try:
        if not OPENAI_API_KEY:
            raise HTTPException(503, "Server missing OPENAI_API_KEY")
        
        prompt = f"""Please process and clean up this transcribed audio text from a patient-doctor conversation. 

MEDICAL CONTEXT:
{medical_context}

TRANSCRIBED TEXT:
{text}

Please:
1. Correct any transcription errors
2. Fix grammar and punctuation
3. Ensure medical terminology is accurate
4. Maintain the conversational tone
5. Keep the original meaning and intent

Return only the cleaned text without any additional commentary."""

        client = openai.OpenAI(api_key=OPENAI_API_KEY)
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You are a medical transcription assistant. Clean up and correct transcribed audio while maintaining accuracy and medical context."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            max_tokens=500,
            temperature=0.1
        )
        
        processed_text = response.choices[0].message.content.strip()
        return processed_text
        
    except Exception as e:
        print(f"Error processing text with OpenAI: {e}")
        raise HTTPException(500, f"Failed to process text: {str(e)}")

def _build_knowledge(user_name: str, agent_name: str, cfg=None) -> str:
    """
    Build a simple system prompt using just agent_name and user_name.
    """
    return dedent(f"""
 ROLE & PERSONA:
You are Dr. {agent_name}, a compassionate and experienced family physician specializing in telehealth consultations for seniors. You provide care while maintaining clinical accuracy and building trust through genuine human connection.​

CORE COMMUNICATION PRINCIPLES:
Brevity with warmth: Keep responses under 2-3 sentences unless patients request more detail​
Active listening: If interrupted, stop immediately and listen. Acknowledge with "I hear you" or "Tell me more"
Plain language: Avoid medical jargon. Use analogies seniors can relate to ("your heart is like a pump")
Empathetic reflection: Mirror patients' words and reference ("You mentioned this pain started last Tuesday and has gotten worse")

Collaborative planning: Always confirm understanding ("Does this plan make sense to you?")​



—---------

CONVERSATION FLOW:

Opening (First response only):
"Hello {user_name}, I'm Dr. {agent_name}. It's wonderful to see you today. Thank you for taking the time for this visit. How have you been feeling lately?"

Chief Concern Exploration:

"What's bringing you in to see me today?"

"Can you tell me more about when this started?"

"How is this affecting your daily life? Your sleep? Your activities?"

"Have you noticed anything else that's concerning you?"

Medical History & Safety:

"Are you taking any medications or supplements? Any recent changes?"

"Do you have any allergies I should know about, especially to medications?"

"When did you last see your doctor for your regular checkup?"

Assessment & Planning:

"From what you've shared, this sounds like [condition/explanation]. Let me explain what might be happening..."

"Does this explanation make sense so far? Any questions about what I've said?"

"Here's what I recommend we do next... How does this plan feel to you?"

SAFETY & LIMITATIONS:

Always recommend in-person evaluation for concerning symptoms

Acknowledge limitations: "While I can provide guidance, it's important to see your regular doctor for..."

Never provide specific medication dosages or replace emergency care​

EMPATHY TECHNIQUES:

Use validating phrases: "That sounds really difficult" or "I can understand why you're worried"

Show genuine concern: "I'm glad you reached out about this"

End warmly: "Take care of yourself, and don't hesitate to reach out if you have questions"​

    """).strip()

async def _mint_token() -> str:
    if not HEYGEN_API_KEY:
        raise HTTPException(503, "Server missing HEYGEN_API_KEY")
    url = f"{HEYGEN_API_BASE}/streaming.create_token"
    headers = {"x-api-key": HEYGEN_API_KEY}
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(url, headers=headers)
    try:
        r.raise_for_status()
    except httpx.HTTPError as e:
        raise HTTPException(502, f"HeyGen token HTTP error: {e}; body={r.text}")
    data = r.json()
    token = data.get("access_token") or data.get("token") or (data.get("data") or {}).get("token") or (data.get("data") or {}).get("access_token")
    if not token:
        raise HTTPException(502, f"HeyGen token response missing token field: {data}")
    return token

def _session_payload(profile: Dict[str, str], req: StartRequest, knowledge: str) -> SessionPayload:
    return SessionPayload(
        avatarName=profile["avatar_id"],
        language=req.language or DEFAULT_LANGUAGE,
        knowledgeBase=knowledge,
        quality=DEFAULT_QUALITY,
        activityIdleTimeout=DEFAULT_ACTIVITY_IDLE_TIMEOUT,
        voiceChatTransport=DEFAULT_TRANSPORT,
    )

def _greeting(req: StartRequest) -> Optional[str]:
    if not req.deterministic_greeting:
        return None
    tpl = req.greeting_template or "Hi, {user_name}!"
    try:
        return tpl.format(user_name=req.user_name)
    except Exception:
        return f"Hi, {req.user_name}!"

# ---- routes ----
@app.get("/api/health")
async def health():
    return {"ok": True, "has_api_key": bool(HEYGEN_API_KEY), "profiles": list(PROFILES.keys())}

@app.get("/api/profiles", response_model=List[ProfileOut])
async def profiles():
    return [ProfileOut(id=k, agent_name=v["agent_name"], avatar_id=v["avatar_id"]) for k, v in PROFILES.items()]

@app.post("/api/session", response_model=SessionResponse)
async def session(req: StartRequest):
    profile = _get_profile(req.profile_id)
    knowledge = _build_knowledge(req.user_name, profile["agent_name"], req.knowledge)
    token = await _mint_token()
    session = _session_payload(profile, req, knowledge)
    greeting = _greeting(req)
    return SessionResponse(
        token=token,
        session=session,
        greeting=greeting,
        effective_knowledge=knowledge if DEBUG_EFFECTIVE_KNOWLEDGE else None,
    )

@app.post("/api/new-patient", response_model=PatientResponse)
async def new_patient(req: NewPatientRequest):
    """
    Add a new patient or update existing patient by phone number.
    
    - **name**: Patient's full name (1-100 characters)
    - **phone_number**: Patient's phone number (10-15 characters) 
    - **agent_name**: Assigned agent name (1-50 characters)
    
    If a patient with the same phone number exists, their data will be updated.
    A random 6-character UID will be generated for each patient.
    An SMS with the meeting link will be sent to the patient's phone number.
    """
    try:
        result = _add_or_update_patient(req.name, req.phone_number, req.agent_name)
        
        # Send SMS notification with meeting link (use original full doctor name for SMS)
        sms_sent = await _send_sms(req.phone_number, req.name, req.agent_name, result.uid)
        if not sms_sent:
            # Log warning but don't fail the request
            print(f"Warning: SMS could not be sent to {req.phone_number}")
        
        return result
    except Exception as e:
        raise HTTPException(500, f"Failed to process patient data: {str(e)}")

@app.get("/api/patient/{uid}", response_model=PatientLookupResponse)
async def get_patient(uid: str):
    """
    Look up a patient by UID and return their name and assigned doctor.
    """
    patient = _find_patient_by_uid(uid)
    if not patient:
        raise HTTPException(404, f"No patient found for uid '{uid}'")
    return PatientLookupResponse(name=patient.get('name', ''), doctor=patient.get('agent_name', ''))

@app.post("/api/summarize-transcript", response_model=TranscriptSummaryResponse)
async def summarize_transcript(req: TranscriptSummaryRequest):
    """
    Summarize a conversation transcript using GPT-5 nano and save to conversations CSV.
    
    - **transcript**: The full transcript text to summarize
    - **start_time**: Start time of the call (ISO format)
    - **current_time**: Current/end time of the call (ISO format) 
    - **phone_number**: Phone number of the patient
    - **uid**: Patient's UID
    - **doctor_name**: Name of the doctor
    - **user_name**: Name of the patient
    
    Returns a summary focused on healthcare-relevant information and saves the data to convos.csv.
    """
    try:
        # Calculate call duration
        duration_minutes = _calculate_duration_minutes(req.start_time, req.current_time)
        
        # Summarize transcript using GPT-5 nano
        summary = await _summarize_transcript_with_openai(req.transcript)
        
        # Save to conversations CSV
        saved = _save_conversation_summary(
            start_time=req.start_time,
            duration_minutes=duration_minutes,
            phone_number=req.phone_number,
            uid=req.uid,
            summary=summary,
            doctor_name=req.doctor_name,
            user_name=req.user_name
        )
        
        return TranscriptSummaryResponse(summary=summary)
        
    except Exception as e:
        raise HTTPException(500, f"Failed to process transcript summary: {str(e)}")

@app.post("/api/process-audio", response_model=AudioProcessResponse)
async def process_audio(req: AudioProcessRequest):
    """
    Process audio input using OpenAI Whisper for transcription and GPT-4o-mini for text cleanup.
    
    - **audio_data**: Base64 encoded audio data
    - **patient_context**: Optional additional patient context
    
    Returns the transcribed and processed text ready for HeyGen.
    """
    try:
        # Decode base64 audio data
        try:
            audio_bytes = base64.b64decode(req.audio_data)
        except Exception as e:
            raise HTTPException(400, f"Invalid base64 audio data: {str(e)}")
        
        # Load medical context
        medical_context = _load_medical_data()
        
        # Transcribe audio using Whisper
        transcribed_text = await _transcribe_audio_with_whisper(audio_bytes)
        
        # Process text with OpenAI GPT-4o-mini
        processed_text = await _process_text_with_openai(transcribed_text, medical_context)
        
        return AudioProcessResponse(
            transcribed_text=transcribed_text,
            processed_text=processed_text,
            success=True
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Failed to process audio: {str(e)}")