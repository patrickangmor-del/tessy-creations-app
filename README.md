# Tessy Creations

A customer & order management app for Tessy Creations, built with Flutter.
Everything is stored on-device (no internet required, no cloud account).

## Project status

Building in stages. Current stage: **project setup** (app shell + navigation).
See the plan in the original task description for what's next.

## Running the app

You'll need:

1. **Flutter SDK** installed on your computer — https://docs.flutter.dev/get-started/install
2. **Android Studio** (for the Android SDK + an emulator, or to plug in a real phone/tablet over USB with "USB debugging" turned on in Developer Options)

Then, from this project folder:

```bash
flutter pub get
flutter devices        # confirm your phone/tablet or emulator shows up
flutter run             # builds and installs the app, with live hot-reload
```

To install a release build you can keep on the device without staying connected to a computer:

```bash
flutter build apk --release
# APK will be at build/app/outputs/flutter-apk/app-release.apk
# copy it to the phone/tablet and open it to install (allow "install from unknown sources" if asked)
```

## Checking the code without a device

```bash
flutter analyze   # static checks
flutter test      # automated tests
```
