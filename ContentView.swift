import SwiftUI

struct ContentView: View {
    @StateObject private var audioPlayer = AudioPlayer()

    private var longestDuration: TimeInterval {
        audioPlayer.tracks.map(\.duration).max() ?? 1
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            HStack(alignment: .center) {

                VStack(alignment: .leading, spacing: 8) {
                    Text(audioPlayer.artist)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(audioPlayer.album)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let image = audioPlayer.albumArt {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 96, height: 96)
                }
            }
            .padding()

            Divider()

            // MARK: Track List
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(audioPlayer.tracks) { track in
                        TrackRow(
                            track: track,
                            audioPlayer: audioPlayer,
                            longestDuration: longestDuration
                        )
                    }
                }
                .padding(.top, 8)
            }

            Divider()

            // MARK: Controls
            HStack {
                Button("Select Album") {
                    audioPlayer.selectAlbum()
                }

                Spacer()

                Button("Play") {
                    audioPlayer.play()
                }
                .disabled(audioPlayer.isPlaying || audioPlayer.tracks.isEmpty)

                Button("Pause") {
                    audioPlayer.pause()
                }
                .disabled(!audioPlayer.isPlaying)
            }
            .padding()
        }
        .frame(minWidth: 720, maxWidth: 900, minHeight: 520)
    }
}

// MARK: - Track Row
private struct TrackRow: View {
    let track: Track
    @ObservedObject var audioPlayer: AudioPlayer
    let longestDuration: TimeInterval

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 12) {

                ZStack {
                    if audioPlayer.isCurrent(track) && audioPlayer.isPlaying {
                        Image(systemName: "play.fill")
                            .font(.caption)
                    } else {
                        Text(String(format: "%02d", track.trackNumber))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 28)

                Text(track.title)
                    .lineLimit(1)

                Spacer(minLength: 12)

                let available = max(geo.size.width - 240, 120)
                let relative = longestDuration > 0
                    ? CGFloat(track.duration / longestDuration)
                    : 0

                let totalWidth = max(available * relative, 20)
                let filledWidth = totalWidth * CGFloat(track.progress)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: totalWidth, height: 6)

                    Capsule()
                        .fill(audioPlayer.glowStyle.color)
                        .frame(width: filledWidth, height: 6)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(height: 44)
    }
}
