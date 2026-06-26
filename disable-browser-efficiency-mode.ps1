# =============================================================================
#  Browser Efficiency Mode Disabler — Service-Ready Edition
#  Runs as a Windows service (via NSSM) or standalone. Logs to file.
# =============================================================================

param(
    [int]$IntervalSeconds = 5,
    [string]$LogDir = "$env:ProgramData\BrowserEfficiencyDisabler"
)

# --- Ensure log directory exists ---
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$logFile = Join-Path $LogDir "service.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

# List of browsers to process with their process names
$browsers = @{
    "Brave Browser"  = "brave"
    "Brave Beta"     = "brave-beta"
    "Brave Nightly"  = "brave-nightly"
    "Google Chrome"  = "chrome"
    "Vivaldi"        = "vivaldi"
    "Microsoft Edge" = "msedge"
}

Write-Log "=== SERVICE STARTED ==="
Write-Log "Polling interval: ${IntervalSeconds}s | Browsers: $($browsers.Keys -join ', ')"

# --- Main monitoring loop ---
while ($true) {
    Start-Sleep -Seconds $IntervalSeconds

    foreach ($browser in $browsers.GetEnumerator()) {
        try {
            $processes = Get-Process -Name $browser.Value -ErrorAction Stop

            foreach ($process in $processes) {
                if (-not $process.HasExited -and $process.PriorityClass -eq [System.Diagnostics.ProcessPriorityClass]::Idle) {
                    $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal
                    Write-Log "FIXED: $($browser.Key) (PID: $($process.Id)) $($process.MainWindowTitle)"
                }
            }
        }
        catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
            # No processes of this browser running — silently skip
        }
        catch {
            Write-Log "ERROR scanning '$($browser.Key)': $_" -Level "ERROR"
        }
    }
}
