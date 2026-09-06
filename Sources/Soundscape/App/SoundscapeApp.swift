import SwiftUI
import GoogleSignIn

@main
struct SoundscapeApp: App {
    @State private var container = AppContainer.live()
    @State private var localeManager = LocaleManager.shared

    init() {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !clientID.isEmpty else {
            return
        }
        let serverClientID = Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID,
            serverClientID: serverClientID
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
                .withLocale(localeManager)
                .task { await container.session.restore() }
                // Google returns to this custom URL scheme after the account
                // chooser. Without forwarding that callback, the app never
                // receives its ID token and appears unable to sign in.
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
