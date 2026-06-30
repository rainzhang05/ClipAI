# qhelp

A lightweight macOS command-line utility that monitors the system clipboard and sends new content (text or images) to an AI model, displaying the response in a native Liquid Glass overlay.

## Features

- **Clipboard Monitoring** — Watches `NSPasteboard` for any new content
- **Multi-Provider** — Anthropic, OpenAI, Gemini, Grok, Kimi, DeepSeek, Qwen, GLM
- **Liquid Glass Overlay** — System-native glass on macOS 26+ (material fallback on older macOS)
- **Interactive Overlay** — Scroll and copy text; click header to dismiss; never steals focus
- **Rich Markdown** — Headings, bold/italic, lists, code blocks, links, and blockquotes in responses
- **Keychain API Keys** — Prompt once per provider; saved securely in macOS Keychain
- **Sequential Queue** — One request at a time, up to 20 queued items
- **Duplicate Detection** — SHA-256 hashing for consecutive identical content

## Installation

```bash
git clone <repository-url>
cd qhelp
chmod +x Scripts/*.sh
./Scripts/install.sh
```

```bash
qhelp claude-sonnet-4-6
qhelp gpt-4o
qhelp gemini-2.5-flash
```

## API Keys

On first use of each provider, qhelp prompts for your API key (hidden input) and saves it to the **macOS Keychain**.

Environment variables override Keychain when set:

| Provider | Environment Variable |
|----------|---------------------|
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| Gemini | `GEMINI_API_KEY` |
| Grok | `XAI_API_KEY` |
| Kimi | `MOONSHOT_API_KEY` |
| DeepSeek | `DEEPSEEK_API_KEY` |
| Qwen | `DASHSCOPE_API_KEY` |
| GLM | `ZHIPU_API_KEY` |

Optional: `QWEN_BASE_URL` to override the default international DashScope endpoint.

## Overlay Behavior

- Appears bottom-right above the Dock
- Fades in and **stays visible** until dismissed
- **Click the header** ("Click to dismiss") to fade out
- **Scroll and copy** response text in the content area
- **Copy all** button copies the full raw response (including markdown)
- Responses render as **rich markdown** (headings, lists, code blocks, links)
- Drag-select works within each block; use Copy all for the entire response
- Does **not** activate qhelp or steal focus from your current app
