// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppAtlas",
    defaultLocalization: "de",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AppAtlas", targets: ["AppAtlas"])
    ],
    targets: [
        .executableTarget(
            name: "AppAtlas",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("Security"),
                .linkedFramework("NaturalLanguage"),
                .linkedFramework("Translation"),
                .linkedFramework("WebKit")
            ]
        ),
        .testTarget(
            name: "AppAtlasTests",
            dependencies: ["AppAtlas"]
        )
    ]
)
