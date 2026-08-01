# Noise App Template

一个用于构建 **原生 macOS 应用（Racket 后端）** 的启动模板，基于 [Noise](https://github.com/Bogdanp/Noise) 框架。

用 Racket 编写业务逻辑，以带类型的 RPC 暴露出来，再从 SwiftUI 前端调用 —— Noise 用一个生成的客户端和基于管道的二进制协议把两者桥接起来。本模板把整套工具链都接好了，并能 **自动适配你已安装的 Racket 版本**，省去繁琐的逐版本配置。

![SwiftUI](https://img.shields.io/badge/SwiftUI-2396F3?logo=swift&logoColor=white) ![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[English](README.md) · **中文**

## 你会得到什么

- 一个可跑通的端到端示例（一个玩具计数器应用），展示完整模式：一个 `define-record`、若干 `define-rpc`，以及调用它们的 SwiftUI 界面。
- 一个 `setup` 脚本 —— 检测你的 Racket 版本，检出匹配的 Noise 分支，拉取 LFS 二进制，构建 xcframework，并编译后端 —— 只需运行一次，Racket 版本变更时再运行一次。
- 一个 `Makefile` —— 把 `app-core/*.rkt` 变成内嵌的 `core.zo`，并重新生成 Swift `Backend.swift` 客户端。

## 快速开始

### 前置要求

| 工具 | 用途 |
|------|-----|
| Racket (CS) | 运行 / 编译后端 |
| Xcode（Swift 6，macOS 14 SDK） | 构建前端 |
| git + git-lfs | Noise 的预编译二进制由 LFS 托管 |

### 一条命令

```bash
git clone https://github.com/<you>/noise-app-template.git my-app
cd my-app
./bin/setup
```

`setup` 做了所有事：匹配你的 Racket 版本，拉取 Noise，构建桥接，并运行 `make`。完成后：

```bash
swift build
.build/debug/App
```

### 日常开发

```bash
make          # 修改 app-core/*.rkt 后  → 重新构建 core.zo + Backend.swift
swift build   # 修改 app/*.swift 后
.build/debug/App
```

> **顺序很重要：** 当 Racket 代码有改动时，务必在 `swift build` 之前先 `make`，以保证内嵌的 `core.zo` 和生成的 `Backend.swift` 保持同步。

## 打包分发

`swift build` 产出的是裸可执行文件，不是 `.app`。`package` 脚本会组装出真正的
macOS 应用包（含内嵌的 `core.zo`），再打包成 `.dmg` 用于分发：

```bash
./bin/package                       # → dist/App.dmg（未签名）
```

它会重建后端（`make`）、执行 release 构建、组装 `dist/<App>.app`
（`Contents/MacOS` + `Contents/Resources/res/core.zo` + `Info.plist`），并生成一个
拖拽安装的 `.dmg`。应用名取自 `Package.swift` 中的 `APP_NAME`；若产品名与 SPM target
名不同，用 `--name` 覆盖。

**签名与公证**（让 Gatekeeper 不再弹警告）需要你的 Apple 开发者 ID —— 传入后脚本会
一并完成签名、公证、装订，并对 DMG 签名：

```bash
./bin/package \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  --notarize "apple-id@example.com" \
  --team-id ABCD123456
```

| 选项 | 作用 |
|------|------|
| `--name X` | 指定 `.app` / `.dmg` 名称（默认取 Package.swift 的 `APP_NAME`） |
| `--sign "..."` | 用 Developer ID Application 身份签名 |
| `--notarize "apple-id"` | 提交给 notarytool 公证（需配合 `--sign`） |
| `--team-id ABCD123456` | 公证用的 Apple team ID（需配合 `--notarize`） |
| `--skip-dmg` | 只生成 `dist/<App>.app` |

RacketCS 运行时是静态链接的，所以产物在任何 macOS 14+ 机器上都能跑 —— **目标机器无需安装 Racket。**

## 改成你自己的应用

示例是一个计数器，这样你能看到完整的往返链路。要把它变成你的应用：

1. **重命名**（可选）：修改 `Package.swift` 中的 `APP_NAME`、`app/` 目录，以及 `app/Backend/Backend+shared.swift` 中的 `moduleName`。
2. **定义你的类型** —— 在 `app-core/types.rkt` 中用 `define-record` / `define-enum`。
3. **定义你的操作** —— 在 `app-core/rpc.rkt` 中用 `define-rpc`（这就是你的后端 API）。
4. **运行 `make`** —— `Backend.swift` 会根据你的类型重新生成，每个 RPC 对应一个 `async throws` 方法。
5. **构建界面** —— 在 `app/` 中编写，调用 `try await Backend.shared.<rpc>(...)`。

就这些 —— 桥接是自动生成的；你一边写 Racket，另一边写 Swift。

### 完整模式，端到端

Racket 声明类型和 RPC：

```racket
;; app-core/types.rkt
(define-record (Counter : Identifiable)
  [id : UVarint] [label : String] [value : Varint])

;; app-core/rpc.rkt
(define-rpc (increment-counter [for-id id : UVarint] : (Optional Counter))
  ...)
```

`make` 生成 Swift 镜像：

```swift
// app/Backend.swift  (自动生成 —— 请勿手动编辑)
public struct Counter: Identifiable, Readable, Sendable, Writable { let id: UVarint; ... }
public func incrementCounter(forId id: UVarint) async throws -> Counter? { ... }
```

Swift 调用它：

```swift
let c = try await Backend.shared.incrementCounter(forId: id)
```

## Racket 版本匹配如何工作

Noise 的预编译 RacketCS 静态库必须与你的 Racket *完全* 匹配。上游 [Bogdanp/Noise](https://github.com/Bogdanp/Noise) 为每个 Racket 版本维护一个分支（`racket-8.18`、`racket-9.0`……）。`./bin/setup` 会：

1. 通过 `racket -e '(version)'` 读取你的版本。
2. 选择最匹配的分支 —— 先找精确匹配，再找最近的较早版本，最后是最近的较晚版本。
3. 检出到 `../Noise`，`git lfs pull` 拉取二进制，并 `make` 构建 xcframework。

因此当你升级 Racket（比如 9.0 → 9.2）时，只需重新运行 `./bin/setup`，它会自动重新定位 Noise。

## 目录结构

```
noise-app-template/
├── app-core/          # Racket 后端
│   ├── main.rkt           # 入口：(main in-fd out-fd) → (serve ...)
│   ├── rpc.rkt            # 你的 define-rpc 操作
│   ├── types.rkt          # 你的 define-record / define-enum 类型
│   └── info.rkt           # Racket 包元数据
├── app/               # SwiftUI 前端
│   ├── App/               # @main 应用 + store
│   ├── Backend/           # Backend.shared 单例（稳健的 core.zo 查找）
│   ├── Backend.swift      # 自动生成 —— 运行 `make`；请勿编辑
│   └── res/               # core.zo 输出到这里（自动生成）
├── tests/             # 后端测试
├── bin/
│   ├── setup              # 一键引导（版本感知）
│   └── codegen            # Makefile 使用的 codegen 后备
├── Makefile           # core.zo + Backend.swift 流水线
└── Package.swift      # SPM 清单
```

## 注意事项与陷阱（免得踩坑）

- **不要把 record 命名为 `Task`。** 它会与 Swift 的并发 `Task` 冲突。（之前的 rtaskly 移植就踩了这个坑 —— 改名为 `TaskItem`。）
- **`define-rpc` 是固定参数个数。** 对"可能缺失"的参数请用 `(Optional T)`，而不是可选参数。
- **`make` 要在 `swift build` 之前。** 内嵌的 `core.zo` 和生成的 `Backend.swift` 都来自你的 Racket 源码；如果过期，应用可能崩溃或调用缺失的方法。
- **record 需要 `: Identifiable`**，如果你想直接在 SwiftUI `List`/`ForEach` 中使用它（它们要求有 `id`）。

## 许可证

MIT。
