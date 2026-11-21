#!/usr/bin/env bash
# Naye session mein Godot + Blender dobara lagane ke liye:  bash scripts/setup_env.sh
set -euo pipefail
GODOT_VER=4.7.2; BLENDER_VER=5.3.0; T=/opt/tools; mkdir -p $T
if ! command -v godot >/dev/null; then
  d=$(mktemp -d); curl -sSfL -o $d/g.zip "https://downloads.godotengine.org/?version=${GODOT_VER}&flavor=stable&slug=linux.x86_64.zip&platform=linux.64"
  python3 -I -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" $d/g.zip $T/godot
  chmod +x $T/godot/Godot*; ln -sf $T/godot/Godot_v${GODOT_VER}-stable_linux.x86_64 /usr/local/bin/godot
fi
if ! command -v blender >/dev/null; then
  d=$(mktemp -d); b=https://download.blender.org/release/Blender${BLENDER_VER%.*}
  curl -sSfL -o $d/b.tar.xz $b/blender-${BLENDER_VER}-linux-x64.tar.xz
  curl -sSfL $b/blender-${BLENDER_VER}.sha256 | grep linux-x64 | sed "s#blender-.*#$d/b.tar.xz#" | sha256sum -c -
  mkdir -p $T/blender; tar -xf $d/b.tar.xz -C $T/blender --strip-components=1; ln -sf $T/blender/blender /usr/local/bin/blender
fi
godot --headless --version; blender -b --version | head -1
echo "Ab .env aur config/agents.json banao (templates: .env.example, config/agents.example.json)"
