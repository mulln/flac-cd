import SwiftUI

enum GlowStyle: CaseIterable, Identifiable {
    case alpine
    case blaupunkt
    case pioneer

    var id: Self { self }

    var label: String {
        switch self {
        case .alpine: return "Alpine"
        case .blaupunkt: return "Blaupunkt"
        case .pioneer: return "Pioneer"
        }
    }

    var color: Color {
        switch self {
        case .alpine:
            return Color(red: 0.55, green: 0.95, blue: 0.55) // Alpine green
        case .blaupunkt:
            return Color(red: 1.0, green: 0.6, blue: 0.25) // Blaupunkt orange
        case .pioneer:
            return Color(red: 0.45, green: 0.65, blue: 1.0) // Pioneer blue
        }
    }

    func next() -> GlowStyle {
        let all = Self.allCases
        let index = all.firstIndex(of: self)!
        return all[(index + 1) % all.count]
    }
}
