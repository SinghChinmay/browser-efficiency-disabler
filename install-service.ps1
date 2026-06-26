# =============================================================================
#  Install "BrowserEfficiencyDisabler" as a Windows service using NSSM
#  Run this script AS ADMINISTRATOR
# =============================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$serviceName  = "BrowserEfficiencyDisabler"
$scriptPath   = Join-Path $PSScriptRoot "disable-browser-efficiency-mode.ps1"
$nssmDir      = Join-Path $PSScriptRoot "nssm"
$nssmExe      = Join-Path $nssmDir "nssm.exe"
$nssmZip      = Join-Path $PSScriptRoot "nssm.zip"
$nssmVersion  = "2.24"
$nssmUrl      = "https://nssm.cc/release/nssm-$nssmVersion.zip"

# --- Step 1: Download NSSM if not present ---
if (-not (Test-Path $nssmExe)) {
    Write-Host "Downloading NSSM v$nssmVersion..." -ForegroundColor Cyan
    if (Test-Path $nssmZip) { Remove-Item $nssmZip -Force }
    Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmZip -UseBasicParsing

    Write-Host "Extracting NSSM..." -ForegroundColor Cyan
    Expand-Archive -Path $nssmZip -DestinationPath $nssmDir -Force
    Remove-Item $nssmZip -Force

    # NSSM extracts to a subfolder like nssm-2.24/win64 — find the right exe
    $found = Get-ChildItem -Path $nssmDir -Recurse -Filter "nssm.exe" |
        Where-Object { $_.Directory.Name -like "*win64*" } |
        Select-Object -First 1

    if (-not $found) {
        $found = Get-ChildItem -Path $nssmDir -Recurse -Filter "nssm.exe" | Select-Object -First 1
    }

    if ($found) {
        $nssmExe = $found.FullName
        Write-Host "NSSM located at: $nssmExe" -ForegroundColor Green
    } else {
        Write-Error "Could not find nssm.exe after extraction."
        exit 1
    }
}

# --- Step 2: Remove existing service if present ---
$existing = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Removing existing service '$serviceName'..." -ForegroundColor Yellow
    & $nssmExe stop $serviceName 2>$null
    Start-Sleep -Seconds 2
    & $nssmExe remove $serviceName confirm
    Start-Sleep -Seconds 1
}

# --- Step 3: Install the service ---
Write-Host "Installing service '$serviceName'..." -ForegroundColor Cyan

$pwshPath = (Get-Command powershell.exe -ErrorAction Stop).Source

& $nssmExe install $serviceName $pwshPath @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-WindowStyle", "Hidden",
    "-File", "`"$scriptPath`""
)

# --- Step 4: Configure service settings ---
& $nssmExe set $serviceName DisplayName      "Browser Efficiency Mode Disabler"
& $nssmExe set $serviceName Description      "Prevents Windows from applying Efficiency Mode (Idle priority) to browser processes."
& $nssmExe set $serviceName Start            "SERVICE_AUTO_START"
& $nssmExe set $serviceName AppStdout        "$env:ProgramData\BrowserEfficiencyDisabler\nssm-stdout.log"
& $nssmExe set $serviceName AppStderr        "$env:ProgramData\BrowserEfficiencyDisabler\nssm-stderr.log"
& $nssmExe set $serviceName AppRotateFiles   1
& $nssmExe set $serviceName AppRotateBytes   1048576       # 1 MB
& $nssmExe set $serviceName AppExit          "Default"     # Restart on failure
& $nssmExe set $serviceName AppRestartDelay  5000          # 5 seconds before restart

# --- Step 5: Start the service ---
Write-Host "Starting service..." -ForegroundColor Cyan
& $nssmExe start $serviceName

Start-Sleep -Seconds 2
$svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Host "SUCCESS: Service '$serviceName' is running!" -ForegroundColor Green
} else {
    Write-Host "WARNING: Service may not have started. Check logs:" -ForegroundColor Yellow
    Write-Host "  Service log: $env:ProgramData\BrowserEfficiencyDisabler\service.log" -ForegroundColor White
    Write-Host "  NSSM log:    $env:ProgramData\BrowserEfficiencyDisabler\nssm-stderr.log" -ForegroundColor White
}

Write-Host ""
Write-Host "========== QUICK COMMANDS ==========" -ForegroundColor Cyan
Write-Host "  Check status : Get-Service $serviceName"
Write-Host "  View logs    : Get-Content '$env:ProgramData\BrowserEfficiencyDisabler\service.log' -Tail 20"
Write-Host "  Stop service : & '$nssmExe' stop $serviceName"
Write-Host "  Uninstall    : .\uninstall-service.ps1"
