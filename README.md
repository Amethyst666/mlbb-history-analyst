# MLBB Analyst

Advanced Mobile Legends: Bang Bang match history analyzer and statistics tracker.

## Features

- **Match History Parsing:** Reads binary match files directly from the game's data folder.
- **Detailed Statistics:** Calculates KDA, Gold, Damage, Healing, and more.
- **Player Profiles:** Tracks player performance across matches.
- **Asset Gallery:** View heroes, items, and spells data.
- **Multi-Language Support:** English and Russian.
- **Dark Mode:** Modern UI.

## Installation & Setup

### Access to Match History (Android 11+)

Due to Android's Scoped Storage restrictions, accessing the `Android/data` folder requires specific permissions. This app supports two methods:

#### 1. SAF (Storage Access Framework) - Recommended
This is the official Android method, but it requires manual folder selection.

1.  Go to **Settings** -> **File Access Method**.
2.  Select **SAF (System Picker)**.
3.  Click **Select SAF Folder**.
4.  Navigate to `Android > data > com.mobile.legends > files > dragon2017 > `FightHistory`.
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
2.  Tap the **+** button on the main screen to import recent matches.
3.  View match details and player statistics.

## Development

This project is built with Flutter.

```bash
flutter pub get
flutter run
```

### Dependencies
- `sqflite`: Local database.
- `permission_handler`: Permission management.
- `file_picker`: File selection.
- `rikka.shizuku`: Shizuku integration (Android).

## License

MIT
