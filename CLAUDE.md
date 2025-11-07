# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Setlist Playlist Builder is a macOS native application that fetches concert setlists from setlist.fm and automatically creates Apple Music playlists. It uses Rust for the core logic and Swift for Apple Music integration via MusicKit, connected through FFI (Foreign Function Interface).

**Current Phase**: Phase 1 - Project Setup & FFI Bridge

**Badges**:
```markdown
[![CI](https://github.com/username/repo/workflows/Pull%20Request%20CI/badge.svg)](https://github.com/username/repo/actions)
[![codecov](https://codecov.io/gh/username/repo/branch/main/graph/badge.svg)](https://codecov.io/gh/username/repo)
```

## Essential Commands

**Using Makefile** (recommended):
```bash
make help          # Show all available targets
make dev           # First-time setup (install tools, create .env)
make build         # Build project
make test          # Run all tests
make ci-check      # Run all CI checks (format, clippy, test, coverage)
make coverage-open # Generate and view coverage report
make run           # Run the application
```

**Direct cargo commands**:
```bash
# Build and run
cargo build
cargo run
cargo build --release

# Testing
cargo test
cargo test test_name -- --nocapture

# Quality checks (or use: make ci-check)
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo tarpaulin --fail-under 80

# Dependencies
cargo add <crate>               # Add latest stable version
cargo update                    # Update to latest compatible
cargo outdated                  # Check for newer versions
```

**See [BUILD.md](.claude/BUILD.md) for complete Makefile documentation.**

## Quick Reference

**Detailed documentation** (refer agents to these files for specific topics):

- **[Build System](.claude/BUILD.md)** - Makefile targets, build process, development workflow
- **[Architecture](.claude/ARCHITECTURE.md)** - Layered architecture, design patterns, code organization
- **[Dependencies](.claude/DEPENDENCIES.md)** - Dependency management, version policy, core crates
- **[Testing](.claude/TESTING.md)** - Testing philosophy, coverage requirements, mocking strategy
- **[CI/CD](.claude/CICD.md)** - GitHub Actions workflows, release process, branch protection

## Core Principles (Critical)

### 1. Clean Architecture
- **NO business logic in CLI/UI layers** - See [ARCHITECTURE.md](.claude/ARCHITECTURE.md)
- Services contain business logic, controllers orchestrate, CLI handles I/O
- Dependencies flow inward: CLI → Controllers → Services → Adapters → Clients

### 2. Testing Requirements
- **Minimum 80% code coverage** - See [TESTING.md](.claude/TESTING.md)
- Use `mockall` for trait mocking with `#[automock]`
- Focus on high-value tests (services, algorithms, domain logic)
- CI enforces coverage threshold

### 3. Dependencies
- **Always use latest stable versions** - See [DEPENDENCIES.md](.claude/DEPENDENCIES.md)
- MUST use: tokio (async), reqwest (HTTP), swift-bridge (FFI)
- Use `cargo add` to get latest versions automatically

### 4. CI/CD
- **All PRs must pass CI checks** - See [CICD.md](.claude/CICD.md)
- CI runs: format, clippy, tests, coverage (80% minimum)
- **Codecov integration**: Coverage reports on every PR with pass/fail status
- Merges to main auto-release binary with version from Cargo.toml
- Weekly dependency checks create issues for outdated crates

## Project Structure

```
src/
├── main.rs                    # Entry point (minimal, delegates to CLI)
├── cli/                       # CLI layer (parsing, display)
├── controllers/               # Workflow orchestration
├── services/                  # Business logic (80%+ coverage target)
├── adapters/                  # External service integration
├── clients/                   # HTTP/API communication
├── domain/                    # Core domain models
├── config/                    # Configuration management
└── bridge.rs                  # Swift FFI bridge definitions

swift/MusicKitBridge/          # Swift/MusicKit integration
tests/unit/                    # Unit tests (pure logic)
tests/integration/             # Integration tests (with mocks)
.github/workflows/             # CI/CD pipelines
```

## Module Structure (Rust 2018+)

**NEVER use `mod.rs` files** - Use modern Rust 2018+ structure:

```
src/
├── services.rs               # Module declaration
└── services/
    ├── music_service.rs      # Implementation
    └── setlist_service.rs    # Implementation
```

In `src/services.rs`:
```rust
pub mod music_service;
pub mod setlist_service;

pub use music_service::MusicService;
pub use setlist_service::SetlistService;
```

## API Requirements

### Setlist.fm API
- **Registration**: https://www.setlist.fm/settings/api (free)
- **Rate limit**: 2 requests/second
- **Auth**: API key in `x-api-key` header
- **Base URL**: `https://api.setlist.fm/rest/1.0/`
- **Env var**: `SETLIST_FM_API_KEY` (store in `.env` file)

### Apple MusicKit
- **Requirements**: macOS 12.0+, active Apple Music subscription
- **Developer**: Apple Developer account ($99/year) for MusicKit identifier
- **Auth**: Native macOS dialog (MusicKit.requestAuthorization)

## Environment Setup

```bash
# 1. Install Xcode Command Line Tools
xcode-select --install

# 2. Verify Swift and Rust
swift --version    # Should be 5.x+
rustc --version    # Should be 1.70+

# 3. Create .env file
echo "SETLIST_FM_API_KEY=your-api-key-here" > .env

# 4. Add dependencies
cargo add tokio --features full
cargo add reqwest --features json
cargo add serde --features derive
cargo add serde_json clap --features derive
cargo add anyhow thiserror dotenvy swift-bridge
cargo add --dev mockall wiremock

# 5. Install coverage tool
cargo install cargo-tarpaulin

# 6. Install dependency management tools
cargo install cargo-outdated cargo-edit
```

## Common Gotchas

1. **Swift compilation errors** - Ensure Xcode Command Line Tools installed: `xcode-select --install`
2. **FFI boundary issues** - Use simple types (primitives, strings) across FFI, not complex Rust types
3. **Business logic in wrong layer** - Move domain logic from controllers/CLI to services
4. **Test coverage below 80%** - Run `cargo tarpaulin --out Html` to identify gaps
5. **Not using traits for dependencies** - All adapters/clients must be behind traits with `#[automock]`
6. **Bypassing CI checks** - Never merge without passing all CI checks
7. **Module structure** - Never create `mod.rs` files, use Rust 2018+ structure
8. **Environment variables** - Always add `.env` to `.gitignore`

## Next Steps

**Phase 1 - Project Setup & FFI Bridge**:
1. Set up GitHub Actions workflows (see [CICD.md](.claude/CICD.md))
2. Set up Codecov integration
3. Configure branch protection rules on GitHub
4. Add all dependencies using `cargo add`
5. Create build.rs for Swift compilation
6. Create minimal Swift module with test function
7. Verify FFI bridge works (call Swift from Rust)
8. Create initial PR to test CI pipeline with Codecov

## Resources

- **Project Plan**: `plans/setlist-playlist-builder-plan.md` (detailed implementation roadmap)
- **Setlist.fm API**: https://api.setlist.fm/docs/1.0/index.html
- **MusicKit**: https://developer.apple.com/documentation/musickit
- **swift-bridge**: https://github.com/chinedufn/swift-bridge
- **Tokio**: https://tokio.rs
- **Clap**: https://docs.rs/clap

---

**For detailed information on specific topics, refer agents to the appropriate file in `.claude/`:**
- Build system & Makefile → [BUILD.md](.claude/BUILD.md)
- Architecture details → [ARCHITECTURE.md](.claude/ARCHITECTURE.md)
- Dependency management → [DEPENDENCIES.md](.claude/DEPENDENCIES.md)
- Testing strategy → [TESTING.md](.claude/TESTING.md)
- CI/CD workflows → [CICD.md](.claude/CICD.md)
