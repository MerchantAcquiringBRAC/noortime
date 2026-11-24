import SwiftUI
import UIKit

/// NoorTime colour palette. Every colour adapts automatically to Light / Dark mode.
enum NTColor {
    /// Screen background (off-white in light, deep green-black in dark).
    static let background = dynamic(light: 0xF7F4EC, dark: 0x0B1512)
    /// Card surface.
    static let card = dynamic(light: 0xFFFFFF, dark: 0x14251F)
    /// Main brand colour (deep emerald).
    static let emerald = dynamic(light: 0x0B5D4B, dark: 0x3CB89A)
    /// Hero card gradient colours (same in both themes so white text stays readable).
    static let heroTop = Color(hex: 0x0A4D3F)
    static let heroBottom = Color(hex: 0x0F7058)
    /// Soft gold accent.
    static let gold = dynamic(light: 0x9A7420, dark: 0xE3C06A)
    static let goldOnHero = Color(hex: 0xE8C877)
    /// Text colours.
    static let textPrimary = dynamic(light: 0x14201C, dark: 0xF2EFE6)
    static let textSecondary = dynamic(light: 0x56665F, dark: 0xA9B8B1)
    /// Highlight behind the next prayer row.
    static let highlight = dynamic(light: 0xE4F1EC, dark: 0x1B3A31)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

enum NTLayout {
    static let cornerRadius: CGFloat = 22
    static let screenPadding: CGFloat = 20
    static let spacing: CGFloat = 18
}

extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(UIColor(hex: hex))
    }
}

/// Rounded white/dark card used across the app.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NTColor.card)
            .clipShape(RoundedRectangle(cornerRadius: NTLayout.cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func ntCard() -> some View {
        modifier(CardBackground())
    }
}
