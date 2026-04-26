# Migration Plan

## Goal

Refactor the Android app into a native SwiftUI iPhone app without disturbing the existing Kotlin or React code. The first iOS milestone should prove that the intake flow, patient registration, and avatar session startup work on real Apple hardware.

## Current source of truth

- Android app: `lahacks/Kotlin`
- Backend: `lahacks/ReactTS/backend`

## Product flow to preserve

1. Home screen
2. Doctor selection
3. Phone entry and patient registration
4. Checkup session
5. Optional auth and dashboard history

## Recommended implementation order

### Phase 1: SwiftUI shell

- Port routing and screen flow.
- Port shared models and request/response contracts.
- Port patient registration and patient lookup.
- Keep auth mocked or lightly stubbed.

### Phase 2: Native avatar session

- Use the LiveAvatar REST flow already proven in Android:
  - `POST /sessions/token`
  - `POST /sessions/start`
  - `POST /sessions/stop`
- Do not auto-start sessions on view load.
- Trigger session startup only from a clear `Start Visit` button.
- Render the avatar with the native LiveKit Swift SDK rather than a web view.

### Phase 3: Transcription and summary

- Use backend summarization first.
- Keep transcript state local in SwiftUI.
- Add an abstraction layer for speech recognition.
- Evaluate Apple Speech / Apple frameworks or backend Whisper before considering local iOS Whisper.

### Phase 4: Dashboard and auth

- Replace demo dashboard data with real backend-backed history.
- Wire a real auth provider if you still need saved history on iOS.

## What should not be ported directly

### Android-only local ML

The current `WhisperManager` and `GemmaManager` depend on Zetic MLange Android APIs. That stack is not a simple Swift port. Preserve the app architecture, but replace the concrete implementation on iOS later.

### WebView avatar rendering

The Android debugging path showed that WebView and emulator media decoding were major sources of failure. For iOS, the native renderer should be the default direction.

## Risk areas

- paid session usage during iteration
- LiveAvatar account balance and billing cadence
- simulator vs physical-device media differences
- speech recognition parity with the Android prototype

## Guardrails

- keep all secrets out of committed Swift source
- require explicit start for billable avatar sessions
- prefer protocol-based service boundaries so audio, auth, and avatar internals can evolve without rewriting the UI

