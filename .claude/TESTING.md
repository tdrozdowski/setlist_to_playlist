# Testing Guide

This document describes testing philosophy, practices, and requirements for the Setlist Playlist Builder project.

## Testing Philosophy

**CRITICAL**: Maintain **minimum 80% test coverage** across the codebase.

**Core Principles**:
1. **80% Coverage Minimum**: All code must meet or exceed 80% test coverage
2. **High-Value Testing**: Focus on business logic, algorithms, and workflows
3. **Skip Low-Value Tests**: Don't test simple data objects, binaries, or trivial code
4. **Iterate for Coverage**: Continuously improve tests until target coverage is met
5. **Mock Dependencies**: Use `automock` (via mockall) for Rust trait mocking

## What to Test

### High-Value Tests (Focus Here)

| Component | Coverage Target | Why |
|-----------|----------------|-----|
| **Services** | 90%+ | Contains business logic and domain rules |
| **Controllers** | 85%+ | Orchestrates workflows |
| **Adapters** | 85%+ | External service integration |
| **Algorithms** | 95%+ | Song matching, fuzzy matching, confidence scoring |
| **Domain Models** | 90%+ | Validation logic, transformations |
| **Clients** | 80%+ | API communication |

### Low-Value Tests (Skip These)

❌ Simple data structures with no logic (plain structs with only fields)
❌ Generated code (swift-bridge FFI bindings)
❌ Main.rs binary entry point
❌ Trivial getters/setters
❌ Simple type conversions (`From` impls with no logic)
❌ Configuration structs (unless complex validation)

## Coverage Tools

### Installation

```bash
# Install tarpaulin for coverage reporting
cargo install cargo-tarpaulin
```

### Running Coverage

```bash
# Run tests with coverage report (HTML)
cargo tarpaulin --out Html --output-dir coverage

# View coverage report
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux

# Run with XML output (for CI/Codecov)
cargo tarpaulin --out Xml --output-dir ./coverage

# Check coverage threshold (fail if below 80%)
cargo tarpaulin --fail-under 80

# Exclude files from coverage
cargo tarpaulin --exclude-files 'src/main.rs' 'src/bridge.rs'
```

### Continuous Improvement Process

1. **Run coverage** after each feature implementation
2. **Identify uncovered code** paths using HTML report
3. **Add tests** to cover critical paths
4. **Iterate** until 80%+ coverage achieved
5. **Don't artificially inflate** coverage with low-value tests

## Mockall Integration

### Installation

```bash
cargo add --dev mockall
```

### Pattern for Mockable Traits

**All adapters and clients must be behind traits** for testability.

```rust
// src/adapters/music_adapter.rs
use mockall::automock;

#[automock]
pub trait MusicAdapterTrait {
    fn search(&self, title: &str, artist: &str) -> Result<Vec<Track>>;
    fn create_playlist(&self, name: &str, track_ids: &[TrackId]) -> Result<PlaylistId>;
}

pub struct MusicAdapter {
    bridge: Box<dyn MusicKitBridge>,
}

impl MusicAdapterTrait for MusicAdapter {
    fn search(&self, title: &str, artist: &str) -> Result<Vec<Track>> {
        // Implementation
        let raw_results = self.bridge.search_catalog(title, artist)?;
        Ok(raw_results.into_iter().map(Track::from).collect())
    }
}
```

### Using Mocks in Tests

```rust
// tests/unit/services/music_service_test.rs
use mockall::predicate::*;
use crate::adapters::MockMusicAdapterTrait;

#[test]
fn test_match_songs_with_mocked_adapter() {
    let mut mock_adapter = MockMusicAdapterTrait::new();

    // Set expectations
    mock_adapter
        .expect_search()
        .with(eq("Paranoid Android"), eq("Radiohead"))
        .times(1)
        .returning(|_, _| Ok(vec![
            Track {
                track_id: "123".into(),
                title: "Paranoid Android".into(),
                artist: "Radiohead".into(),
            }
        ]));

    let service = MusicService::new(Box::new(mock_adapter), /* ... */);
    let songs = vec![Song {
        title: "Paranoid Android".into(),
        artist: "Radiohead".into()
    }];

    let matches = service.match_songs(&songs).unwrap();
    assert_eq!(matches.len(), 1);
    assert_eq!(matches[0].track_id, "123");
}
```

### Advanced Mocking

```rust
// Multiple calls with different results
mock_adapter
    .expect_search()
    .times(2)
    .returning(|title, _| {
        if title == "Song 1" {
            Ok(vec![Track { /* ... */ }])
        } else {
            Ok(vec![])
        }
    });

// Verify function was called
mock_adapter
    .expect_search()
    .times(1)
    .return_once(|_, _| Ok(vec![]));

// Match any argument
mock_adapter
    .expect_search()
    .with(always(), eq("Radiohead"))  // Any title, specific artist
    .returning(|_, _| Ok(vec![]));
```

## Unit Tests (Pure Business Logic)

**Test services, algorithms, and domain logic without I/O.**

### Services (Mock Adapters)

```rust
// tests/unit/services/music_service_test.rs
use mockall::predicate::*;

#[test]
fn test_filter_confident_matches() {
    let mock_adapter = MockMusicAdapterTrait::new();
    let mock_matcher = MockFuzzyMatcherTrait::new();

    let service = MusicService::new(
        Box::new(mock_adapter),
        Box::new(mock_matcher),
    );

    let matches = vec![
        MatchResult { confidence: 0.95, track_id: "1".into() },
        MatchResult { confidence: 0.60, track_id: "2".into() },
        MatchResult { confidence: 0.85, track_id: "3".into() },
    ];

    let filtered = service.filter_confident_matches(matches).unwrap();

    assert_eq!(filtered.len(), 2); // Only high-confidence matches
    assert!(filtered.contains(&"1".into()));
    assert!(filtered.contains(&"3".into()));
}

#[test]
fn test_match_songs_calls_adapter() {
    let mut mock_adapter = MockMusicAdapterTrait::new();

    mock_adapter
        .expect_search()
        .with(eq("Song Title"), eq("Artist"))
        .times(1)
        .returning(|_, _| Ok(vec![Track { /* ... */ }]));

    let service = MusicService::new(Box::new(mock_adapter), /* ... */);
    let songs = vec![Song { title: "Song Title".into(), artist: "Artist".into() }];

    let result = service.match_songs(&songs).unwrap();
    assert!(!result.is_empty());
}
```

### Algorithms (Pure Functions)

```rust
// tests/unit/services/matching/fuzzy_matcher_test.rs
#[test]
fn test_fuzzy_match_with_live_suffix() {
    let matcher = FuzzyMatcher::new();
    let song = Song { title: "Paranoid Android".into(), artist: "Radiohead".into() };
    let candidate = Track { title: "Paranoid Android - Live".into(), artist: "Radiohead".into() };

    let score = matcher.calculate_similarity(&song, &candidate);

    assert!(score > 0.9); // Should match despite "Live" suffix
}

#[test]
fn test_fuzzy_match_with_typo() {
    let matcher = FuzzyMatcher::new();
    let song = Song { title: "Paranoid Android".into(), artist: "Radiohead".into() };
    let candidate = Track { title: "Parano1d Android".into(), artist: "Radiohead".into() };

    let score = matcher.calculate_similarity(&song, &candidate);

    assert!(score > 0.8); // Should still match with minor typo
}

#[test]
fn test_exact_match_has_highest_score() {
    let matcher = FuzzyMatcher::new();
    let song = Song { title: "Karma Police".into(), artist: "Radiohead".into() };
    let candidate = Track { title: "Karma Police".into(), artist: "Radiohead".into() };

    let score = matcher.calculate_similarity(&song, &candidate);

    assert_eq!(score, 1.0); // Exact match should be 1.0
}
```

### Domain Models (Validation Logic)

```rust
// tests/unit/domain/setlist_test.rs
#[test]
fn test_setlist_url_parsing() {
    let url = "https://www.setlist.fm/setlist/radiohead/2023/madison-square-garden-123abc.html";
    let id = SetlistId::from_url(url).unwrap();

    assert_eq!(id.value(), "123abc");
}

#[test]
fn test_invalid_setlist_url_returns_error() {
    let url = "https://example.com/invalid";
    let result = SetlistId::from_url(url);

    assert!(result.is_err());
}

#[test]
fn test_song_validation() {
    let song = Song {
        title: "".into(),  // Empty title
        artist: "Radiohead".into(),
    };

    let result = song.validate();

    assert!(result.is_err());
    assert_eq!(result.unwrap_err().to_string(), "Song title cannot be empty");
}
```

### Running Unit Tests

```bash
# Run all unit tests
cargo test --lib

# Run specific test
cargo test test_filter_confident_matches -- --nocapture

# Run tests in specific module
cargo test music_service

# Run tests with output
cargo test -- --nocapture
```

## Integration Tests (With Mocks)

**Test controllers, adapters, and clients with mocked dependencies.**

### Controllers (Mock Services)

```rust
// tests/integration/controllers/playlist_controller_test.rs
use mockall::predicate::*;

#[test]
fn test_create_playlist_workflow() {
    let mut mock_setlist_service = MockSetlistServiceTrait::new();
    let mut mock_music_service = MockMusicServiceTrait::new();

    // Set up expectations
    mock_setlist_service
        .expect_fetch_setlist()
        .with(eq("abc123"))
        .returning(|_| Ok(Setlist { /* ... */ }));

    mock_music_service
        .expect_match_songs()
        .returning(|_| Ok(vec![MatchResult { /* ... */ }]));

    mock_music_service
        .expect_create_playlist()
        .returning(|_, _| Ok(PlaylistId::from("playlist123")));

    let controller = PlaylistController::new(
        Box::new(mock_setlist_service),
        Box::new(mock_music_service),
    );

    let result = controller.create_from_setlist_url(
        "https://www.setlist.fm/setlist/.../abc123.html",
        Some("Test Playlist")
    ).unwrap();

    assert_eq!(result.playlist_name, "Test Playlist");
    assert!(result.tracks_added > 0);
}
```

### Adapters (Mock Clients)

```rust
// tests/integration/adapters/music_adapter_test.rs
#[test]
fn test_search_returns_domain_models() {
    let mut mock_bridge = MockMusicKitBridge::new();

    mock_bridge
        .expect_search_catalog()
        .returning(|_, _| vec![
            RawSearchResult {
                id: "123".into(),
                name: "Song Title".into(),
                artist_name: "Artist".into(),
            }
        ]);

    let adapter = MusicAdapter::new(Box::new(mock_bridge));
    let results = adapter.search("Song Title", "Artist").unwrap();

    assert!(!results.is_empty());
    assert_eq!(results[0].title, "Song Title");
    assert_eq!(results[0].artist, "Artist");
}
```

### Clients (Mock HTTP with wiremock)

```bash
cargo add --dev wiremock
```

```rust
// tests/integration/clients/setlist_client_test.rs
use wiremock::{MockServer, Mock, ResponseTemplate};
use wiremock::matchers::{method, path};

#[tokio::test]
async fn test_fetch_setlist() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/setlist/12345"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": "12345",
            "artist": { "name": "Radiohead" },
            "venue": { "name": "Madison Square Garden" }
        })))
        .mount(&mock_server)
        .await;

    let client = SetlistClient::new(&mock_server.uri());
    let setlist = client.fetch_setlist("12345").await.unwrap();

    assert_eq!(setlist.artist.name, "Radiohead");
    assert_eq!(setlist.venue.name, "Madison Square Garden");
}

#[tokio::test]
async fn test_fetch_setlist_not_found() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/setlist/invalid"))
        .respond_with(ResponseTemplate::new(404))
        .mount(&mock_server)
        .await;

    let client = SetlistClient::new(&mock_server.uri());
    let result = client.fetch_setlist("invalid").await;

    assert!(result.is_err());
}
```

### Running Integration Tests

```bash
# Run all integration tests
cargo test --test '*'

# Run specific integration test file
cargo test --test playlist_controller_test

# Run all tests (unit + integration)
cargo test
```

## Test Organization

### Directory Structure

```
tests/
├── unit/                            # Unit tests (pure business logic)
│   ├── services/
│   │   ├── music_service_test.rs
│   │   ├── setlist_service_test.rs
│   │   └── matching/
│   │       ├── fuzzy_matcher_test.rs
│   │       └── confidence_test.rs
│   └── domain/
│       ├── setlist_test.rs
│       └── song_test.rs
│
└── integration/                     # Integration tests (with mocks)
    ├── controllers/
    │   └── playlist_controller_test.rs
    ├── adapters/
    │   ├── music_adapter_test.rs
    │   └── setlist_adapter_test.rs
    └── clients/
        └── setlist_client_test.rs
```

### Test Naming Conventions

- **Unit tests**: `test_<function_name>_<scenario>`
  - Example: `test_filter_confident_matches_removes_low_confidence`
- **Integration tests**: `test_<workflow>_<scenario>`
  - Example: `test_create_playlist_workflow_success`

## Swift Tests

### Testing Swift MusicKit Bridge

Swift tests should be written in Xcode:

```swift
// swift/Tests/MusicKitBridgeTests.swift
import XCTest
@testable import MusicKitBridge

class MusicKitBridgeTests: XCTestCase {
    func testSearchCatalog() {
        let results = search_catalog("Paranoid Android", artist: "Radiohead")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results[0].title.contains("Paranoid Android"))
    }

    func testAuthorizationStatus() {
        let status = check_authorization_status()
        XCTAssertNotNil(status)
    }
}
```

**Run Swift tests**:
```bash
# In Xcode: Cmd+U
# Or from command line:
xcodebuild test -scheme MusicKitBridge
```

## Continuous Integration

**CI enforces 80% coverage** on every PR. See [CICD.md](CICD.md) for details.

```yaml
# .github/workflows/pr.yml (excerpt)
- name: Run coverage (80% minimum required)
  run: cargo tarpaulin --fail-under 80 --out Xml --output-dir ./coverage
```

## Best Practices

### 1. Test One Thing Per Test

❌ **Bad**:
```rust
#[test]
fn test_everything() {
    // Tests multiple behaviors
    assert!(service.match_songs(&songs).is_ok());
    assert!(service.filter_matches(matches).is_ok());
    assert!(service.create_playlist(name, tracks).is_ok());
}
```

✅ **Good**:
```rust
#[test]
fn test_match_songs_returns_results() {
    // Tests one specific behavior
    let results = service.match_songs(&songs).unwrap();
    assert!(!results.is_empty());
}

#[test]
fn test_filter_matches_removes_low_confidence() {
    let filtered = service.filter_matches(matches).unwrap();
    assert!(filtered.iter().all(|m| m.confidence > 0.8));
}
```

### 2. Use Descriptive Assertions

❌ **Bad**:
```rust
assert!(result.is_ok());
```

✅ **Good**:
```rust
assert!(result.is_ok(), "Expected search to succeed but got error: {:?}", result.err());
```

### 3. Test Edge Cases

```rust
#[test]
fn test_empty_song_list() {
    let results = service.match_songs(&[]).unwrap();
    assert_eq!(results.len(), 0);
}

#[test]
fn test_null_artist() {
    let song = Song { title: "Title".into(), artist: "".into() };
    let result = service.match_songs(&[song]);
    assert!(result.is_err());
}
```

### 4. Test Error Paths

```rust
#[test]
fn test_adapter_error_propagates() {
    let mut mock_adapter = MockMusicAdapterTrait::new();
    mock_adapter
        .expect_search()
        .returning(|_, _| Err(anyhow!("API error")));

    let service = MusicService::new(Box::new(mock_adapter));
    let result = service.match_songs(&songs);

    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("API error"));
}
```

## Troubleshooting

### Coverage Below 80%

1. Run HTML coverage report: `cargo tarpaulin --out Html`
2. Open `coverage/index.html` in browser
3. Identify uncovered lines (shown in red)
4. Add tests for uncovered code paths
5. Focus on services, algorithms, domain logic
6. Skip trivial code (getters, simple From impls)

### Mock Not Called

```rust
// Ensure mock expectations are met
let mut mock = MockTrait::new();
mock.expect_function()
    .times(1)  // Explicitly set expected call count
    .returning(|| Ok(()));

// Test code that should call mock

// Mock will panic if not called exactly once
```

### Async Tests Hanging

```rust
// Use #[tokio::test] for async tests
#[tokio::test]
async fn test_async_function() {
    let result = async_function().await;
    assert!(result.is_ok());
}
```

### Test Fails in CI But Passes Locally

- Check for environment-specific behavior
- Ensure tests don't depend on local files
- Use mocks for all external dependencies
- Check for race conditions in async tests
