#!/usr/bin/env python3
"""
Test script for the audio processing endpoint.
This script creates a simple test audio file and sends it to the /api/process-audio endpoint.
"""

import os
import base64
import requests
import tempfile
import wave
import numpy as np

def create_test_audio():
    """Create a simple test audio file with a sine wave."""
    # Create a 1-second sine wave at 440 Hz (A note)
    sample_rate = 16000
    duration = 1.0
    frequency = 440
    
    # Generate sine wave
    t = np.linspace(0, duration, int(sample_rate * duration), False)
    audio_data = np.sin(2 * np.pi * frequency * t)
    
    # Convert to 16-bit PCM
    audio_data = (audio_data * 32767).astype(np.int16)
    
    # Create temporary WAV file
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
        with wave.open(temp_file.name, 'w') as wav_file:
            wav_file.setnchannels(1)  # Mono
            wav_file.setsampwidth(2)  # 16-bit
            wav_file.setframerate(sample_rate)
            wav_file.writeframes(audio_data.tobytes())
        return temp_file.name

def test_audio_processing():
    """Test the audio processing endpoint."""
    # Create test audio file
    audio_file_path = create_test_audio()
    
    try:
        # Read audio file and encode as base64
        with open(audio_file_path, 'rb') as audio_file:
            audio_bytes = audio_file.read()
            audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')
        
        # Prepare request data
        request_data = {
            "audio_data": audio_base64,
            "patient_context": "Test patient: John Doe, Doctor: Dr. Smith"
        }
        
        # Send request to the endpoint
        print("Sending test audio to /api/process-audio endpoint...")
        response = requests.post(
            "http://localhost:8000/api/process-audio",
            json=request_data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Response status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Audio processing successful!")
            print(f"Transcribed text: {result.get('transcribed_text', 'N/A')}")
            print(f"Processed text: {result.get('processed_text', 'N/A')}")
            print(f"Success: {result.get('success', False)}")
        else:
            print(f"❌ Audio processing failed: {response.text}")
    
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
    
    finally:
        # Clean up temporary file
        if os.path.exists(audio_file_path):
            os.unlink(audio_file_path)

if __name__ == "__main__":
    print("🧪 Testing OpenAI Whisper Audio Processing Integration")
    print("=" * 60)
    test_audio_processing()
