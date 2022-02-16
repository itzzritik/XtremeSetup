# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "pwsh `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath wt.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

cls
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host "|                                                                                                                                             |"
Write-Host "|                                     Installing Oh-My-Posh Modules in Powershell (https://ohmyposh.dev/)                                     |"
Write-Host "|                                                                                                                                             |"
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""

$ModuleList = @('posh-git','oh-my-posh','git-aliases')
Foreach ($item in $ModuleList) { 
    if (!(Get-Module -ListAvailable $item -ErrorAction SilentlyContinue)) {
        Write-Host "     Installing $item module..."
        Install-Module -Name $item -Scope CurrentUser
        Write-Host "     Yayy! $item installed succesfully 🎉"
    }
    else {
        Write-Host "     Yayy! $item already installed 🎉"
    }
}

Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
# Get-PoshThemes

# -----------------------------------------------------------------------------------
# Setup Powershell Profilecode 
# -----------------------------------------------------------------------------------

$PowershellProfile = @"
Set-PoshPrompt -Theme space | out-null
Import-Module posh-git
Import-Module git-aliases -DisableNameChecking
cls
"@

Write-Host ""
Write-Host "     Setting up OH-MY-POSH theme into file: $PROFILE"
Set-Content -Path $PROFILE -Value $PowershellProfile

# -----------------------------------------------------------------------------------
# Setup Nerd Font
# -----------------------------------------------------------------------------------

#Install this Font manually -> https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FantasqueSansMono

Write-Host ""
$WindowsSettings = "$Env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
Write-Host "     Deleting default windows terminal settings at: $WindowsSettings"
Remove-Item -Path $WindowsSettings -Force -Recurse | out-null
Write-Host "     Setting up symbolic Link for windows terminal settings as: $PSScriptRoot\settings"
New-Item -ItemType SymbolicLink -Path $WindowsSettings -Target "$PSScriptRoot\settings" | out-null

Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host ""
Write-Host ""
PAUSE
