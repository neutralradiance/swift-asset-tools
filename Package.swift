// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "AssetTools",
  platforms: [.macOS(.v10_12)],
  products: [
    .library(
      name: "AssetTools",
      targets: ["AssetTools"]
    )
  ],
  dependencies: [
    .package(
      name: "Light",
      url: "https://github.com/neutralradiance/swift-light",
      .branch("main")
    ),
    .package(
      url: "https://github.com/JohnSundell/Files",
      .branch("master")
    ),
    .package(
      name: "PNG",
      url: "https://github.com/kelvin13/png",
      .branch("master")
    )
  ],
  targets: [
    .target(
      name: "AssetTools",
      dependencies: [
        "Light",
        "Files",
        .product(name: "png", package: "PNG")
      ]
    ),
    .testTarget(
      name: "AssetToolsTests",
      dependencies: ["AssetTools"]
    )
  ]
)
