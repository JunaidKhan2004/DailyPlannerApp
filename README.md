# Priora

A production-quality Flutter productivity app for managing daily tasks, staying focused with Pomodoro, and syncing data across devices via Firebase.

## Features

- **Task Management** — Create, edit, and delete tasks with title, description, due date/time, and priority levels (Low, Medium, High)
- **Task Categories** — Organize tasks with labels: Personal, Work, Health, Study, Other (each with emoji + color)
- **Sub-tasks** — Break tasks into smaller checklist items with progress tracking
- **Calendar View** — Week/month calendar with event dots for days that have tasks
- **Home Screen** — Animated time-of-day backgrounds (starry night, clouds, sun rays, shooting stars) with live clock
- **Search** — Full-text search across task titles and descriptions with priority/status filters
- **Stats Screen** — Streak tracker, today/week/all-time completion rates, last 7 days bar chart
- **Pomodoro Timer** — Segmented ring timer with Focus / Short Break / Long Break phases and session tracking
- **Google Sign-In** — Sign in with Google to sync tasks across all your devices
- **Two-Way Sync** — Bidirectional Firestore ↔ Hive sync on login (last-write-wins merge)
- **Offline-first** — All data stored locally in Hive; works fully without internet
- **Onboarding** — First-launch walkthrough
- **Settings** — Light / Dark / System theme toggle
- **Crashlytics** — Automatic crash reporting via Firebase Crashlytics

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart 3.8+) |
| State Management | Riverpod 2.6 |
| Local DB | Hive CE (offline source of truth) |
| Cloud Sync | Firebase Firestore |
| Authentication | Firebase Auth + Google Sign-In |
| Crash Reporting | Firebase Crashlytics |
| Navigation | GoRouter 14 |
| Notifications | flutter_local_notifications |
| UI | Material 3, Custom Surface3D widget, Iconsax icons, Google Fonts (Inter + Orbitron) |

## Architecture

Clean Architecture with three layers:

```
Presentation  →  Domain  →  Data  →  Hive (local)
                                  →  Firebase Firestore (cloud)
```

- **Domain** — `TaskRepository` interface (no framework dependencies)
- **Data** — `TaskLocalSource` (Hive), `TaskRepositoryImpl`, `FirestoreService`
- **Presentation** — Riverpod providers, screens, widgets

### Offline-First Rule
Hive is always the source of truth. Firestore sync is fire-and-forget — failures never block local operations.

### Sync Flow

```
Login  →  syncOnLogin()  →  Firestore ↔ Hive two-way merge
Task CRUD  →  Hive (instant)  →  Firestore (background)
Logout  →  Hive.clear()  →  Firebase sign out
```

## Project Structure

```
lib/
├── main.dart                    # Bootstrap
├── firebase_options.dart        # Firebase config
├── app/                         # Router + Theme
├── core/
│   ├── constants/
│   ├── providers/               # authStateProvider, authSyncProvider
│   ├── services/                # FirebaseAuthService, FirestoreService, NotificationService
│   └── widgets/                 # Surface3D, AnimatedBackground, AppDrawer
└── features/
    ├── auth/                    # Google Sign-In screen
    ├── onboarding/
    ├── tasks/                   # Home, Add/Edit, Search, TaskCard
    ├── stats/
    ├── pomodoro/
    └── settings/
```

## Getting Started

### Prerequisites
- Flutter 3.10+
- Dart 3.8+
- Android min SDK 23

### Setup

```bash
# Install dependencies
flutter pub get

# Run
flutter run
```

### Firebase Setup (already configured)
- Project: `priora-app-b7015`
- `google-services.json` placed in `android/app/`
- Services enabled: Auth (Google), Firestore, Crashlytics, Analytics

## Android

- **Min SDK:** 23 (Android 6.0)
- **Package:** `com.planner.priora`
- **Build system:** Gradle KTS

## Data & Privacy

- Tasks are stored locally on device (Hive)
- If signed in, tasks are synced to Firebase Firestore under the user's account (`users/{uid}/tasks/`)
- Signing out clears local data from the device
- Guest mode (no sign-in) keeps data local only — no cloud backup
