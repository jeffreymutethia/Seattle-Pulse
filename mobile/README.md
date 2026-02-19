# Seattle Pulse Mobile (Optional)

This directory contains the Seattle Pulse Flutter app code. Mobile is optional and not required for the main web/API demo.

## Prerequisites

Install Flutter locally (do not vendor Flutter SDK into this repository):
- https://docs.flutter.dev/get-started/install

Verify your local setup:

```bash
flutter doctor
```

## Local Run

From this `mobile/` directory:

```bash
flutter pub get
flutter run
```

## Notes

- Keep app code in this folder (`lib/`, `android/`, `ios/`, etc.).
- Do not commit a local Flutter SDK checkout such as `mobile/flutter/`.
