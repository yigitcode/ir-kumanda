#!/usr/bin/env bash
# Builds IR Köprü without Gradle: aapt2 -> javac -> d8 -> zipalign -> apksigner.
set -euo pipefail
cd "$(dirname "$0")"

SDK="${ANDROID_HOME:-$LOCALAPPDATA/Android/Sdk}"
BT="$SDK/build-tools/36.0.0"
PLATFORM="$SDK/platforms/android-36/android.jar"
KEYSTORE="${KEYSTORE:-$HOME/.android/debug.keystore}"
VERSION_CODE=3
VERSION_NAME=0.3

rm -rf build
mkdir -p build/classes build/dex out

"$BT/aapt2.exe" link -o build/base.apk -I "$PLATFORM" \
  --manifest AndroidManifest.xml -A assets \
  --min-sdk-version 23 --target-sdk-version 34 \
  --version-code "$VERSION_CODE" --version-name "$VERSION_NAME"

javac --release 11 -encoding UTF-8 -Xlint:-options -cp "$PLATFORM" -d build/classes $(find src -name '*.java')

"$BT/d8.bat" --release --min-api 23 --lib "$PLATFORM" --output build/dex $(find build/classes -name '*.class')

python -I tools/pack_apk.py build/base.apk build/dex/classes.dex build/unsigned.apk
"$BT/zipalign.exe" -p -f 4 build/unsigned.apk build/aligned.apk
"$BT/apksigner.bat" sign --ks "$KEYSTORE" --ks-pass pass:android --key-pass pass:android \
  --ks-key-alias androiddebugkey --out out/ir-kopru.apk build/aligned.apk
"$BT/apksigner.bat" verify out/ir-kopru.apk
# Same panel, served from the PC so it can change without reinstalling the APK.
cp assets/panel.html out/panel.html
ls -l out/ir-kopru.apk
