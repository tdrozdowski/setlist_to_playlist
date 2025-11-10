# Makefile for Setlist Playlist Builder
# Manages Rust + Swift build process

.PHONY: help build clean test fmt clippy check coverage install dev ci-check release run

# Default target
.DEFAULT_GOAL := help

##@ General

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

build: ## Build the project (debug mode)
	@echo "Building project (debug)..."
	cargo build

build-release: ## Build the project (release mode)
	@echo "Building project (release)..."
	cargo build --release

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	cargo clean
	@echo "Cleaning coverage reports..."
	rm -rf coverage/

rebuild: clean build ## Clean and rebuild

##@ Testing

test: ## Run all tests
	@echo "Running tests..."
	cargo test --verbose

test-unit: ## Run only unit tests
	@echo "Running unit tests..."
	cargo test --lib

test-integration: ## Run only integration tests
	@echo "Running integration tests..."
	cargo test --test '*'

test-specific: ## Run specific test (usage: make test-specific TEST=test_name)
	@echo "Running test: $(TEST)"
	cargo test $(TEST) -- --nocapture

##@ Code Quality

fmt: ## Check code formatting
	@echo "Checking code formatting..."
	cargo fmt --all -- --check

fmt-fix: ## Fix code formatting
	@echo "Formatting code..."
	cargo fmt --all

clippy: ## Run clippy (strict mode, as CI does)
	@echo "Running clippy..."
	cargo clippy --all-targets --all-features -- -D warnings

clippy-fix: ## Fix clippy warnings (where possible)
	@echo "Fixing clippy warnings..."
	cargo clippy --fix --all-targets --all-features

check: ## Quick check (no build)
	@echo "Running cargo check..."
	cargo check

##@ Coverage

coverage: ## Generate coverage report (HTML)
	@echo "Generating coverage report..."
	cargo tarpaulin --out Html --output-dir coverage
	@echo "Coverage report generated at coverage/index.html"

coverage-open: coverage ## Generate and open coverage report
	@echo "Opening coverage report..."
	open coverage/index.html 2>/dev/null || xdg-open coverage/index.html 2>/dev/null || echo "Please open coverage/index.html manually"

coverage-ci: ## Generate coverage report (XML for CI)
	@echo "Generating coverage report for CI..."
	cargo tarpaulin --out Xml --output-dir ./coverage

coverage-check: ## Check if coverage meets 80% threshold
	@echo "Checking coverage threshold (80% minimum)..."
	cargo tarpaulin --fail-under 80

##@ CI Checks

ci-check: fmt clippy test coverage-check ## Run all CI checks locally
	@echo ""
	@echo "✅ All CI checks passed!"
	@echo ""

pre-commit: fmt-fix clippy test ## Run pre-commit checks (with auto-fix)
	@echo ""
	@echo "✅ Pre-commit checks passed!"
	@echo ""

##@ Development

dev: ## Set up development environment
	@echo "Setting up development environment..."
	@command -v rustc >/dev/null 2>&1 || { echo "Rust is not installed. Please install from https://rustup.rs"; exit 1; }
	@command -v swift >/dev/null 2>&1 || { echo "Swift is not installed. Please install Xcode Command Line Tools"; exit 1; }
	@echo "Rust version: $$(rustc --version)"
	@echo "Swift version: $$(swift --version | head -1)"
	@echo "Installing cargo tools..."
	@command -v cargo-tarpaulin >/dev/null 2>&1 || cargo install cargo-tarpaulin
	@command -v cargo-outdated >/dev/null 2>&1 || cargo install cargo-outdated
	@command -v cargo-edit >/dev/null 2>&1 || cargo install cargo-edit
	@command -v cargo-audit >/dev/null 2>&1 || cargo install cargo-audit
	@echo ""
	@echo "Creating .env file from .env.example (if not exists)..."
	@[ -f .env ] || ([ -f .env.example ] && cp .env.example .env) || echo "SETLIST_FM_API_KEY=your-api-key-here" > .env
	@echo ""
	@echo "✅ Development environment ready!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Add your setlist.fm API key to .env"
	@echo "  2. Run 'make build' to build the project"
	@echo "  3. Run 'make test' to run tests"
	@echo ""

install-tools: ## Install required cargo tools
	@echo "Installing cargo tools..."
	cargo install cargo-tarpaulin cargo-outdated cargo-edit cargo-audit

##@ Dependencies

deps-check: ## Check for outdated dependencies
	@echo "Checking for outdated dependencies..."
	cargo outdated

deps-update: ## Update dependencies to latest compatible versions
	@echo "Updating dependencies..."
	cargo update
	@echo "Updated. Run 'make deps-check' to see if there are newer versions available."

deps-upgrade: ## Upgrade dependencies to latest versions (including breaking changes)
	@echo "Upgrading dependencies to latest versions..."
	cargo upgrade
	@echo "Upgraded. Run 'make test' to ensure everything still works."

deps-audit: ## Audit dependencies for security vulnerabilities
	@echo "Auditing dependencies for security vulnerabilities..."
	cargo audit

deps-tree: ## Show dependency tree
	@echo "Dependency tree (depth 1):"
	cargo tree --depth 1

##@ Swift

swift-check: ## Check Swift version and Xcode tools
	@echo "Swift version:"
	@swift --version
	@echo ""
	@echo "Xcode Command Line Tools path:"
	@xcode-select --print-path

swift-clean: ## Clean Swift build artifacts (if any)
	@echo "Cleaning Swift build artifacts..."
	@rm -rf swift/.build 2>/dev/null || true
	@echo "Done."

##@ Release

release: ## Build release binary
	@echo "Building release binary..."
	cargo build --release
	@echo ""
	@echo "Release binary built at: target/release/setlist_to_playlist"
	@echo ""

app-bundle: ## Build macOS app bundle with code signing
	@echo "Building macOS app bundle..."
	@./scripts/build-app-bundle.sh

install: release ## Install binary to /usr/local/bin
	@echo "Installing binary to /usr/local/bin..."
	@sudo cp target/release/setlist_to_playlist /usr/local/bin/
	@echo "✅ Installed! Run 'setlist_to_playlist --help' to get started."

uninstall: ## Uninstall binary from /usr/local/bin
	@echo "Uninstalling binary from /usr/local/bin..."
	@sudo rm -f /usr/local/bin/setlist_to_playlist
	@echo "✅ Uninstalled."

##@ Run

run: ## Run the application (debug mode)
	@echo "Running application..."
	cargo run

run-release: ## Run the application (release mode)
	@echo "Running application (release mode)..."
	cargo run --release

##@ Documentation

docs: ## Generate and open Rust documentation
	@echo "Generating documentation..."
	cargo doc --no-deps --open

docs-all: ## Generate documentation including dependencies
	@echo "Generating documentation (including dependencies)..."
	cargo doc --open

##@ Maintenance

audit: deps-audit ## Alias for deps-audit

outdated: deps-check ## Alias for deps-check

watch: ## Watch for changes and rebuild (requires cargo-watch)
	@command -v cargo-watch >/dev/null 2>&1 || { echo "cargo-watch not installed. Run: cargo install cargo-watch"; exit 1; }
	@echo "Watching for changes..."
	cargo watch -x build

watch-test: ## Watch for changes and run tests (requires cargo-watch)
	@command -v cargo-watch >/dev/null 2>&1 || { echo "cargo-watch not installed. Run: cargo install cargo-watch"; exit 1; }
	@echo "Watching for changes and running tests..."
	cargo watch -x test

##@ Info

info: ## Display project information
	@echo "Project: Setlist Playlist Builder"
	@echo ""
	@echo "Rust version: $$(rustc --version)"
	@echo "Cargo version: $$(cargo --version)"
	@echo "Swift version: $$(swift --version | head -1)"
	@echo ""
	@echo "Project structure:"
	@echo "  src/          - Rust source code"
	@echo "  swift/        - Swift source code (MusicKit bridge)"
	@echo "  tests/        - Test code"
	@echo "  .claude/      - Documentation"
	@echo ""
	@echo "Documentation:"
	@echo "  CLAUDE.md              - Quick reference"
	@echo "  .claude/ARCHITECTURE.md - Architecture details"
	@echo "  .claude/DEPENDENCIES.md - Dependency management"
	@echo "  .claude/TESTING.md      - Testing guide"
	@echo "  .claude/CICD.md         - CI/CD guide"
	@echo "  .claude/BUILD.md        - Build system guide"
	@echo ""
