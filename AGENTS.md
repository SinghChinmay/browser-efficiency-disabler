# Browser Efficiency Mode Disabler — Agent Instructions

## Project Overview
PowerShell utility that monitors browser processes and prevents Windows from applying "Efficiency Mode" (Idle priority). Packaged as a Windows service via NSSM.

User-facing docs: [README.md](./README.md)

## Files
| File | Purpose |
|------|---------|
| `disable-browser-efficiency-mode.ps1` | Core monitor script (the payload, also runs standalone) |
| `install-service.ps1` | Downloads NSSM, registers & starts the Windows service |
| `uninstall-service.ps1` | Stops & removes the service |

## Key Conventions
- All scripts are standalone — run them directly from `c:\tools`, no build step.
- `$PSScriptRoot` is used for sibling-script paths (not hardcoded absolute paths).
- Scripts that touch Windows services use `#Requires -RunAsAdministrator`.
- Error handling: `$ErrorActionPreference = "Stop"` in install/uninstall scripts.
  ⚠ This does **not** affect native `.exe` calls in Windows PowerShell 5.1 — NSSM commands (`& $nssmExe ...`) won't throw on non-zero exit. Check `$LASTEXITCODE` if needed.
- Service name is hardcoded as `"BrowserEfficiencyDisabler"` across all three scripts — when renaming, change all three.
- Logs live at `$env:ProgramData\BrowserEfficiencyDisabler\`.

## External Dependency
- **NSSM** (Non-Sucking Service Manager) — downloaded on-the-fly by `install-service.ps1` from `https://nssm.cc`. Version controlled by `$nssmVersion` (default `"2.24"`). Extracted to `c:\tools\nssm\`. The installer prefers `pwsh.exe` over `powershell.exe` for the service runtime.

## NSSM Discovery Pattern
Both `install-service.ps1` and `uninstall-service.ps1` search recursively for `nssm.exe`, preferring the `*win64*` subfolder. This logic is duplicated — **keep both copies in sync** when modifying.

## Patterns to Preserve
- **ProcessCommandException catch**: The core monitor script catches `[Microsoft.PowerShell.Commands.ProcessCommandException]` specifically for "no matching processes found" — this is intentional and must not be broadened to a generic catch.
- **NSSM arg splatting**: `install-service.ps1` uses `@(...)` array splatting for NSSM arguments — preserve this style.

## Configurable Parameters (core script only)
- `-IntervalSeconds` (default 5) — how often to poll for idle browser processes.
- `-LogDir` (default `$env:ProgramData\BrowserEfficiencyDisabler`) — where logs are written.
