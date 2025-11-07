# Architecture Guide

This document describes the layered architecture and design patterns for the Setlist Playlist Builder project.

## Architecture Philosophy

**CRITICAL**: This project follows strict layered architecture with **NO business logic in UI/CLI layers**.

**Core Principles**:
1. **Separation of Concerns**: Each layer has a single, well-defined responsibility
2. **Testability**: Business logic isolated from I/O makes unit testing straightforward
3. **Maintainability**: Changes to one layer don't cascade to others
4. **Extensibility**: Easy to add new adapters (e.g., Spotify support) without touching business logic

**Prohibited**:
- ❌ Business logic in CLI handlers (main.rs)
- ❌ Direct API calls from controllers
- ❌ Database/external service logic in service layer
- ❌ Domain logic in adapters/clients

**Pattern Usage**:
- **Controllers**: Orchestrate use cases, coordinate between services
- **Services**: Business logic, domain rules, orchestration
- **Repositories**: Data access abstraction (if we add persistence)
- **Adapters**: External service integration (Apple Music, setlist.fm)
- **Clients**: Low-level HTTP/API communication

## High-Level Flow

```
CLI Layer (presentation)
    ↓
Controller (orchestration)
    ↓
Service Layer (business logic)
    ↓ ↓
SetlistAdapter    MusicAdapter
    ↓                 ↓
SetlistClient    MusicKitBridge (Swift FFI)
    ↓                 ↓
setlist.fm API    Apple Music
```

## Detailed Layer Architecture

### 1. CLI Layer (`src/cli/`)
**Responsibility**: Parse arguments, display output, handle user interaction
**No Business Logic**: Only coordinates calls to controllers

```
src/cli/
├── commands.rs      # Command definitions (clap)
├── handlers.rs      # Command handlers (delegate to controllers)
└── output.rs        # Formatting and display logic
```

### 2. Controller Layer (`src/controllers/`)
**Responsibility**: Orchestrate use cases, coordinate between services
**Example**: PlaylistController coordinates SetlistService and MusicService

```
src/controllers/
├── playlist_controller.rs  # Orchestrates playlist creation workflow
└── search_controller.rs    # Orchestrates setlist search workflow
```

### 3. Service Layer (`src/services/`)
**Responsibility**: Business logic, domain rules, song matching algorithms
**Independent of I/O**: Services accept domain objects, return domain results

```
src/services/
├── setlist_service.rs    # Setlist business logic
├── music_service.rs      # Music search and matching business logic
├── matching.rs           # Matching submodule declaration
└── matching/
    ├── fuzzy_matcher.rs  # Fuzzy matching algorithms
    ├── confidence.rs     # Match confidence scoring
    └── strategies.rs     # Match strategy implementations
```

### 4. Adapter Layer (`src/adapters/`)
**Responsibility**: Translate between domain models and external services
**Adapters wrap clients**: Provide domain-friendly interface over raw API clients

```
src/adapters/
├── setlist_adapter.rs        # Wraps SetlistClient, returns domain models
└── music_adapter.rs          # Wraps MusicKitBridge, returns domain models
```

### 5. Client Layer (`src/clients/`)
**Responsibility**: Low-level HTTP/API communication, request/response handling
**No business logic**: Just API calls and serialization

```
src/clients/
├── setlist_client.rs    # HTTP client for setlist.fm REST API
└── models.rs            # API response DTOs (Data Transfer Objects)
```

### 6. Domain Layer (`src/domain/`)
**Responsibility**: Core domain models, shared across layers
**Pure data structures**: No I/O, no external dependencies

```
src/domain/
├── setlist.rs        # Setlist domain models
├── song.rs           # Song domain models
├── playlist.rs       # Playlist domain models
└── match_result.rs   # Song match results
```

### 7. Swift FFI Bridge (`swift/MusicKitBridge/`)
**Responsibility**: Native MusicKit integration (acts as a client)

```
swift/MusicKitBridge/
├── Authorization.swift      # MusicKit permission handling
├── CatalogSearch.swift      # Apple Music catalog search
├── PlaylistCreator.swift    # Playlist creation and track management
└── Models.swift             # Swift-side models for FFI
```

### 8. Config Layer (`src/config/`)
**Responsibility**: Configuration loading and validation

```
src/config/
├── env_config.rs       # Environment variable loading
└── user_config.rs      # User preferences (TOML)
```

## Example: Playlist Creation Flow

```rust
// 1. CLI Layer (src/cli/handlers.rs)
pub fn handle_create_playlist(url: String, name: Option<String>) -> Result<()> {
    let controller = PlaylistController::new();
    let result = controller.create_from_setlist_url(&url, name.as_deref())?;

    // Display output (no business logic)
    println!("Created playlist: {}", result.playlist_name);
    println!("Added {} tracks", result.tracks_added);
    Ok(())
}

// 2. Controller Layer (src/controllers/playlist_controller.rs)
pub struct PlaylistController {
    setlist_service: SetlistService,
    music_service: MusicService,
}

impl PlaylistController {
    pub fn create_from_setlist_url(&self, url: &str, name: Option<&str>) -> Result<PlaylistResult> {
        // Orchestrate the workflow (no business logic)
        let setlist_id = parse_setlist_url(url)?;
        let setlist = self.setlist_service.fetch_setlist(setlist_id)?;
        let songs = self.setlist_service.extract_songs(&setlist)?;

        let matches = self.music_service.match_songs(&songs)?;
        let track_ids = self.music_service.filter_confident_matches(matches)?;

        let playlist_name = name.unwrap_or(&generate_playlist_name(&setlist));
        let playlist = self.music_service.create_playlist(playlist_name, &track_ids)?;

        Ok(PlaylistResult { /* ... */ })
    }
}

// 3. Service Layer (src/services/music_service.rs)
pub struct MusicService {
    music_adapter: Box<dyn MusicAdapterTrait>,
    matcher: Box<dyn FuzzyMatcherTrait>,
}

impl MusicService {
    pub fn match_songs(&self, songs: &[Song]) -> Result<Vec<MatchResult>> {
        // Business logic: matching strategy, confidence thresholds
        songs.iter()
            .map(|song| {
                let results = self.music_adapter.search(&song.title, &song.artist)?;
                let best_match = self.matcher.find_best_match(song, &results)?;
                Ok(best_match)
            })
            .collect()
    }

    pub fn filter_confident_matches(&self, matches: Vec<MatchResult>) -> Result<Vec<TrackId>> {
        // Business logic: confidence threshold filtering
        Ok(matches.into_iter()
            .filter(|m| m.confidence > 0.8)
            .map(|m| m.track_id)
            .collect())
    }
}

// 4. Adapter Layer (src/adapters/music_adapter.rs)
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
        // Translate domain request to FFI call, convert response to domain model
        let raw_results = self.bridge.search_catalog(title, artist)?;
        Ok(raw_results.into_iter().map(Track::from).collect())
    }
}

// 5. FFI Bridge (defined in src/bridge.rs, implemented in Swift)
#[swift_bridge::bridge]
mod ffi {
    extern "Swift" {
        fn search_catalog(title: &str, artist: &str) -> Vec<RawSearchResult>;
    }
}
```

## Layered Architecture Rules

**CRITICAL Rules for Maintaining Clean Architecture**:

### 1. Dependency Direction
Dependencies flow inward:
```
CLI → Controllers → Services → Adapters → Clients
                 → Domain    ←
```
- Inner layers NEVER depend on outer layers
- Domain layer has NO external dependencies
- Services depend on adapter **traits**, not implementations

### 2. Layer Responsibilities

| Layer | Responsibility | Can Depend On | Cannot Depend On |
|-------|---------------|---------------|------------------|
| CLI | User I/O, parsing, display | Controllers | Services, Adapters, Clients |
| Controllers | Orchestrate workflows | Services (via traits) | Adapters, Clients |
| Services | Business logic, domain rules | Adapters (via traits), Domain | Clients, Controllers, CLI |
| Adapters | External service integration | Clients (via traits), Domain | Services, Controllers |
| Clients | Raw API calls | Domain (for DTOs) | Everything else |
| Domain | Data structures, validation | Nothing | Everything |

### 3. Testing Strategy by Layer

| Layer | Testing Approach | Coverage Target |
|-------|-----------------|-----------------|
| CLI | Integration tests only | Low priority |
| Controllers | Mock services | 85%+ |
| Services | Mock adapters, test business logic | 90%+ |
| Adapters | Mock clients | 85%+ |
| Clients | Mock HTTP (wiremock) | 80%+ |
| Domain | Test validation logic | 90%+ |
| Algorithms | Comprehensive unit tests | 95%+ |

### 4. When to Use Each Pattern

**Controller**:
- When orchestrating multiple services for a use case
- When coordinating a multi-step workflow
- Example: `PlaylistController` coordinates `SetlistService` and `MusicService`

**Service**:
- When implementing business logic or domain rules
- When applying algorithms (fuzzy matching, confidence scoring)
- Example: `MusicService` contains song matching logic

**Repository**:
- When abstracting data persistence (not needed yet)
- Future: If we add local caching or database

**Adapter**:
- When integrating external services (setlist.fm, Apple Music)
- When translating between domain models and external APIs
- Example: `MusicAdapter` wraps MusicKitBridge, returns domain models

**Client**:
- When making raw API calls (HTTP, FFI)
- When handling low-level request/response logic
- Example: `SetlistClient` makes HTTP requests to setlist.fm API

## Module Structure (Rust 2018+)

**CRITICAL**: Use modern Rust module structure. **NEVER create `mod.rs` files**.

### ❌ NEVER DO THIS (Old Rust 2015 Style):
```
src/
├── services/
│   ├── mod.rs          ❌ WRONG - Do not create this!
│   ├── music_service.rs
│   └── setlist_service.rs
```

### ✅ ALWAYS DO THIS (Modern Rust 2018+ Style):
```
src/
├── services.rs         ✅ Module declaration file
├── services/
│   ├── music_service.rs   ✅ Implementation files
│   └── setlist_service.rs ✅ Implementation files
```

**How it works:**
1. **Create a module file** at the parent level: `src/services.rs`
2. **Declare submodules** in that file:
   ```rust
   // src/services.rs
   pub mod music_service;
   pub mod setlist_service;

   // Re-export commonly used items
   pub use music_service::MusicService;
   pub use setlist_service::SetlistService;
   ```
3. **Create implementation files** in the directory: `src/services/*.rs`

**When Adding New Modules:**
1. Create `src/module_name.rs` for the module declaration
2. Create `src/module_name/` directory for submodules
3. Add submodule files as `src/module_name/submodule.rs`
4. Declare submodules in `src/module_name.rs` with `pub mod submodule;`
5. **NEVER create `src/module_name/mod.rs`**

### Example: Nested Modules

For services with a matching submodule:
```
src/
├── services.rs                    # Declares services module
├── services/
│   ├── setlist_service.rs
│   ├── music_service.rs
│   ├── matching.rs                # Declares matching submodule
│   └── matching/
│       ├── fuzzy_matcher.rs
│       ├── confidence.rs
│       └── strategies.rs
```

In `src/services/matching.rs`:
```rust
pub mod fuzzy_matcher;
pub mod confidence;
pub mod strategies;

pub use fuzzy_matcher::FuzzyMatcher;
pub use confidence::ConfidenceCalculator;
```

## Swift FFI Interface Design

### Key Bridge Functions

**Authorization**:
```rust
// Rust side (src/bridge.rs)
pub fn request_music_authorization() -> Result<AuthorizationStatus, String>;
pub fn check_authorization_status() -> AuthorizationStatus;
```

**Catalog Search**:
```rust
// Rust side
pub struct SearchResult {
    pub track_id: String,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub duration_ms: u32,
}

pub fn search_catalog(
    song_title: &str,
    artist: &str,
) -> Result<Vec<SearchResult>, String>;
```

**Playlist Creation**:
```rust
// Rust side
pub fn create_playlist(
    name: &str,
    description: Option<&str>,
    track_ids: Vec<String>,
) -> Result<String, String>; // Returns playlist ID
```

### FFI Best Practices

**Types that cross FFI boundary**:
- ✅ Primitives: `i32`, `u32`, `f64`, `bool`
- ✅ Strings: `&str` (from Rust), `String` (to Rust)
- ✅ Vectors: `Vec<T>` where T is FFI-safe
- ✅ Simple structs with FFI-safe fields
- ❌ Complex types: `HashMap`, `Option<Box<dyn Trait>>`, etc.

**Error Handling**:
- Swift errors → String descriptions → Rust
- Rust uses `Result<T, String>` for FFI functions
- Internal Rust code uses `anyhow::Result` or `thiserror`

**Async Functions**:
- swift-bridge handles async bridging automatically
- Swift async functions can be called from Rust
- Use tokio runtime on Rust side

## Key Architecture Decisions

### Why Layered Architecture?
- **Testability**: Business logic can be tested without external dependencies
- **Maintainability**: Changes to external APIs don't affect business logic
- **Extensibility**: Easy to add new adapters (Spotify, Tidal, etc.)
- **Clarity**: Clear separation of concerns makes code easier to understand

### Why Traits for Dependencies?
- **Mockability**: Services can be tested with mock adapters
- **Flexibility**: Easy to swap implementations
- **Dependency Inversion**: Depend on abstractions, not concretions

### Why Domain Layer?
- **Shared Models**: Domain models used across all layers
- **Business Rules**: Validation and business rules in domain objects
- **Independence**: Domain is independent of external concerns

### Why Adapters vs Direct Client Usage?
- **Translation**: Adapters translate external API models to domain models
- **Isolation**: Services don't know about external API details
- **Testability**: Easier to test services with mocked adapters

## Common Mistakes to Avoid

1. **Business logic in CLI handlers** - Move to services
2. **Direct API calls from controllers** - Use adapters
3. **Domain models depending on external crates** - Keep domain pure
4. **Services depending on concrete adapter types** - Use traits
5. **Adapters containing business logic** - Move to services
6. **Controllers containing domain logic** - Move to services
7. **Using `mod.rs` files** - Use Rust 2018+ module structure
8. **Complex types across FFI** - Use simple types or serialization
