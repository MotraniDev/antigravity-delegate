# Migration from Gemini CLI

As of **June 18, 2026**, Google deprecated `gemini` for individual, Pro, and Ultra accounts in favor of **Antigravity CLI (`agy`)**.

Official sources:
- [Google Developers Blog — transition announcement](https://developers.googleblog.com/en/an-important-update-transitioning-gemini-cli-to-antigravity-cli/)
- [GitHub discussion #28017](https://github.com/google-gemini/gemini-cli/discussions/28017)

## Who must migrate

| Account | `gemini` | `agy` |
| --- | --- | --- |
| Free / individual | Stopped | **Use this** |
| Google AI Pro / Ultra | Stopped | **Use this** |
| Code Assist Enterprise | Still works | Optional |
| Paid API key only | Still works (API, not OAuth) | N/A |

## Install Antigravity CLI

```powershell
# Windows
irm https://antigravity.google/cli/install.ps1 | iex
```

Binary location: `%LOCALAPPDATA%\agy\bin\agy.exe`

## Import Gemini config

```bash
agy plugin import gemini
```

Carries over: skills, MCP servers, agents, `GEMINI.md` memory.

## Command mapping

| gemini-delegate / Gemini CLI | antigravity-delegate / agy |
| --- | --- |
| `gemini -p "brief"` | `agy -p "brief"` |
| `--approval-mode=yolo` | `--dangerously-skip-permissions` |
| `-m flash` | `--model "Gemini 3.5 Flash (Low)"` |
| `-r latest` | `--continue` / `-c` |
| `~/.gemini/oauth_creds.json` | OS keyring (`gemini:antigravity`) |
| `delegate-gemini` | `delegate-antigravity` |

## Skills in this repo

- **`antigravity-delegate`** — use for individual Google account delegation (this skill).
- **`gemini-delegate`** — legacy; individual OAuth no longer works on `gemini`.
- **`opencode-delegate`** — unchanged; different implementer.
