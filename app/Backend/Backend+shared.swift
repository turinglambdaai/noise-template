import Foundation

/// App-wide Noise backend singleton.
///
/// Points the generated `Backend` client at the bundled `res/core.zo`
/// module bundle and tells it to run the `main` procedure in the `main`
/// module (see app-core/main.rkt). The Racket server boots on a background
/// thread inside `NoiseBackend.Backend`.
///
/// **Finding core.zo.** An SPM `executableTarget` is *not* an `.app` bundle:
/// `Bundle.main` points at the executable file itself, which does not carry
/// the `.copy("res")` resources. Those land in the module's resource bundle
/// (reachable via `Bundle.module`). So we look, in order:
///   1. `Bundle.module` → "res/core.zo" (the normal SPM case)
///   2. `Bundle.main` (a real .app bundle, when packaged for distribution)
///   3. candidate paths for the .build/dev layout
extension Backend {
  static let shared: Backend = {
    Backend(withZo: findCoreZo(), andMod: "main", andProc: "main")
  }()

  /// Resolves the embedded Racket bundle URL, with fallbacks.
  private static func findCoreZo() -> URL {
    if let url = Bundle.module.url(forResource: "res/core", withExtension: "zo") {
      return url
    }
    if let url = Bundle.main.url(forResource: "res/core", withExtension: "zo") {
      return url
    }
    let execDir = Bundle.main.bundleURL
    let moduleName = "App"  // must match the SPM target name in Package.swift
    let candidates: [URL] = [
      execDir.appendingPathComponent("res/core.zo"),
      execDir.appendingPathComponent("App/res/core.zo"),
      execDir
        .deletingLastPathComponent()
        .appendingPathComponent("arm64-apple-macosx/debug/\(moduleName)_\(moduleName).bundle/res/core.zo"),
    ]
    for c in candidates where FileManager.default.fileExists(atPath: c.path) {
      return c
    }
    fatalError("""
      res/core.zo not found. Run `./bin/setup` (or `make` then `swift build`).
      Looked in Bundle.module, Bundle.main, and: \(candidates.map(\.path))
      """)
  }
}
