# Build System Guide

This document describes the build system and Makefile for the Setlist Playlist Builder project.

## Overview

The project uses **Cargo** (Rust) and **swift-bridge** (Swift FFI) with a **Makefile** for common tasks.

## Quick Start

```bash
# Set up development environment (one-time)
make dev

# Build the project
make build

# Run tests with coverage
make ci-check

# Run the application
make run
```

## Makefile Targets

### Quick Reference

```bash
make help          # Show all available targets
make build         # Build debug version
make test          # Run all tests
make ci-check      # Run all CI checks locally
make coverage-open # Generate and view coverage report
make run           # Run the application
```

### General Targets

| Target | Description |
|--------|-------------|
| `help` | Display all available targets with descriptions |
| `info` | Display project information and structure |

### Build Targets

| Target | Description |
|--------|-------------|
| `build` | Build the project in debug mode |
| `build-release` | Build the project in release mode (optimized) |
| `clean` | Remove all build artifacts and coverage reports |
| `rebuild` | Clean and rebuild from scratch |
| `check` | Quick check without building (faster than `build`) |

**Examples**:
```bash
# Standard build
make build

# Release build (optimized, slower compile)
make build-release

# Clean everything and rebuild
make rebuild

# Quick check (no binary produced)
make check
```

### Testing Targets

| Target | Description |
|--------|-------------|
| `test` | Run all tests (unit + integration) |
| `test-unit` | Run only unit tests (tests in `src/`) |
| `test-integration` | Run only integration tests (tests in `tests/`) |
| `test-specific` | Run specific test by name |

**Examples**:
```bash
# Run all tests
make test

# Run only unit tests
make test-unit

# Run specific test
make test-specific TEST=test_filter_confident_matches

# Run tests with verbose output
cargo test -- --nocapture
```

### Code Quality Targets

| Target | Description |
|--------|-------------|
| `fmt` | Check code formatting (fails if not formatted) |
| `fmt-fix` | Automatically format all code |
| `clippy` | Run clippy with strict settings (as CI does) |
| `clippy-fix` | Automatically fix clippy warnings (where possible) |

**Examples**:
```bash
# Check formatting (CI runs this)
make fmt

# Fix formatting
make fmt-fix

# Run clippy (strict mode)
make clippy

# Auto-fix clippy warnings
make clippy-fix
```

### Coverage Targets

| Target | Description |
|--------|-------------|
| `coverage` | Generate HTML coverage report |
| `coverage-open` | Generate and open HTML coverage report in browser |
| `coverage-ci` | Generate XML coverage report (for CI/Codecov) |
| `coverage-check` | Check if coverage meets 80% threshold (fails if below) |

**Examples**:
```bash
# Generate and view coverage
make coverage-open

# Just check if coverage is ≥80%
make coverage-check

# Generate XML for CI
make coverage-ci
```

**Coverage reports** are saved to `coverage/` directory:
- `coverage/index.html` - Interactive HTML report
- `coverage/cobertura.xml` - XML report for CI

### CI Checks Targets

| Target | Description |
|--------|-------------|
| `ci-check` | Run all CI checks: format, clippy, test, coverage (80%) |
| `pre-commit` | Run pre-commit checks with auto-fix (format, clippy, test) |

**Examples**:
```bash
# Run all CI checks (what GitHub Actions runs)
make ci-check

# Run pre-commit checks (with auto-fix for format/clippy)
make pre-commit
```

**CI check order**:
1. ✅ Format check (`cargo fmt --check`)
2. ✅ Clippy check (`cargo clippy -- -D warnings`)
3. ✅ Tests (`cargo test`)
4. ✅ Coverage check (`cargo tarpaulin --fail-under 80`)

### Development Targets

| Target | Description |
|--------|-------------|
| `dev` | Set up development environment (install tools, create .env) |
| `install-tools` | Install required cargo tools (tarpaulin, outdated, etc.) |
| `watch` | Watch for changes and rebuild automatically |
| `watch-test` | Watch for changes and run tests automatically |

**Examples**:
```bash
# First-time setup
make dev

# Just install tools
make install-tools

# Watch mode (requires cargo-watch)
cargo install cargo-watch
make watch
make watch-test
```

**Tools installed by `make dev`**:
- `cargo-tarpaulin` - Coverage reporting
- `cargo-outdated` - Check for outdated dependencies
- `cargo-edit` - `cargo add`, `cargo upgrade` commands
- `cargo-audit` - Security vulnerability scanning

### Dependency Targets

| Target | Description |
|--------|-------------|
| `deps-check` | Check for outdated dependencies |
| `deps-update` | Update dependencies to latest compatible versions |
| `deps-upgrade` | Upgrade dependencies to latest versions (including breaking) |
| `deps-audit` | Audit dependencies for security vulnerabilities |
| `deps-tree` | Show dependency tree (depth 1) |

**Examples**:
```bash
# Check what's outdated
make deps-check

# Update within compatibility (respects semver)
make deps-update

# Upgrade to latest (may include breaking changes)
make deps-upgrade

# Security audit
make deps-audit

# View dependency tree
make deps-tree
```

**Dependency management workflow**:
```bash
# 1. Check for updates
make deps-check

# 2. Update compatible versions
make deps-update

# 3. Test everything still works
make test

# 4. If needed, upgrade with breaking changes
make deps-upgrade
make test
```

### Swift Targets

| Target | Description |
|--------|-------------|
| `swift-check` | Check Swift version and Xcode Command Line Tools |
| `swift-clean` | Clean Swift build artifacts |

**Examples**:
```bash
# Verify Swift installation
make swift-check

# Clean Swift artifacts
make swift-clean
```

### Release Targets

| Target | Description |
|--------|-------------|
| `release` | Build optimized release binary |
| `install` | Build and install binary to `/usr/local/bin` |
| `uninstall` | Remove installed binary from `/usr/local/bin` |

**Examples**:
```bash
# Build release
make release
# Binary at: target/release/setlist_to_playlist

# Install globally
make install
# Now available as: setlist_to_playlist

# Uninstall
make uninstall
```

### Run Targets

| Target | Description |
|--------|-------------|
| `run` | Run the application in debug mode |
| `run-release` | Run the application in release mode |

**Examples**:
```bash
# Run debug version
make run

# Run release version (optimized)
make run-release
```

### Documentation Targets

| Target | Description |
|--------|-------------|
| `docs` | Generate Rust documentation (project only) and open in browser |
| `docs-all` | Generate Rust documentation (including dependencies) and open |

**Examples**:
```bash
# Generate and view docs
make docs

# Include dependency docs
make docs-all
```

## Build System Architecture

### Rust + Swift Compilation

The build process involves:

1. **Cargo triggers build.rs** (if exists)
2. **build.rs compiles Swift code** via swift-bridge
3. **Swift generates FFI bindings** for Rust
4. **Rust compiles** with Swift bindings
5. **Linker combines** Rust and Swift object files

### Build Configuration

**build.rs** (to be created in Phase 1):
```rust
// build.rs
fn main() {
    // Configure swift-bridge compilation
    swift_bridge_build::parse_bridges(vec!["src/bridge.rs"])
        .write_all_concatenated("swift/generated/");
}
```

**Cargo.toml** build dependencies:
```toml
[build-dependencies]
swift-bridge-build = "0.1"
```

### Swift Module Structure

```
swift/
├── MusicKitBridge/
│   ├── Authorization.swift      # MusicKit auth
│   ├── CatalogSearch.swift      # Search implementation
│   ├── PlaylistCreator.swift    # Playlist operations
│   └── Models.swift             # Swift-side models
└── generated/                    # Generated by swift-bridge
    └── bridge.swift             # Auto-generated FFI glue
```

## Development Workflow

### First-Time Setup

```bash
# 1. Clone repository
git clone <repo-url>
cd setlist_to_playlist

# 2. Set up development environment
make dev

# 3. Add API key to .env
echo "SETLIST_FM_API_KEY=your-key-here" >> .env

# 4. Build project
make build

# 5. Run tests
make test
```

### Daily Development

```bash
# 1. Pull latest changes
git pull

# 2. Update dependencies
make deps-update

# 3. Start development
make watch-test  # Auto-run tests on save

# OR work normally
# - Make changes
# - Run: make test
# - Run: make ci-check (before committing)
```

### Before Committing

```bash
# Run all CI checks locally
make ci-check

# OR run pre-commit with auto-fix
make pre-commit

# Then commit
git add .
git commit -m "feat: Add fuzzy matching"
```

### Before Creating PR

```bash
# 1. Ensure all CI checks pass
make ci-check

# 2. Check coverage
make coverage-open

# 3. Update version if needed (for releases)
# Edit Cargo.toml: version = "0.2.0"

# 4. Push and create PR
git push origin feature-branch
```

## Common Tasks

### Adding a New Dependency

```bash
# 1. Add dependency
cargo add <crate-name>

# 2. Build
make build

# 3. Test
make test

# 4. Check dependency tree
make deps-tree
```

### Fixing Clippy Warnings

```bash
# 1. See warnings
make clippy

# 2. Auto-fix (some warnings)
make clippy-fix

# 3. Manually fix remaining
# Edit code...

# 4. Verify
make clippy
```

### Improving Test Coverage

```bash
# 1. Generate coverage report
make coverage-open

# 2. Identify uncovered lines (red in HTML)
# Open: coverage/index.html

# 3. Add tests for uncovered code

# 4. Check coverage improved
make coverage-check
```

### Building for Release

```bash
# 1. Update version in Cargo.toml
# version = "1.0.0"

# 2. Build release
make release

# 3. Test release binary
target/release/setlist_to_playlist --help

# 4. Install locally (optional)
make install
```

## Troubleshooting

### Build Fails

**Swift compiler not found**:
```bash
# Check Swift installation
make swift-check

# Install Xcode Command Line Tools
xcode-select --install
```

**Cargo compilation errors**:
```bash
# Clean and rebuild
make rebuild

# Check Rust version
rustc --version  # Should be 1.70+
```

### Tests Fail

**Coverage below 80%**:
```bash
# Generate HTML report
make coverage-open

# Add tests for uncovered code
# Re-check
make coverage-check
```

**Specific test failing**:
```bash
# Run with output
make test-specific TEST=test_name

# Or directly with cargo
cargo test test_name -- --nocapture
```

### Makefile Doesn't Work

**Make not installed**:
```bash
# macOS (via Xcode Command Line Tools)
xcode-select --install

# Or use Homebrew
brew install make

# Linux
sudo apt-get install build-essential  # Debian/Ubuntu
sudo yum install make                  # RedHat/CentOS
```

**Target not found**:
```bash
# List all targets
make help
```

### Performance Issues

**Slow compilation**:
```bash
# Use cargo check instead of build for quick feedback
make check

# Use watch mode for incremental builds
make watch
```

**Slow tests**:
```bash
# Run only unit tests (faster)
make test-unit

# Run specific test
make test-specific TEST=test_name
```

## CI/CD Integration

The Makefile targets match GitHub Actions workflows:

### PR Workflow
```yaml
# .github/workflows/pr.yml uses:
- cargo fmt --all -- --check     # = make fmt
- cargo clippy -- -D warnings    # = make clippy
- cargo test                     # = make test
- cargo tarpaulin --fail-under 80 # = make coverage-check
```

### Local CI Simulation
```bash
# Run exactly what CI runs
make ci-check
```

## Advanced Usage

### Custom Coverage Threshold

```bash
# Check for 90% coverage instead of 80%
cargo tarpaulin --fail-under 90
```

### Parallel Test Execution

```bash
# Run tests in parallel (default)
cargo test

# Run tests serially (for debugging)
cargo test -- --test-threads=1
```

### Verbose Output

```bash
# Verbose build
cargo build --verbose

# Verbose tests
cargo test --verbose

# Show test output
cargo test -- --nocapture
```

### Cross-Compilation

**Note**: This project targets macOS only (requires Swift/MusicKit).

```bash
# Build for specific target
cargo build --target aarch64-apple-darwin  # Apple Silicon
cargo build --target x86_64-apple-darwin   # Intel Mac
```

## Performance Tips

1. **Use `make check`** for quick feedback (no binary produced)
2. **Use `make watch`** for automatic rebuilds during development
3. **Use `make test-unit`** to run fast unit tests without integration tests
4. **Enable incremental compilation** (enabled by default in debug builds)
5. **Use release builds** for performance testing: `make run-release`

## Environment Variables

The build system respects these environment variables:

| Variable | Purpose | Default |
|----------|---------|---------|
| `CARGO_TARGET_DIR` | Build output directory | `target/` |
| `RUST_BACKTRACE` | Enable backtraces | `0` (set to `1` for debugging) |
| `RUST_LOG` | Logging level | None (set to `debug` for verbose logs) |

**Example**:
```bash
# Build with custom target directory
CARGO_TARGET_DIR=/tmp/build make build

# Run with debug logging
RUST_LOG=debug make run
```

## Integration with IDEs

### VS Code

Add tasks to `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build",
      "type": "shell",
      "command": "make build",
      "problemMatcher": ["$rustc"]
    },
    {
      "label": "Test",
      "type": "shell",
      "command": "make test",
      "problemMatcher": ["$rustc"]
    }
  ]
}
```

### IntelliJ IDEA / RustRover

1. Open project
2. Makefile plugin auto-detects targets
3. Right-click Makefile → Run target

## Summary

**Quick Commands**:
```bash
make dev           # First-time setup
make build         # Build project
make test          # Run tests
make ci-check      # Run all CI checks
make coverage-open # View coverage
make run           # Run application
```

**Before Commit**:
```bash
make ci-check      # Ensure all checks pass
```

**Before PR**:
```bash
make ci-check && make coverage-open
```

**For Help**:
```bash
make help          # Show all targets
make info          # Show project info
```
