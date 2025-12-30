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

        // Use AlbumLoader (so your parsing/cleanup logic is centralized)
        let loaded = AlbumLoader.loadAlbum(from: folder)
        tracks = loaded.map { t in
            Track(url: t.url, trackNumber: t.trackNumber, title: t.title, duration: t.duration, progress: 0.0)
        }

        album = folder.lastPathComponent
        artist = folder.deletingLastPathComponent().lastPathComponent
        currentTrack = nil
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

            // If we don't already have duration, update it from the loaded player (non-deprecated)
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

            // Optional: auto-advance when track completes
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
            // Album finished
            pause()
            return
        }

        // Mark finished track fully filled
        tracks[idx].progress = 1.0

        currentTrack = tracks[nextIndex]
        player = nil
        play()
    }
}
