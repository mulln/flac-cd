import Foundation
import AVFoundation

struct AlbumLoader {

    // MARK: - Text Helpers

    static func stripExtension(_ text: String) -> String {
        URL(fileURLWithPath: text)
            .deletingPathExtension()
            .lastPathComponent
    }

    
    static func prettify(_ text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Title-case fallback (respects locale)
        return cleaned.localizedCapitalized
    }

    static func stripTrailingGarbage(_ text: String) -> String {
        let parts = text.split(separator: " ")

        guard let last = parts.last else { return text }

        let isGarbage =
            (6...10).contains(last.count) &&
            last.allSatisfy { $0.isHexDigit }

        if isGarbage {
            return parts.dropLast().joined(separator: " ")
        }

        return text
    }

    static func parseFilename(_ filename: String)
    -> (trackNumber: Int, artist: String?, title: String) {

        let noExt = stripExtension(filename)
        let cleaned = stripTrailingGarbage(noExt)

        // Split on explicit delimiter FIRST
        let dashParts = cleaned
            .split(separator: "-", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // Normalize tokens only AFTER structural parsing
        func normalize(_ s: String) -> String {
            s.replacingOccurrences(of: "_", with: " ")
             .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Case: 01 - Artist - Title
        if dashParts.count >= 3, let n = Int(dashParts[0]) {
            let artist = prettify(normalize(dashParts[1]))
            let title  = prettify(normalize(dashParts.dropFirst(2).joined(separator: " ")))
            return (n, artist, title)
        }

        // Case: 01 - Title
        if dashParts.count >= 2, let n = Int(dashParts[0]) {
            let title = prettify(normalize(dashParts.dropFirst(1).joined(separator: " ")))
            return (n, nil, title)
        }

        // Fallback
        return (0, nil, prettify(normalize(cleaned)))
    }



    // MARK: - Load Album

    static func loadAlbum(from folderURL: URL) -> [Track] {
        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        let flacURLs = urls
            .filter { $0.pathExtension.lowercased() == "flac" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var tracks: [Track] = []

        for url in flacURLs {
            let asset = AVURLAsset(url: url)
            let filename = url.deletingPathExtension().lastPathComponent
            let parsed = parseFilename(filename)

            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let duration = durationSeconds.isFinite ? durationSeconds : 0

            tracks.append(
                Track(
                    url: url,
                    trackNumber: parsed.trackNumber,
                    title: parsed.title,
                    duration: duration,
                    progress: 0
                )
            )
        }

        return tracks.sorted {
            if $0.trackNumber == 0 { return false }
            if $1.trackNumber == 0 { return true }
            return $0.trackNumber < $1.trackNumber
        }
    }
}
