# antigravity-delegate — install notes (lenovo / Windows)

## Install agy

```powershell
irm https://antigravity.google/cli/install.ps1 | iex
```

Manual install (if script hangs): binary at `%LOCALAPPDATA%\agy\bin\agy.exe` (v1.0.16+).
Copied to `C:\Users\lenovo\.local\bin\agy.exe`.

## Global delegate

| Path | Purpose |
| --- | --- |
| `C:\Users\lenovo\.local\bin\delegate-antigravity.cmd` | PATH shim |
| `C:\Users\lenovo\.local\bin\delegate-antigravity.ps1` | Global script |
| `scripts/delegate-antigravity.ps1` | Skill copy |

## First-time auth

```powershell
agy
# Google OAuth → trust workspace folder
```

Verify: `cmdkey /list | Select-String antigravity`

## Credentials stay local

This repo contains **no API keys or OAuth tokens**. Antigravity auth is Google OAuth in the OS keyring / `%LOCALAPPDATA%\antigravity-cli\` on your machine. The delegate scripts only **check** that credentials exist; they never embed or upload them. `.gitignore` blocks token files from being committed.

## Quick test

```powershell
delegate-antigravity -Brief "Reply with exactly: OK" -PrintTimeout 5m -TimeoutMinutes 8
```

## Migrate Gemini config

```powershell
agy plugin import gemini
```

## Sibling skills

- `antigravity-delegate` — individual Google account (use this)
- `gemini-delegate` — deprecated for individual OAuth
- `opencode-delegate` — OpenCode implementer
