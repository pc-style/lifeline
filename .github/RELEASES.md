# Release Process

## Creating a Release

1. **Update version** in `pyproject.toml` (if needed)
2. **Create and push a tag:**
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

3. **GitHub Actions will automatically:**
   - Build macOS DMG
   - Build Windows executable + ZIP
   - Build Linux tarball
   - Create GitHub release with all artifacts

## Manual Testing

Before tagging, test locally:

```bash
# Test install script
./scripts/test_install.sh

# Test macOS build (on macOS only)
./scripts/build_dmg.sh

# Test Windows build (on Windows only)
powershell -ExecutionPolicy Bypass -File scripts/build_windows.ps1
```

## Workflow Files

- `.github/workflows/build-release.yml` - Builds all platforms and creates releases
- `.github/workflows/test-install.yml` - Tests install script on push/PR

## Artifacts

All builds go to `dist/`:
- `dist/LifeLine.dmg` (macOS)
- `dist/LifeLine-Windows.zip` (Windows)
- `dist/LifeLine-Linux.tar.gz` (Linux)

GitHub Actions uploads these to the release automatically.

