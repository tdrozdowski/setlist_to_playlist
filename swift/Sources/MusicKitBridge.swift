import Foundation
import MusicKit

/// Swift implementation of MusicKit integration
/// This provides the actual Apple Music functionality that will be called from Rust
public class MusicKitBridge {

    /// Test function to verify FFI bridge is working
    /// Returns a simple greeting message
    public static func testConnection() -> String {
        return "Hello from Swift/MusicKit!"
    }

    /// Request authorization for MusicKit
    /// Returns true if authorized, false otherwise
    public static func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        return status == .authorized
    }

    /// Search for tracks matching a query
    /// Returns track identifiers as strings in the format "id|title|artist"
    public static func searchTracks(query: String) async -> [String] {
        // Ensure we have authorization before searching
        guard await MusicAuthorization.request() == .authorized else {
            return []
        }

        do {
            // Perform catalog search for songs
            var searchRequest = MusicCatalogSearchRequest(term: query, types: [Song.self])
            searchRequest.limit = 25  // Get top 25 results

            let searchResponse = try await searchRequest.response()

            // Extract song information and format as "id|title|artist"
            let trackInfo = searchResponse.songs.map { song in
                let id = song.id.rawValue
                let title = song.title
                let artist = song.artistName
                return "\(id)|\(title)|\(artist)"
            }

            return trackInfo
        } catch {
            // Log error and return empty array
            print("MusicKit search error: \(error.localizedDescription)")
            return []
        }
    }

    /// Create a playlist with the given name and track IDs
    /// Returns the playlist ID if successful, empty string otherwise
    public static func createPlaylist(name: String, trackIds: [String]) async -> String {
        // TODO: Implement actual playlist creation
        // For now, return empty string until we implement the full playlist logic
        return ""
    }
}
