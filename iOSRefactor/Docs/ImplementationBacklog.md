# Implementation Backlog

This backlog turns the high-level migration plan into a concrete build order for the new iOS codebase.

## Milestone 1: Generate and boot the app shell

- Generate the Xcode project from `project.yml`.
- Verify the app boots into `HomeView`.
- Confirm build settings read values from `Config/Secrets.xcconfig`.

Definition of done:
- The app launches in the iPhone simulator on a Mac.
- Navigation works from home to doctor selection to phone entry.

## Milestone 2: Port backend-backed patient intake

- Validate `BackendAPIClient.registerPatient`.
- Add a patient lookup flow for dashboard hydration.
- Add lightweight loading and error states for every backend request.

Definition of done:
- A new patient can be registered from the SwiftUI flow.
- The returned `uid` is carried into the checkup flow.

## Milestone 3: Native avatar session startup

- Add the LiveKit Swift package through Swift Package Manager.
- Replace `NativeAvatarView` with a real native renderer.
- Connect the renderer to `livekitURL` and `livekitClientToken`.
- Keep session start behind the explicit `Start Visit` button.
- Stop the session on call end and on view dismissal.

Definition of done:
- A LiveAvatar session starts on a real iPhone.
- Remote video renders natively without WebView.
- Exiting the visit stops the paid session cleanly.

## Milestone 4: Transcript capture

- Replace `PlaceholderTranscriptCaptureService`.
- Start with Apple-native speech APIs or backend-uploaded audio.
- Keep the service behind `TranscriptCaptureServiceProtocol`.

Definition of done:
- The transcript list receives live or near-live entries during a visit.

## Milestone 5: Summary generation

- Send transcript text to the existing backend summary route first.
- Show summary and next steps in `CheckupView`.
- Preserve failure states so summary issues do not break the visit flow.

Definition of done:
- A completed visit can produce a summary and next steps from the backend.

## Milestone 6: Dashboard and auth

- Replace sample dashboard history with real backend-backed data.
- Decide whether auth is required for the iOS MVP or can stay deferred.
- Add a lightweight persistence strategy for the current patient session.

Definition of done:
- Returning users can see previous checkups or the app clearly stays in guest mode.

## Nice-to-have follow-ups

- Add unit tests for service decoding and view model state transitions.
- Add a non-production mock mode for SwiftUI previews.
- Add analytics around session start failures and summary failures.
- Add a guardrail screen that shows estimated credit usage before starting a paid session.
