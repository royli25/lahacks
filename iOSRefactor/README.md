# Amiya Health iOS Refactor

This folder is a clean SwiftUI-first refactor workspace for the existing `Kotlin` Android app. It does not overwrite or modify the current Android or React code.

## Why this exists

The current avatar path works well enough to prove that LiveAvatar sessions can start, but the Android Emulator is not a trustworthy target for final media validation. This iOS refactor is meant to:

- preserve the current product flow
- move avatar playback to a native mobile path instead of WebView-first rendering
- avoid burning paid LiveAvatar sessions during every screen load
- give you a GitHub-uploadable Swift codebase you can continue on a Mac

## What is included

- a SwiftUI app shell
- app routing and screen scaffolding
- Codable models mapped from the Kotlin data layer
- backend and LiveAvatar API clients
- a `CheckupViewModel` built around an explicit `Start Visit` action instead of auto-starting paid sessions
- migration docs and a Kotlin-to-Swift feature audit
- XcodeGen project scaffolding

## What is intentionally not finished yet

- native LiveKit video rendering
- iOS auth integration
- on-device Whisper/Gemma replacement
- persistent dashboard history

Those are called out in [Docs/MigrationPlan.md](./Docs/MigrationPlan.md).

## Recommended next steps on a Mac

1. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig`.
2. Fill in `LIVEAVATAR_API_KEY` and `BACKEND_BASE_URL`.
3. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen).
4. Run `xcodegen generate` from this folder.
5. Open the generated Xcode project.
6. Add the LiveKit Swift SDK through Swift Package Manager.
7. Replace `NativeAvatarView` with a real native LiveKit renderer.

## Important migration decisions

- Do not port the Android WebView avatar approach to iOS.
- Do not auto-start paid avatar sessions on screen open.
- Do not try to directly port the Android Zetic MLange Whisper/Gemma stack on day one.
- Keep the backend summarization path available as the first working transcript/summary implementation.
