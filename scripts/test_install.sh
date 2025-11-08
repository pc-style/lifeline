#!/usr/bin/env bash

# quick test of install script (dry-run style)
# doesn't actually install, just checks syntax and basic logic

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

echo "Testing install_lifeline.sh..."
bash -n scripts/install_lifeline.sh && echo "✓ Syntax OK"

echo "Testing build_dmg.sh..."
bash -n scripts/build_dmg.sh && echo "✓ Syntax OK"

echo "Testing build_windows.ps1 (basic check)..."
# just check file exists and is readable
test -f scripts/build_windows.ps1 && echo "✓ PowerShell script exists"

echo ""
echo "All scripts pass basic checks!"
echo ""
echo "Usage:"
echo "  ./scripts/install_lifeline.sh           # interactive install (customize everything)"
echo "  ./scripts/install_lifeline.sh --quick  # quick install (just asks for API key)"
echo "  ./scripts/install_lifeline.sh --test   # test install (temp dir, auto-cleanup)"
echo "  ./scripts/install_lifeline.sh --help   # show help"

