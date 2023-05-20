cls
# Self-elevate the script if not already running as administrator
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-w 0 -d . pwsh `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath wt.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host "|                                                                                                                                             |"
Write-Host "|                                                             SETTING UP WINDOWS                                                              |"
Write-Host "|                                                                                                                                             |"
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
# Install apps
Invoke-Expression -Command "$PSScriptRoot/scripts/install-apps.ps1"
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
# Enable Startup Verbos
Invoke-Expression -Command "$PSScriptRoot/scripts/enable-startup-verbos.ps1"
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
# Increase Hibernation Size
Invoke-Expression -Command "$PSScriptRoot/scripts/increase-hibernation-size.ps1"
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
# Setup Windows Terminal
Invoke-Expression -Command "$PSScriptRoot/scripts/setup-windows-terminal.ps1"
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host "|                                                                   DONE 🎉                                                                   |"
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host ""
Write-Host ""
PAUSE
