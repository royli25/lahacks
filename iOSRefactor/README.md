# Amiya Health iOS Refactor

This folder is a clean SwiftUI-first refactor workspace for the existing `Kotlin` Android app. It does not overwrite or modify the current Android or React code.

## Why this exists

This iOS refactor is now narrowed to one goal: start a direct HeyGen/LiveAvatar doctor call on a real iPhone with LiveKit handling media.

- preserve the call flow
- move avatar playback to a native mobile path instead of WebView-first rendering
- avoid burning paid LiveAvatar sessions during every screen load
- give you a GitHub-uploadable Swift codebase you can continue on a Mac

## What is included

- a SwiftUI app shell
- name entry, doctor selection, and call screens
- LiveAvatar API client
- direct LiveAvatar/LiveKit call setup for HeyGen-only testing
- a `CheckupViewModel` built around an explicit `Start Visit` action instead of auto-starting paid sessions
- XcodeGen project scaffolding

## What is intentionally removed for this build

- backend registration
- phone number entry
- SMS/text-message flow
- dashboard/auth/history
- transcript summary
- local Zetic STT/LLM

## Recommended next steps on a Mac

1. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig`.
2. Fill in `LIVEAVATAR_API_KEY`.
3. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen).
4. Run `xcodegen generate` from this folder.
5. Open the generated Xcode project.
6. Confirm the generated project resolves the LiveKit Swift package.
7. Run on a real iPhone for microphone and LiveKit validation.

## Important migration decisions

- Do not port the Android WebView avatar approach to iOS.
- Do not auto-start paid avatar sessions on screen open.
- Do not send a LiveAvatar `context_id` until a valid context ID is confirmed for the API key.
