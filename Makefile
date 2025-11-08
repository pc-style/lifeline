.PHONY: help install run web example export test format lint type-check clean clean-all build build-linux build-windows build-macos build-frontend

help:
	@echo "LifeLine - Available Commands"
	@echo "=============================="
	@echo "  make install      - Install dependencies with UV"
	@echo "  make run          - Run LifeLine CLI"
	@echo "  make web          - Run LifeLine Web Server"
	@echo "  make example      - Run example usage script"
	@echo "  make export       - Export timeline data to JSON"
	@echo "  make test         - Run tests"
	@echo "  make format       - Format code with Black"
	@echo "  make lint         - Lint code with Ruff"
	@echo "  make type-check   - Type check with mypy"
	@echo "  make quality      - Run all quality checks"
	@echo "  make build        - Build executables for current platform"
	@echo "  make build-linux  - Build Linux executables"
	@echo "  make build-windows - Build Windows executables"
	@echo "  make build-macos  - Build macOS DMG"
	@echo "  make build-frontend - Build Next.js frontend"
	@echo "  make clean        - Remove generated files"
	@echo "  make clean-all    - Remove all artifacts (including .venv)"

install:
	uv sync

run:
	uv run python main.py

web:
	uv run uvicorn web:app --reload --port 8000

example:
	uv run python examples/example_usage.py

export:
	uv run python -m lifeline.mcp_server

test:
	uv run pytest

format:
	uv run black lifeline/ main.py examples/

lint:
	uv run ruff check lifeline/ main.py examples/

type-check:
	uv run mypy lifeline/

quality: format lint type-check
	@echo "All quality checks passed!"

clean:
	@echo "Cleaning Python artifacts..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	rm -f data/*.db-journal data/*.db-wal data/*.db-shm
	@echo "Cleaning build artifacts..."
	rm -rf build/ 2>/dev/null || true
	rm -rf dist/ 2>/dev/null || true
	find . -maxdepth 1 -name "*.spec" -type f -delete 2>/dev/null || true
	@echo "Cleaning frontend build..."
	rm -rf web-ui/.next 2>/dev/null || true
	rm -rf web-ui/.turbo 2>/dev/null || true
	@echo "Cleaning ruff cache..."
	rm -rf .ruff_cache/ 2>/dev/null || true
	@echo "Cleaning test installs..."
	find /tmp -maxdepth 1 -type d -name "lifeline-*" -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete!"

clean-all: clean
	@echo "Cleaning virtual environment..."
	rm -rf .venv 2>/dev/null || true
	rm -f .env 2>/dev/null || true
	@echo "Deep clean complete!"

# Build targets
build-frontend:
	@echo "Building Next.js frontend..."
	cd web-ui && \
	if command -v pnpm >/dev/null 2>&1; then \
		pnpm install && pnpm build; \
	elif command -v npm >/dev/null 2>&1; then \
		npm install && npm run build; \
	else \
		echo "Error: npm or pnpm required for frontend build"; exit 1; \
	fi

build-linux:
	@echo "Building Linux executables..."
	@bash scripts/build_linux.sh

build-windows:
	@echo "Building Windows executables..."
	@powershell -ExecutionPolicy Bypass -File scripts/build_windows.ps1

build-macos:
	@echo "Building macOS DMG..."
	@bash scripts/build_dmg.sh

build:
	@echo "Building for current platform..."
	@if [ "$$(uname -s)" = "Linux" ]; then \
		$(MAKE) build-linux; \
	elif [ "$$(uname -s)" = "Darwin" ]; then \
		$(MAKE) build-macos; \
	else \
		echo "Error: Unknown platform. Use make build-linux, build-windows, or build-macos"; \
		exit 1; \
	fi
