import SwiftUI

/// Farbpalette "Indigo" – dieselben Grundwerte wie auf der Tagesplaner-Webseite.
enum Theme {
    static let bg       = Color(light: 0xf3f4f8, dark: 0x12121a)
    static let card     = Color(light: 0xffffff, dark: 0x1b1c28)
    static let ink      = Color(light: 0x181a2b, dark: 0xeceefa)
    static let mute     = Color(light: 0x666b82, dark: 0x9a9fb8)
    static let line     = Color(light: 0xdfe2ec, dark: 0x2a2c3d)
    static let accent   = Color(light: 0x5b4bdb, dark: 0x9a8cff)
    static let hot      = Color(light: 0xc2410c, dark: 0xfb923c)
    static let empty    = Color(light: 0xe8e5fb, dark: 0x2a2650)
    static let onAccent = Color(light: 0xffffff, dark: 0x12121a)

    // Verlauf für den Kopfbereich
    static let heroA    = Color(light: 0x5b4bdb, dark: 0x6c5ce7)
    static let heroB    = Color(light: 0x8e6cf2, dark: 0x3b2fb0)
    // Schatten der Karten
    static let shadow   = Color(light: 0x1b1550, dark: 0x000000)
}
