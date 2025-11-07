# Dependency Management Guide

This document describes dependency management policies and practices for the Setlist Playlist Builder project.

## Core Principle

**CRITICAL**: Always use the **latest stable versions** of all dependencies.

## Version Policy

- Use `cargo add <crate>` to automatically get latest stable version
- Avoid pinning to specific versions unless required for compatibility
- Regularly run `cargo update` to get latest compatible versions
- Check for breaking changes when updating major versions
- Run weekly dependency checks via CI

## Core Pillar Crates

**CRITICAL**: New dependencies MUST be compatible with these core crates:

1. **Tokio** (async runtime) - All async operations use Tokio (latest stable)
2. **Reqwest** (HTTP client) - All HTTP requests use reqwest with tokio runtime (latest stable)
3. **swift-bridge** (FFI) - Swift-Rust communication layer (latest stable)

## Required Dependencies

### Production Dependencies

```toml
[dependencies]
# Async runtime (REQUIRED: tokio with full features)
tokio = { version = "1.x", features = ["full"] }

# HTTP client (REQUIRED: reqwest with json)
reqwest = { version = "0.x", features = ["json"] }

# Serialization (REQUIRED: serde with derive)
serde = { version = "1.x", features = ["derive"] }
serde_json = "1.x"

# CLI parsing
clap = { version = "4.x", features = ["derive"] }

# Error handling
anyhow = "1.x"
thiserror = "2.x"

# Environment variables
dotenvy = "0.x"

# FFI bridge
swift-bridge = "0.x"
```

### Development Dependencies

```toml
[dev-dependencies]
# Testing
mockall = "0.x"      # Trait mocking with #[automock]
wiremock = "0.x"     # HTTP mocking for client tests
```

**Note**: Versions shown are illustrative. Always use `cargo add` to get the actual latest stable version.

## Adding Dependencies

### Quick Start

```bash
# Core async and HTTP
cargo add tokio --features full
cargo add reqwest --features json

# Serialization
cargo add serde --features derive
cargo add serde_json

# CLI
cargo add clap --features derive

# Error handling
cargo add anyhow thiserror

# Environment
cargo add dotenvy

# FFI
cargo add swift-bridge

# Testing (dev dependencies)
cargo add --dev mockall wiremock
```

### Commands

```bash
# Add production dependency (gets latest stable)
cargo add <crate-name>

# Add with features
cargo add <crate-name> --features <feature1>,<feature2>

# Add dev dependency
cargo add --dev <crate-name>

# Update all dependencies to latest compatible versions
cargo update

# Check for outdated dependencies
cargo outdated  # Requires: cargo install cargo-outdated

# Update Cargo.toml to latest versions (breaking changes)
cargo upgrade   # Requires: cargo install cargo-edit
```

## Specific Use Cases

### Async Runtime
**MUST use `tokio`** (latest stable) for all async operations.

```bash
cargo add tokio --features full
```

**Required features**: `["full"]` for complete feature set

### HTTP Client
**MUST use `reqwest`** (latest stable) with tokio runtime.

```bash
cargo add reqwest --features json
```

**Required features**: `["json"]` for automatic JSON (de)serialization

### JSON Parsing
Use `serde` + `serde_json` (standard in Rust ecosystem, latest stable).

```bash
cargo add serde --features derive
cargo add serde_json
```

**Required features**: `["derive"]` for derive macros

### CLI
Use `clap` (latest stable) with derive feature.

```bash
cargo add clap --features derive
```

**Required features**: `["derive"]` for ergonomic command-line parsing

### Error Handling
- Use `anyhow` (latest stable) for application errors (flexible)
- Use `thiserror` (latest stable) for library errors (structured)

```bash
cargo add anyhow thiserror
```

### Environment Variables
Use `dotenvy` (latest stable, modern fork of `dotenv`).

```bash
cargo add dotenvy
```

Load `.env` file at startup in main.rs:
```rust
use dotenvy::dotenv;

fn main() {
    dotenv().ok(); // Load .env file
    // ...
}
```

### Testing - Mocking
Use `mockall` (latest stable) for trait mocking with `#[automock]`.

```bash
cargo add --dev mockall
```

**Pattern**:
```rust
use mockall::automock;

#[automock]
pub trait MusicAdapterTrait {
    fn search(&self, title: &str, artist: &str) -> Result<Vec<Track>>;
}
```

### Testing - HTTP Mocking
Use `wiremock` (latest stable) for HTTP mocking.

```bash
cargo add --dev wiremock
```

**Pattern**:
```rust
use wiremock::{MockServer, Mock, ResponseTemplate};

#[tokio::test]
async fn test_fetch_setlist() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/setlist/12345"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "artist": { "name": "Radiohead" }
        })))
        .mount(&mock_server)
        .await;

    let client = SetlistClient::new(&mock_server.uri());
    let setlist = client.fetch_setlist("12345").await.unwrap();
    assert_eq!(setlist.artist.name, "Radiohead");
}
```

### FFI Bridge
Use `swift-bridge` (latest stable).

```bash
cargo add swift-bridge
```

**Note**: swift-bridge requires build.rs configuration.

## Evaluation Criteria

Before adding a new crate, verify:

### 1. Active Maintenance
- **Always use latest stable version** from crates.io
- Updated within last 6 months (preferred)
- Active GitHub repository with recent commits
- Supports recent Rust stable (1.70+)
- Use `cargo add` to automatically get latest version

**Check maintenance**:
```bash
# Check crate info (shows last update date)
cargo search <crate-name> --limit 1

# View on crates.io
open https://crates.io/crates/<crate-name>
```

### 2. Architecture Compatibility
- **Async compatibility**: Must work with Tokio (latest stable)
- **HTTP client**: Must work with reqwest (latest stable) if HTTP-related
- **FFI compatibility**: Must be FFI-safe if crossing Rust-Swift boundary
- **macOS compatibility**: Must support macOS targets

### 3. Quality Indicators
- Well-documented on docs.rs
- Provides usage examples
- Reasonable dependency tree (check with `cargo tree -p <crate>`)
- Compatible license (MIT, Apache-2.0, BSD)

### 4. No Conflicts
- Does not require different async runtime (async-std, smol)
- Does not conflict with existing dependencies
- Does not duplicate functionality we already have

## Keeping Dependencies Updated

### Manual Updates

```bash
# Update to latest compatible versions (respects semver)
cargo update

# Check for newer versions (including breaking changes)
cargo outdated

# Update Cargo.toml to latest versions
cargo upgrade

# Verify everything still builds and tests pass
cargo test
cargo clippy
```

### Automated Updates

**CI runs weekly dependency checks** (`.github/workflows/dependencies.yml`):
- Checks for outdated dependencies every Sunday
- Creates GitHub issue if dependencies are outdated
- Issue prompts maintainers to run `cargo upgrade` and test

**Best Practice**: Update dependencies at the start of each development session or weekly.

## Dependency Tree Management

### Checking Dependencies

```bash
# View direct dependencies
cargo tree --depth 1

# View full dependency tree
cargo tree

# View dependencies of specific crate
cargo tree -p <crate-name>

# Identify duplicate versions
cargo tree --duplicates
```

### Avoiding Dependency Hell

1. **Use latest stable versions** - Reduces version conflicts
2. **Minimal features** - Only enable features you need
3. **Check tree before adding** - Run `cargo tree -p <new-crate>` to see transitive deps
4. **Update regularly** - Prevents falling far behind

## Red Flags - Do NOT Add Crates That:

❌ Require a different async runtime (async-std, smol)
❌ Haven't been updated in >2 years (unless extremely stable)
❌ Conflict with existing core dependencies (different HTTP client, different datetime library)
❌ Have security advisories (check `cargo audit`)
❌ Are pre-1.0 with breaking changes in patch versions
❌ Duplicate functionality we already have (multiple HTTP clients, multiple JSON parsers)

## Security

### Audit Dependencies

```bash
# Install cargo-audit
cargo install cargo-audit

# Check for known vulnerabilities
cargo audit

# Check for advisories in dependencies
cargo audit --deny warnings
```

**CI runs security audits** on every PR (optional, can add to `.github/workflows/pr.yml`).

## Documentation

### Commenting Dependencies in Cargo.toml

**Good practice**: Add comments explaining why crates were added.

```toml
[dependencies]
# Async runtime - required for all async operations
tokio = { version = "1.43", features = ["full"] }

# HTTP client - required for setlist.fm API calls
reqwest = { version = "0.12", features = ["json"] }

# Song matching - Levenshtein distance for fuzzy matching
# Last updated: 2025-01 (actively maintained)
strsim = "0.11"
```

## Troubleshooting

### Build Fails After Adding Dependency

1. **Check compatibility**: Verify crate works with Tokio/reqwest
2. **Check features**: Some crates require specific feature flags
3. **Check MSRV**: Ensure crate supports recent Rust version
4. **Clean build**: Run `cargo clean && cargo build`

### Dependency Conflicts

1. **Check versions**: Run `cargo tree --duplicates`
2. **Update all**: Run `cargo update` to resolve conflicts
3. **Check compatibility**: Some crates may be incompatible

### CI Fails with Dependency Errors

1. **Check Cargo.lock**: Ensure Cargo.lock is committed
2. **Check cache**: CI caches may be stale, clear cache
3. **Local test**: Reproduce locally with `cargo clean && cargo build`

## Example: Full Initial Setup

```bash
# Create project
cargo new setlist_to_playlist
cd setlist_to_playlist

# Add all core dependencies
cargo add tokio --features full
cargo add reqwest --features json
cargo add serde --features derive
cargo add serde_json
cargo add clap --features derive
cargo add anyhow
cargo add thiserror
cargo add dotenvy
cargo add swift-bridge

# Add dev dependencies
cargo add --dev mockall
cargo add --dev wiremock

# Install tools
cargo install cargo-tarpaulin      # Coverage
cargo install cargo-outdated        # Check outdated deps
cargo install cargo-edit            # cargo upgrade command
cargo install cargo-audit           # Security audit

# Verify build
cargo build

# Check dependency tree
cargo tree --depth 1

# Run tests
cargo test
```
