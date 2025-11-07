mod bridge;

// Uncomment these imports when Swift linking is configured
// use bridge::{request_authorization, search_tracks, test_connection};

#[cfg(not(tarpaulin_include))]
fn main() {
    run();
}

fn run() {
    println!("=== Setlist Playlist Builder ===\n");
    println!("Phase 2 Status: Swift MusicKit bridge implemented");
    println!("\nImplemented Features:");
    println!("  ✓ FFI bridge definitions (src/bridge.rs)");
    println!("  ✓ Swift MusicKit search (swift/Sources/MusicKitBridge.swift)");
    println!("  ✓ Authorization flow");
    println!("  ✓ Apple Music catalog search");
    println!("\nNext Steps:");
    println!("  • Configure Swift library linking in build system");
    println!("  • Test MusicKit authorization flow");
    println!("  • Verify search results parsing");
    println!("  • Begin Phase 3: setlist.fm API client");
    println!("\nNote: Full Swift-Rust execution demo requires additional");
    println!("      build configuration for linking Swift frameworks.");
}

/// Proof of concept demo - to be enabled once Swift linking is configured
#[allow(dead_code)]
fn run_demo_placeholder() {
    // This will be uncommented and tested once Swift library linking is set up
    // See: https://github.com/chinedufn/swift-bridge/tree/master/examples
    //
    // println!("=== Setlist Playlist Builder - FFI Bridge Demo ===\n");
    // println!("1. Testing FFI bridge connection...");
    // let message = test_connection();
    // println!("   ✓ Bridge response: {}\n", message);
    //
    // println!("2. Requesting MusicKit authorization...");
    // let authorized = request_authorization();
    // if authorized {
    //     println!("   ✓ Authorization granted!\n");
    //     println!("3. Searching Apple Music...");
    //     let results = search_tracks("Bohemian Rhapsody Queen".to_string());
    //     println!("   ✓ Found {} results", results.len());
    // }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_run() {
        // Test that run executes without panicking
        run();
    }
}
