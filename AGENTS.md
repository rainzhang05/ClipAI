# qhelp — Agent Guide

macOS clipboard-to-AI utility. Monitors the system pasteboard, sends new text or images to an AI provider, and shows the response in a floating overlay.

## Repository layout

```
qhelp/
├── Package.swift              # SwiftPM manifest (macOS 13+)
├── Sources/
│   ├── qhelp/main.swift       # Thin executable entry point
│   └── QHelpCore/             # Shared library — all app logic lives here
│       ├── QHelpApplication.swift
│       ├── CLI/               # Argument parsing and --help
│       ├── Clipboard/         # Pasteboard monitoring and content types
│       ├── Config/            # Keychain API key storage and terminal prompts
│       ├── Models/            # Shared error types
│       ├── Overlay/           # SwiftUI overlay UI (glass panel, markdown)
│       ├── Providers/         # AI provider clients and routing
│       └── Queue/             # Serial request processing
├── Tests/                     # Custom assert-based test runner (not XCTest)
└── Scripts/                   # build.sh, install.sh, uninstall.sh
```

## Runtime architecture

```
CLI (exact model name)
    → ProviderRegistry.resolve(modelName:)
        → ProviderCatalog.kind(for:) — prefix routing only
        → model name sent verbatim to API
ClipboardMonitor (NSPasteboard polling)
    → RequestQueue (Swift actor, max 20 items, one in flight)
        → AIProvider.send(content:)
        → OverlayManager.show(text:isError:) on MainActor
            → OverlayView (SwiftUI in NSPanel)
```

### Key behaviors

- **Accessory app** — `NSApplication` uses `.accessory` activation policy; overlay is a `.nonactivatingPanel` and never steals focus.
- **Overlay** — Bottom-right floating panel; click header to dismiss; scrollable content; Copy all writes raw response to pasteboard.
- **Markdown** — Success responses render via native block parser (`MarkdownDocumentParser` + `ResponseMarkdownView`); errors use plain text.
- **API keys** — One Keychain entry per provider (`qhelp.<kind>`); env vars override Keychain.

## Provider routing

qhelp does not maintain a model catalog. The user passes an exact API model name; routing uses prefix only:

| Prefix / pattern | Provider | Client |
|------------------|----------|--------|
| `claude-*` | Anthropic | `AnthropicProvider` (Messages API) |
| `gpt-*`, `o1*`, `o3*`, `o4*` | OpenAI | `OpenAICompatibleProvider` |
| `gemini-*` | Gemini | `GeminiProvider` (generateContent) |
| `grok-*` | Grok | `OpenAICompatibleProvider` |
| `kimi-*`, `moonshot-*` | Kimi | `OpenAICompatibleProvider` |
| `deepseek-*` | DeepSeek | `OpenAICompatibleProvider` |
| `qwen-*` | Qwen | `OpenAICompatibleProvider` |
| `glm-*` | GLM | `OpenAICompatibleProvider` |

Base URLs and env vars live in `ProviderCatalog.swift`. Unknown models at the API surface fail with a provider error, not a qhelp validation error.

## Important files

| File | Role |
|------|------|
| `QHelpApplication.swift` | Wires CLI, monitor, queue, overlay; handles SIGINT/SIGTERM |
| `ProviderRegistry.swift` | Resolves model alias → provider instance |
| `ProviderCatalog.swift` | Prefix routing, API URLs, image capability heuristics |
| `RequestQueue.swift` | Serial async processing; calls overlay on MainActor |
| `OverlayManager.swift` | NSPanel lifecycle, transparent NSHostingView |
| `OverlayView.swift` | Header, dismiss, Copy all, markdown vs plain error content |
| `ClipboardMonitor.swift` | Polls pasteboard; deduplicates via SHA-256 hash |

## Build and test

```bash
swift build -c release
swift run -c release qhelpTests
./Scripts/install.sh   # installs to /usr/local/bin or ~/.local/bin
```

Tests use a custom runner in `Tests/TestSupport.swift` (`@main enum TestRunner`). QHelpCore exposes internals to tests via `@testable import` and `-enable-testing` swift settings.

## Conventions for agents

- Keep `Sources/qhelp/main.swift` minimal; add logic to `QHelpCore`.
- New providers: extend `ProviderKind`, `ProviderCatalog`, and either `OpenAICompatibleProvider` or a dedicated client; wire in `ProviderRegistry`.
- Overlay changes stay in `Sources/QHelpCore/Overlay/`; preserve non-activating panel policy (`OverlayInteractionPolicy`).
- Do not commit API keys or `.build/` artifacts.
- Prefer small, focused diffs matching existing naming and file placement.
