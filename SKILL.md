---
name: antigravity-delegate
description: >-
  Delegate a coding task to the Antigravity CLI (agy) as a background implementer, then review its
  diff and land it yourself. Use when the user wants to hand implementation work to Antigravity CLI —
  phrasings like "have Antigravity do X", "delegate to agy", "run it through Antigravity CLI", or
  "use agy to implement/fix/refactor" — especially after the June 2026 Gemini CLI deprecation for
  individual accounts. Authentication uses Google account OAuth (Windows Credential Manager / OS
  keyring), not API keys. DO NOT USE for tasks small enough to do inline.
license: MIT
compatibility: Requires the `agy` CLI installed and Google OAuth cached, and git. Windows: PowerShell 5.1+ and `delegate-antigravity` on PATH. Unix: bash and `scripts/delegate-antigravity.sh`.
metadata:
  version: 0.1.0
---

# Antigravity Delegate

You are the **orchestrator**. Hand a bounded coding task to **Antigravity CLI (`agy`)** as a separate
implementer, then review what it produced and land it yourself.

Antigravity replaced Gemini CLI for individual / Pro / Ultra Google accounts as of June 18, 2026.
See [references/migration-from-gemini.md](references/migration-from-gemini.md).

## When NOT to use this

- The task is small enough to do inline.
- `agy` is not installed or Google OAuth is not cached (run `agy` once and sign in).
- The user still has enterprise Gemini CLI access and prefers `gemini-delegate` or `opencode-delegate`.

## Prerequisites (check once)

1. `agy --version` succeeds.
2. **Google account auth cached** — see [references/authentication.md](references/authentication.md).
3. Target repo directory is trusted (run `agy` once in that folder if prompted).
4. Optional: `agy plugin import gemini` to migrate MCP/skills from Gemini CLI.

### Windows (lenovo): global helper on PATH

```powershell
delegate-antigravity -BriefPath .\my-brief.txt
delegate-antigravity -Brief "Your brief." -Dir F:\path\to\repo
```

Run `Get-Help delegate-antigravity`. Script: `scripts/delegate-antigravity.ps1`.

## Choose the model

List models: `agy models`. Override with `-Model`. Default in the delegate script: `Gemini 3.5 Flash (Low)`.

| Model profile | Use for |
| --- | --- |
| `Gemini 3.5 Flash (Low)` | **Default** — fast mechanical work |
| `Gemini 3.5 Flash (Medium/High)` | Balanced / richer context |
| `Gemini 3.1 Pro (High)` | Judgment-heavy tasks |

## The loop

### 1. Write the brief

`agy` sees only the brief + working tree. Template: [references/writing-the-brief.md](references/writing-the-brief.md).

### 2. Dispatch

```powershell
delegate-antigravity -BriefPath .\brief.txt -Dir F:\path\to\repo
delegate-antigravity -Brief "Implement X. Run pytest. Do not commit."
```

| Parameter | Default | Notes |
| --- | --- | --- |
| `-BriefPath` / `-Brief` | (required) | One of the two |
| `-Model` | `Gemini 3.5 Flash (Low)` | From `agy models` |
| `-Dir` | current directory | Working directory |
| `-Sandbox` | off | Enable OS sandbox |
| `-Continue` | — | Resume latest conversation (`-c`) |
| `-PrintTimeout` | `25m` | Passed to `--print-timeout` |
| `-TimeoutMinutes` | `30` | Outer kill (must exceed print timeout) |
| `-TrustWorkspace` | on | Adds `-Dir` to `trustedWorkspaces` automatically |
| `-ShowConsole` | on | New console for TTY output; `-ShowConsole:$false` works with closed stdin |

Direct CLI:

```bash
agy -p "brief" --dangerously-skip-permissions --print-timeout 15m
```

### 3. Wait

Scripts block until `agy` exits or outer timeout. Success = exit `0`.

### 4. Review

Re-run gates; read `git diff`. Checklist: [references/review-and-land.md](references/review-and-land.md).

### 5. Land

You commit. Delta brief:

```powershell
delegate-antigravity -Brief "Fix the fixture." -Continue -Dir F:\path\to\repo
```

## Autonomy

`--dangerously-skip-permissions` (default) auto-approves all tool calls — required for unattended delegation. Your diff review is the safety net.

## References

- [references/authentication.md](references/authentication.md)
- [references/migration-from-gemini.md](references/migration-from-gemini.md)
- [references/writing-the-brief.md](references/writing-the-brief.md)
- [references/dispatch-and-poll.md](references/dispatch-and-poll.md)
- [references/review-and-land.md](references/review-and-land.md)
- [README.md](README.md)
