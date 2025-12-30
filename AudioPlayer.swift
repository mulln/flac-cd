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
    @Published var albumArt: NSImage?

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

        tracks = AlbumLoader.loadAlbum(from: folder).map {
            Track(
                url: $0.url,
                trackNumber: $0.trackNumber,
                title: $0.title,
                duration: $0.duration,
                progress: 0
            )
        }

        album = folder.lastPathComponent
        artist = folder.deletingLastPathComponent().lastPathComponent
        currentTrack = nil

        albumArt = loadAlbumArt(from: folder)
    }

    // MARK: - Album Art Loading
    private func loadAlbumArt(from folder: URL) -> NSImage? {
        let fm = FileManager.default

        // 1️⃣ Look for image files in folder
        if let urls = try? fm.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            let image = urls
                .filter {
                    ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased())
                }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
                .first
                .flatMap { NSImage(contentsOf: $0) }

            if image != nil {
                return image
            }
        }

        // 2️⃣ Fallback: embedded artwork from first track
        guard let first = tracks.first else { return nil }

        let asset = AVURLAsset(url: first.url)
        for item in asset.commonMetadata {
            if item.commonKey == .commonKeyArtwork,
               let data = item.dataValue,
               let image = NSImage(data: data) {
                return image
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
