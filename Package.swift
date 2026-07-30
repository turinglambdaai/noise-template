// swift-tools-version:6.0
//
// Noise app template — SPM manifest for a macOS app built on Noise.
//
// After `./bin/setup` (or `make` then `swift build`):
//
//   swift build
//   .build/debug/App
//
// Noise is expected at ../Noise (placed there by ./bin/setup). Change APP_NAME
// below and the target name/dir to match your app.

import PackageDescription

/// Change this to your app's name. It must match: the executable target name,
/// the directory under which sources live (app/), and the bundle lookup in
/// Backend+shared.swift.
let APP_NAME = "App"

let package = Package(
  name: APP_NAME,
  platforms: [.macOS(.v14)],
  targets: [
    .executableTarget(
      name: APP_NAME,
      dependencies: [
        .product(name: "Noise", package: "Noise"),
        .product(name: "NoiseBackend", package: "Noise"),
        .product(name: "NoiseSerde", package: "Noise"),
      ],
      path: "app",
      exclude: ["res"],
      resources: [
        .copy("res"),
      ]
    ),
  ]
)

// Noise is checked out at ../Noise by ./bin/setup (matching the current
// Racket version). For the Bogdanp/Noise layout, the SPM package is at the
// repo root, so we depend on ../Noise directly.
package.dependencies = [
  .package(path: "../Noise"),
]
