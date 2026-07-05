# Authentication — Google account login

Antigravity CLI uses **Google OAuth**, stored in the **OS secure store** — not `GEMINI_API_KEY`.

## One-time setup

1. **Install `agy`** (if missing):

```powershell
irm https://antigravity.google/cli/install.ps1 | iex
# Or binary already at: %LOCALAPPDATA%\agy\bin\agy.exe
# Global copy: C:\Users\lenovo\.local\bin\agy.exe
```

2. **Sign in interactively** (required once per machine; Gemini CLI tokens do **not** transfer):

```bash
agy
```

Choose **Google OAuth**, complete the browser flow, accept terms, and **trust the workspace folder** when prompted.

3. **Verify cached credentials:**

| Platform | Location |
| --- | --- |
| Windows | Credential Manager: `LegacyGeneric:target=gemini:antigravity` |
| macOS | Keychain entry for Antigravity |
| Linux | Secret Service / dbus |
| File fallback | `%LOCALAPPDATA%\antigravity-cli\antigravity-oauth-token` or `~/.gemini/antigravity-cli/antigravity-oauth-token` |

Windows check:

```powershell
cmdkey /list | Select-String antigravity
```

4. **Trust target repos** — first `agy` launch in a new folder may ask "Do you trust this folder?" Approve once per directory (or parent).

5. **Smoke test** (use the delegate wrapper — it closes stdin correctly):

```powershell
delegate-antigravity -Brief "Reply with exactly: OK" -PrintTimeout 5m -TimeoutMinutes 8 -ShowConsole:$false
```

First run can take 20–30s while auth and MCP initialize.

## Headless / delegation

`-p` / `--print` runs non-interactively. The **delegate script** handles three agy footguns:

- Closes stdin immediately (prevents infinite hang)
- Auto-trusts `-Dir` via `trustedWorkspaces`
- Uses generous timeouts (25m / 30m)

`GEMINI_API_KEY` is **ignored** by Antigravity CLI. Auth is keyring/OAuth only.

## Migrate from Gemini CLI

```bash
agy plugin import gemini
```

Imports MCP servers, skills, and agent config from `~/.gemini/`.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Hangs with no output on `-p` | Use `delegate-antigravity` (closes stdin). Or trust folder via `-TrustWorkspace`. |
| Hangs forever | Open stdin not closed — fixed in delegate script |
| Empty stdout but exit 0 | Known non-TTY behavior — review `git diff` instead |
| Not signed in | `agy` → Google OAuth |
| `agy` not on PATH | Copy to `~/.local/bin` or run `agy install` |
| Eligibility / region error | Check [antigravity.google](https://antigravity.google); some regions restricted |
| Desktop creds but CLI hangs | Antigravity Desktop and CLI share keyring — run `agy` once to complete CLI onboarding |

## Logout

Inside interactive `agy`: `/logout` clears keyring credentials.
