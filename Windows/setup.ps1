cls
# Self-elevate the script if not already running as administrator
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-w 0 -d . pwsh `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath wt.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

Write-Host ""
Write-Host "+-----------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host "______________/\\\\\\\\\\\_____/\\\\\\\\\_________/\\\\\\\\\______/\\\________/\\\__/\\\\\\\\\\\_____/\\\\\\\\\\\___________"
Write-Host " _____________\/////\\\///____/\\\\\\\\\\\\\_____/\\\///////\\\___\/\\\_______\/\\\_\/////\\\///____/\\\/////////\\\_________"
Write-Host "  _________________\/\\\______/\\\/////////\\\___\/\\\_____\/\\\___\//\\\______/\\\______\/\\\______\//\\\______\///__________"
Write-Host "   _________________\/\\\_____\/\\\_______\/\\\___\/\\\\\\\\\\\/_____\//\\\____/\\\_______\/\\\_______\////\\\_________________"
Write-Host "    _________________\/\\\_____\/\\\\\\\\\\\\\\\___\/\\\//////\\\______\//\\\__/\\\________\/\\\__________\////\\\______________"
Write-Host "     _________________\/\\\_____\/\\\/////////\\\___\/\\\____\//\\\______\//\\\/\\\_________\/\\\_____________\////\\\___________"
Write-Host "      __________/\\\___\/\\\_____\/\\\_______\/\\\___\/\\\_____\//\\\______\//\\\\\__________\/\\\______/\\\______\//\\\__________"
Write-Host "       _________\//\\\\\\\\\______\/\\\_______\/\\\___\/\\\______\//\\\______\//\\\________/\\\\\\\\\\\_\///\\\\\\\\\\\/___________"
Write-Host "        __________\/////////_______\///________\///____\///________\///________\///________\///////////____\///////////_____________"
Write-Host
Write-Host ""

Write-Host "+-----------------------------------------------------------------------------------------------------------------------------------+"
Write-Host "|                                                                                                                                   |"
Write-Host "|                                                        SETTING UP WINDOWS                                                         |"
Write-Host "|                                                                                                                                   |"
Write-Host "+-----------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
# Install apps
Invoke-Expression -Command "$PSScriptRoot/scripts/install-apps.ps1"
Write-Host ""
Write-Host "+-----------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
# Enable Startup Verbos
Invoke-Expression -Command "$PSScriptRoot/scripts/enable-startup-verbos.ps1"
Write-Host ""
Write-Host "+-----------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
# Increase Hibernation Size
Invoke-Expression -Command "$PSScriptRoot/scripts/increase-hibernation-size.ps1"
Write-Host ""
Write-Host "+-----------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
# Setup Windows Terminal
Invoke-Expression -Command "$PSScriptRoot/scripts/setup-windows-terminal.ps1"
Write-Host ""
Write-Host "+-----------------------------------------------------------------------------------------------------------------------------------+"
Write-Host "|                                                              DONE 🎉                                                              |"
Write-Host "+-----------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host ""
Write-Host ""
PAUSE
