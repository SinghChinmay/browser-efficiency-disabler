# 🚫 Browser Efficiency Mode Disabler

**Prevents Windows 10/11 from throttling your browsers into "Efficiency Mode" (Idle priority).**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-lightgrey)]()

---

## The Problem

Windows 10 and 11 have a feature called **Efficiency Mode** that demotes background processes to Idle CPU priority. The idea is to save battery and free up resources, but browsers are often the biggest victims. Tabs you haven't clicked on in a few minutes? Efficiency Mode. A media player tab playing music in the background? Efficiency Mode. The result is sluggish tab switching, stuttering media, and unresponsive web apps.

This tool fixes that — automatically.

## How It Works

A lightweight PowerShell script runs as a **Windows service**, polling every 5 seconds. When it detects a supported browser process stuck in `Idle` priority, it bumps it back to `Normal`. That's it.

```
┌─────────────┐     poll every 5s     ┌──────────────────┐
│  Windows     │ ◄────────────────── │  Browser          │
│  Service     │                      │  Efficiency Mode  │
│  (NSSM)      │ ──────────────────► │  Disabler         │
└─────────────┘   bump to Normal      └──────────────────┘
```

### Supported Browsers

| Browser | Process Name |
|---|---|
| Brave Browser | `brave` |
| Brave Beta | `brave-beta` |
| Brave Nightly | `brave-nightly` |
| Google Chrome | `chrome` |
| Microsoft Edge | `msedge` |
| Vivaldi | `vivaldi` |

---

## Quick Start

### 1. Install the Service

Run **PowerShell as Administrator**:

```powershell
cd c:\tools
.\install-service.ps1
```

This downloads [NSSM](https://nssm.cc), registers the service, and starts it immediately. The service is set to **auto-start on boot**.

### 2. Verify It's Running

```powershell
Get-Service BrowserEfficiencyDisabler
```

### 3. Check the Logs

```powershell
Get-Content "$env:ProgramData\BrowserEfficiencyDisabler\service.log" -Tail 20
```

---

## Uninstalling

Run **as Administrator**:

```powershell
.\uninstall-service.ps1
```

This stops and removes the Windows service. Logs are kept at `C:\ProgramData\BrowserEfficiencyDisabler\` — delete the folder manually if you want a clean slate.

---

## Running Standalone (No Service)

If you just want to try it without installing a service:

```powershell
.\disable-browser-efficiency-mode.ps1
```

Press `Ctrl+C` to stop. With no service, output goes to the PowerShell console.

### Customizing the Polling Interval

```powershell
.\disable-browser-efficiency-mode.ps1 -IntervalSeconds 10
```

The default is 5 seconds. Increase it if you want less frequent checks; decrease it for near-instant fixes (though 1s is the practical minimum).

---

## Requirements

| Requirement | Notes |
|---|---|
| **Windows 10 or 11** | Only these versions have Efficiency Mode |
| **PowerShell 5.1** | Built into Windows 10/11 — nothing to install |
| **Administrator rights** | Required to install/remove the Windows service (not needed for standalone mode) |
| **Internet connection** | Needed only during `install-service.ps1` to download NSSM (~400 KB) |

---

## Project Structure

```
c:\tools\
├── disable-browser-efficiency-mode.ps1   # The monitor script (runs standalone or as a service)
├── install-service.ps1                   # Downloads NSSM and installs the Windows service
├── uninstall-service.ps1                 # Stops and removes the Windows service
└── AGENTS.md                             # Instructions for AI coding agents
```

---

## Logs

All logs go to `C:\ProgramData\BrowserEfficiencyDisabler\`:

| Log File | Content |
|---|---|
| `service.log` | When a browser process was fixed (timestamp, browser name, PID, window title) |
| `nssm-stdout.log` | NSSM wrapper standard output (rotates at 1 MB) |
| `nssm-stderr.log` | NSSM wrapper error output (rotates at 1 MB) |

### Example Log Output

```
2026-06-27 14:32:05 [INFO] === SERVICE STARTED ===
2026-06-27 14:32:05 [INFO] Polling interval: 5s | Browsers: Brave Browser, Brave Beta, ...
2026-06-27 14:32:45 [INFO] FIXED: Google Chrome (PID: 18432) YouTube - Google Chrome
2026-06-27 14:35:10 [INFO] FIXED: Microsoft Edge (PID: 22156) New Tab
```

---

## Troubleshooting

### The service installed but won't start

Check the NSSM error log:
```powershell
Get-Content "$env:ProgramData\BrowserEfficiencyDisabler\nssm-stderr.log"
```

Common causes:
- **Script execution policy** — NSSM passes `-ExecutionPolicy Bypass`, so this shouldn't be an issue. If it is, run `Set-ExecutionPolicy RemoteSigned`.
- **Path issues** — The install script was run from a different folder. Always run `install-service.ps1` from `c:\tools`.

### Service is running but no logs appear

The service checks browsers every 5 seconds but only logs when it **fixes** a process. If no browsers are in Efficiency Mode yet, there's nothing to log. Open a browser, minimize it, and wait a few minutes.

### The NSSM download fails

The script downloads from `https://nssm.cc`. If that site is unreachable, download NSSM manually from [nssm.cc/download](https://nssm.cc/download), extract the `win64\nssm.exe` to `c:\tools\nssm\`, and re-run the installer.

---

## FAQ

**Will this drain my battery?**  
Negligibly. The script wakes up for a few milliseconds every 5 seconds to call `Get-Process`. It does no disk I/O unless it finds a process to fix.

**Can I add my own browser?**  
Edit the `$browsers` hashtable in `disable-browser-efficiency-mode.ps1`. Add the friendly name and the process name (check Task Manager for the exact `.exe` name without the extension).

**Does this survive Windows updates?**  
Yes. NSSM registers a proper Windows service. It persists across reboots and updates.

**Why not just change a registry setting?**  
There is no registry key to disable Efficiency Mode per-application. Microsoft only exposes this through the Task Manager UI, and even that resets after the process restarts. A monitor script is the only reliable workaround.

---

## License

This project is provided as-is under the [MIT License](https://opensource.org/licenses/MIT). Do whatever you want with it.
