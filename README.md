# StreakBase

[![License](https://img.shields.io/github/license/mrnithesh/streakbase)](LICENSE)
[![Build Status](https://img.shields.io/github/actions/workflow/status/mrnithesh/streakbase/flutter.yml)](https://github.com/mrnithesh/streakbase/actions)

An open-source, offline-first habit tracker app that helps you build and maintain streaks.

## Features

- 📱 Fully offline functionality
- 📊 GitHub-style heatmap visualization
- 🔔 Local notifications for reminders
- 💾 Data backup and restore
- 📤 Import/Export functionality
- 🏷️ Habit categorization
- 📝 Notes and tracking

## Getting Started

1. Clone the repository
```bash
git clone https://github.com/mrnithesh/streakbase.git
cd streakbase
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Building from Source

1. Generate JSON serialization code:
```bash
flutter pub run build_runner build
```

2. Build the app:
```bash
flutter build apk  # For Android
flutter build ios  # For iOS
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.
