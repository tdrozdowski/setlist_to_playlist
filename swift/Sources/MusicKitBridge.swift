import Foundation
import MusicKit

/// Test function to verify FFI bridge is working
/// Returns a simple greeting message
public func testConnection() -> RustString {
    return "Hello from Swift/MusicKit!".intoRustString()
}

/// Request authorization for MusicKit (synchronous wrapper)
/// Returns true if authorized, false otherwise
public func requestAuthorization() -> Bool {
    // Use a semaphore to block until async work completes
    let semaphore = DispatchSemaphore(value: 0)
    var result = false

    Task {
        let status = await MusicAuthorization.request()
        result = status == .authorized
        semaphore.signal()
    }

    semaphore.wait()
    return result
}

/// Search for tracks matching a query (synchronous wrapper)
/// Returns track identifiers as strings in the format "id|title|artist"
public func searchTracks(query: RustString) -> RustVec<RustString> {
    // Convert RustString to Swift String
    let queryString = query.toString()

    // Use a semaphore to block until async work completes
    let semaphore = DispatchSemaphore(value: 0)
    var results = RustVec<RustString>()

    Task {
        // Ensure we have authorization before searching
        guard await MusicAuthorization.request() == .authorized else {
            semaphore.signal()
            return
        }

        do {
            // Perform catalog search for songs
            var searchRequest = MusicCatalogSearchRequest(term: queryString, types: [Song.self])
            searchRequest.limit = 25  // Get top 25 results

            let searchResponse = try await searchRequest.response()

            // Build RustVec by adding elements one by one
            for song in searchResponse.songs {
                let id = song.id.rawValue
                let title = song.title
                let artist = song.artistName
                let trackInfo = "\(id)|\(title)|\(artist)".intoRustString()
                results.push(value: trackInfo)
            }
        } catch {
            // Log error
            print("MusicKit search error: \(error.localizedDescription)")
        }

        semaphore.signal()
    }

    semaphore.wait()
    return results
}

/// Create a playlist with the given name and track IDs (synchronous wrapper)
/// Returns the playlist ID if successful, empty string otherwise
public func createPlaylist(name: RustString, track_ids: RustVec<RustString>) -> RustString {
    // TODO: Implement actual playlist creation
    // For now, return empty string until we implement the full playlist logic
    return "".intoRustString()
}
