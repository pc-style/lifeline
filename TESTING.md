# Testing Checklist

## Quick Test (5 minutes)

### 1. Test Install Script - Test Mode
```bash
./scripts/install_lifeline.sh --test
```
**Expected:** 
- Creates temp dir `/tmp/lifeline-*`
- Installs dependencies
- Runs auto-tests (module imports)
- Cleans up automatically
- No errors

### 2. Test Install Script - Quick Mode
```bash
./scripts/install_lifeline.sh --quick
```
**Expected:**
- Prompts for API key
- Installs in current directory
- Creates `.venv` and `.env`
- Shows completion message

### 3. Test Install Script - Interactive Mode
```bash
./scripts/install_lifeline.sh
```
**Expected:**
- Prompts for install directory (default: `~/.local/lifeline`)
- Prompts for API key
- Asks about alias creation
- Asks about PATH addition
- Asks about desktop shortcut
- Creates everything as configured

### 4. Test Script Syntax Validation
```bash
./scripts/test_install.sh
```
**Expected:**
- All scripts pass syntax checks
- Shows usage examples

---

## Build Tests (if on macOS)

### 5. Test DMG Build (macOS only)
```bash
./scripts/build_dmg.sh
```

**Prerequisites:**
- macOS system
- Node.js/npm installed (for create-dmg)
- Python 3.10+

**Expected:**
- Converts `icon.png` → `LifeLine.icns`
- Builds CLI executable with PyInstaller
- Builds web server executable with PyInstaller
- Builds Next.js frontend (if npm/pnpm available)
- Creates `LifeLine.app` launcher with icon
- Creates DMG at `dist/LifeLine.dmg`
- DMG has custom icon

**Verify DMG contents:**
```bash
# Mount the DMG
open dist/LifeLine.dmg

# Check contents (should have):
# - LifeLine.app (with icon)
# - LifeLine CLI
# - LifeLine Web
# - READ_ME_FIRST.txt
# - lifeline (CLI launcher script)
# - frontend/ (if built)
```

**Test the app:**
1. Copy `LifeLine` folder from DMG to `/Applications` or Desktop
2. Create `.env` file with `OPENAI_API_KEY=test-key-123`
3. Double-click `LifeLine.app`
4. Should open browser to `http://localhost:8000`
5. Or run `./LifeLine CLI` in Terminal

---

## Windows Build Test (if on Windows)

### 6. Test Windows Build
```powershell
powershell -ExecutionPolicy Bypass -File scripts/build_windows.ps1
```

**Expected:**
- Creates `dist/LifeLine-Windows.zip`
- Contains `LifeLine.exe`
- Contains `READ_ME_FIRST.txt`

---

## GitHub Actions Test

### 7. Test Install Script in CI
Push to a branch and check GitHub Actions:
```bash
git add .
git commit -m "test install script"
git push
```

**Check:** `.github/workflows/test-install.yml` should run and pass

### 8. Test Release Build (when ready)
```bash
git tag v0.1.0
git push origin v0.1.0
```

**Check:** `.github/workflows/build-release.yml` should:
- Build macOS DMG
- Build Windows ZIP
- Build Linux tarball
- Create GitHub release with all artifacts

---

## Manual Verification

### After Quick Install:
```bash
source .venv/bin/activate
uv run python -c "import lifeline; print('OK')"
uv run python main.py --help
```

### After Interactive Install:
```bash
# If alias was created:
lifeline --help

# If PATH was added:
source ~/.bashrc  # or ~/.zshrc
which lifeline

# Check desktop shortcut exists:
ls ~/Desktop/LifeLine*  # macOS
ls ~/Desktop/lifeline.desktop  # Linux
```

---

## Common Issues to Watch For

1. **Icon conversion fails** - Check if `sips` and `iconutil` are available
2. **PyInstaller build fails** - Check Python version and dependencies
3. **Frontend build fails** - Check if npm/pnpm is installed
4. **DMG creation fails** - Check if `create-dmg` is installed globally
5. **App icon not showing** - May need `fileicon` tool: `brew install fileicon`

---

## Quick Smoke Test (All Modes)

Run this to test all install modes quickly:
```bash
# Test mode (auto-cleanup)
./scripts/install_lifeline.sh --test

# Quick mode (in temp dir)
mkdir /tmp/lifeline-test && cd /tmp/lifeline-test
cp -r /path/to/lifeline/* .
./scripts/install_lifeline.sh --quick
# Enter test API key when prompted
# Verify .venv and .env exist
cd ~ && rm -rf /tmp/lifeline-test
```

---

## What to Report

If something fails, note:
1. Which test failed
2. Error message
3. Your OS version
4. Python version (`python3 --version`)
5. Node version (`node --version` or `npm --version`)

