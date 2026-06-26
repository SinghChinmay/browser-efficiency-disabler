# =============================================================================
#  Uninstall the "BrowserEfficiencyDisabler" Windows service
#  Run this script AS ADMINISTRATOR
# =============================================================================

#Requires -RunAsAdministrator

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
Start-Sleep -Seconds 3

Write-Host "Removing service '$serviceName'..." -ForegroundColor Yellow
& $nssmExe remove $serviceName confirm

Write-Host "Service uninstalled." -ForegroundColor Green

# Optionally clean up logs
$logDir = "$env:ProgramData\BrowserEfficiencyDisabler"
if (Test-Path $logDir) {
    Write-Host "Logs remain at: $logDir (delete manually if desired)" -ForegroundColor DarkGray
}
