// FFI Bridge between Rust and Swift
// This module defines the interface for calling Swift MusicKit code from Rust
//
// IMPORTANT: This is infrastructure code, not business logic
// - Keep this file focused on FFI declarations only
// - Business logic belongs in services/adapters layers
// - Test coverage: Not required (FFI glue code, tested via integration tests)

#[swift_bridge::bridge]
mod ffi {
    extern "Swift" {
        // Test function to verify FFI bridge connectivity
        #[swift_bridge(swift_name = "testConnection")]
        fn test_connection() -> String;

        // Request MusicKit authorization
        // Returns true if authorized, false otherwise
        // Note: Swift side blocks on async work using DispatchSemaphore
        #[swift_bridge(swift_name = "requestAuthorization")]
        fn request_authorization() -> bool;

        // Search for tracks matching a query
        // Returns track identifiers as strings
        // Note: Swift side blocks on async work using DispatchSemaphore
        #[swift_bridge(swift_name = "searchTracks")]
        fn search_tracks(query: String) -> Vec<String>;

        // Create a playlist with the given name and track IDs
        // Returns the playlist ID if successful, empty string otherwise
        // Note: Swift side blocks on async work using DispatchSemaphore
        #[swift_bridge(swift_name = "createPlaylist")]
        fn create_playlist(name: String, track_ids: Vec<String>) -> String;
    }
}

// Re-export FFI functions for use in adapters
#[allow(unused_imports)]
pub use ffi::*;

#[cfg(test)]
mod tests {
    #[test]
    fn test_ffi_module_compiles() {
        // This test just verifies the module compiles
        // Actual FFI functionality is tested via integration tests
    }
}
