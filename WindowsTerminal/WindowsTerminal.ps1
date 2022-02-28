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
Write-Host "|                                                         SETTING UP WINDOWS TERMINAL                                                         |"
Write-Host "|                                                                                                                                             |"
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""

Write-Host "     Installing Oh-My-Posh Modules in Powershell (https://ohmyposh.dev)"
Write-Host ""
$ModuleList = @('posh-git','oh-my-posh', 'git-aliases')
for($i=0; $i -lt $ModuleList.Length; $i++) {
    $item = $ModuleList[$i]
    $index = $i + 1
    if (!(Get-Module -ListAvailable $item -ErrorAction SilentlyContinue)) {
        Write-Host -NoNewLine "     •)   Installing $item module..." -ForeGroundColor Yellow
        $CommandLine = "-command `"Install-Module -Name $item -Scope CurrentUser -Force`""
        Start-Process -FilePath pwsh -ArgumentList $CommandLine -Wait
        # wt -w 0 sp -d . pwsh -command "Install-Module -Name $item -Scope CurrentUser"
        Write-Host "`r     $index)   Done! $item installed succesfully 🎉" -ForeGroundColor Green
    }
    else {
        Write-Host "     $index)   Yayy! $item already installed 🎉" -ForeGroundColor Green
    }
}
# Get-PoshThemes

$PowershellProfile = @"
Set-PoshPrompt -Theme space | out-null
Import-Module posh-git
Import-Module git-aliases -DisableNameChecking
cls
"@

Write-Host ""
Write-Host "     Setting up OH-MY-POSH theme into file:"
Write-Host "     •    $PROFILE" -ForeGroundColor Green
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Set-Content -Path $PROFILE -Value $PowershellProfile

#Install this Font manually -> https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FantasqueSansMono

Write-Host ""
Write-Host "     Setting up Windows Terminal 'Settings.json' file as a Symbolic Link"
Write-Host ""
$WindowsSettings = "$Env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
Write-Host "     1)  Deleting default windows terminal settings located at:"
Write-Host "          •   $WindowsSettings" -ForeGroundColor Green
Remove-Item -Path $WindowsSettings -Force -Recurse | out-null
Write-Host ""
Write-Host "     2)  Setting up symbolic link for windows terminal settings as:"
Write-Host "          •   $PSScriptRoot\settings" -ForeGroundColor Green
New-Item -ItemType SymbolicLink -Path $WindowsSettings -Target "$PSScriptRoot\settings" | out-null

Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host "|                                                                   DONE 🎉                                                                   |"
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host ""
Write-Host ""
PAUSE
