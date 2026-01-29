import SwiftUI

enum AppLayout {
    static let tabBarHeight: CGFloat = 96
}

enum AppColors {
    static let cream = Color(hex: "#FFF8F0")
    static let peach = Color(hex: "#FF8577")
    static let peachDark = Color(hex: "#E66A5C")
    static let mint = Color(hex: "#6EE7B7")
    static let sunny = Color(hex: "#FCD34D")
    static let textMain = Color(hex: "#3D3D3D")
    static let textSub = Color(hex: "#8B8B8B")
    static let white = Color.white
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
