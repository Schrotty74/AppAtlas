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
    dependencies: [
        .package(path: "../AppMetadataKit")
    ],
    targets: [
        .executableTarget(
            name: "AppAtlas",
            dependencies: [
                "AppMetadataKit"
            ],
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
