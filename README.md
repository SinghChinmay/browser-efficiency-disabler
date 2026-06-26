# Disable Windows Efficiency Mode for Chrome, Edge, Brave & Vivaldi

**Stop Windows 10 and Windows 11 from throttling your browser into Idle priority — automatically. Fix slow tabs, stuttering media, and unresponsive web apps caused by Windows Efficiency Mode.**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-lightgrey)]()

---

## Why Windows Efficiency Mode Slows Down Your Browser

Windows 10 and Windows 11 include a feature called **Efficiency Mode** that demotes background processes to **Idle CPU priority** to conserve battery and free up system resources. While this sounds useful, web browsers are frequently misidentified as "idle" — even when they're actively playing music, hosting video calls, or holding tabs you intend to return to.

The result: **sluggish tab switching**, **stuttering audio/video playback**, and **unresponsive web applications**. Efficiency Mode kicks in silently, and there is no built-in toggle to disable it for specific apps like Chrome, Edge, Brave, or Vivaldi.

**This tool fixes that — automatically, in the background, without any user interaction.**

---

## How It Works

A lightweight PowerShell script runs as a **Windows background service**, polling every 5 seconds. Whenever it finds a supported browser process trapped in `Idle` priority, it restores it to `Normal` priority — undoing Windows Efficiency Mode in real time.

```
┌─────────────────┐    poll every 5s    ┌──────────────────────┐
│  Windows Service │ ◄───────────────── │  Browser Efficiency   │
│  (NSSM-hosted)  │                     │  Mode Disabler        │
│                  │ ──────────────────► │  (PowerShell script)  │
└─────────────────┘  bump to Normal      └──────────────────────┘
```

### Supported Browsers

| Browser | Process Name |
|---|---|
| Google Chrome | `chrome` |
| Microsoft Edge | `msedge` |
| Brave Browser | `brave` |
| Brave Beta | `brave-beta` |
| Brave Nightly | `brave-nightly` |
| Vivaldi | `vivaldi` |

> Want to add another Chromium-based browser? See the [FAQ](#faq).

---

## Quick Start: Install the Service

### 1. Run the Installer

Open **PowerShell as Administrator** and run:

```powershell
.\install-service.ps1
```

This automatically:
- Downloads [NSSM](https://nssm.cc) (the Non-Sucking Service Manager, ~400 KB)
- Registers a Windows service named `BrowserEfficiencyDisabler`
- Configures it to **auto-start on boot**
- Starts it immediately

### 2. Verify It's Running

```powershell
Get-Service BrowserEfficiencyDisabler
```

Expected output: `Status: Running`, `StartType: Automatic`.

### 3. Check Recent Activity

```powershell
Get-Content "$env:ProgramData\BrowserEfficiencyDisabler\service.log" -Tail 20
```

You should see `FIXED` entries whenever the script bumps a browser process out of Idle priority.

---

## Uninstall the Service

Run **PowerShell as Administrator**:

```powershell
.\uninstall-service.ps1
```

This stops and removes the Windows service. Log files remain at `C:\ProgramData\BrowserEfficiencyDisabler\` — delete that folder manually for a complete cleanup.

---

## Run Without Installing (Standalone Mode)

To test the script without setting up a Windows service:

```powershell
.\disable-browser-efficiency-mode.ps1
```

Press `Ctrl+C` to stop. Output prints directly to the console instead of a log file.

### Adjust the Polling Interval

```powershell
.\disable-browser-efficiency-mode.ps1 -IntervalSeconds 10
```

The default is **5 seconds**. Increase for lower CPU usage; decrease (minimum ~1s) for faster detection.

---

## Requirements

| Requirement | Details |
|---|---|
| **Windows 10 or Windows 11** | Efficiency Mode is exclusive to these versions |
| **PowerShell 5.1 or later** | Built into Windows 10/11 — no extra install needed |
| **Administrator privileges** | Required only to install/uninstall the service (not for standalone mode) |
| **Internet connection** | Needed once during install to download NSSM (~400 KB) |

---

## Log Files

All logs are written to `C:\ProgramData\BrowserEfficiencyDisabler\`:

| Log File | Content |
|---|---|
| `service.log` | Timestamped record of every browser process fixed (PID, window title) |
| `nssm-stdout.log` | NSSM wrapper standard output (auto-rotates at 1 MB) |
| `nssm-stderr.log` | NSSM wrapper error output (auto-rotates at 1 MB) |

### Sample Log Output

```
2026-06-27 14:32:05 [INFO] === SERVICE STARTED ===
2026-06-27 14:32:05 [INFO] Polling interval: 5s | Browsers: Brave Browser, Brave Beta, ...
2026-06-27 14:32:45 [INFO] FIXED: Google Chrome (PID: 18432) YouTube — Google Chrome
2026-06-27 14:35:10 [INFO] FIXED: Microsoft Edge (PID: 22156) New Tab
```

---

## Troubleshooting

### Service installed but won't start

Check the NSSM error log:

```powershell
Get-Content "$env:ProgramData\BrowserEfficiencyDisabler\nssm-stderr.log"
```

Common causes:
- **PowerShell execution policy** — The installer passes `-ExecutionPolicy Bypass`, so policy restrictions shouldn't apply. If they do, run: `Set-ExecutionPolicy RemoteSigned`.
- **Wrong working directory** — Always run `install-service.ps1` from the project folder (`c:\tools`).

### Service is running but no fixes appear in the log

The script only writes a log entry when it **detects and fixes** a browser in Efficiency Mode. If no browser has been demoted yet, there's nothing to log. Open Chrome or Edge, minimize the window, and wait a few minutes — Windows will eventually apply Efficiency Mode, and you'll see `FIXED` entries appear.

### NSSM download fails

The installer fetches NSSM from `https://nssm.cc`. If that site is unreachable, [download NSSM manually](https://nssm.cc/download), extract `win64\nssm.exe` into the project's `nssm\` folder, then re-run the installer.

---

## FAQ

### Does this drain battery or use a lot of CPU?

No. The script wakes up for a few milliseconds every 5 seconds to call `Get-Process` — a lightweight, built-in PowerShell cmdlet. It only writes to disk when it finds a process to fix. The overhead is negligible.

### Can I add Firefox, Opera, or another browser?

Yes. Edit the `$browsers` hashtable in `disable-browser-efficiency-mode.ps1` and add your browser's process name. To find the exact `.exe` name, open Task Manager, right-click the browser process, select **Properties**, and note the name (without `.exe`). Then add a line like:

```powershell
"Firefox" = "firefox"
```

### Does this survive Windows Updates and reboots?

Yes. The service is registered through NSSM as a standard Windows service with `StartType: Automatic`. It starts on boot and persists across Windows updates.

### Why not use a registry tweak or Group Policy?

Microsoft does not expose Efficiency Mode control through the Windows Registry or Group Policy. The only built-in toggle is in Task Manager's **Details** tab, and that setting resets as soon as the process restarts. A lightweight background monitor is the only reliable workaround.

### Is this safe to run?

Yes. The script only reads process information and adjusts CPU priority — it does not modify system files, the registry, or browser settings. The source is a single, readable PowerShell script (~60 lines of logic).

---

## Project Structure

```
├── disable-browser-efficiency-mode.ps1   # Core monitor script (standalone or service payload)
├── install-service.ps1                   # Downloads NSSM + installs the Windows service
├── uninstall-service.ps1                 # Stops and removes the Windows service
├── README.md                             # You are here
└── AGENTS.md                             # AI coding agent instructions
```

---

## License

MIT — see [LICENSE](https://opensource.org/licenses/MIT). Use it, modify it, share it.
