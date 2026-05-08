import SwiftUI

extension Color {
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let whaleInk = Color(red: 0.08, green: 0.16, blue: 0.34)
    static let whaleBlue = Color(red: 0.08, green: 0.42, blue: 0.95)
    static let whaleCyan = Color(red: 0.10, green: 0.82, blue: 0.92)
    static let whaleMint = Color(red: 0.44, green: 0.96, blue: 0.80)
    static let whaleSurface = Color(nsColor: .windowBackgroundColor)
    static let whaleStroke = Color.primary.opacity(0.08)
    static let whalePanel = Color.primary.opacity(0.035)
    static let whalePanelStrong = Color.primary.opacity(0.06)
    static let cacheHitColor = Color.green
    static let cacheMissColor = Color.orange
    static let outputColor = Color.blue
    static let trendUpColor = Color.red
    static let trendDownColor = Color.green

    static func modelColor(_ modelName: String) -> Color {
        let colors: [Color] = [.blue, .orange, .green, .purple, .pink, .teal, .yellow, .red]
        var hasher = Hasher()
        hasher.combine(modelName)
        let idx = abs(hasher.finalize()) % colors.count
        return colors[idx]
    }

    /// Build a foreground style scale for chart's BarMark grouping by model name.
    static func modelColorScale(for modelNames: [String]) -> [String: Color] {
        var seen: [String: Color] = [:]
        let palette: [Color] = [.blue, .orange, .green, .purple, .teal, .pink, .yellow, .red]
        for name in modelNames {
            if seen[name] == nil {
                seen[name] = palette[seen.count % palette.count]
            }
        }
        return seen
    }

    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double

        switch sanitized.count {
        case 6:
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
        default:
            red = 1
            green = 1
            blue = 1
        }

        self.init(red: red, green: green, blue: blue)
    }

    var hexString: String {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? .white
        let red = Int(round(nsColor.redComponent * 255))
        let green = Int(round(nsColor.greenComponent * 255))
        let blue = Int(round(nsColor.blueComponent * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
