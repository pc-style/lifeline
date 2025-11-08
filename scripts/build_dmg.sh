#!/usr/bin/env bash

# builds macOS dmg for LifeLine (ish)

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

draw_banner() {
  printf "============================================\n"
  printf "  LifeLine :: dmg kitchen\n"
  printf "============================================\n"
}

die() {
  echo "fatal: $1" >&2
  exit 1
}

need_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    die "missing $cmd $hint"
  fi
}

ensure_uv() {
  if command -v uv >/dev/null 2>&1; then
    return
  fi
  printf "installing uv (bo tak szybciej)\n"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
}

ensure_createdmg() {
  if command -v create-dmg >/dev/null 2>&1; then
    return
  fi
  printf "installing create-dmg via npm (wymaga node)\n"
  if ! command -v npm >/dev/null 2>&1; then
    printf "brak npm - zainstaluj node first (brew install node?)\n"
    exit 1
  fi
  npm install -g create-dmg || {
    printf "create-dmg install fail, sorry\n"
    exit 1
  }
}

convert_icon() {
  local png_icon="$1"
  local icns_output="$2"
  
  if [ ! -f "$png_icon" ]; then
    printf "warning: icon not found at %s\n" "$png_icon"
    return 1
  fi
  
  printf "converting icon to .icns format...\n"
  
  # create temporary iconset directory
  local iconset_dir="build/LifeLine.iconset"
  rm -rf "$iconset_dir"
  mkdir -p "$iconset_dir"
  
  # macOS requires specific sizes for .icns
  # use sips (built into macOS) to resize
  local sizes=(16 32 64 128 256 512 1024)
  local sizes_2x=(32 64 128 256 512 1024)
  
  for size in "${sizes[@]}"; do
    sips -z "$size" "$size" "$png_icon" --out "$iconset_dir/icon_${size}x${size}.png" >/dev/null 2>&1 || true
  done
  
  for size in "${sizes_2x[@]}"; do
    sips -z "$size" "$size" "$png_icon" --out "$iconset_dir/icon_${size}x${size}@2x.png" >/dev/null 2>&1 || true
  done
  
  # convert iconset to .icns
  iconutil -c icns "$iconset_dir" -o "$icns_output" || {
    printf "warning: iconutil failed, trying alternative method\n"
    # fallback: just copy largest size
    cp "$png_icon" "$icns_output" 2>/dev/null || return 1
  }
  
  rm -rf "$iconset_dir"
  printf "icon converted: %s\n" "$icns_output"
  return 0
}

build_binaries() {
  mkdir -p build
  printf "\n> checking pyinstaller...\n"
  if ! uv run python -c "import PyInstaller" 2>/dev/null; then
    printf "installing pyinstaller...\n"
    uv pip install pyinstaller || die "pyinstaller install failed"
  fi

  printf "\n> bundling CLI with pyinstaller (może chwilę zająć)\n"
  uv run pyinstaller \
    --clean \
    --noconfirm \
    --onefile \
    --name lifeline-cli \
    --add-data "lifeline:lifeline" \
    main.py || die "CLI build failed"

  printf "\n> bundling web server with pyinstaller...\n"
  uv run pyinstaller \
    --clean \
    --noconfirm \
    --onefile \
    --name lifeline-web \
    --add-data "lifeline:lifeline" \
    web.py || die "web server build failed"
}

build_frontend() {
  printf "\n> building Next.js frontend...\n"
  
  if ! command -v npm >/dev/null 2>&1 && ! command -v pnpm >/dev/null 2>&1; then
    printf "warning: npm/pnpm not found, skipping frontend build\n"
    printf "frontend will need to be built separately\n"
    return 0
  fi

  cd web-ui || die "web-ui directory not found"
  
  # use pnpm if available, else npm
  if command -v pnpm >/dev/null 2>&1; then
    printf "using pnpm...\n"
    pnpm install || die "pnpm install failed"
    pnpm build || die "pnpm build failed"
  else
    printf "using npm...\n"
    npm install || die "npm install failed"
    npm run build || die "npm build failed"
  fi
  
  cd ..
  printf "frontend build complete\n"
}

create_launcher() {
  local app_dir="$1"
  local launcher="$app_dir/LifeLine.app"
  local icon_path="${2:-}"
  
  mkdir -p "$launcher/Contents/MacOS"
  mkdir -p "$launcher/Contents/Resources"
  
  # copy icon if provided
  if [ -n "$icon_path" ] && [ -f "$icon_path" ]; then
    cp "$icon_path" "$launcher/Contents/Resources/icon.icns" 2>/dev/null || true
  fi
  
  # create launcher script
  cat > "$launcher/Contents/MacOS/LifeLine" <<'LAUNCHER'
#!/usr/bin/env bash
# LifeLine launcher - starts web interface

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$APP_DIR"

# source .env if it exists
if [ -f "$APP_DIR/.env" ]; then
  set -a
  source "$APP_DIR/.env"
  set +a
fi

# start web server (will prompt for API key if needed)
"$APP_DIR/LifeLine Web" &
WEB_PID=$!

# wait a bit for server to start
sleep 2

# open browser
open "http://localhost:8000"

# wait for user to close
wait $WEB_PID
LAUNCHER

  chmod +x "$launcher/Contents/MacOS/LifeLine"
  
  # create Info.plist
  cat > "$launcher/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>LifeLine</string>
  <key>CFBundleIdentifier</key>
  <string>com.lifeline.app</string>
  <key>CFBundleName</key>
  <string>LifeLine</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
PLIST

  # add icon reference if icon exists
  if [ -f "$launcher/Contents/Resources/icon.icns" ]; then
    cat >> "$launcher/Contents/Info.plist" <<PLIST
  <key>CFBundleIconFile</key>
  <string>icon</string>
PLIST
  fi

  cat >> "$launcher/Contents/Info.plist" <<PLIST
</dict>
</plist>
PLIST

  # set icon using fileicon (if available) or Rez/DeRez
  if [ -f "$launcher/Contents/Resources/icon.icns" ]; then
    # try to set icon using fileicon (install via: brew install fileicon)
    if command -v fileicon >/dev/null 2>&1; then
      fileicon set "$launcher" "$launcher/Contents/Resources/icon.icns" 2>/dev/null || true
    fi
  fi

  printf "created macOS launcher app\n"
}

stage_payload() {
  local stage_dir="build/dmg-stage"
  local app_dir="$stage_dir/LifeLine"
  local icon_icns="${1:-}"
  
  rm -rf "$stage_dir"
  mkdir -p "$app_dir"

  # copy executables
  cp dist/lifeline-cli "$app_dir/LifeLine CLI"
  cp dist/lifeline-web "$app_dir/LifeLine Web"
  chmod +x "$app_dir/LifeLine CLI"
  chmod +x "$app_dir/LifeLine Web"

  # copy frontend if built
  if [ -d "web-ui/.next" ]; then
    printf "copying frontend build...\n"
    cp -r web-ui/.next "$app_dir/frontend" 2>/dev/null || true
    cp -r web-ui/public "$app_dir/frontend-public" 2>/dev/null || true
  fi

  # create launcher app (with icon if available)
  create_launcher "$app_dir" "$icon_icns"

  # create README
  cat > "$app_dir/READ_ME_FIRST.txt" <<'EOF'
LifeLine - Personal Memory & Timeline Assistant
===============================================

QUICK START:
1. Double-click "LifeLine.app" to start the web interface
   (or run "./LifeLine Web" in Terminal for web server)
2. Open http://localhost:8000 in your browser

CLI MODE:
1. Open Terminal
2. cd to this directory
3. ./LifeLine\ CLI

SETUP:
First launch will automatically prompt you for your OpenAI API key if not set.
The key will be saved to .env file in this directory.

You can also set it manually:
Option 1 - Environment variable:
  export OPENAI_API_KEY="sk-..."

Option 2 - Create .env file in this directory:
  echo "OPENAI_API_KEY=sk-..." > .env

COMPONENTS:
- LifeLine.app          - Launcher (starts web interface)
- LifeLine CLI          - Command-line interface
- LifeLine Web          - Web server (backend)
- frontend/             - Web UI (if built)

Tip: timeline data ląduje w ./data (auto tworzone).

Have fun, ugh.
EOF

  # create CLI launcher script
  cat > "$app_dir/lifeline" <<'CLI_SCRIPT'
#!/usr/bin/env bash
# LifeLine CLI launcher

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$APP_DIR"

# source .env if it exists
if [ -f "$APP_DIR/.env" ]; then
  set -a
  source "$APP_DIR/.env"
  set +a
fi

exec "$APP_DIR/LifeLine CLI" "$@"
CLI_SCRIPT

  chmod +x "$app_dir/lifeline"
}

make_dmg() {
  local stage_dir="build/dmg-stage"
  local dmg_name="LifeLine.dmg"
  local out="dist/$dmg_name"
  local icon_icns="${1:-}"
  local icon_args=()

  rm -f "$out"
  mkdir -p dist

  if [ -n "$icon_icns" ] && [ -f "$icon_icns" ]; then
    icon_args=(--volicon "$icon_icns")
    printf "using icon: %s\n" "$icon_icns"
  else
    printf "warning: brak icon.icns, jadę bez custom ikony\n"
  fi

  create-dmg \
    --volname "LifeLine" \
    --window-pos 200 120 \
    --window-size 540 380 \
    --icon "LifeLine" 130 200 \
    --icon-size 96 \
    --app-drop-link 410 200 \
    "${icon_args[@]}" \
    "$out" \
    "$stage_dir"

  printf "\nDMG ready -> %s\n" "$out"
}

main() {
  if [ "$(uname -s)" != "Darwin" ]; then
    printf "sorry, dmg build tylko na macOS\n"
    exit 1
  fi

  draw_banner
  ensure_uv
  ensure_createdmg
  need_cmd "python3"

  # convert icon
  local icon_png="$project_root/icon.png"
  local icon_icns="build/LifeLine.icns"
  
  if [ -f "$icon_png" ]; then
    convert_icon "$icon_png" "$icon_icns" || icon_icns=""
  else
    printf "warning: icon.png not found, skipping icon conversion\n"
    icon_icns=""
  fi

  build_binaries
  build_frontend
  stage_payload "$icon_icns"
  make_dmg "$icon_icns"

  printf "\nDone. Drag DMG to friends, post na slacku, etc.\n"
}

main "$@"

