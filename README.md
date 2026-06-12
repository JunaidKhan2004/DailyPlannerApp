# Daily Planner App

A feature-rich Flutter productivity app for managing daily tasks, tracking habits, and staying focused.

## Features

- **Task Management** — Create, edit, and delete tasks with title, description, due date/time, and priority levels (low, medium, high)
- **Task Categories** — Organize tasks with labels: Personal, Work, Health, Study, Other (each with emoji + color)
- **Sub-tasks** — Break tasks into smaller checklist items with progress tracking
- **Calendar View** — Week/month calendar with event dots for days that have tasks
- **Home Screen** — Animated time-of-day backgrounds (starry night, clouds, sun rays, shooting stars) based on current hour
- **Search** — Full-text search across task titles and descriptions
- **Stats Screen** — Streak tracker, today/week/all-time completion rates, last 7 days bar chart
- **Pomodoro Timer** — Segmented ring timer with Focus / Short Break / Long Break phases and session tracking
- **Onboarding** — First-launch walkthrough
- **Settings** — App preferences and theme options
- **Offline-first** — All data stored locally with Hive CE; cloud sync via Appwrite (anonymous sessions)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| State Management | Riverpod |
| Local DB | Hive CE |
| Cloud Sync | Appwrite SDK v13 |
| Navigation | go_router |
| UI | Custom Surface3D widget, Iconsax icons |

## Architecture

Clean Architecture with three layers:
- **Domain** — entities, repository interfaces
- **Data** — Hive adapters, Appwrite sources, repository implementations
- **Presentation** — Riverpod providers, screens, widgets

## Getting Started

```bash
flutter pub get
flutter run
```

Requires Flutter 3.10+ and Dart 3.0+.
