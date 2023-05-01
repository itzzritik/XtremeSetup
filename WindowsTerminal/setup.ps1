cls
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host "|                                                                                                                                             |"
Write-Host "|                                                         SETTING UP WINDOWS TERMINAL                                                         |"
Write-Host "|                                                                                                                                             |"
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host "     Installing Scoop - A command-line installer for Windows (https://scoop.sh)"
Write-Host ""
$ScoopCommand = "-command `"iwr -useb get.scoop.sh | iex`""
$ScoopCode = (Start-Process -FilePath pwsh -ArgumentList $ScoopCommand -PassThru -Wait).ExitCode
Write-Host "     Done! Scoop installed succesfully (Exitcode: $ScoopCode ) 🎉" -ForeGroundColor Green
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-w 0 -d . pwsh `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath wt.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

Write-Host ""
Write-Host "     Installing Oh-My-Posh with Scoop (https://ohmyposh.dev)"
Write-Host ""
$OMPExistsCommand = "-command `"oh-my-posh --version`""
$OMPExistsCode = (Start-Process -FilePath pwsh -ArgumentList $OMPExistsCommand -PassThru -Wait).ExitCode
if ($OMPExistsCode) {
    $OMPInstallCommand = "-command `"scoop install https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/oh-my-posh.json`""
    $OMPInstallCode = (Start-Process -FilePath pwsh -ArgumentList $OMPInstallCommand -PassThru -Wait).ExitCode
    Write-Host "     Done! Oh-My-Posh installed succesfully (Exitcode: $OMPInstallCode ) 🎉" -ForeGroundColor Green
}
else {
    Write-Host "     Yayy! Oh-My-Posh already installed 🎉" -ForeGroundColor Green
}
$OMPAddToDefender = "-command `"Add-MpPreference -ExclusionPath (Get-Command oh-my-posh).Source`""
Start-Process -FilePath pwsh -ArgumentList $OMPAddToDefender -PassThru -Wait
Write-Host "     Oh-My-Posh added to Windows Defender exclusion list 🎉" -ForeGroundColor Green
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host "     Installing Node (https://nodejs.org/)"
Write-Host ""
winget install OpenJS.NodeJS.LTS
Start-Process -FilePath "$Env:Programfiles/nodejs/install_tools.bat" -Wait -passthru;$a.ExitCode
npm install -g npm
Write-Host "     Node installed and setup succesfully 🎉" -ForeGroundColor Green
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host "     Installing Git (https://git-scm.com)"
Write-Host ""
winget install --id Git.Git -e --source winget
ssh-keygen -t ed25519 -C "ritik.space@gmail.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
git config --global user.name "Ritik Srivastava"
git config --global user.email "ritik.space@gmail.com"
git config --global gpg.format ssh
git config --global commit.gpgsign true
git config --global user.signingkey ~/.ssh/id_ed25519
Write-Host "     Git installed and setup succesfully 🎉" -ForeGroundColor Green
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host "     Installing Oh-My-Posh Extension in Powershell"
Write-Host ""
$ModuleList = @('posh-git', 'git-aliases', 'z')
for($i=0; $i -lt $ModuleList.Length; $i++) {
    $item = $ModuleList[$i]
    $index = $i + 1
    if (!(Get-Module -ListAvailable $item -ErrorAction SilentlyContinue)) {
        Write-Host -NoNewLine "     •)   Installing $item module..." -ForeGroundColor Yellow
        $CommandLine = "-command `"Install-Module -Name $item -Scope CurrentUser -Force`""
        Start-Process -FilePath pwsh -ArgumentList $CommandLine -PassThru -Wait
        # wt -w 0 sp -d . pwsh -command "Install-Module -Name $item -Scope CurrentUser"
        Write-Host "`r     $index)   Done! $item installed succesfully 🎉" -ForeGroundColor Green
    }
    else {
        Write-Host "     $index)   Yayy! $item already installed 🎉" -ForeGroundColor Green
    }
}

# Get-PoshThemes
$PowershellProfile = @'
try {
    oh-my-posh --version | Out-Null
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\space.omp.json" | Invoke-Expression
    Import-Module posh-git
    Import-Module git-aliases -DisableNameChecking
}
catch [System.Management.Automation.CommandNotFoundException] {}
cls
'@

Write-Host ""
Write-Host "     Setting up OH-MY-POSH theme into file:"
Write-Host "     •    $PROFILE" -ForeGroundColor Green
Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Set-Content -Path $PROFILE -Value $PowershellProfile

#Install this Font manually -> https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FantasqueSansMono
# https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/FantasqueSansMono/Regular/complete/Fantasque%20Sans%20Mono%20Regular%20Nerd%20Font%20Complete.ttf

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
Write-Host ""
Write-Host "     Installing Doppler CLI (https://docs.doppler.com/docs/install-cli)"
Write-Host ""
$DopplerExistsCommand = "-command `"doppler --version`""
$DopplerExistsCode = (Start-Process -FilePath pwsh -ArgumentList $DopplerExistsCommand -PassThru -Wait).ExitCode
if ($DopplerExistsCode) {
    $DopplerAddCommand = "-command `"scoop bucket add doppler https://github.com/DopplerHQ/scoop-doppler.git`""
    $DopplerAddCode = (Start-Process -FilePath pwsh -ArgumentList $DopplerAddCommand -PassThru -Wait).ExitCode
    $DopplerInstallCommand = "-command `"scoop install doppler`""
    $DopplerInstallCode = (Start-Process -FilePath pwsh -ArgumentList $DopplerInstallCommand -PassThru -Wait).ExitCode
    Write-Host "     Done! Doppler CLI installed succesfully (Exitcode: $DopplerInstallCode ) 🎉" -ForeGroundColor Green
}
else {
    Write-Host "     Yayy! Doppler already installed 🎉" -ForeGroundColor Green
}

Write-Host ""
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host "|                                                                   DONE 🎉                                                                   |"
Write-Host "+---------------------------------------------------------------------------------------------------------------------------------------------+"
Write-Host ""
Write-Host ""
Write-Host ""
PAUSE
