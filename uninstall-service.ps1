# =============================================================================
#  Uninstall the "BrowserEfficiencyDisabler" Windows service
#  Run this script AS ADMINISTRATOR
# =============================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$serviceName = "BrowserEfficiencyDisabler"
$nssmDir     = Join-Path $PSScriptRoot "nssm"

# Find nssm.exe
$nssmExe = Get-ChildItem -Path $nssmDir -Recurse -Filter "nssm.exe" -ErrorAction SilentlyContinue |
    Where-Object { $_.Directory.Name -like "*win64*" } |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $nssmExe) {
    $nssmExe = Get-ChildItem -Path $nssmDir -Recurse -Filter "nssm.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}

if (-not $nssmExe) {
    Write-Error "NSSM not found. Was the service installed using install-service.ps1?"
    exit 1
}

Write-Host "Stopping service '$serviceName'..." -ForegroundColor Yellow
& $nssmExe stop $serviceName 2>$null

# Poll until the service is actually stopped (or timeout after 30 s)
$timeout = (Get-Date).AddSeconds(30)
do {
    Start-Sleep -Milliseconds 500
    $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
} while (($null -eq $svc -or $svc.Status -ne "Stopped") -and (Get-Date) -lt $timeout)

if ($svc -and $svc.Status -ne "Stopped") {
    Write-Warning "Service did not stop within 30 seconds; attempting removal anyway."
}

Write-Host "Removing service '$serviceName'..." -ForegroundColor Yellow
& $nssmExe remove $serviceName confirm

Write-Host "Service uninstalled." -ForegroundColor Green

# Optionally clean up logs
$logDir = "$env:ProgramData\BrowserEfficiencyDisabler"
if (Test-Path $logDir) {
    Write-Host "Logs remain at: $logDir (delete manually if desired)" -ForegroundColor DarkGray
}
