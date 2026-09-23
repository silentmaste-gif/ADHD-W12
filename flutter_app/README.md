# AiDHD — Flutter App

Flutter/Dart version of the AiDHD app. Features login/register, ADHD likelihood screening, daily mood check-ins, daily assessments, history tracking, learn articles, task reminders, local notifications, and AI chat integration.

---

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                      # Entry point
│   ├── app.dart                       # Root widget + screen router
│   ├── models/
│   │   ├── user.dart                  # User profile and avatar model
│   │   ├── history_entry.dart         # HistoryEntry and mood model
│   │   └── task.dart                  # Task and reminder model
│   ├── services/
│   │   ├── auth_service.dart           # Firebase Authentication and profiles
│   │   ├── history_service.dart        # Per-user history persistence
│   │   ├── task_service.dart           # Per-user Firestore task persistence
│   │   └── notification_service.dart   # Device reminder notifications
│   ├── providers/
│   │   └── app_provider.dart          # Global state (Provider) + buildAiContext()
│   ├── theme/
│   │   └── app_theme.dart             # AIDHD color tokens + Material 3 theme
│   ├── widgets/
│   │   └── bottom_nav.dart            # Shared bottom navigation bar
│   └── screens/
│       ├── login_screen.dart
│       ├── signup_screen.dart
│       ├── initial_assessment_screen.dart
│       ├── home_screen.dart
│       ├── chat_screen.dart
│       ├── profile_screen.dart
│       ├── settings_screen.dart
│       └── remaining_screens.dart     # History, Mood, Assessment, Learn, Notifications, etc.
└── pubspec.yaml
```

---

## Running Locally in VS Code

### Step 1 — Install Flutter

Download and install the Flutter SDK from https://docs.flutter.dev/get-started/install

After installing, verify everything is set up:

```bash
flutter doctor
```

Fix any issues it reports (Android Studio, Xcode, Chrome, etc.) before continuing.

### Step 2 — Install the VS Code Flutter Extension

Open VS Code → Extensions (Ctrl+Shift+X) → search **Flutter** → Install.

Restart VS Code after installing.

### Step 3 — Open the flutter_app folder

**Important:** Open the `flutter_app/` subfolder directly in VS Code, **not** the parent project folder.

```
File → Open Folder → select "flutter_app"
```

### Step 4 — Generate platform folders

Flutter needs platform-specific folders (android/, ios/, web/) that are not committed to git. Run this **once** from inside the `flutter_app/` directory:

```bash
flutter create . --project-name aidhd
```

This is safe — it will not overwrite your existing Dart files.

### Step 5 — Install dependencies

```bash
flutter pub get
```

### Step 6 — Run the app

**Option A — VS Code (recommended):**
Press **F5** or go to Run → Start Debugging. Select a target device from the picker at the bottom of VS Code.

**Option B — Terminal:**

```bash
# Run on a connected Android/iOS device or emulator
flutter run

# Run in Chrome (web)
flutter run -d chrome

# Run in a specific emulator (list available devices first)
flutter devices
flutter run -d <device-id>
```

### Common Issues

| Problem | Fix |
|---|---|
| `No devices found` | Start an Android emulator in Android Studio, or connect a physical device with USB debugging on |
| `flutter: command not found` | Add Flutter's `bin/` directory to your PATH — see https://docs.flutter.dev/get-started/install |
| `google_fonts` network error | The app downloads Inter font at runtime. Make sure the emulator/device has internet access |
| Build fails on first run | Run `flutter clean && flutter pub get` then try again |

---

## Firebase backend

The app uses Firebase Authentication and Firestore for user profiles, history,
tasks, and completion records. Firebase migration instructions, Firestore
structure, security rules, and the secure AI API architecture are in
[FIREBASE_SETUP.md](FIREBASE_SETUP.md).

Keep private AI provider keys on the backend. Do not place them in Flutter code
or distribute them in an APK.

## Android beta release

Install Android Studio and the Android SDK, then run `flutter doctor` and
`flutter doctor --android-licenses`. Configure a private release keystore
before publishing. The Android application ID is `com.silentmaste.aidhd` and
the app label is `AiDHD`.

```bash
flutter clean
flutter pub get
flutter build apk --release
```

For Google Play, build an app bundle:

```bash
flutter build appbundle --release
```

Test notifications on a physical Android device, including permission,
restart, reboot, and a future date/time reminder.

---

## Adding Real AI Chat

Open `lib/screens/chat_screen.dart`. The `Future.delayed` block is marked with an `AI INTEGRATION POINT` comment — replace it with your API call.

Pass `context.read<AppProvider>().buildAiContext()` as the system prompt. It returns:

- User profile (id, name, age, gender)
- Initial ADHD likelihood screening result
- Latest daily assessment score + category
- Full history (mood logs + assessments, most recent first)
