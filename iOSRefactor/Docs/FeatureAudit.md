# Feature Audit

This maps the current Kotlin app into the new Swift refactor structure.

## Existing Kotlin modules

- `MainActivity.kt`
- `navigation/NavGraph.kt`
- `ui/screens/HomeScreen.kt`
- `ui/screens/DoctorSelectionScreen.kt`
- `ui/screens/PhoneEntryScreen.kt`
- `ui/screens/AuthScreen.kt`
- `ui/screens/DashboardScreen.kt`
- `ui/screens/CheckupScreen.kt`
- `viewmodel/CheckupViewModel.kt`
- `api/ApiClient.kt`
- `api/ApiService.kt`
- `api/LiveAvatarApiClient.kt`
- `api/LiveAvatarApiService.kt`
- `data/models/Models.kt`
- `ml/WhisperManager.kt`
- `ml/GemmaManager.kt`

## Swift targets in this refactor

- `Sources/App`
  - app entry, routing, dependencies
- `Sources/Core/Config`
  - environment and build-time configuration
- `Sources/Core/Models`
  - Codable request/response and domain models
- `Sources/Core/Services`
  - backend and LiveAvatar API clients plus service protocols
- `Sources/Features/Home`
- `Sources/Features/DoctorSelection`
- `Sources/Features/PhoneEntry`
- `Sources/Features/Auth`
- `Sources/Features/Dashboard`
- `Sources/Features/Checkup`

## Important behavior changes

- The Swift plan does not auto-start billable avatar sessions on screen load.
- The Swift plan treats native LiveKit rendering as the target implementation.
- The Swift plan keeps local STT/LLM behind protocols instead of pretending the Android Zetic stack can be ported directly.

