# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-w 0 -d . pwsh `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath wt.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

cls
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host "|                                                                                                                                             |"
Write-Host "|                                                SETTING UP DOPPLER (https://www.doppler.com)                                                 |"
Write-Host "|                                                                                                                                             |"
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host "     Installing Scoop - A command-line installer for Windows (https://scoop.sh)"
Write-Host ""
iwr -useb get.scoop.sh | iex
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host "     Installing Doppler CLI (https://docs.doppler.com/docs/install-cli)"
Write-Host ""
scoop bucket add doppler https://github.com/DopplerHQ/scoop-doppler.git
scoop install doppler
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host "     Please login to doppler to complete the installation"
doppler login
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host "|                                                                   DONE 🎉                                                                   |"
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host ""
Write-Host ""
PAUSE