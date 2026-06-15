# Priora — Daily Planner App

## Project Overview

**App Name:** Priora (package: `com.planner.priora`)  
**Version:** 0.1.0  
**Platform:** Android (iOS structure present, not configured)  
**Architecture:** Offline-first Clean Architecture + MVVM  
**State Management:** Riverpod 2.6.1  
**Min SDK:** Android 23 (Android 6.0)

---

## Tech Stack

| Concern | Library | Version |
|---------|---------|---------|
| State management | flutter_riverpod | 2.6.1 |
| Local database | hive_ce + hive_ce_flutter | 2.10.1 / 2.2.0 |
| Routing | go_router | 14.8.1 |
| Cloud sync | Appwrite | 13.0.0 |
| Auth | Firebase Auth + Google Sign-In | 5.5.0 / 6.2.2 |
| Firestore | cloud_firestore | 5.6.5 |
| Crashlytics | firebase_crashlytics | 4.3.5 |
| Analytics | firebase_analytics | 11.4.5 |
| Notifications | flutter_local_notifications | 18.0.0 |
| Calendar UI | table_calendar | 3.1.3 |
| Fonts | google_fonts (Inter, Orbitron) | 6.2.1 |
| Icons | iconsax_flutter | 1.0.1 |
| Persistence | shared_preferences | 2.3.2 |
| Utilities | uuid, intl, connectivity_plus | latest |

---

## Project Structure

```
lib/
├── main.dart                          # Bootstrap — Hive, Firebase, Appwrite, Notifications
├── firebase_options.dart              # Firebase config (Android only)
├── app/
│   ├── app.dart                       # Root MaterialApp.router
│   ├── router/app_router.dart         # GoRouter — routes + redirects
│   └── theme/app_theme.dart           # Design system — colors, typography, components
├── core/
│   ├── constants/app_constants.dart   # Box names, app-wide constants
│   ├── utils/date_utils.dart          # Date helpers (dateOnly, isSameDay, formatters)
│   ├── providers/auth_provider.dart   # authStateProvider, currentUserProvider
│   ├── services/
│   │   ├── firebase_auth_service.dart # Google Sign-In / Sign-Out
│   │   ├── notification_service.dart  # Local notifications + scheduling
│   │   └── appwrite_service.dart      # Appwrite cloud sync
│   └── widgets/
│       ├── surface_3d.dart            # Reusable 3D-effect button/card
│       ├── animated_background.dart   # 6 floating gradient orbs
│       ├── confirm_dialog.dart        # Reusable confirmation dialog
│       └── app_drawer.dart            # Navigation drawer
└── features/
    ├── auth/
    │   └── screens/login_screen.dart  # Google Sign-In UI
    ├── onboarding/
    │   └── screens/onboarding_screen.dart
    ├── tasks/
    │   ├── data/
    │   │   ├── models/task_model.dart         # TaskModel (Hive), SubTask, enums
    │   │   ├── sources/task_local_source.dart # Hive CRUD wrapper
    │   │   └── repositories/task_repository_impl.dart
    │   ├── domain/
    │   │   └── repositories/task_repository.dart  # Interface
    │   └── presentation/
    │       ├── providers/task_providers.dart  # All task Riverpod providers
    │       ├── screens/
    │       │   ├── home_screen.dart           # Calendar + task list
    │       │   ├── add_edit_task_screen.dart  # Task CRUD form
    │       │   └── search_screen.dart         # Full-text search
    │       └── widgets/
    │           ├── task_card.dart             # Task list item
    │           └── live_clock_card.dart       # Orbitron real-time clock
    ├── settings/
    │   ├── providers/settings_providers.dart  # ThemeModeNotifier
    │   └── screens/settings_screen.dart
    ├── stats/
    │   └── screens/stats_screen.dart          # Streak, completion, bar chart
    └── pomodoro/
        └── screens/pomodoro_screen.dart       # Timer + segmented ring
```

---

## Architecture

### Layers

```
Presentation  →  Domain  →  Data  →  Hive (local)
                                  →  Appwrite (cloud, optional)
                                  →  Firebase Firestore (cloud, optional)
```

**Domain** (`task_repository.dart`) — interface only, no framework deps  
**Data** (`task_local_source.dart`, `task_repository_impl.dart`) — Hive wrapper + cloud sync  
**Presentation** (`task_providers.dart` + screens) — Riverpod reactive state

### Offline-First Rule
Hive is **always** the source of truth. Cloud sync (Appwrite/Firebase) is fire-and-forget — failures are silent and never block local operations.

### Hive Box Watch Pattern
```dart
Stream<List<TaskModel>> watchAll() async* {
  yield _box.values.toList();         // emit immediately
  yield* _box.watch().map((_) => _box.values.toList());  // then on change
}
```

---

## Data Model

### TaskModel (Hive typeId=0)

| Field | Type | Notes |
|-------|------|-------|
| id | String | UUID v4 |
| title | String | required |
| description | String | optional |
| dueDate | DateTime | date-only (time zeroed) |
| dueTimeMinutes | int? | minutes since midnight |
| priority | TaskPriority | low / medium / high |
| category | TaskCategory | personal / work / health / study / other |
| isCompleted | bool | |
| isSynced | bool | cloud sync flag |
| subtasks | List\<SubTask\> | each has id, title, isDone |
| createdAt / updatedAt | DateTime | |

### SubTask
```dart
class SubTask { String id, title; bool isDone; }
```

### Enums
```dart
enum TaskPriority { low, medium, high }
enum TaskCategory { personal, work, health, study, other }
// TaskCategory has .label and .emoji getters
```

---

## Riverpod Providers

### Task Providers (`task_providers.dart`)

| Provider | Type | Purpose |
|----------|------|---------|
| `taskLocalSourceProvider` | Provider | Singleton TaskLocalSource |
| `taskRepositoryProvider` | Provider | Singleton TaskRepository |
| `tasksStreamProvider` | StreamProvider\<List\<TaskModel\>\> | Live Hive stream |
| `selectedDateProvider` | StateProvider\<DateTime\> | Calendar selection |
| `calendarFormatProvider` | StateProvider\<CalendarFormat\> | Week/month toggle |
| `tasksForSelectedDateProvider` | Provider\<List\<TaskModel\>\> | Filtered by date, sorted |
| `searchQueryProvider` | StateProvider\<String\> | Search input |
| `filteredTasksProvider` | Provider\<List\<TaskModel\>\> | Search results |
| `taskCountByDayProvider` | Provider\<Map\<DateTime,int\>\> | Calendar event dots |
| `appStatsProvider` | Provider\<AppStats\> | Streak, rates, last 7 days |

### Auth Providers (`auth_provider.dart`)

| Provider | Type | Purpose |
|----------|------|---------|
| `authStateProvider` | StreamProvider\<User?\> | Firebase auth stream |
| `currentUserProvider` | Provider\<User?\> | Current user (nullable) |

### Settings Providers (`settings_providers.dart`)

| Provider | Type | Purpose |
|----------|------|---------|
| `themeModeProvider` | StateNotifierProvider\<ThemeModeNotifier, ThemeMode\> | Persisted theme |
| `onboardingCompleteProvider` | FutureProvider\<bool\> | Reads SharedPreferences |

---

## Routes

Defined in `AppRoutes` constants:

| Constant | Path | Screen |
|----------|------|--------|
| `login` | `/login` | LoginScreen |
| `onboarding` | `/onboarding` | OnboardingScreen |
| `home` | `/` | HomeScreen |
| `newTask` | `/task/new` | AddEditTaskScreen |
| `editTask` | `/task/edit` | AddEditTaskScreen |
| `search` | `/search` | SearchScreen |
| `settings` | `/settings` | SettingsScreen |
| `stats` | `/stats` | StatsScreen |
| `pomodoro` | `/pomodoro` | PomodoroScreen |

### Redirect Logic
1. Onboarding incomplete → `/onboarding`
2. Logged-in user on `/login` → `/`
3. Guest mode allowed — no forced auth redirect

---

## Design System (`app_theme.dart`)

### Color Palette
```dart
deepPlum  = Color(0xFF574964)   // primary
mauve     = Color(0xFF9F8383)   // secondary
dustyPink = Color(0xFFC8AAAA)   // tertiary
peach     = Color(0xFFFFDAB3)   // accent
```

### Priority Colors
```dart
priorityHigh   = Color(0xFFC06A6A)  // red
priorityMedium = Color(0xFFD99A5B)  // orange
priorityLow    = Color(0xFF7E9C7E)  // green
```

### Category Colors
personal=blue, work=indigo, health=green, study=orange, other=grey

### Typography
- **Body/UI:** Inter (google_fonts)
- **Clock/Monospace:** Orbitron (google_fonts) — used in LiveClockCard + Pomodoro timer

### Surface3D Widget
Core reusable component. Creates a hard-edged 3D press effect:
```dart
Surface3D(
  color: AppTheme.deepPlum,
  edgeColor: Surface3D.darken(AppTheme.deepPlum, 0.4),
  depth: 7,
  borderRadius: 20,
  onTap: () {},
  child: ...,
)
```
- `Surface3D.darken(color, amount)` — static helper, lerps to black

---

## Services

### FirebaseAuthService
```dart
FirebaseAuthService.signInWithGoogle()  // returns User? (null = cancelled)
FirebaseAuthService.signOut()           // signs out of both Firebase + Google
FirebaseAuthService.currentUser         // User?
FirebaseAuthService.authStateChanges    // Stream<User?>
```

### NotificationService
```dart
NotificationService.init()
NotificationService.requestPermissions()
NotificationService.scheduleTaskReminder(task)   // TZ-aware, skips past times
NotificationService.cancelTaskReminder(taskId)
```
- Channel: `task_reminders` (high priority)
- Android exact alarm: `exactAllowWhileIdle`
- Notification ID = hash of task UUID (consistent across reschedules)

### AppwriteService
```dart
AppwriteService.init()
AppwriteService.upsertTask(task)
AppwriteService.deleteTask(taskId)
AppwriteService.fetchAll()     // returns List<TaskModel>
```
- Config in `AppwriteConfig` class — fill projectId, databaseId, endpoint
- All methods silent-fail — never throw

---

## Firebase Configuration

### `firebase_options.dart`
Auto-generated from `google-services.json`. Do not edit manually.
- Project ID: `priora-app-b7015`
- Android app ID: `1:260302773984:android:8a830438168cf95125ba85`

### Crashlytics
Configured in `main.dart`:
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (e, s) {
  FirebaseCrashlytics.instance.recordError(e, s, fatal: true);
  return true;
};
```

---

## Android Build

**File:** `android/app/build.gradle.kts`

```
minSdk       = 23
compileSdk   = flutter.compileSdkVersion
jvmTarget    = 11
desugaring   = enabled
```

**Plugins applied:**
- `com.google.gms.google-services` (4.4.2)
- `com.google.firebase.crashlytics` (3.0.3)

---

## Stats Calculations (`appStatsProvider`)

| Stat | Calculation |
|------|-------------|
| Today | Tasks where dueDate == today |
| Week | Tasks where dueDate in Mon–Sun of current week |
| Streak | Consecutive days back from today with ≥1 completed task |
| Last 7 days | Per-day total/done for trailing 7 days |
| All-time | All tasks ever in Hive box |

---

## Key Patterns & Conventions

### Date Storage
- `dueDate` stored as midnight UTC (date-only, time zeroed via `AppDateUtils.dateOnly()`)
- `dueTimeMinutes` stored separately as `int` (minutes since midnight)
- Never mix date+time in a single DateTime field

### Model Updates
Always use `copyWith()` — never mutate a TaskModel directly:
```dart
final updated = task.copyWith(isCompleted: true, updatedAt: DateTime.now());
await repo.updateTask(updated);
```

### Navigation
Use `context.go()` to replace stack, `context.push()` to add to stack:
```dart
context.go(AppRoutes.home);           // replace
context.push(AppRoutes.settings);     // push
```

### Consumer Widgets
Screens use `ConsumerWidget` (stateless) or `ConsumerStatefulWidget` (stateful):
```dart
class MyScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksForSelectedDateProvider);
  }
}
```

---

## Setup & Configuration Checklist

### Firebase (already done)
- [x] Firebase project created (`priora-app-b7015`)
- [x] `google-services.json` placed in `android/app/`
- [x] SHA-1 fingerprint added to Firebase Console
- [x] Google Sign-In enabled in Firebase Auth
- [x] `firebase_options.dart` generated
- [x] Crashlytics configured in `main.dart`

### Appwrite (optional cloud sync)
- [ ] Create Appwrite project at cloud.appwrite.io
- [ ] Create database + `tasks` collection
- [ ] Update `AppwriteConfig` in `appwrite_service.dart`:
  ```dart
  static const projectId = 'YOUR_PROJECT_ID';
  static const databaseId = 'YOUR_DB_ID';
  static const tasksCollectionId = 'YOUR_COLLECTION_ID';
  ```

### Release Build
- [ ] Create release keystore
- [ ] Update `build.gradle.kts` with signing config
- [ ] Set `versionCode` / `versionName` in `pubspec.yaml`
- [ ] Test with `flutter build apk --release`

---

## Running the App

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release

# Analyze code
flutter analyze

# Clean build
flutter clean && flutter pub get
```

---

## Common Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `PlatformException channel-error firebase_core` | minSdk too low | Set `minSdk = 23` in `build.gradle.kts` |
| `oauth_client empty` in google-services.json | SHA-1 not added | Add SHA-1 in Firebase Console → re-download json |
| `DefaultFirebaseOptions not found` | Missing firebase_options.dart | Run `flutterfire configure` or create manually |
| Hive adapter not found | Adapter not registered | Register in `main.dart` before `openBox()` |
| Notifications not firing | Past time / permissions denied | Check `dueTimeMinutes` > current time + check permissions |
