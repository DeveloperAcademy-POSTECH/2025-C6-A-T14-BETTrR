// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BettrAI",
    platforms: [.iOS("26.0"), .macOS(.v13)],
    products: [.library(name: "BettrAI", type: .static, targets: ["BettrAI"])],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", exact: "12.6.0")
    ],
    targets: [
        .target(
            name: "BettrAI",
            dependencies: [.product(name: "FirebaseAILogic", package: "firebase-ios-sdk")]
        ),
        .testTarget(
            name: "BettrAITests",
            dependencies: [
                "BettrAI",
                .product(name: "FirebaseAILogic", package: "firebase-ios-sdk")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
