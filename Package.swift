// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacWineManager",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacWineManager", targets: ["MacWineManager"])
    ],
    targets: [
        .executableTarget(name: "MacWineManager")
    ],
    swiftLanguageModes: [.v5]
)
