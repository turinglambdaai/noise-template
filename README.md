# Noise App Template

A starter template for building **native macOS apps with a Racket backend**, using the [Noise](https://github.com/Bogdanp/Noise) framework.

Write your business logic in Racket, expose it as typed RPCs, and call it from a SwiftUI frontend — Noise bridges the two with a generated client and a binary protocol over pipes. This template wires up the whole toolchain and **auto-adapts to whatever Racket version you have installed**, so you skip the fiddly per-version setup.

![SwiftUI](https://img.shields.io/badge/SwiftUI-2396F3?logo=swift&logoColor=white) ![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white)

## What you get

- A working end-to-end example (a toy counter app) showing the full pattern: a `define-record`, several `define-rpc`s, and a SwiftUI UI calling them.
- A `setup` script that detects your Racket version, checks out the matching Noise branch, pulls the LFS binaries, builds the xcframeworks, and compiles the backend — run it once, and again whenever Racket changes.
- A `Makefile` that turns `app-core/*.rkt` into an embedded `core.zo` and regenerates the Swift `Backend.swift` client.

## Quick start

### Prerequisites

| Tool | Why |
|------|-----|
| Racket (CS) | runs/compiles the backend |
| Xcode (Swift 6, macOS 14 SDK) | builds the frontend |
| git + git-lfs | Noise's prebuilt binaries are LFS-hosted |

### One command

```bash
git clone https://github.com/<you>/noise-app-template.git my-app
cd my-app
./bin/setup
```

`setup` does everything: matches your Racket version, fetches Noise, builds the bridges, and runs `make`. When it finishes:

```bash
swift build
.build/debug/App
```

### Day-to-day

```bash
make          # after changing app-core/*.rkt  → rebuilds core.zo + Backend.swift
swift build   # after changing app/*.swift
.build/debug/App
```

> **Order matters:** always `make` before `swift build` when Racket code changed, so the bundled `core.zo` and generated `Backend.swift` stay in sync.

## Make it your own

The example is a counter so you can see the round-trip work. To turn it into your app:

1. **Rename** (optional): change `APP_NAME` in `Package.swift`, the `app/` dir, and the `moduleName` in `app/Backend/Backend+shared.swift`.
2. **Define your types** in `app-core/types.rkt` with `define-record` / `define-enum`.
3. **Define your operations** in `app-core/rpc.rkt` with `define-rpc` (this is your backend API).
4. **Run `make`** — `Backend.swift` is regenerated with your types and one `async throws` method per RPC.
5. **Build the UI** in `app/`, calling `try await Backend.shared.<rpc>(...)`.

That's it — the bridge is generated; you write Racket on one side, Swift on the other.

### The pattern, end to end

Racket declares types and RPCs:

```racket
;; app-core/types.rkt
(define-record (Counter : Identifiable)
  [id : UVarint] [label : String] [value : Varint])

;; app-core/rpc.rkt
(define-rpc (increment-counter [for-id id : UVarint] : (Optional Counter))
  ...)
```

`make` generates the Swift mirror:

```swift
// app/Backend.swift  (generated — don't edit)
public struct Counter: Identifiable, Readable, Sendable, Writable { let id: UVarint; ... }
public func incrementCounter(forId id: UVarint) async throws -> Counter? { ... }
```

Swift calls it:

```swift
let c = try await Backend.shared.incrementCounter(forId: id)
```

## How Racket version matching works

Noise's prebuilt RacketCS static libraries must match your Racket *exactly*. The upstream [Bogdanp/Noise](https://github.com/Bogdanp/Noise) keeps a branch per Racket release (`racket-8.18`, `racket-9.0`, …). `./bin/setup`:

1. Reads your version via `racket -e '(version)'`.
2. Picks the best matching branch — exact match first, then the nearest earlier release, then the nearest later one.
3. Checks it out into `../Noise`, `git lfs pull`s the binaries, and `make`s the xcframeworks.

So when you upgrade Racket (say 9.0 → 9.2), just re-run `./bin/setup` and it re-targets Noise automatically.

## Layout

```
noise-app-template/
├── app-core/          # Racket backend
│   ├── main.rkt           # entry: (main in-fd out-fd) → (serve ...)
│   ├── rpc.rkt            # your define-rpc operations
│   ├── types.rkt          # your define-record / define-enum types
│   └── info.rkt           # Racket package metadata
├── app/               # SwiftUI frontend
│   ├── App/               # @main app + store
│   ├── Backend/           # Backend.shared singleton (robust core.zo lookup)
│   ├── Backend.swift      # GENERATED — run `make`; don't edit
│   └── res/               # core.zo lands here (generated)
├── tests/             # backend tests
├── bin/
│   ├── setup              # one-shot bootstrap (version-aware)
│   └── codegen            # codegen fallback used by the Makefile
├── Makefile           # core.zo + Backend.swift pipeline
└── Package.swift      # SPM manifest
```

## Notes & pitfalls (so you don't hit them)

- **Don't name a record `Task`.** It collides with Swift's concurrency `Task`. (The earlier rtaskly port hit this — it renamed to `TaskItem`.)
- **`define-rpc` has fixed arity.** Use `(Optional T)` for "maybe absent" args rather than optional parameters.
- **`make` before `swift build`.** The bundled `core.zo` and generated `Backend.swift` both come from your Racket sources; if they're stale the app may crash or call missing methods.
- **A record needs `: Identifiable`** if you want to use it directly in SwiftUI `List`/`ForEach` (it requires an `id`).

## License

MIT.
