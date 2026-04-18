// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TorahChat",
    platforms: [
        .iOS("17.0"),
    ],
    products: [
        .iOSApplication(
            name: "TorahChat",
            targets: ["AppModule"],
            bundleIdentifier: "com.jleznek.torahchat",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .book),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone,
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad])),
            ],
            capabilities: [
                .outgoingNetworkConnections(),
            ]
        ),
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources/TorahChat"
        ),
    ]
)
