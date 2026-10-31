#!/usr/bin/env bash

# ==============================================================================
# Universal Native Gradle APK Builder (Optimized)
# Zero EAS / Zero Cloud dependencies
# Generates an installable APK in the project's relative dist/ folder
# ==============================================================================

set -e

CURRENT_DIR="$(pwd)"
DEST_DIR="${DEST_DIR:-$CURRENT_DIR/dist}"
mkdir -p "$DEST_DIR"

# Target architecture: defaults to arm64-v8a (standard for 99% of Android phones)
# Use `ARCH=all ./build-apk.sh` to build for all CPU architectures if needed.
ARCH="${ARCH:-arm64-v8a}"

# Enforce shared global Gradle cache across all projects
# Prevents re-downloading react-android, hermes-android, and core AARs per project.
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"

# 1. Cross-platform Android SDK Detection
if [ -z "$ANDROID_HOME" ]; then
  if [ -d "$HOME/Library/Android/sdk" ]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
  elif [ -d "$HOME/Android/Sdk" ]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
  fi
fi

if [ -n "$ANDROID_HOME" ]; then
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
  export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
else
  echo "[WARN] Android SDK directory not found in default locations."
  echo "[WARN] Ensure ANDROID_HOME is set in your environment if the build fails."
fi

# 2. Validate Project Root
if [ ! -f "$CURRENT_DIR/package.json" ]; then
  echo "[ERROR] package.json not found in current directory."
  echo "[ERROR] Please run this script from the root of your project."
  exit 1
fi

# 3. Extract Project Metadata
METADATA=$(node -e '
  let name = "";
  let version = "";
  try {
    const app = require("./app.json");
    if (app && app.expo) {
      name = (app.expo.name || "").replace(/[^a-zA-Z0-9_-]/g, "");
      version = app.expo.version || "";
    }
  } catch (_) {}

  try {
    const pkg = require("./package.json");
    if (!name) name = (pkg.name || "App").replace(/[^a-zA-Z0-9_-]/g, "");
    if (!version) version = pkg.version || "1.0.0";
  } catch (_) {}

  console.log((name || "App") + "\t" + (version || "1.0.0"));
')

PROJECT_NAME=$(echo "$METADATA" | cut -f1)
PROJECT_VERSION=$(echo "$METADATA" | cut -f2)

APK_FILENAME="${PROJECT_NAME}-v${PROJECT_VERSION}.apk"
FINAL_APK_PATH="${DEST_DIR}/${APK_FILENAME}"

echo "=========================================================="
echo "Native Gradle APK Builder (Optimized)"
echo "=========================================================="
echo "Project:      ${PROJECT_NAME} (v${PROJECT_VERSION})"
echo "Working Dir:  ${CURRENT_DIR}"
echo "Output Path:  ${FINAL_APK_PATH}"
echo "Architecture: ${ARCH}"
echo "=========================================================="
echo ""

# 4. Generate native Android folder if not already present
if [ ! -d "$CURRENT_DIR/android" ] || [ ! -f "$CURRENT_DIR/android/gradlew" ]; then
  echo "[INFO] Android native folder missing. Generating via expo prebuild..."
  npx expo prebuild --platform android --no-install
fi

# 5. Build APK natively using Gradle
echo "[INFO] Building signed APK via Gradle..."
echo "[NOTE] First-time build downloads dependencies from Maven. Do not interrupt."

cd "$CURRENT_DIR/android"
chmod +x ./gradlew

# Build flags: parallel compilation + build cache enabled + exclude tests/lint
GRADLE_ARGS=("assembleDebug" "--parallel" "--build-cache" "-x" "lint" "-x" "test")

# Target specific architecture to cut compilation time by ~70%
if [ "$ARCH" != "all" ] && [ "$ARCH" != "universal" ]; then
  GRADLE_ARGS+=("-PreactNativeArchitectures=${ARCH}")
fi

./gradlew "${GRADLE_ARGS[@]}"

cd "$CURRENT_DIR"

# 6. Locate the generated signed APK
GENERATED_APK=$(find "$CURRENT_DIR/android/app/build/outputs/apk" -name "*debug.apk" -type f | head -n 1)

if [ -z "$GENERATED_APK" ]; then
  echo "[ERROR] Could not locate generated APK file."
  exit 1
fi

echo "[INFO] Found APK at: ${GENERATED_APK}"
echo "[INFO] Copying APK to: ${FINAL_APK_PATH}"
cp "$GENERATED_APK" "$FINAL_APK_PATH"

FILE_SIZE=$(du -h "$FINAL_APK_PATH" | awk '{print $1}')

# 7. Cleanup intermediate build artifacts to keep project folder tiny (~1.2 GB reclaimed)
echo "[INFO] Cleaning temporary compiler intermediates and C++ build caches..."
rm -rf "$CURRENT_DIR/android/app/build"
rm -rf "$CURRENT_DIR/android/app/.cxx"

echo ""
echo "=========================================================="
echo "[SUCCESS] Standalone APK ready to install!"
echo "Location:  ${FINAL_APK_PATH}"
echo "File Size: ${FILE_SIZE}"
echo "=========================================================="
