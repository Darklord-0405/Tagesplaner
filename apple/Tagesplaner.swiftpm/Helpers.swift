import SwiftUI
#if os(macOS)
import AppKit
typealias PlatformColor = NSColor
#else
import UIKit
typealias PlatformColor = UIColor
#endif

/// Tage werden als Text "yyyy-MM-dd" gespeichert (einfach vergleichbar und stabil).
enum DayKey {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        return c
    }()

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(_ d: Date) -> String { formatter.string(from: d) }

    static func date(_ k: String) -> Date { formatter.date(from: k) ?? Date() }

    static var today: String { key(Date()) }

    static func add(_ k: String, days: Int) -> String {
        let d = date(k)
        return key(calendar.date(byAdding: .day, value: days, to: d) ?? d)
    }

    /// Montag = 0 ... Sonntag = 6
    static func weekdayIndex(_ k: String) -> Int {
        let w = calendar.component(.weekday, from: date(k)) // 1 = Sonntag
        return (w + 5) % 7
    }

    static func monday(of k: String) -> String { add(k, days: -weekdayIndex(k)) }

    static func days(from a: String, to b: String) -> Int {
        calendar.dateComponents([.day], from: date(a), to: date(b)).day ?? 0
    }

    static func range(from a: String, to b: String) -> [String] {
        let n = days(from: a, to: b)
        guard n >= 0 else { return [] }
        return (0...n).map { add(a, days: $0) }
    }
}

let weekdayNames = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

private let germanFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "de_DE")
    return f
}()

/// Formatiert einen Tages-Schlüssel auf Deutsch, z. B. label(k, "EEEE, d. MMMM").
func label(_ k: String, _ format: String) -> String {
    germanFormatter.dateFormat = format
    return germanFormatter.string(from: DayKey.date(k))
}

func shortWeekday(_ k: String) -> String {
    weekdayNames[DayKey.weekdayIndex(k)]
}

// MARK: - Farben (hell/dunkel, wie auf den Web-Seiten)

private func platformColor(_ hex: UInt32) -> PlatformColor {
    PlatformColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        #if os(macOS)
        self.init(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return platformColor(isDark ? dark : light)
        }))
        #else
        self.init(uiColor: UIColor { traits in
            platformColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
        #endif
    }
}

// MARK: - Wiederverwendbare Bausteine

extension View {
    func card(padding: CGFloat = 14, radius: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
            )
    }

    func inlineTitle() -> some View {
        #if os(iOS)
        return self.navigationBarTitleDisplayMode(.inline)
        #else
        return self
        #endif
    }

    func sheetSize() -> some View {
        #if os(macOS)
        return self.frame(minWidth: 460, minHeight: 540)
        #else
        return self
        #endif
    }
}

/// Fortschrittsbalken (10 pt hoch, abgerundet).
struct BarView: View {
    let value: Double
    let color: Color

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.empty)
                Capsule()
                    .fill(color)
                    .frame(width: g.size.width * CGFloat(min(max(value, 0), 1)))
            }
        }
        .frame(height: 10)
        .animation(.easeOut(duration: 0.3), value: value)
    }
}

/// Abhak-Kästchen mit abgerundeten Ecken.
struct CheckBox: View {
    let on: Bool
    var size: CGFloat = 26

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(on ? Theme.accent : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(on ? Theme.accent : Theme.mute, lineWidth: 2)
            )
            .overlay {
                if on {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundStyle(Theme.onAccent)
                }
            }
            .frame(width: size, height: size)
    }
}
