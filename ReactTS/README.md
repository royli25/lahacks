# Amiya Health

Accessible, affordable AI-powered virtual checkups for seniors.

## The Problem
### 🔴 **70% of elders feel telehealth has excessive complexity and friction, leading to fewer seniors attending preventative care leaving less peace of mind for caregivers.**

A growing number of seniors are skipping medical checkups due to cost, mobility challenges, and complex technology. This creates an urgent need for accessible, affordable, personalized, and human-centered virtual care that supports preventative health and caregiver peace of mind.

Limited access to regular checkups leaves millions of seniors vulnerable to preventable health decline, while placing greater emotional and logistical burdens on families and caregivers striving to support their well-being.

## Our Solution

Amiya Health provides an affordable, on-demand AI doctor that offers personalized, interactive virtual checkups.

Through a single click of a SMS text message, seniors can connect to a lifelike AI avatar doctor that conducts conversational health checkups, provides personalized medical guidance, and provides caregivers with detailed reports. 

## How It Works

1. Caregiver creates an account and completes onboarding with elder's information
2. System sends SMS notification to senior's phone via Twilio
3. Senior clicks the link and joins a video call with an AI doctor avatar, without any extra downloads or technical setup required.
4. Conversation is transcribed in real-time during the video call
5. After the call ends, GPT-o4 mini generates a summary of the consultation
6. Summary is stored in the database and accessible via caregiver dashboard

## System Architecture

<img src="Flowchart%20(1).png" alt="Amiya Health System Flow" width="500">

**Caregiver Flow (Green)**
- Home page navigation
- Onboarding process: Enter elder's name, select doctor, provide phone number
- Dashboard to view all patient conversations
- All data stored in Supabase Database

**Elder Patient Flow (Blue)**
- Receives SMS notification via Twilio
- Opens link to join video call
- Interactive video call with AI doctor avatar and live transcription
- Ends call when consultation is complete

**Backend Processing (Red)**
- Creates new user records in Supabase
- Sends SMS notifications through Twilio
- Manages real-time video calls with transcription
- Core technology processes each interaction:
  - Medical dataset informs conversation context
  - OpenAI GPT-4o-mini generates intelligent responses
  - HeyGen creates lifelike avatar video
  - ElevenLabs synthesizes natural voice
- Post-call processing:
  - GPT-4 summarizes the full transcript
  - Summary stored in user's database for caregiver access

## Technology Stack

**Frontend**
- React 18 with modern hooks
- Interactive web-based video interface
- CSS3 for styling

**AI and Voice**
- OpenAI GPT-4o-mini for intelligent medical conversations
- OpenAI Whisper API for Speech-To-Text.
- HeyGen for avatar video generation
- ElevenLabs for natural voice synthesis

**Communications**
- Twilio for SMS notifications

**Data**
- Medical dataset for accurate health guidance

## Hackathon Limitations

### AI Model Limitations

Due to budget and time constraints during the hackathon, we used base free tier APIs with ElevenLabs & HeyGen. In production, we would use higher quality reasoning models and video outputs for more realistic and accurate interactions.

### Medical Dataset & API

We found API endpoints at Mayo Clinic, National Library of Medicine, that can be integrated as Data for our AI responses.

### Specialist Referrals

People with certain insurance plans or lack thereof are able to book direct appointments with specialists, bypassing traditional family doctors.

---


