import SwiftUI

@main
struct GlassWebApp: App {
    var body: some Scene {
        WindowGroup {
            BrowserView()
                .preferredColorScheme(.light)
        }
    }
}
