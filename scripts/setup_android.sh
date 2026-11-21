#!/usr/bin/env bash
# APK banane ke औज़ार: Godot export templates + Android SDK + debug keystore. Idempotent.
set -euo pipefail
GV=4.7.2; T=/opt/tools; SDK=$T/android-sdk
mkdir -p $T $SDK
TPL=$HOME/.local/share/godot/export_templates/${GV}.stable
if [ ! -f "$TPL/android_debug.apk" ]; then
  echo "[1/4] export templates"; curl -sSfL -o $T/templates.tpz "https://downloads.godotengine.org/?version=${GV}&flavor=stable&slug=export_templates.tpz&platform=templates"
  d=$(mktemp -d); python3 -I -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" $T/templates.tpz $d
  mkdir -p "$TPL"; cp -r $d/templates/* "$TPL"/; rm -rf $d $T/templates.tpz
fi
if [ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "[2/4] android cmdline-tools"; curl -sSfL -o $T/cmdtools.zip "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
  d=$(mktemp -d); python3 -I -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" $T/cmdtools.zip $d
  mkdir -p $SDK/cmdline-tools; mv $d/cmdline-tools $SDK/cmdline-tools/latest; chmod -R +x $SDK/cmdline-tools/latest/bin; rm -f $T/cmdtools.zip
fi
echo "[3/4] sdk packages"
yes | $SDK/cmdline-tools/latest/bin/sdkmanager --sdk_root=$SDK --licenses >/dev/null 2>&1 || true
$SDK/cmdline-tools/latest/bin/sdkmanager --sdk_root=$SDK "platform-tools" "build-tools;34.0.0" "build-tools;35.0.1" "platforms;android-34" "platforms;android-35" 2>&1 | tail -3
KS=$T/debug.keystore
if [ ! -f $KS ]; then
  echo "[4/4] debug keystore"
  keytool -genkeypair -v -keystore $KS -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 9999 -storepass android -keypass android -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
fi
echo "ANDROID SETUP DONE"
