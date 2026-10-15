import FirebaseAppCheck
import FirebaseCore

final class FirebaseBootstrap {
    func configure() {
        AppCheck.setAppCheckProviderFactory(Self.makeAppCheckProviderFactory())
        FirebaseApp.configure()
    }

    private static func makeAppCheckProviderFactory() -> any AppCheckProviderFactory {
#if DEBUG
        AppCheckDebugProviderFactory()
#else
        BettrCheckProviderFactory()
#endif
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
