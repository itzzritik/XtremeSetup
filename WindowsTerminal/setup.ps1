# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "pwsh `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath wt.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

################################################################################################################################
# Install Oh-My-Posh Module in Powershell (https://ohmyposh.dev/)
################################################################################################################################

cls
$ModuleList = @('posh-git','oh-my-posh','git-aliases')
Foreach ($item in $ModuleList) { 
    if (!(Get-Module -ListAvailable $item -ErrorAction SilentlyContinue)) {
        Write-Host "Installing $item module..."
        Install-Module -Name $item -Scope CurrentUser
        Write-Host "Yayy! $item installed succesfully 🎉"
    }
    else {
        Write-Host "Yayy! $item already installed 🎉"
    }
}
# Get-PoshThemes

# -----------------------------------------------------------------------------------
# Setup Powershell Profile
# -----------------------------------------------------------------------------------

$PowershellProfile = @"
Set-PoshPrompt -Theme space | out-null
Import-Module posh-git
Import-Module git-aliases -DisableNameChecking
cls
"@

echo $PowershellProfile > $PROFILE

# -----------------------------------------------------------------------------------
# Setup Nerd Font
# -----------------------------------------------------------------------------------

#Install this Font manually -> https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FantasqueSansMono

$WindowsSettings = "$Env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
echo "
Deleting default windows terminal settings at: $WindowsSettings"
Remove-Item -Path $WindowsSettings -Force -Recurse | out-null
echo "Setting up symbolic Link for windows terminal settings to: $PSScriptRoot\settings"
New-Item -ItemType SymbolicLink -Path $WindowsSettings -Target "$PSScriptRoot\settings" | out-null

ECHO ""
PAUSE
