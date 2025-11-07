# Setlist to Playlist Builder

[![CI](https://github.com/tdrozdowski/setlist_to_playlist/actions/workflows/pr.yml/badge.svg)](https://github.com/tdrozdowski/setlist_to_playlist/actions/workflows/pr.yml)
[![codecov](https://codecov.io/gh/tdrozdowski/setlist_to_playlist/branch/master/graph/badge.svg)](https://codecov.io/gh/tdrozdowski/setlist_to_playlist)

Convert concert setlists into Apple Music playlists automatically.

## Overview

This Rust CLI tool fetches setlists from setlist.fm and creates corresponding Apple Music playlists using MusicKit integration via Rust-Swift FFI bridge.

## Features

- 🎸 Fetch concert setlists from setlist.fm API
- 🎵 Search and match tracks in Apple Music catalog
- 📝 Create playlists with matched songs
- 🎯 Fuzzy matching for accurate track resolution
- ⚡ Fast, async operations with Tokio

## Prerequisites

- macOS 12.0+ (Monterey or later)
- Rust 1.70+ (latest stable recommended)
- Swift toolchain (comes with Xcode)
- Apple Music subscription
- setlist.fm API key ([get one here](https://www.setlist.fm/settings/api))

## Installation

```bash
# Clone the repository
git clone https://github.com/tdrozdowski/setlist_to_playlist.git
cd setlist_to_playlist

# Copy environment template
cp .env.example .env

# Add your setlist.fm API key to .env
# SETLIST_FM_API_KEY=your-api-key-here

# Build the project
make build

# Or using cargo directly
cargo build --release
```

## Usage

```bash
# Fetch a setlist and create playlist
setlist_to_playlist --artist "Pearl Jam" --date "2024-10-15" --venue "Seattle"

# Search for specific concert
setlist_to_playlist --setlist-id "abc123"
```

## Development

See [CLAUDE.md](CLAUDE.md) for comprehensive development documentation.

### Quick Start

```bash
# First-time setup (installs tools, creates .env)
make dev

# Run all CI checks locally
make ci-check

# Build project
make build

# Run tests
make test

# Generate and view coverage
make coverage-open
```

### Project Structure

```
.
├── src/
│   ├── main.rs           # CLI entry point
│   └── bridge.rs         # Rust-Swift FFI bridge
├── swift/
│   └── Sources/
│       └── MusicKitBridge.swift  # MusicKit integration
├── .claude/              # Detailed documentation
│   ├── ARCHITECTURE.md   # Layered architecture guide
│   ├── BUILD.md         # Build system details
│   ├── CICD.md          # CI/CD workflows
│   ├── DEPENDENCIES.md  # Dependency management
│   └── TESTING.md       # Testing strategy
└── tests/               # Integration tests
```

## Architecture

This project follows a strict **8-layer architecture** designed for testability and maintainability:

1. **CLI Layer** - Command-line interface (clap)
2. **Controller Layer** - Request coordination
3. **Service Layer** - Business logic (90% test coverage target)
4. **Adapter Layer** - External service integration (85% coverage)
5. **Client Layer** - HTTP/API clients
6. **Domain Layer** - Core types and algorithms (90% coverage)
7. **FFI Layer** - Rust-Swift bridge
8. **External Layer** - MusicKit (Swift), setlist.fm API

See [.claude/ARCHITECTURE.md](.claude/ARCHITECTURE.md) for detailed design patterns.

## Testing

Minimum **80% code coverage** enforced by CI with layer-specific targets:

- Services: 90%+
- Algorithms: 95%+
- Adapters: 85%+
- Domain: 90%+

```bash
# Run tests
make test

# Generate coverage report
make coverage

# View coverage in browser
make coverage-open
```

## CI/CD

GitHub Actions workflows:

- **PR Workflow** - Format, clippy, tests, coverage on every PR
- **Release Workflow** - Build and release binary on merge to master
- **Dependencies Workflow** - Weekly outdated dependency checks

All PRs must pass:
- ✅ `cargo fmt --check`
- ✅ `cargo clippy -- -D warnings`
- ✅ `cargo test`
- ✅ 80% minimum test coverage

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following our architecture guidelines
4. Run local CI checks (`make ci-check`)
5. Commit your changes
6. Push to your branch
7. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [setlist.fm](https://www.setlist.fm) - Concert setlist data
- [swift-bridge](https://github.com/chinedufn/swift-bridge) - Rust-Swift FFI bridge
- [MusicKit](https://developer.apple.com/musickit/) - Apple Music integration

---

Built with ❤️ using Rust and Swift
