// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TorahChat",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .executable(name: "TorahChat", targets: ["TorahChat"]),
    ],
    targets: [
        .executableTarget(
            name: "TorahChat",
            path: "Sources/TorahChat"
        ),
    ]
)
