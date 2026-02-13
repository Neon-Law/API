// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "API",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "API", targets: ["API"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-openapi-generator.git",
            from: "1.6.0"
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-runtime.git",
            from: "1.7.0"
        ),
        .package(
            url: "https://github.com/swift-server/swift-openapi-hummingbird.git",
            from: "2.0.1"
        ),
        .package(
            url: "https://github.com/hummingbird-project/hummingbird.git",
            from: "2.18.3"
        ),
        .package(
            url: "https://github.com/soto-project/soto.git",
            from: "7.3.0"
        ),
        .package(
            url: "https://github.com/swiftlang/swift-format.git",
            from: "600.0.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "API",
            dependencies: [
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                ),
                .product(
                    name: "OpenAPIHummingbird",
                    package: "swift-openapi-hummingbird"
                ),
                .product(
                    name: "Hummingbird",
                    package: "hummingbird"
                ),
                .product(
                    name: "SotoCodeCommit",
                    package: "soto"
                ),
            ],
            path: "Sources/API",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ],
            plugins: [
                .plugin(
                    name: "OpenAPIGenerator",
                    package: "swift-openapi-generator"
                )
            ]
        ),
        .testTarget(
            name: "APITests",
            dependencies: [
                "API",
                .product(
                    name: "HummingbirdTesting",
                    package: "hummingbird"
                ),
            ],
            path: "Tests"
        ),
    ]
)
