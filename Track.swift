import Foundation

struct Track: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let trackNumber: Int
    let title: String
    var duration: TimeInterval
    var progress: Double = 0.0
}
