# ClipAI

ClipAI is a macOS clipboard-to-AI helper. Run it with an exact model name, copy text or an image, and ClipAI sends the clipboard content to the matching provider. The response appears in a floating Liquid Glass overlay.

## Install

Requires macOS 13 or newer and Swift 5.9 or newer.

```bash
git clone https://github.com/rainzhang05/ClipAI
cd ClipAI
chmod +x Scripts/*.sh
./Scripts/install.sh
```

The install script builds a release binary and installs `clip` to `/usr/local/bin` when possible, otherwise to `~/.local/bin`.

## Use

Start ClipAI with the exact API model name you want to use:

```bash
clip claude-sonnet-4-6
clip gpt-4o
clip gemini-2.5-flash
```

Then copy text or an image from any app. ClipAI watches the system clipboard, processes new clipboard items one at a time, and shows the AI response in the bottom-right overlay.

Press `Ctrl+C` in the terminal to quit.

## Overlay Controls

- Scroll the overlay to read longer responses.
- Select and copy text directly from the overlay.
- Press `c` while the overlay is visible to copy the full raw response once.
- Press `Space` while the overlay is visible to dismiss it.
- If macOS has not granted ClipAI keyboard monitoring permission, click the overlay before pressing `c` or `Space`.
- ClipAI runs as an accessory app, so the overlay does not switch you away from your current app.

## API Keys

On first use, ClipAI prompts for the provider API key and saves it in the macOS Keychain. Environment variables override Keychain values.

| Provider | Model prefix | Environment variable |
| --- | --- | --- |
| Anthropic | `claude-*` | `ANTHROPIC_API_KEY` |
| OpenAI | `gpt-*`, `o1*`, `o3*`, `o4*` | `OPENAI_API_KEY` |
| Google Gemini | `gemini-*` | `GEMINI_API_KEY` |
| xAI Grok | `grok-*` | `XAI_API_KEY` |
| Moonshot Kimi | `kimi-*`, `moonshot-*` | `MOONSHOT_API_KEY` |
| DeepSeek | `deepseek-*` | `DEEPSEEK_API_KEY` |
| Qwen / DashScope | `qwen-*` | `DASHSCOPE_API_KEY` |
| Zhipu GLM | `glm-*` | `ZHIPU_API_KEY` |

Optional: set `QWEN_BASE_URL` to override the default Qwen/DashScope endpoint.

ClipAI routes only by model prefix and sends the model name to the provider unchanged. If the model name is invalid, the provider returns the error.

## Model Options

At startup, ClipAI checks provider model metadata. When the provider reports supported options, ClipAI may ask whether to enable thinking or which reasoning effort to use. If no supported options are reported, ClipAI starts clipboard monitoring without extra prompts.

## Development

```bash
swift build -c release
swift run -c release ClipAITests
swift run -c release ClipAITests ProviderCatalogTests
```

Run `clip --help` for the built-in command help.

## License

MIT. See [LICENSE](LICENSE).
