import SwiftUI
import Foundation

enum TintColor: String, CaseIterable {
    case cyan
    case blue
    case purple
    case pink
    case red
    case orange
    case yellow
    case yelloGreen
    case green
    
    var title: LocalizedStringKey {
        switch self {
        case .cyan:
            return "KEY_CYAN"
        case .blue:
            return "KEY_BLUE"
        case .purple:
            return "KEY_PURPLE"
        case .pink:
            return "KEY_PINK"
        case .red:
            return "KEY_RED"
        case .orange:
            return "KEY_ORANGE"
        case .yellow:
            return "KEY_YELLOW"
        case .yelloGreen:
            return "KEY_YELLOWGREEN"
        case .green:
            return "KEY_GREEN"
        }
    }
    
    var color: Color {
        switch self {
        case .cyan:
            return Color.cyan
        case .blue:
            return Color.blue
        case .purple:
            return Color.purple
        case .pink:
            return Color.pink
        case .red:
            return Color.red
        case .orange:
            return Color.orange
        case .yellow:
            return Color.yellow
        case .yelloGreen:
            return Color.yellow.mix(with: Color.green, by: 0.3)
        case .green:
            return Color.green
        }
    }
}
