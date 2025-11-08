#!/usr/bin/env bash

# LifeLine Linux build script
# builds executable with pyinstaller, packages for distribution

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

draw_banner() {
  printf "============================================\n"
  printf "  LifeLine :: Linux build kitchen\n"
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
  if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
}

build_binary() {
  mkdir -p build dist
  printf "\n> checking pyinstaller...\n"
  if ! uv run python -c "import PyInstaller" 2>/dev/null; then
    printf "installing pyinstaller...\n"
    uv pip install pyinstaller || die "pyinstaller install failed"
  fi

  printf "\n> bundling CLI with pyinstaller (może chwilę zająć)\n"
  uv run pyinstaller \
    --clean \
    --noconfirm \
    lifeline-cli.spec || die "CLI build failed"
  
  printf "\n> bundling web server with pyinstaller...\n"
  uv run pyinstaller \
    --clean \
    --noconfirm \
    lifeline-web.spec || die "Web server build failed"
}

stage_payload() {
  local stage_dir="build/linux-stage"
  local app_dir="$stage_dir/LifeLine"

  rm -rf "$stage_dir"
  mkdir -p "$app_dir"

  # copy executables
  cp dist/lifeline-cli "$app_dir/lifeline-cli"
  cp dist/lifeline-web "$app_dir/lifeline-web"
  chmod +x "$app_dir/lifeline-cli"
  chmod +x "$app_dir/lifeline-web"

  # create README
  cat > "$app_dir/README.txt" <<'EOF'
LifeLine (Linux)
=================

QUICK START - CLI:
  ./lifeline-cli

QUICK START - Web UI:
  ./lifeline-web
  Then open http://localhost:8000 in your browser

SETUP:
First launch będzie narzekał jeśli nie ustawisz OPENAI_API_KEY.
Set it like:
  export OPENAI_API_KEY="sk-..."

Or create .env file in this directory:
  echo "OPENAI_API_KEY=sk-..." > .env

Tip: timeline data ląduje w ~/.lifeline (auto tworzone).

Have fun, ugh.
EOF

  # create launcher scripts
  cat > "$app_dir/lifeline" <<'LAUNCHER'
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

exec "$APP_DIR/lifeline-cli" "$@"
LAUNCHER

  cat > "$app_dir/lifeline-web" <<'WEB_LAUNCHER'
#!/usr/bin/env bash
# LifeLine Web launcher

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$APP_DIR"

# source .env if it exists
if [ -f "$APP_DIR/.env" ]; then
  set -a
  source "$APP_DIR/.env"
  set +a
fi

exec "$APP_DIR/lifeline-web" "$@"
WEB_LAUNCHER

  chmod +x "$app_dir/lifeline"
  chmod +x "$app_dir/lifeline-web"
}

make_tarball() {
  local stage_dir="build/linux-stage"
  local tarball_name="LifeLine-Linux.tar.gz"
  local out="dist/$tarball_name"

  rm -f "$out"
  mkdir -p dist

  cd "$stage_dir"
  tar -czf "../../$out" LifeLine
  cd "$project_root"

  printf "\nTarball ready -> %s\n" "$out"
}

main() {
  draw_banner
  ensure_uv
  need_cmd "python3"

  build_binary
  stage_payload
  make_tarball

  printf "\nDone. Upload to GitHub releases, whatever.\n"
}

main "$@"
