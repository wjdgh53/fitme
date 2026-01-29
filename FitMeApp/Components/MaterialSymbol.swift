import SwiftUI

enum MaterialSymbolStyle {
    case outlined
    case rounded
}

struct MaterialSymbol: View {
    let name: String
    let size: CGFloat
    var style: MaterialSymbolStyle = .outlined

    var body: some View {
        Text(name)
            .font(.custom(fontName, size: size))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private var fontName: String {
        switch style {
        case .outlined:
            return "MaterialSymbolsOutlined20pt-Thin"
        case .rounded:
            return "MaterialSymbolsRounded20pt-Thin"
        }
    }
}
