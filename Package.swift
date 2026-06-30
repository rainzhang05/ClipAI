// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "qhelp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "qhelp", targets: ["qhelp"])
    ],
    targets: [
        .target(
            name: "QHelpCore",
            path: "Sources/QHelpCore",
            swiftSettings: [
                .unsafeFlags(["-enable-testing"], .when(configuration: .debug)),
                .unsafeFlags(["-enable-testing"], .when(configuration: .release))
            ]
        ),
        .executableTarget(
            name: "qhelp",
            dependencies: ["QHelpCore"],
            path: "Sources/qhelp"
        ),
        .executableTarget(
            name: "qhelpTests",
            dependencies: ["QHelpCore"],
            path: "Tests"
        )
    ]
)
