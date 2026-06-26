# Browser Efficiency Mode Disabler — Agent Instructions

## Project Overview
PowerShell utility that monitors browser processes and prevents Windows from applying "Efficiency Mode" (Idle priority). Packaged as a Windows service via NSSM.

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
- Service name is hardcoded as `"BrowserEfficiencyDisabler"` across all three scripts — when renaming, change all three.
- Logs live at `$env:ProgramData\BrowserEfficiencyDisabler\`.

## External Dependency
- **NSSM** (Non-Sucking Service Manager) — downloaded on-the-fly by `install-service.ps1` from `https://nssm.cc`. Extracted to `c:\tools\nssm\`. The installer searches for the `win64` variant first.

## Configurable Parameters (core script only)
- `-IntervalSeconds` (default 5) — how often to poll for idle browser processes.
- `-LogDir` (default `$env:ProgramData\BrowserEfficiencyDisabler`) — where logs are written.
