import SwiftUI

@main
struct TagesplanerApp: App {
    @StateObject private var store = PlannerStore()

    var body: some Scene {
        WindowGroup("Tagesplaner – Version 3") {
            PlannerView()
                .environmentObject(store)
                #if os(macOS)
                .frame(minWidth: 480, minHeight: 600)
                #endif
        }
    }
}
