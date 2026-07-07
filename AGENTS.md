# ClipAI — Agent Guide

macOS clipboard-to-AI utility. Monitors the system pasteboard, sends new text or images to an AI provider, and shows the response in a floating overlay.

## Repository layout

```
ClipAI/
├── Package.swift              # SwiftPM manifest (macOS 13+)
├── Sources/
│   ├── clip/main.swift        # Thin executable entry point
│   └── ClipAICore/             # Shared library — all app logic lives here
│       ├── ClipAIApplication.swift
│       ├── CLI/               # Argument parsing and --help
│       ├── Clipboard/         # Pasteboard monitoring and content types
│       ├── Config/            # Keychain API key storage and terminal prompts
│       ├── Models/            # Shared types (errors, model options)
│       ├── Overlay/           # SwiftUI overlay UI (glass panel, markdown)
│       ├── Providers/         # AI provider clients, routing, capability fetch
│       └── Queue/             # Serial request processing
├── Tests/                     # Custom assert-based test runner (not XCTest)
│   ├── Support/               # Assertions, TestCase protocol, suite registry
│   ├── Runner/                # ClipAITests entry point
│   ├── Clipboard/
│   ├── CLI/
│   ├── Provider/
│   ├── Overlay/
│   └── Queue/
└── Scripts/                   # build.sh, install.sh, uninstall.sh
```

## Runtime architecture

```
CLI (exact model name)
    → resolve API key
    → ModelCapabilityFetcher (provider Models API)
    → ModelOptionsPrompt (thinking / effort when supported)
    → ProviderRegistry.resolve(modelName:, options:)
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
- **Overlay** — Bottom-right floating panel; click header or press Space while visible to dismiss; press `c` while visible to copy the raw response once. Global key consumption requires macOS permission and falls back to focused-panel shortcuts when unavailable.
- **Markdown** — Success responses render via native block parser (`MarkdownDocumentParser` + `ResponseMarkdownView`); errors use plain text.
- **API keys** — One Keychain entry per provider (`clipai.<kind>`); env vars override Keychain.
- **Model options** — `ModelCapabilityFetcher` reads provider Models API metadata; `ModelOptionsPrompt` asks for thinking/effort when supported; auto-applies temperature/top_p/verbosity defaults when metadata indicates support. OpenAI-compatible vendors without extended metadata get no prompts (metadata-only, no probe requests).

## Provider routing

ClipAI does not maintain a model catalog. The user passes an exact API model name; routing uses prefix only:

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

Base URLs and env vars live in `ProviderCatalog.swift`. Unknown models at the API surface fail with a provider error, not a ClipAI validation error.

## Important files

| File | Role |
|------|------|
| `ClipAIApplication.swift` | Wires CLI, capability fetch, options prompt, monitor, queue, overlay |
| `ProviderRegistry.swift` | Resolves model → provider instance; fetches capabilities |
| `ModelCapabilityFetcher.swift` | Provider Models API client and JSON parsing |
| `ModelOptionsPrompt.swift` | Terminal prompts for thinking and reasoning effort |
| `ProviderCatalog.swift` | Prefix routing, API URLs, image capability heuristics |
| `RequestQueue.swift` | Serial async processing; calls overlay on MainActor |
| `OverlayManager.swift` | NSPanel lifecycle, transparent NSHostingView |
| `OverlayView.swift` | Header, dismiss, Copy all, markdown vs plain error content |
| `ClipboardMonitor.swift` | Polls pasteboard; deduplicates via SHA-256 hash |

## Build and test

```bash
swift build -c release
swift run -c release ClipAITests
./Scripts/install.sh   # installs to /usr/local/bin or ~/.local/bin
```

Tests use a custom runner in `Tests/Runner/main.swift` and shared helpers in `Tests/Support/TestSupport.swift`. Run all suites or one at a time:

```bash
swift run -c release ClipAITests
swift run -c release ClipAITests ProviderCatalogTests
```

CI runs separate GitHub Actions workflows per test category under `.github/workflows/`.

## Conventions for agents

- Keep `Sources/clip/main.swift` minimal; add logic to `ClipAICore`.
- New providers: extend `ProviderKind`, `ProviderCatalog`, and either `OpenAICompatibleProvider` or a dedicated client; wire in `ProviderRegistry`.
- Overlay changes stay in `Sources/ClipAICore/Overlay/`; preserve non-activating panel policy (`OverlayInteractionPolicy`).
- Do not commit API keys or `.build/` artifacts.
- Prefer small, focused diffs matching existing naming and file placement.
