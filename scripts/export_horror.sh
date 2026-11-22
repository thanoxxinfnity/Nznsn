#!/usr/bin/env bash
# Khilauna Nagar APK: sirf kaam aane wale assets ek staging copy mein rakhke export (poora repo 300MB+ hai).
# bash scripts/export_horror.sh   -> build/KhilaunaNagar.apk (debug-signed, arm64, landscape)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
STG=/tmp/claude-0/hc_export
rm -rf "$STG" && mkdir -p "$STG"
(cd "$ROOT/horror_city" && tar cf - --exclude=.godot --exclude=assets/props --exclude=assets/characters --exclude=assets/rigged_old --exclude=assets/rigged --exclude=assets/anims --exclude=tools .) | (cd "$STG" && tar xf -)
mkdir -p "$STG/assets/props" "$STG/assets/rigged" "$STG/assets/characters"
python3 - "$ROOT" "$STG" <<'PY'
import re, sys, glob, os, shutil
root, stg = sys.argv[1], sys.argv[2]
code = "".join(open(f, encoding="utf-8").read() for f in glob.glob(root + "/horror_city/game/*.gd"))
tokens = set(re.findall(r'"([A-Za-z0-9_%]+)"', code))
n = 0
for f in glob.glob(root + "/horror_city/assets/props/*.glb"):
    stem = os.path.basename(f)[:-4]
    ok = stem in tokens or any("%" in t and stem.startswith(t.split("%")[0]) for t in tokens)
    if ok:
        shutil.copy(f, stg + "/assets/props/"); n += 1
for f in ["assets/rigged/M01_Gudiya.glb", "assets/characters/M04_FPArmsFlashlight.glb"]:
    shutil.copy(root + "/horror_city/" + f, stg + "/" + f)
print("props copied:", n)
PY
cat > "$STG/export_presets.cfg" <<'CFG'
[preset.0]

name="Android"
platform="Android"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="KhilaunaNagar.apk"
patches=PackedStringArray()
encryption_include_filters=""
encryption_exclude_filters=""
seed=0
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

custom_template/debug=""
custom_template/release=""
gradle_build/use_gradle_build=false
gradle_build/export_format=0
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
version/code=1
version/name="0.1"
package/unique_name="com.nznsn.khilaunanagar"
package/name="Khilauna Nagar"
package/signed=true
screen/immersive_mode=true
screen/orientation=0
permissions/vibrate=true
CFG
cd "$STG"
godot --headless --path . --import >/dev/null 2>&1 || true
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 godot --headless --path . --export-debug "Android" "$STG/KhilaunaNagar.apk" 2>&1 | grep -E "ERROR|error|Exporting|Failed" | head -10 || true
mkdir -p "$ROOT/build"
cp "$STG/KhilaunaNagar.apk" "$ROOT/build/KhilaunaNagar.apk"
ls -la "$ROOT/build/KhilaunaNagar.apk"
