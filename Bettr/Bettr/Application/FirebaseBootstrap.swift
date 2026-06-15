import FirebaseAppCheck
import FirebaseCore

final class FirebaseBootstrap {
    func configure() {
        AppCheck.setAppCheckProviderFactory(BettrCheckProviderFactory())
        FirebaseApp.configure()
    }
}

private final class BettrCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            AppAttestProvider(app: app)
        } else {
            DeviceCheckProvider(app: app)
        }
    }
}
