# Setlist Playlist Builder - Project Plan

## Overview
A macOS native application that fetches concert setlists from setlist.fm and automatically creates Apple Music playlists using the native MusicKit framework via Swift-Rust interop.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Rust Application                          │
│                                                              │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  Setlist.fm      │────────▶│   Song Matching  │         │
│  │  API Client      │         │   & Deduplication│         │
│  └──────────────────┘         └──────────────────┘         │
│           │                             │                   │
│           │                             ▼                   │
│           │                    ┌──────────────────┐         │
│           │                    │  Swift FFI       │         │
│           │                    │  Bridge Layer    │         │
│           │                    └──────────────────┘         │
└───────────┼────────────────────────────┼───────────────────┘
            │                             │
            ▼                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Swift Module                              │
│                                                              │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  Apple Music     │────────▶│   MusicKit       │         │
│  │  Search          │         │   Playlist API   │         │
│  └──────────────────┘         └──────────────────┘         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Apple Music    │
                    │   User Library   │
                    └──────────────────┘
```

## Technology Stack

### Rust Components
- **Runtime**: Tokio (async)
- **HTTP Client**: reqwest (for setlist.fm API)
- **JSON**: serde + serde_json
- **Swift Bridge**: swift-bridge (0.1.57) or swift-rs (1.0.7)
- **CLI**: clap (for command-line interface)
- **Error Handling**: anyhow or thiserror

### Swift Components
- **MusicKit**: Native framework for Apple Music integration
- **StoreKit**: For subscription status checks
- **Foundation**: Core Swift libraries

### External APIs
- **Setlist.fm API**: Fetch concert setlists (requires free API key)
- **MusicKit**: Search catalog, create playlists, add tracks

## Project Structure

```
setlist-playlist-builder/
├── Cargo.toml
├── build.rs                    # Swift compilation setup
├── src/
│   ├── main.rs                # CLI entry point
│   ├── setlist/
│   │   ├── client.rs          # Setlist.fm API client
│   │   └── models.rs          # Setlist data structures
│   ├── music/
│   │   ├── bridge.rs          # Swift FFI bridge definitions
│   │   └── matcher.rs         # Song matching logic
│   └── config.rs              # API keys, configuration
├── swift/
│   ├── MusicKitBridge/
│   │   ├── PlaylistCreator.swift
│   │   ├── CatalogSearch.swift
│   │   └── Authorization.swift
│   └── include/
│       └── bridge.h           # C header for FFI
├── tests/
│   └── integration_tests.rs
└── README.md
```

## Implementation Phases

### Phase 1: Project Setup & FFI Bridge
**Goal**: Establish basic Swift-Rust communication

**Tasks**:
1. Create new Rust project with Cargo
2. Add swift-bridge dependency and build configuration
3. Create minimal Swift module with test function
4. Verify FFI bridge works (call Swift from Rust)
5. Set up proper error handling across FFI boundary

**Deliverable**: Rust app can successfully call Swift function and receive response

### Phase 2: MusicKit Authorization & Search
**Goal**: Swift module can interact with MusicKit

**Tasks**:
1. Implement MusicKit authorization flow in Swift
   - Request user permission
   - Check subscription status
   - Handle authorization states
2. Implement Apple Music catalog search
   - Search by song title + artist
   - Return track IDs and metadata
   - Handle multiple results/disambiguation
3. Expose search functionality to Rust via FFI
4. Test with sample queries

**Deliverable**: Rust app can search Apple Music catalog via Swift bridge

### Phase 3: Setlist.fm API Client
**Goal**: Fetch and parse setlist data

**Tasks**:
1. Register for setlist.fm API key
2. Implement HTTP client for setlist.fm REST API
   - Get setlist by ID
   - Search setlists by artist
   - Search setlists by venue/date
3. Parse JSON responses into Rust structs
4. Extract song list with artist metadata
5. Handle API rate limiting
6. Add error handling for API failures

**Deliverable**: Rust app can fetch setlists and extract song lists

### Phase 4: Song Matching Logic
**Goal**: Match setlist songs to Apple Music tracks

**Tasks**:
1. Implement fuzzy matching algorithm
   - Handle variations in song titles
   - Match featuring artists
   - Detect live versions vs. studio
2. Batch search optimization
   - Group searches efficiently
   - Cache results
3. Handle ambiguous matches
   - Multiple results for same song
   - Different versions (live, acoustic, etc.)
4. Generate match confidence scores
5. User review workflow for uncertain matches

**Deliverable**: High-accuracy matching of setlist songs to Apple Music tracks

### Phase 5: Playlist Creation
**Goal**: Create and populate playlists in user's library

**Tasks**:
1. Implement playlist creation in Swift
   - Create new playlist with name
   - Set description/artwork (optional)
2. Implement track addition
   - Add tracks by ID
   - Handle failures gracefully
3. Expose playlist operations to Rust
4. End-to-end workflow:
   - Fetch setlist
   - Match songs
   - Create playlist
   - Add matched tracks
5. Error recovery and rollback

**Deliverable**: Complete workflow from setlist URL to Apple Music playlist

### Phase 6: CLI & User Experience
**Goal**: Polished command-line interface

**Tasks**:
1. Implement CLI with clap
   - `create` command: from setlist URL
   - `search` command: find setlists
   - `config` command: set API keys
2. Interactive prompts for ambiguous matches
3. Progress indicators for long operations
4. Detailed logging and error messages
5. Configuration file support (~/.setlist-playlist-builder.toml)
6. Dry-run mode (preview without creating)

**Deliverable**: User-friendly CLI tool

### Phase 7: Testing & Polish
**Goal**: Production-ready application

**Tasks**:
1. Unit tests for all Rust modules
2. Integration tests for API clients
3. Manual testing with various setlists
4. Error handling audit
5. Performance optimization
6. Documentation:
   - README with setup instructions
   - API key acquisition guide
   - Usage examples
   - Troubleshooting guide
7. Release packaging (Homebrew formula?)

**Deliverable**: Stable v1.0.0 release

## API Requirements

### Setlist.fm API
- **Free tier**: 2 requests/second
- **Registration**: https://www.setlist.fm/settings/api
- **Authentication**: API key in request header (`x-api-key`)
- **Base URL**: `https://api.setlist.fm/rest/1.0/`
- **Key endpoints**:
  - `GET /setlist/{setlistId}` - Get specific setlist
  - `GET /search/setlists` - Search setlists

### Apple MusicKit
- **Requirements**:
  - Apple Developer account ($99/year)
  - MusicKit identifier (create in developer portal)
  - Private key for JWT signing
- **User requirements**:
  - macOS 12.0+ (Monterey)
  - Active Apple Music subscription
  - Signed into Music.app

## Data Flow Example

```
1. User: setlist-playlist create https://www.setlist.fm/setlist/...

2. Rust fetches setlist from API:
   {
     "artist": "Radiohead",
     "eventDate": "2023-05-20",
     "sets": {
       "set": [
         { "song": [
           { "name": "Everything In Its Right Place" },
           { "name": "Paranoid Android" },
           ...
         ]}
       ]
     }
   }

3. For each song, Rust calls Swift to search Apple Music:
   Swift: search("Everything In Its Right Place", artist: "Radiohead")
   → Returns track ID: "1234567890"

4. Rust collects all matched track IDs

5. Rust calls Swift to create playlist:
   Swift: createPlaylist(
     name: "Radiohead - 2023-05-20",
     trackIds: ["1234567890", "2345678901", ...]
   )

6. Success! Playlist appears in user's Music.app library
```

## Swift FFI Interface Design

### Authorization
```rust
// Rust side
pub fn request_music_authorization() -> Result<AuthorizationStatus, String>;
pub fn check_authorization_status() -> AuthorizationStatus;
```

### Search
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

### Playlist Creation
```rust
// Rust side
pub fn create_playlist(
    name: &str,
    description: Option<&str>,
    track_ids: Vec<String>,
) -> Result<String, String>; // Returns playlist ID
```

## Configuration File Format

```toml
# ~/.setlist-playlist-builder.toml

[setlist_fm]
api_key = "your-api-key-here"

[apple_music]
# MusicKit auth handled interactively via native dialogs

[matching]
# Fuzzy match threshold (0.0-1.0)
confidence_threshold = 0.8

# Auto-accept high-confidence matches
auto_accept_threshold = 0.95

# Prefer studio versions over live
prefer_studio = true

[playlist]
# Template for playlist names
name_template = "{artist} - {date}"

# Include venue in description
include_venue = true
```

## Command-Line Interface

```bash
# Create playlist from setlist URL
setlist-playlist create https://www.setlist.fm/setlist/...

# With custom name
setlist-playlist create --name "Best Concert Ever" https://...

# Dry run (preview matches without creating)
setlist-playlist create --dry-run https://...

# Search for setlists
setlist-playlist search --artist "Radiohead" --year 2023

# Configure API keys
setlist-playlist config set setlist-fm-api-key YOUR_KEY

# Check authorization status
setlist-playlist auth status

# Request authorization (opens Music.app)
setlist-playlist auth request
```

## Development Considerations

### Swift-Rust Bridge Choices

**Option A: swift-bridge (0.1.57)**
- ✅ More ergonomic API
- ✅ Better documentation
- ✅ Supports async (with tokio feature)
- ✅ Active development
- ⚠️ Less mature (0.1.x version)

**Option B: swift-rs (1.0.7)**
- ✅ Stable 1.0 release
- ✅ Simpler, proven approach
- ✅ Good for basic FFI
- ⚠️ Less feature-rich

**Recommendation**: Start with **swift-bridge** for better ergonomics and async support.

### Error Handling Strategy

Errors cross FFI boundary as strings initially. Consider:
1. Define error codes for common cases
2. Use Result types on both sides
3. Swift errors wrapped in NSError → String description
4. Rust errors using thiserror for structured types

### Authorization Flow UX

MusicKit authorization requires user interaction:
1. First run: Rust calls Swift authorization request
2. Swift shows native macOS authorization dialog
3. User approves in Music.app
4. Future runs: Check cached authorization status
5. Handle expired/revoked authorization gracefully

### Testing Strategy

**Unit Tests (Rust)**:
- Setlist.fm response parsing
- Song matching algorithms
- Configuration management

**Unit Tests (Swift)**:
- MusicKit wrapper functions
- Error handling

**Integration Tests**:
- Mock setlist.fm API responses
- Test FFI bridge with fake data
- End-to-end without real API calls

**Manual Tests**:
- Real setlists with various edge cases
- Different artists/genres
- Live versions, covers, features

### Performance Considerations

1. **Batch API calls** where possible
2. **Cache search results** (in-memory during session)
3. **Parallel search** for multiple songs (with rate limiting)
4. **Progress indicators** for long operations
5. Consider **local database** for historical matches (future enhancement)

## Future Enhancements (v2.0+)

1. **GUI application** using Tauri or native macOS SwiftUI
2. **Playlist updates** - sync setlist changes to existing playlists
3. **Multiple setlists** - combine setlists into one playlist
4. **Tour playlists** - all setlists from a tour
5. **Collaborative playlists** - share with other Apple Music users
6. **Statistics** - match success rates, popular songs
7. **Spotify support** - dual backend for Spotify users
8. **iOS companion app** - mobile version
9. **Automatic cover detection** - distinguish covers from originals
10. **Local music library** - match against user's existing library first

## Resources

### Documentation
- Setlist.fm API: https://api.setlist.fm/docs/1.0/index.html
- MusicKit: https://developer.apple.com/documentation/musickit
- swift-bridge: https://github.com/chinedufn/swift-bridge
- swift-rs: https://github.com/Brendonovich/swift-rs

### Example Projects
- Search GitHub for "swift-bridge musickit" examples
- Look for Rust-Swift FFI examples
- Study MusicKit sample code from Apple

### Community
- swift-bridge GitHub discussions
- Rust macOS Discord channels
- Apple Developer Forums (MusicKit section)

## Getting Started Checklist

- [ ] Install Xcode and Xcode Command Line Tools
- [ ] Verify Swift compiler: `swift --version`
- [ ] Verify Rust toolchain: `rustc --version`
- [ ] Register for setlist.fm API key
- [ ] Sign up for Apple Developer account (if not already)
- [ ] Create MusicKit identifier in developer portal
- [ ] Generate MusicKit private key
- [ ] Test Music.app has active subscription
- [ ] Create new Rust project
- [ ] Add swift-bridge dependency
- [ ] Build "Hello World" FFI bridge
- [ ] Verify can call Swift from Rust

## Estimated Timeline

- **Phase 1** (FFI Setup): 3-5 days
- **Phase 2** (MusicKit Integration): 5-7 days
- **Phase 3** (Setlist.fm Client): 3-4 days
- **Phase 4** (Song Matching): 5-7 days
- **Phase 5** (Playlist Creation): 3-4 days
- **Phase 6** (CLI/UX): 4-5 days
- **Phase 7** (Testing/Polish): 5-7 days

**Total**: ~4-6 weeks for MVP (assuming part-time development)

## Success Criteria

A successful v1.0 should:
- ✅ Create playlist from setlist URL in <30 seconds
- ✅ Match >90% of songs for popular artists
- ✅ Handle errors gracefully (API failures, authorization issues)
- ✅ Provide clear feedback on ambiguous matches
- ✅ Work reliably across repeated uses
- ✅ Have comprehensive documentation
- ✅ Support dry-run mode for previewing

## Notes

- This is a **learning project** - expect to iterate on design
- Start simple, add features incrementally
- MusicKit authorization flow is complex - budget extra time
- Song matching is the hardest part - perfect matches unlikely
- Consider limiting initial scope to recent/popular setlists
- Test with your own concert experiences for motivation!

## License Considerations

- Setlist.fm API: Check terms of service for commercial use
- MusicKit: Apple Developer license agreement
- Consider MIT or Apache-2.0 for your code
- Note: This tool is for personal use; distributing playlists may have legal implications

---

**Last Updated**: 2025-01-05
**Status**: Planning Phase
**Next Step**: Phase 1 - FFI Bridge Setup
