# MLBB Analyst

Advanced Mobile Legends: Bang Bang match history analyzer and statistics tracker.

## Features

- **Match History Parsing:** Reads binary match files (`FightHistory`) directly from game directories. Supports 5v5 (Classic & Ranked) modes and automatically ignores non-5v5 modes.
- **Detailed Statistics:** Calculates KDA, Gold, Damage (Dealt, Taken, Tower/Push), Healing, and CC Duration per match.
- **Lane & Role Breakdown:** Categorized by Lanes (EXP, Mid, Roam, Jungle, Gold) with localized names and pie chart breakdown.
- **Global Server Stats:** Displays server winrate, pickrate, and banrate alongside personal performance.
- **Teammates & Player Profiles:** Track teammate synergy, wins, losses, alias management, and custom notes.
- **Database Maintenance:** One-tap cleanup of broken or non-5v5 matches.
- **Asset Gallery:** View heroes, items, and spells data.
- **Multi-Language Support:** English and Russian localization.
- **Dark Mode:** Modern UI.

## Installation & Setup

### Access to Match History (Android 11+)

Due to Android's Scoped Storage restrictions, accessing the `Android/data` folder requires specific permissions. This app supports two methods:

#### 1. SAF (Storage Access Framework) - Recommended
This is the official Android method, but it requires manual folder selection.

1.  Go to **Settings** -> **File Access Method**.
2.  Select **SAF (System Picker)**.
3.  Click **Select SAF Folder**.
4.  Navigate to `Android > data > com.mobile.legends > files > dragon2017 > FightHistory`.
    *   For AppGallery version, the folder is `com.mobilelegends.hwag`.
5.  Click **"Use this folder"** at the bottom of the screen.

*Note: On some devices (e.g., Xiaomi, Samsung Android 13/14), the system picker might restrict selection of the `Android/data` folder. In this case, use the Shizuku method.*

#### 2. Shizuku (Advanced)
This method uses ADB permissions to access files directly, bypassing system picker restrictions.

1.  Install the **Shizuku** app from the Play Store or GitHub.
2.  Start Shizuku (via Wireless Debugging or Root).
3.  In **MLBB Analyst**, go to **Settings**.
4.  Select **Shizuku (ADB)** as the access method.
5.  Click **Request Shizuku Access** and allow permission in the Shizuku dialog.

## Usage

1.  Open the app.
2.  Tap the **+** button on the main screen to import recent 5v5 matches.
3.  View match details, hero statistics, lane performance, and teammate profiles.

## Development

This project is built with Flutter.

```bash
flutter pub get
flutter run
```

### Dependencies
- `sqflite`: Local database storage.
- `permission_handler`: Permission management.
- `file_picker`: File selection.
- `http`: Fetching global server statistics.
- `shared_preferences`: User settings persistence.

## License

MIT

