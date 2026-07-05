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
