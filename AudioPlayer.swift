import Foundation
import AVFoundation
import AppKit
import Combine

final class AudioPlayer: ObservableObject {

    // MARK: - Published State
    @Published var tracks: [Track] = []
    @Published var currentTrack: Track?
    @Published var isPlaying: Bool = false
    @Published var artist: String = "—"
    @Published var album: String = "—"
    @Published var glowStyle: GlowStyle = .alpine
    @Published var albumArt: NSImage?   // ✅ FIX: backing property

    // MARK: - Private
    private var player: AVAudioPlayer?
    private var progressTimer: Timer?

    // MARK: - Album Loading
    func selectAlbum() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        if panel.runModal() == .OK, let folder = panel.url {
            loadAlbum(from: folder)
        }
    }

    private func loadAlbum(from folder: URL) {
        stop()

        tracks = AlbumLoader.loadAlbum(from: folder)

        let parsed = AlbumLoader.parseAlbumFolder(folder.lastPathComponent)

        artist = parsed.artist
            ?? folder.deletingLastPathComponent().lastPathComponent

        if let year = parsed.year {
            album = "\(parsed.album) (\(year))"
        } else {
            album = parsed.album
        }

        // ✅ LOAD ALBUM ART
        albumArt = loadAlbumArt(from: folder)

        currentTrack = nil
    }

    // MARK: - Album Art Loading
    private func loadAlbumArt(from folder: URL) -> NSImage? {

        let fm = FileManager.default

        // 1️⃣ Folder image (preferred)
        if let urls = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
            if let imageURL = urls.first(where: {
                ["jpg", "jpeg", "png"].contains($0.pathExtension.lowercased())
            }) {
                return NSImage(contentsOf: imageURL)
            }
        }

        // 2️⃣ Embedded art fallback (first track)
        if let firstTrack = tracks.first {
            let asset = AVURLAsset(url: firstTrack.url)
            for item in asset.commonMetadata {
                if item.commonKey?.rawValue == "artwork",
                   let data = item.dataValue {
                    return NSImage(data: data)
                }
            }
        }

        return nil
    }

    // MARK: - Playback
    func play() {
        guard !tracks.isEmpty else { return }

        if currentTrack == nil {
            currentTrack = tracks.first
        }

        guard let track = currentTrack else { return }

        if player == nil || player?.url != track.url {
            player = try? AVAudioPlayer(contentsOf: track.url)
            player?.prepareToPlay()

            if let idx = tracks.firstIndex(where: { $0.id == track.id }),
               let p = player,
               tracks[idx].duration <= 0 {
                tracks[idx].duration = p.duration
            }
        }

        player?.play()
        isPlaying = true
        startProgressTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        stopProgressTimer()
    }

    func isCurrent(_ track: Track) -> Bool {
        track.id == currentTrack?.id
    }

    // MARK: - Progress Tracking
    private func startProgressTimer() {
        stopProgressTimer()

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard
                let self = self,
                let player = self.player,
                let index = self.tracks.firstIndex(where: { $0.id == self.currentTrack?.id })
            else { return }

            let duration = max(player.duration, 0.1)
            let progress = player.currentTime / duration
            self.tracks[index].progress = min(progress, 1.0)

            if progress >= 0.999 {
                self.advanceToNextTrack()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func advanceToNextTrack() {
        guard let current = currentTrack,
              let idx = tracks.firstIndex(where: { $0.id == current.id }) else { return }

        let nextIndex = idx + 1
        guard nextIndex < tracks.count else {
            pause()
            return
        }

        tracks[idx].progress = 1.0
        currentTrack = tracks[nextIndex]
        player = nil
        play()
    }
}import Foundation
import AVFoundation
import AppKit
import Combine

final class AudioPlayer: ObservableObject {

    // MARK: - Published State
    @Published var tracks: [Track] = []
    @Published var currentTrack: Track?
    @Published var isPlaying: Bool = false
    @Published var artist: String = "—"
    @Published var album: String = "—"
    @Published var glowStyle: GlowStyle = .alpine
    @Published var albumArt: NSImage?   // ✅ FIX: backing property

    // MARK: - Private
    private var player: AVAudioPlayer?
    private var progressTimer: Timer?

    // MARK: - Album Loading
    func selectAlbum() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        if panel.runModal() == .OK, let folder = panel.url {
            loadAlbum(from: folder)
        }
    }

    private func loadAlbum(from folder: URL) {
        stop()

        tracks = AlbumLoader.loadAlbum(from: folder)

        let parsed = AlbumLoader.parseAlbumFolder(folder.lastPathComponent)

        artist = parsed.artist
            ?? folder.deletingLastPathComponent().lastPathComponent

        if let year = parsed.year {
            album = "\(parsed.album) (\(year))"
        } else {
            album = parsed.album
        }

        // ✅ LOAD ALBUM ART
        albumArt = loadAlbumArt(from: folder)

        currentTrack = nil
    }

    // MARK: - Album Art Loading
    private func loadAlbumArt(from folder: URL) -> NSImage? {

        let fm = FileManager.default

        // 1️⃣ Folder image (preferred)
        if let urls = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
            if let imageURL = urls.first(where: {
                ["jpg", "jpeg", "png"].contains($0.pathExtension.lowercased())
            }) {
                return NSImage(contentsOf: imageURL)
            }
        }

        // 2️⃣ Embedded art fallback (first track)
        if let firstTrack = tracks.first {
            let asset = AVURLAsset(url: firstTrack.url)
            for item in asset.commonMetadata {
                if item.commonKey?.rawValue == "artwork",
                   let data = item.dataValue {
                    return NSImage(data: data)
                }
            }
        }

        return nil
    }

    // MARK: - Playback
    func play() {
        guard !tracks.isEmpty else { return }

        if currentTrack == nil {
            currentTrack = tracks.first
        }

        guard let track = currentTrack else { return }

        if player == nil || player?.url != track.url {
            player = try? AVAudioPlayer(contentsOf: track.url)
            player?.prepareToPlay()

            if let idx = tracks.firstIndex(where: { $0.id == track.id }),
               let p = player,
               tracks[idx].duration <= 0 {
                tracks[idx].duration = p.duration
            }
        }

        player?.play()
        isPlaying = true
        startProgressTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        stopProgressTimer()
    }

    func isCurrent(_ track: Track) -> Bool {
        track.id == currentTrack?.id
    }

    // MARK: - Progress Tracking
    private func startProgressTimer() {
        stopProgressTimer()

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard
                let self = self,
                let player = self.player,
                let index = self.tracks.firstIndex(where: { $0.id == self.currentTrack?.id })
            else { return }

            let duration = max(player.duration, 0.1)
            let progress = player.currentTime / duration
            self.tracks[index].progress = min(progress, 1.0)

            if progress >= 0.999 {
                self.advanceToNextTrack()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func advanceToNextTrack() {
        guard let current = currentTrack,
              let idx = tracks.firstIndex(where: { $0.id == current.id }) else { return }

        let nextIndex = idx + 1
        guard nextIndex < tracks.count else {
            pause()
            return
        }

        tracks[idx].progress = 1.0
        currentTrack = tracks[nextIndex]
        player = nil
        play()
    }
}
