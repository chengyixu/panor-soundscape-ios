import SwiftUI

@main
struct SoundscapeApp: App {
    @State private var container = AppContainer.live()
    @State private var localeManager = LocaleManager.shared

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
                .withLocale(localeManager)
                .task { await container.session.restore() }
        }
    }
}
