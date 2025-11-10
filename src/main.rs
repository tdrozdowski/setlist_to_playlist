mod bridge;

use bridge::{request_authorization, search_tracks, test_connection};

#[cfg(not(tarpaulin_include))]
fn main() {
    run();
}

fn run() {
    println!("=== Setlist Playlist Builder - FFI Bridge Demo ===\n");

    // Test 1: Verify FFI bridge connectivity
    println!("1. Testing FFI bridge connection...");
    let message = test_connection();
    println!("   ✓ Bridge response: {message}\n");

    // Test 2: Request MusicKit authorization
    println!("2. Requesting MusicKit authorization...");
    println!("   (This will show a macOS dialog if not already authorized)");
    let authorized = request_authorization();

    if authorized {
        println!("   ✓ Authorization granted!\n");

        // Test 3: Search Apple Music catalog
        println!("3. Searching Apple Music for 'Bohemian Rhapsody Queen'...");
        let results = search_tracks("Bohemian Rhapsody Queen".to_string());
        println!("   ✓ Found {} results", results.len());

        if !results.is_empty() {
            println!("\n   Sample results:");
            for (i, track) in results.iter().take(3).enumerate() {
                println!("   {}. {}", i + 1, track);
            }
        }

        println!("\n=== Demo Complete! ===");
        println!("\nPhase 2 Status: Swift MusicKit bridge fully functional");
        println!("  ✓ FFI bridge working");
        println!("  ✓ MusicKit authorization");
        println!("  ✓ Apple Music catalog search");
        println!("\nNext: Phase 3 - setlist.fm API client");
    } else {
        println!("   ✗ Authorization denied");
        println!("\nNote: MusicKit requires an active Apple Music subscription");
        println!("      and proper entitlements in the app.");
    }
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
