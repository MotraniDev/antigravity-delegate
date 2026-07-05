# Dispatch and poll

## Before the first run

```powershell
agy --version
cmdkey /list | Select-String antigravity   # Windows auth check
delegate-antigravity -Brief "Reply OK" -PrintTimeout 5m -TimeoutMinutes 8 -ShowConsole:$false
```

## Dispatch

```powershell
delegate-antigravity -BriefPath .\brief.txt -Dir F:\path\to\repo
delegate-antigravity -Brief "text" -Model "Gemini 3.5 Flash (Medium)" -PrintTimeout 25m
delegate-antigravity -Brief "delta fix" -Continue -Dir F:\path\to\repo
```

| Flag | Default | Notes |
| --- | --- | --- |
| `-BriefPath` / `-Brief` | required | Mutually exclusive |
| `-Dir` | cwd | Working directory; auto-trusted when `-TrustWorkspace` |
| `-Model` | `Gemini 3.5 Flash (Low)` | `agy models` |
| `-Sandbox` | off | `--sandbox` |
| `-Continue` | — | `-c` / resume latest |
| `-PrintTimeout` | `25m` | Inner `--print-timeout` |
| `-TimeoutMinutes` | `30` | Outer process kill |
| `-TrustWorkspace` | on | Adds `-Dir` to `~/.gemini/antigravity-cli/settings.json` |
| `-ShowConsole` | on | Optional TTY window; script works with `-ShowConsole:$false` |

## Known agy quirks (fixed in delegate script)

1. **Open stdin hangs `-p`** — if stdin is not closed, `agy -p` waits forever ([issue #318](https://github.com/google-antigravity/antigravity-cli/issues/318)). The delegate script always closes stdin after launch.
2. **Untrusted workspace** — `-p` blocks on an invisible trust prompt. `-TrustWorkspace` adds the target dir to `trustedWorkspaces`.
3. **Non-TTY stdout** — `-p` may not print when stdout is piped ([issue #76](https://github.com/google-antigravity/antigravity-cli/issues/76)). For coding tasks, **review `git diff`** — not stdout.
4. **Slow first run** — silent auth + MCP init can take 20–60s before work starts. Logs: `%USERPROFILE%\.gemini\antigravity-cli\log\`.

## Direct CLI (manual)

Close stdin when not piping a brief:

```powershell
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "agy.exe"
$psi.Arguments = '-p "brief" --dangerously-skip-permissions --print-timeout 25m'
$psi.RedirectStandardInput = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.StandardInput.Close()
$p.WaitForExit()
```

## Timing

- First auth on a cold start: ~5–10s (keyring silent auth).
- Simple prompts: ~20–30s.
- Coding tasks with MCP tools: minutes — increase `-PrintTimeout` and `-TimeoutMinutes`.

## Long briefs

Briefs over 7000 chars are piped on stdin with a short `-p` anchor.

## Exit codes

Non-zero = failure. Outer timeout → exit `124`.

## Commit boundary

Delegate scripts do not commit. Orchestrator reviews and commits.
