# Native APK Builder for Expo & React Native

A lightweight, one-command shell script that builds a standalone, installable `.apk` file directly on your local machine using native Gradle.

**No Expo EAS cloud queues. No Expo account required. Zero cloud dependencies.**

---

## Why Use This?

When building React Native or Expo apps, you often just want a `.apk` file to:
- Test directly on a physical Android device.
- Send a quick preview to a client, tester, or teammate via WhatsApp, Telegram, or Google Drive.
- Avoid waiting 10–30 minutes in free EAS cloud queues.

This script runs the native Android Gradle build locally and outputs a ready-to-install `.apk` in seconds.

---

## Important Things to Know Before Use

### 1. Prerequisites
Make sure your machine has the standard Android development environment configured:
- **Node.js**: v18 or newer.
- **Java JDK**: JDK 17 (recommended for React Native 0.73+ and Expo SDK 50+).
- **Android SDK**: `platform-tools` and `build-tools` installed.
  - The script automatically checks `$HOME/Library/Android/sdk` (macOS) and `$HOME/Android/Sdk` (Linux).
  - If installed elsewhere, export your path:
    ```bash
    export ANDROID_HOME="/path/to/your/android/sdk"
    ```

### 2. Phone Installation (Google Play Protect)
Because this script produces a direct installation APK signed with the standard Android debug keystore:
- When installing on a physical Android device, Google Play Protect may show:
  > **"Unrecognized app"** or **"Blocked by Play Protect"**
- Simply tap **"More details"** and then **"Install anyway"**.
- This is normal for all direct `.apk` files installed outside the Google Play Store.

### 3. Output Location
- Output APKs are automatically saved in the `./dist/` directory inside your project:
  ```text
  your-project/
  └── dist/
      └── YourApp-v1.0.0.apk
  ```
- You can override the output location using the `DEST_DIR` environment variable.

---

## Quick Start

### Method 1: Place inside your project

1. Copy `build-apk.sh` into the root of your Expo or React Native project.
2. Make it executable and run it:
   ```bash
   chmod +x build-apk.sh
   ./build-apk.sh
   ```

### Method 2: Run from anywhere

You can keep `build-apk.sh` in one central folder and run it from any project directory:
```bash
/path/to/build-apk.sh
```

### Method 3: Custom Output Directory

To save the APK to a specific directory (for example, your Desktop):
```bash
DEST_DIR=~/Desktop ./build-apk.sh
```

### Method 4: Run directly with curl (No manual download needed)

Run this one-liner from the root of any Expo or React Native project:
```bash
curl -sSL https://raw.githubusercontent.com/myat-kyaw-thu/build-apk/main/build-apk.sh | bash
```

---

## What the Script Does Automatically

1. **Detects Environment**: Checks for `ANDROID_HOME` and required Android SDK tools across macOS and Linux.
2. **Extracts App Info**: Dynamically reads your app name and version from `app.json` or `package.json`.
3. **Generates Native Files**: If your project doesn't have an `android/` directory yet, it runs `npx expo prebuild --platform android --no-install`.
4. **Builds Signed APK**: Executes `./gradlew assembleDebug`, guaranteeing a signed APK that installs on any Android phone.
5. **Collects Output**: Moves the final APK to `./dist/<AppName>-v<Version>.apk`.
6. **Cleans Temp Files**: Cleans up intermediate build output without deleting the Gradle cache (ensuring subsequent builds remain fast).

---

## Troubleshooting

- **`Android SDK directory not found`**:
  Ensure Android Studio and the Android SDK command-line tools are installed. Set `ANDROID_HOME` in your `~/.zshrc` or `~/.bashrc`.
- **Java version mismatch**:
  Run `java -version`. Ensure you are using JDK 17. If you have multiple Java versions installed, set `JAVA_HOME`.
- **First build takes longer**:
  The very first time you run the script, Gradle will download necessary dependencies and Android wrappers. All future builds will be much faster.

---

## License

MIT License. Free for personal and commercial use.
