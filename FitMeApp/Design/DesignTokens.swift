import SwiftUI

enum AppLayout {
    static let tabBarHeight: CGFloat = 96
}

enum AppColors {
    static let cream = Color(hex: "#F7E8CC")
    static let peach = Color(hex: "#E5A43A")
    static let peachDark = Color(hex: "#CF8F28")
    static let mint = Color(hex: "#6EE7B7")
    static let sunny = Color(hex: "#F3D59A")
    static let textMain = Color(hex: "#2E2218")
    static let textSub = Color(hex: "#5E4A37")
    static let white = Color.white
}

enum AppTheme {
    // Canonical app palette.
    static let appBackground = Color(hex: "#F7E8CC")
    static let primaryButton = Color(hex: "#E5A43A")
    static let primaryButtonPressed = Color(hex: "#CF8F28")
    static let primaryButtonText = Color.white
    static let title = Color(hex: "#2E2218")
    static let subtitle = Color(hex: "#5E4A37")
    static let muted = Color(hex: "#6E5844")
    static let surface = Color(hex: "#F7E8CC")
    static let elevatedSurface = Color.white
    static let subtleSurface = Color(hex: "#F3D59A")
    static let border = Color(hex: "#D8A35A")
    static let iconMuted = Color(hex: "#A8A29E")
    static let success = Color(hex: "#6EE7B7")
    static let cardGold = Color(hex: "#F3D59A")
    static let cardBorderGold = Color(hex: "#D8A35A")
    static let accentGold = Color(hex: "#DFA646")

    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [primaryButton, accentGold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum AppFonts {
    static func nunito(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Nunito", size: size).weight(weight)
    }

    static func quicksand(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Quicksand", size: size).weight(weight)
    }

    static func plusJakarta(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Plus Jakarta Sans", size: size).weight(weight)
    }
}

enum AppMotion {
    static let durationFast: Double = 0.18
    static let durationNormal: Double = 0.24
    static let durationSlow: Double = 0.30
    static let staggerStep: Double = 0.04
    static let pressScale: CGFloat = 0.985
    static let entryOffsetY: CGFloat = 8
    static let spring: Animation = .spring(response: 0.32, dampingFraction: 0.86)
    static let ease: Animation = .easeOut(duration: durationNormal)
}

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: alpha)
    }
}
