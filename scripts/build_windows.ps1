# LifeLine Windows build script
# builds exe with pyinstaller, packages for distribution

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "============================================="
Write-Host "  LifeLine :: Windows build kitchen"
Write-Host "============================================="

# check python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "fatal: python not found, install from python.org"
    exit 1
}

$pythonVersion = python --version
Write-Host "python -> $pythonVersion"

# ensure uv
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "installing uv (bo tak szybciej)"
    $env:PATH = "$env:USERPROFILE\.local\bin;$env:PATH"
    if (-not (Test-Path "$env:USERPROFILE\.local\bin\uv.exe")) {
        Invoke-WebRequest -Uri "https://astral.sh/uv/install.ps1" -UseBasicParsing | Invoke-Expression
    }
}

# ensure pyinstaller
Write-Host "`n> checking pyinstaller..."
$env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"
try {
    uv run python -c "import PyInstaller" 2>$null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Host "installing pyinstaller..."
    uv pip install pyinstaller
    if ($LASTEXITCODE -ne 0) {
        Write-Host "fatal: pyinstaller install failed"
        exit 1
    }
}

# build binary
Write-Host "`n> bundling CLI with pyinstaller (może chwilę zająć)..."
New-Item -ItemType Directory -Force -Path "build" | Out-Null

uv run pyinstaller `
    --clean `
    --noconfirm `
    --onefile `
    --name lifeline-cli `
    --add-data "lifeline;lifeline" `
    main.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "fatal: pyinstaller build failed"
    exit 1
}

# stage payload
$stageDir = "build\windows-stage"
$appDir = "$stageDir\LifeLine"
Remove-Item -Recurse -Force $stageDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $appDir | Out-Null

Copy-Item "dist\lifeline-cli.exe" "$appDir\LifeLine.exe"

@"
LifeLine CLI (Windows)
======================

1. Open Command Prompt or PowerShell
2. cd to wherever you extracted this folder
3. .\LifeLine.exe

First launch will prompt you for your OpenAI API key if not set.
You can also set it manually:
  set OPENAI_API_KEY=sk-...
  # or in PowerShell:
  `$env:OPENAI_API_KEY='sk-...'
  # or create .env file in this directory with:
  # OPENAI_API_KEY=sk-...

Tip: timeline data ląduje w .\data (auto tworzone).

Have fun, ugh.
"@ | Out-File -FilePath "$appDir\READ_ME_FIRST.txt" -Encoding UTF8

# create zip
$zipName = "LifeLine-Windows.zip"
$zipPath = "dist\$zipName"
Remove-Item $zipPath -ErrorAction SilentlyContinue

Write-Host "`n> creating zip archive..."
Compress-Archive -Path "$appDir\*" -DestinationPath $zipPath -Force

Write-Host "`nDone. Windows build ready -> $zipPath"

