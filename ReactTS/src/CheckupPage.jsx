import { useEffect, useRef, useState } from 'react';
import { useParams } from 'react-router-dom';
import StreamingAvatar, { AvatarQuality, VoiceChatTransport, StreamingEvents } from '@heygen/streaming-avatar';

// Custom SVG icons to replace lucide-react
const MicIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/>
    <path d="M19 10v2a7 7 0 0 1-14 0v-2"/>
    <line x1="12" y1="19" x2="12" y2="23"/>
    <line x1="8" y1="23" x2="16" y2="23"/>
  </svg>
);

const MicOffIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <line x1="1" y1="1" x2="23" y2="23"/>
    <path d="M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V4a3 3 0 0 0-5.94-.6"/>
    <path d="M17 16.95A7 7 0 0 1 5 12v-2m14 0v2a7 7 0 0 1-.11 1.23"/>
    <line x1="12" y1="19" x2="12" y2="23"/>
    <line x1="8" y1="23" x2="16" y2="23"/>
  </svg>
);

const VideoIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <polygon points="23 7 16 12 23 17 23 7"/>
    <rect x="1" y="5" width="15" height="14" rx="2" ry="2"/>
  </svg>
);

const VideoOffIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M16 16v1a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h2m5.66 0H14a2 2 0 0 1 2 2v3.34l1 1L23 7v10"/>
    <line x1="1" y1="1" x2="23" y2="23"/>
  </svg>
);

const PhoneIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>
  </svg>
);

const WhisperIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 11H5a2 2 0 0 0-2 2v3c0 1.1.9 2 2 2h4"/>
    <path d="M13 16h4a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2h-4"/>
    <path d="M9 11V9a3 3 0 0 1 6 0v2"/>
    <path d="M12 19v2"/>
    <path d="M8 23h8"/>
  </svg>
);

const WhisperOffIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <line x1="1" y1="1" x2="23" y2="23"/>
    <path d="M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V4a3 3 0 0 0-5.94-.6"/>
    <path d="M17 16.95A7 7 0 0 1 5 12v-2m14 0v2a7 7 0 0 1-.11 1.23"/>
    <path d="M12 19v2"/>
    <path d="M8 23h8"/>
  </svg>
);

export default function CheckupPage() {
  const { uid } = useParams();
  console.log('CheckupPage component mounted, uid:', uid);
  const videoRef = useRef(null);
  const webcamRef = useRef(null);
  const [status, setStatus] = useState('idle');
  const [voiceStatus, setVoiceStatus] = useState('Voice mode idle');
  const [debugInfo, setDebugInfo] = useState('');
  const [pageTitle, setPageTitle] = useState('Patient Checkup');
  const [doctorName, setDoctorName] = useState('');
  const doctorNameRef = useRef('');
  const [transcript, setTranscript] = useState([]); // { who: 'user'|'avatar', text, at }
  const transcriptRef = useRef(null);
  const saRef = useRef(null);
  const [sessionOpen, setSessionOpen] = useState(false);
  const [isMuted, setIsMuted] = useState(false); // mute local microphone (user)
  const [webcamVisible, setWebcamVisible] = useState(true); // toggle webcam visibility
  const [showMain, setShowMain] = useState(false); // switch from loading screen to main UI when stream ready
  const [showControls, setShowControls] = useState(true);
  const [hoveredButton, setHoveredButton] = useState(null);
  const incomingStreamRef = useRef(null); // hold STREAM_READY media stream until video is mounted
  const webcamStreamRef = useRef(null);
  const [forcedName, setForcedName] = useState(null);
  const [forcedProfileId, setForcedProfileId] = useState(null);
  const startedRef = useRef(false);
  const [isAvatarTalking, setIsAvatarTalking] = useState(false);
  const pendingMuteRef = useRef(null);
  const timeoutRef = useRef(null);
  const [useWhisperProcessing, setUseWhisperProcessing] = useState(true); // Toggle for Whisper processing
  const mediaRecorderRef = useRef(null);
  const audioChunksRef = useRef([]);
  const isRecordingRef = useRef(false);

  function mapDoctorToProfileId(doctor) {
    const d = doctor.trim().toLowerCase();
    // Map doctor names to profile IDs (handles both full names and first names)
    if (d.includes('sarah') || d.includes('sarah chen')) return 'alpha';  // Sarah -> Dexter
    if (d.includes('michael') || d.includes('michael rodriguez')) return 'beta';  // Michael -> Ann  
    if (d.includes('emily') || d.includes('emily johnson')) return 'gamma';  // Emily -> Judy
    // Fallback mappings for original names
    if (d === 'dexter') return 'alpha';
    if (d === 'ann') return 'beta';
    if (d === 'judy') return 'gamma';
    return 'alpha'; // Default fallback
  }

  useEffect(() => {
    console.log('useEffect triggered, uid:', uid);
    async function load() {
      console.log('CheckupPage UID from URL:', uid);
      if (!uid) {
        window.location.href = '/';
        return;
      }

      try {
        console.log('Fetching patient data for UID:', uid);
        const response = await fetch(`/api/patient/${uid}`);
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        console.log('Patient data received:', data);
        console.log('data name', data.name);

        const patientName = data.name || 'Patient';
        const doctorName = data.doctor || 'Doctor';
        const profileId = mapDoctorToProfileId(doctorName);

        console.log('Patient data:', { patientName, doctorName, profileId });

        setPageTitle(`${patientName}'s checkup with ${doctorName}`);
        setForcedName(patientName);
        setForcedProfileId(profileId);
        setDoctorName(doctorName);
        doctorNameRef.current = doctorName;

        // Auto-start the session
        console.log('About to start session with:', { patientName, profileId });
        try {
          await startSession(patientName, profileId);
        } catch (sessionError) {
          console.error('Session creation failed:', sessionError);
          setDebugInfo(`Session creation failed: ${sessionError.message}`);
        }
      } catch (error) {
        console.error('Error loading patient data:', error);
        setDebugInfo(`Error loading patient data: ${error.message}`);
      }
    }

    load();
  }, [uid]);

  // Auto-scroll transcript to bottom when it updates
  useEffect(() => {
    const el = transcriptRef.current;
    if (!el) return;
    el.scrollTop = el.scrollHeight;
  }, [transcript]);

  // Initialize control timeout
  useEffect(() => {
    resetTimeout();
    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, []);

  async function startWebcam() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true });
      webcamStreamRef.current = stream;
      if (webcamRef.current) webcamRef.current.srcObject = stream;
    } catch (e) { console.error('Failed to start webcam', e); }
  }
  function stopWebcam() {
    if (webcamStreamRef.current) {
      webcamStreamRef.current.getTracks().forEach(t => t.stop());
      webcamStreamRef.current = null;
      if (webcamRef.current) webcamRef.current.srcObject = null;
    }
  }

  function pushTurn(who, text) {
    if (!text) return;
    const clean = String(text).trim();
    if (!clean) return;
    const sanitizePunctuation = (s) => s.replace(/\s+([\.,!?])/g, '$1');
    setTranscript(prev => {
      if (prev.length === 0) return [{ who, text, at: Date.now() }];
      const last = prev[prev.length - 1];
      if (last.who === who) {
        // merge consecutive messages from same speaker
        const lastClean = String(last.text || '').trim();
        const mergedRaw = lastClean && clean ? `${lastClean} ${clean}` : (lastClean || clean);
        const mergedText = sanitizePunctuation(mergedRaw);
        const merged = { ...last, text: mergedText };
        return [...prev.slice(0, -1), merged];
      }
      return [...prev, { who, text: sanitizePunctuation(clean), at: Date.now() }];
    });
  }

  function getMuteAwareStatus(baseStatus) {
    if (isMuted && (baseStatus === 'Listening…' || baseStatus === 'Waiting for you to speak…')) {
      return 'Muted';
    }
    return baseStatus;
  }

  const resetTimeout = () => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    setShowControls(true);
    timeoutRef.current = setTimeout(() => {
      setShowControls(false);
    }, 1000);
  };

  const handleMouseMove = () => {
    resetTimeout();
  };

  async function startSession(patientName, profileId) {
    if (startedRef.current) {
      console.log('Session already started, skipping...');
      return;
    }
    console.log('Setting startedRef to true');
    startedRef.current = true;

    try {
      console.log('Starting session with payload:', {
        profile_id: profileId,
        user_name: patientName,
        deterministic_greeting: true
      });
      console.log('About to call /api/session endpoint...');

      const response = await fetch('/api/session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          profile_id: profileId,
          user_name: patientName,
          deterministic_greeting: true
        })
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`API request failed with status ${response.status}: ${errorText}`);
      }

      const data = await response.json();
      console.log('Session response:', data);
      console.log('Session response keys:', Object.keys(data));
      
      // Debug: Check if session data exists
      if (!data.session) {
        console.error('No session data in response:', data);
        throw new Error('Session data missing from API response');
      }
      
      console.log('Session data:', data.session);
      console.log('Session data keys:', Object.keys(data.session));
      
      if (!data.session.avatarName) {
        console.error('No avatarName in session:', data.session);
        throw new Error('Avatar name missing from session data');
      }
      
      console.log('Avatar name found:', data.session.avatarName);

      const sa = new StreamingAvatar({
        newSessionConfig: {
          quality: AvatarQuality.HIGH,
          avatarName: data.session.avatarName,
          voice: {
            voiceId: "1bd001e7e50f421d891986aad5158bc8",
            speed: 1.0,
          },
          knowledgeBase: data.session.knowledgeBase,
          language: data.session.language,
          greeting: data.greeting,
          voiceChatTransport: VoiceChatTransport.WEBSOCKET,
        },
        token: data.token,
      });

      saRef.current = sa;

      sa.on(StreamingEvents.STREAM_READY, () => {
        console.log('Stream ready');
        setStatus('Stream ready');
        incomingStreamRef.current = sa.getStream();
        setShowMain(true);
        requestAnimationFrame(() => {
          if (videoRef.current && incomingStreamRef.current) {
            videoRef.current.srcObject = incomingStreamRef.current;
          }
        });
        
        // Auto-start voice chat after a short delay
        setTimeout(() => {
          startVoiceChatWithWhisper();
        }, 1000);
      });

      sa.on(StreamingEvents.STREAM_DISCONNECTED, () => {
        console.log('Stream disconnected');
        setStatus('Stream disconnected');
        if (videoRef.current) {
          videoRef.current.srcObject = null;
        }
        setShowMain(false);
      });

      sa.on(StreamingEvents.USER_TALKING_MESSAGE, (msg) => {
        const text = msg?.detail?.message || msg?.message || '';
        if (text) pushTurn('user', text);
      });

      sa.on(StreamingEvents.AVATAR_TALKING_MESSAGE, (msg) => {
        const text = msg?.detail?.message || msg?.message || '';
        if (text) pushTurn('avatar', text);
      });

      sa.on(StreamingEvents.USER_START, () => {
        setVoiceStatus(getMuteAwareStatus('Listening…'));
      });

      sa.on(StreamingEvents.USER_STOP, () => {
        setVoiceStatus('Processing…');
      });

      sa.on(StreamingEvents.AVATAR_START_TALKING, () => {
        setIsAvatarTalking(true);
        setVoiceStatus(doctorNameRef.current ? `Dr. ${doctorNameRef.current} is speaking…` : 'Avatar is speaking…');
      });

      sa.on(StreamingEvents.AVATAR_STOP_TALKING, () => {
        setIsAvatarTalking(false);
        if (pendingMuteRef.current !== null) {
          setIsMuted(pendingMuteRef.current);
          pendingMuteRef.current = null;
          startVoiceChatWithWhisper();
        }
        setVoiceStatus(getMuteAwareStatus('Waiting for you to speak…'));
      });

      await sa.createStartAvatar();
      setSessionOpen(true);
    } catch (error) {
      console.error('Error starting session:', error);
      setDebugInfo(`Error starting session: ${error.message}`);
      setStatus(`Error: ${error.message}`);
    }
  }

  function stopSession() {
    if (saRef.current) {
      saRef.current.stopAvatar();
      saRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
    stopWebcam();
    setSessionOpen(false);
    setShowMain(false);
    setStatus('Session stopped');
    setVoiceStatus('Voice mode idle');
    startedRef.current = false;
  }

  async function startVoiceChat() {
    try {
      // Request microphone permission
      await navigator.mediaDevices.getUserMedia({ audio: true });
      
      if (saRef.current) {
        await saRef.current.startVoiceChat({
          isInputAudioMuted: isMuted
        });
        console.log('Voice chat started');
      }
    } catch (error) {
      console.error('Failed to start voice chat:', error);
      setDebugInfo(`Voice chat error: ${error.message}`);
    }
  }

  function toggleMute() {
    if (isAvatarTalking) {
      // If avatar is speaking, store the pending mute state
      pendingMuteRef.current = !isMuted;
    } else {
      // If avatar is not speaking, apply mute immediately
      setIsMuted(!isMuted);
      startVoiceChatWithWhisper();
    }
  }

  function toggleWebcam() {
    if (webcamVisible) {
      setWebcamVisible(false);
      stopWebcam();
    } else {
      setWebcamVisible(true);
      startWebcam();
    }
  }

  function toggleWhisperProcessing() {
    setUseWhisperProcessing(!useWhisperProcessing);
    console.log('Whisper processing:', !useWhisperProcessing ? 'enabled' : 'disabled');
  }

  // Audio processing functions for Whisper integration
  async function startAudioRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream, { mimeType: 'audio/webm' });
      mediaRecorderRef.current = mediaRecorder;
      audioChunksRef.current = [];

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          audioChunksRef.current.push(event.data);
        }
      };

      mediaRecorder.onstop = async () => {
        await processAudioChunks();
      };

      mediaRecorder.start(1000); // Record in 1-second chunks
      isRecordingRef.current = true;
      console.log('Audio recording started');
    } catch (error) {
      console.error('Failed to start audio recording:', error);
    }
  }

  function stopAudioRecording() {
    if (mediaRecorderRef.current && isRecordingRef.current) {
      mediaRecorderRef.current.stop();
      isRecordingRef.current = false;
      console.log('Audio recording stopped');
    }
  }

  async function processAudioChunks() {
    if (audioChunksRef.current.length === 0) return;

    try {
      const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/webm' });
      const audioArrayBuffer = await audioBlob.arrayBuffer();
      const audioBase64 = btoa(String.fromCharCode(...new Uint8Array(audioArrayBuffer)));

      console.log('Processing audio with Whisper...');
      
      const response = await fetch('/api/process-audio', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          audio_data: audioBase64,
          patient_context: `Patient: ${forcedName || 'Patient'}, Doctor: ${doctorNameRef.current || 'Doctor'}`
        })
      });

      if (!response.ok) {
        throw new Error(`Audio processing failed: ${response.status}`);
      }

      const result = await response.json();
      console.log('Audio processing result:', result);

      if (result.success && result.processed_text) {
        // Send processed text to HeyGen instead of raw audio
        pushTurn('user', result.processed_text);
        
        // Send the processed text to HeyGen using the speak method
        if (saRef.current && result.processed_text.trim()) {
          await saRef.current.speak(result.processed_text);
        }
      }

      // Clear chunks for next recording
      audioChunksRef.current = [];
    } catch (error) {
      console.error('Error processing audio:', error);
      setDebugInfo(`Audio processing error: ${error.message}`);
    }
  }

  // Modified voice chat function to use Whisper processing
  async function startVoiceChatWithWhisper() {
    try {
      if (useWhisperProcessing) {
        // Start audio recording for Whisper processing
        await startAudioRecording();
      } else {
        // Use original HeyGen voice chat
        await navigator.mediaDevices.getUserMedia({ audio: true });
        
        if (saRef.current) {
          await saRef.current.startVoiceChat({
            isInputAudioMuted: isMuted
          });
          console.log('Voice chat started (direct mode)');
        }
      }
    } catch (error) {
      console.error('Failed to start voice chat:', error);
      setDebugInfo(`Voice chat error: ${error.message}`);
    }
  }

  if (!showMain) {
    return (
      <div style={{
        width: '100%',
        height: '100vh',
        background: 'white',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        fontFamily: "'IBM Plex Sans', sans-serif"
      }}>
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: '2rem'
        }}>
          <div style={{
            width: '40px',
            height: '40px',
            border: '4px solid #f3f3f3',
            borderTop: '4px solid #3498db',
            borderRadius: '50%',
            animation: 'spin 2s linear infinite'
          }}></div>
          <div style={{ textAlign: 'center' }}>
            <h2 style={{ margin: '0 0 1rem 0', color: '#333' }}>Setting up your checkup...</h2>
            <p style={{ margin: 0, color: '#666' }}>{status}</p>
            {debugInfo && <p style={{ margin: '1rem 0 0 0', color: '#e74c3c', fontSize: '0.9rem' }}>{debugInfo}</p>}
          </div>
        </div>
        <style>{`
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        `}</style>
      </div>
    );
  }

  return (
    <>
      <style>{`
        .container {
          width: 100%;
          height: 100vh;
          background: white;
          display: flex;
          overflow: hidden;
          font-family: 'IBM Plex Sans', sans-serif;
        }
        
        .video-frame {
          position: relative;
          flex: 1;
          height: 100vh;
          overflow: hidden;
        }
        
        .transcript-panel {
          width: 28%;
          max-width: 28vw;
          height: 100vh;
          background: white;
          border-left: 1px solid #e5e7eb;
          overflow-y: auto;
          padding: 2rem;
        }
        
        .transcript-entry {
          margin-bottom: 1.5rem;
        }
        
        .transcript-header {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          margin-bottom: 0.5rem;
        }
        
        .transcript-speaker {
          font-weight: 700;
          color: #111827;
          font-size: 0.875rem;
        }
        
        .transcript-timestamp {
          font-size: 0.6875rem;
          color: #9ca3af;
        }
        
        .transcript-text {
          color: #374151;
          line-height: 1.5;
          font-size: 0.875rem;
        }
        
        .main-video {
          width: 100%;
          height: 100%;
          object-fit: cover;
          object-position: center;
        }
        
        .title-overlay {
          position: absolute;
          top: 1.5rem;
          left: 1.5rem;
          color: white;
          font-size: 1.125rem;
          font-weight: 500;
          text-shadow: 2px 2px 8px rgba(0, 0, 0, 0.4), 0 0 12px rgba(0, 0, 0, 0.3);
        }
        
        .webcam-preview {
          position: absolute;
          top: 1.5rem;
          right: 1.5rem;
          width: 20%;
          aspect-ratio: 16 / 9;
          border-radius: 0.5rem;
          border: 2px solid rgba(255, 255, 255, 0.3);
          overflow: hidden;
        }
        
        .webcam-video {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }
        
        .controls-container {
          position: absolute;
          bottom: 0;
          left: 0;
          right: 0;
          display: flex;
          align-items: center;
          justify-content: center;
          padding-bottom: 2rem;
          transition: transform 0.3s ease, opacity 0.3s ease;
        }
        
        .controls-container.hidden {
          transform: translateY(100%);
          opacity: 0;
        }
        
        .controls-container.visible {
          transform: translateY(0);
          opacity: 1;
        }
        
        .controls {
          display: flex;
          align-items: center;
          gap: 1.5rem;
        }
        
        .control-button-wrapper {
          position: relative;
        }
        
        .control-button {
          width: 3.5vw;
          height: 3.5vw;
          min-width: 3rem;
          min-height: 3rem;
          max-width: 4.5rem;
          max-height: 4.5rem;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          border: none;
          cursor: pointer;
          transition: background-color 0.2s ease;
        }
        
        .control-button.camera, .control-button.mic, .control-button.whisper {
          background-color: rgba(55, 65, 81, 0.75);
        }
        
        .control-button.camera:hover, .control-button.mic:hover,         .control-button.whisper:hover {
          background-color: rgba(75, 85, 99, 0.75);
        }
        
        .control-button.whisper.active {
          background-color: rgba(34, 197, 94, 0.75);
        }
        
        .control-button.whisper.active:hover {
          background-color: rgba(34, 197, 94, 0.9);
        }
        
        .control-button.end-call {
          background-color: rgb(220, 38, 38);
        }
        
        .control-button.end-call:hover {
          background-color: rgb(185, 28, 28);
        }
        
        .tooltip {
          position: absolute;
          top: -2.5rem;
          left: 50%;
          transform: translateX(-50%);
          white-space: nowrap;
          background: rgba(0, 0, 0, 0.75);
          color: white;
          font-size: 0.875rem;
          padding: 0.5rem 0.75rem;
          border-radius: 0.375rem;
          pointer-events: none;
        }
        
        .icon {
          width: 1.5vw;
          height: 1.5vw;
          min-width: 1.25rem;
          min-height: 1.25rem;
          max-width: 2rem;
          max-height: 2rem;
          color: white;
        }
        
        .phone-icon {
          transform: rotate(135deg);
        }
        
        .status-indicator {
          position: absolute;
          bottom: 2rem;
          left: 2rem;
          display: flex;
          align-items: center;
          gap: 0.5rem;
          background: rgba(0, 0, 0, 0.6);
          padding: 0.5rem 1rem;
          border-radius: 9999px;
          color: white;
          font-size: 0.875rem;
          z-index: 10;
        }
        
        .status-icon {
          width: 0.75rem;
          height: 0.75rem;
          border-radius: 50%;
          animation: pulse 2s ease-in-out infinite;
        }
        
        .status-icon.listening {
          background-color: #10b981;
        }
        
        .status-icon.thinking {
          background-color: #f59e0b;
        }
        
        .status-icon.speaking {
          background-color: #3b82f6;
        }
        
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
      `}</style>
      
      <div className="container" onMouseMove={handleMouseMove}>
        <div className="video-frame">
          <video ref={videoRef} className="main-video" autoPlay playsInline muted />
          <div className="title-overlay">
            {pageTitle}
          </div>
          
          {webcamVisible && (
            <div className="webcam-preview">
              <video ref={webcamRef} className="webcam-video" autoPlay playsInline muted />
            </div>
          )}
          
          <div className={`controls-container ${showControls ? 'visible' : 'hidden'}`}>
            <div className="controls">
              <div className="control-button-wrapper">
                <button 
                  onClick={toggleWebcam}
                  onMouseEnter={() => setHoveredButton('camera')}
                  onMouseLeave={() => setHoveredButton(null)}
                  className="control-button camera"
                >
                  {webcamVisible ? <VideoIcon /> : <VideoOffIcon />}
                </button>
                {hoveredButton === 'camera' && (
                  <div className="tooltip">
                    {webcamVisible ? 'Turn off camera' : 'Turn on camera'}
                  </div>
                )}
              </div>
              
              <div className="control-button-wrapper">
                <button 
                  onClick={toggleMute}
                  onMouseEnter={() => setHoveredButton('mic')}
                  onMouseLeave={() => setHoveredButton(null)}
                  className="control-button mic"
                >
                  {isMuted ? <MicOffIcon /> : <MicIcon />}
                </button>
                {hoveredButton === 'mic' && (
                  <div className="tooltip">
                    {isMuted ? 'Unmute' : 'Mute'}
                  </div>
                )}
              </div>
              
              <div className="control-button-wrapper">
                <button 
                  onClick={toggleWhisperProcessing}
                  onMouseEnter={() => setHoveredButton('whisper')}
                  onMouseLeave={() => setHoveredButton(null)}
                  className={`control-button whisper ${useWhisperProcessing ? 'active' : ''}`}
                >
                  {useWhisperProcessing ? <WhisperIcon /> : <WhisperOffIcon />}
                </button>
                {hoveredButton === 'whisper' && (
                  <div className="tooltip">
                    {useWhisperProcessing ? 'Disable AI processing' : 'Enable AI processing'}
                  </div>
                )}
              </div>
              
              <div className="control-button-wrapper">
                <button 
                  onClick={stopSession}
                  onMouseEnter={() => setHoveredButton('endCall')}
                  onMouseLeave={() => setHoveredButton(null)}
                  className="control-button end-call"
                >
                  <PhoneIcon className="icon phone-icon" />
                </button>
                {hoveredButton === 'endCall' && (
                  <div className="tooltip">End call</div>
                )}
              </div>
            </div>
          </div>
          
          {(voiceStatus !== 'Voice mode idle' && voiceStatus !== 'idle') && (
            <div className="status-indicator">
              <div className={`status-icon ${
                voiceStatus.includes('Listening') ? 'listening' : 
                voiceStatus.includes('Processing') ? 'thinking' : 
                voiceStatus.includes('speaking') ? 'speaking' : 'listening'
              }`}></div>
              <span>{voiceStatus}</span>
            </div>
          )}
        </div>
        
        <div className="transcript-panel" ref={transcriptRef}>
          {transcript.length === 0 ? (
            <div style={{
              color: '#9ca3af',
              fontSize: '0.875rem',
              textAlign: 'center',
              marginTop: '2rem',
              fontStyle: 'italic'
            }}>
              Start talking and your transcript will appear here
            </div>
          ) : (
            transcript.map((turn, i) => (
              <div key={i} className="transcript-entry">
                <div className="transcript-header">
                  <div className="transcript-speaker">
                    {turn.who === 'user' ? 'You' : (doctorName ? `Dr. ${doctorName}` : 'Avatar')}
                  </div>
                  <div className="transcript-timestamp">
                    {new Date(turn.at).toLocaleTimeString()}
                  </div>
                </div>
                <div className="transcript-text">{turn.text}</div>
              </div>
            ))
          )}
        </div>
      </div>
    </>
  );
}
