import SwiftUI

/// Minimal SwiftUI frontend demonstrating the full Noise round-trip:
/// create a counter, increment it, list counters, delete.
///
/// Replace this with your real UI. The point is just to show the call
/// pattern: `try await Backend.shared.<rpc>(...)` from `@MainActor` code.
@main
struct AppMain: App {
  // Brings the app to the foreground on launch (SPM executables don't steal
  // focus by default, so the window can be created hidden).
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @State private var store = Store()

  var body: some Scene {
    WindowGroup("Noise App") {
      ContentView()
        .environment(store)
        .frame(minWidth: 480, minHeight: 360)
    }
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.activate(ignoringOtherApps: true)
  }
}

/// Tiny @Observable store that wraps the backend.
@MainActor
@Observable
final class Store {
  var counters: [Counter] = []
  var newLabel: String = ""
  var status: String = ""

  func reload() async {
    do { counters = try await Backend.shared.getAllCounters() }
    catch { status = "\(error)" }
  }

  func add() async {
    let label = newLabel.trimmingCharacters(in: .whitespaces)
    guard !label.isEmpty else { return }
    newLabel = ""
    do {
      _ = try await Backend.shared.createCounter(labeled: label)
      await reload()
    } catch { status = "\(error)" }
  }

  func increment(_ id: UInt64) async {
    do { _ = try await Backend.shared.incrementCounter(forId: id); await reload() }
    catch { status = "\(error)" }
  }

  func delete(_ id: UInt64) async {
    do { _ = try await Backend.shared.deleteCounter(forId: id); await reload() }
    catch { status = "\(error)" }
  }
}

struct ContentView: View {
  @Environment(Store.self) private var store

  var body: some View {
    // @Bindable gives us $store bindings from an @Observable via the environment.
    @Bindable var store = store
    VStack(spacing: 16) {
      Text("Noise App Template").font(.largeTitle.bold())
      HStack {
        TextField("Counter label", text: $store.newLabel)
          .textFieldStyle(.roundedBorder)
          .onSubmit { Task { await store.add() } }
        Button("Add") { Task { await store.add() } }
      }
      Divider()
      List(store.counters) { c in
        HStack {
          Text(c.label)
          Spacer()
          Text("\(c.value)").monospacedDigit().foregroundStyle(.secondary)
          Button { Task { await store.increment(c.id) } } label: {
            Image(systemName: "plus.circle")
          }
          Button { Task { await store.delete(c.id) } } label: {
            Image(systemName: "trash")
          }
        }
      }
      if !store.status.isEmpty {
        Text(store.status).font(.caption).foregroundStyle(.red)
      }
    }
    .padding()
    .task { await store.reload() }
  }
}
