// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OneTakeKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14),
    ],
    products: [
        .library(name: "OneTakeKit", targets: ["OneTakeKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "OneTakeKit",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ]
        ),
    ]
)
