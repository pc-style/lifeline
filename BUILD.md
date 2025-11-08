# Building LifeLine Executables

LifeLine can be compiled into standalone executables for Mac, Linux, and Windows. The build system uses PyInstaller to bundle everything into single-file executables.

## Prerequisites

- Python 3.10+ 
- [uv](https://github.com/astral-sh/uv) package manager (auto-installed if missing)
- PyInstaller (auto-installed during build)
- For macOS DMG: macOS with `hdiutil` and `iconutil`
- For Windows: PowerShell
- For frontend: npm or pnpm (optional, for web UI)

## Quick Build

```bash
# Build for current platform
make build

# Or build for specific platform
make build-linux
make build-windows
make build-macos
```

## Manual Build

### Linux

```bash
bash scripts/build_linux.sh
```

Output: `dist/LifeLine-Linux.tar.gz`

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build_windows.ps1
```

Output: `dist/LifeLine-Windows.zip`

### macOS

```bash
bash scripts/build_dmg.sh
```

Output: `dist/LifeLine.dmg`

## Build Process

1. **Install dependencies**: Uses `uv` to manage Python dependencies
2. **Build frontend** (optional): Compiles Next.js frontend if npm/pnpm available
3. **Bundle executables**: Uses PyInstaller with spec files:
   - `lifeline-cli.spec` - CLI executable
   - `lifeline-web.spec` - Web server executable
4. **Package**: Creates platform-specific distribution packages

## Output Structure

### Linux/Windows
```
LifeLine/
├── lifeline-cli      # CLI executable (or .exe on Windows)
├── lifeline-web      # Web server executable (or .exe on Windows)
├── lifeline          # CLI launcher script (Linux only)
├── lifeline-web      # Web launcher script (Linux only)
└── README.txt        # Usage instructions
```

### macOS
```
LifeLine.dmg
└── LifeLine.app      # macOS application bundle
    ├── Contents/
    │   ├── MacOS/LifeLine      # Launcher
    │   └── Resources/
    │       ├── lifeline-cli    # CLI executable
    │       ├── lifeline-web    # Web server executable
    │       └── frontend/       # Built Next.js app (if available)
```

## Data Storage

When running from executables, data is stored in:
- **Linux/macOS**: `~/.lifeline/`
- **Windows**: `%USERPROFILE%\.lifeline\`

When running from source, data is stored in `./data/`

## Troubleshooting

### PyInstaller missing modules
If you get import errors, check the spec files (`lifeline-cli.spec`, `lifeline-web.spec`) and add missing modules to `hiddenimports`.

### Frontend not included
The web server executable works without the frontend (serves API only). To include the frontend:
1. Build it first: `make build-frontend` or `cd web-ui && npm run build`
2. Rebuild the executable

### Large executable size
PyInstaller bundles Python interpreter and all dependencies. This is normal. The executables are ~50-100MB depending on platform.

### macOS code signing
The DMG is not code-signed by default. To sign:
```bash
codesign --deep --force --verify --verbose --sign "Developer ID" LifeLine.app
```

## Advanced: Custom Spec Files

The spec files (`lifeline-cli.spec`, `lifeline-web.spec`) control what gets bundled. You can customize:
- `datas`: Additional data files to include
- `hiddenimports`: Modules PyInstaller might miss
- `excludes`: Modules to exclude (to reduce size)
- `upx`: Compression (enabled by default)

See [PyInstaller docs](https://pyinstaller.org/en/stable/spec-files.html) for details.
