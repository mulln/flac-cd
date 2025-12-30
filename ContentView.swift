import SwiftUI

struct ContentView: View {
    @StateObject private var audioPlayer = AudioPlayer()

    private var longestDuration: TimeInterval {
        audioPlayer.tracks.map(\.duration).max() ?? 1
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Header
            HStack(alignment: .center, spacing: 28) {

                // Artist / Album (Balanced)
                VStack(alignment: .leading, spacing: 8) {

                    Text(audioPlayer.artist)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(audioPlayer.album)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6) // 👈 pushes visual center down slightly

                Spacer()

                // Album Art
                if let image = audioPlayer.albumArt {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(audioPlayer.glowStyle.color, lineWidth: 2)
                                .shadow(
                                    color: audioPlayer.glowStyle.color.opacity(0.6),
                                    radius: 8
                                )
                        )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20) // 👈 adds vertical breathing room
            .frame(minHeight: 150)

            Divider()

            // MARK: - Track List
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

            // MARK: - Controls
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
        .frame(minHeight: 520)
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

                // Leading indicator
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

                let available = max(geo.size.width - 240, 80)
                let relative = longestDuration > 0
                    ? CGFloat(track.duration / longestDuration)
                    : 0

                let totalWidth = max(available * relative, 12)
                let filledWidth = totalWidth * CGFloat(track.progress)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: totalWidth, height: 6)

                    Capsule()
                        .fill(audioPlayer.glowStyle.color.opacity(0.45))
                        .frame(width: filledWidth, height: 12)
                        .blur(radius: 6)

                    Capsule()
                        .fill(audioPlayer.glowStyle.color)
                        .frame(width: filledWidth, height: 6)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if audioPlayer.isCurrent(track) {
                        audioPlayer.glowStyle = audioPlayer.glowStyle.next()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(height: 44)
    }
}
