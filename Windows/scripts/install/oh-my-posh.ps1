# Self-elevate the script if not already running as administrator
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-w 0 -d . pwsh `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath wt.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

Write-Host "     Installing Oh-My-Posh with Winget (https://ohmyposh.dev)"
Write-Host ""

$OMPExistsCommand = "-command `"oh-my-posh --version`""
$OMPExistsCode = (Start-Process -FilePath pwsh -ArgumentList $OMPExistsCommand -PassThru -Wait).ExitCode

# Install Oh-My-Posh
if ($OMPExistsCode) {
    $OMPInstallCommand = "-command `"winget install JanDeDobbeleer.OhMyPosh -s winget`""
    $OMPInstallCode = (Start-Process -FilePath pwsh -ArgumentList $OMPInstallCommand -PassThru -Wait).ExitCode
    Write-Host "     ✔ Done! Oh-My-Posh installed succesfully (Exitcode: $OMPInstallCode ) 🎉" -ForeGroundColor Green
}
else {
    Write-Host "     ✔ Yayy! Oh-My-Posh already installed 🎉" -ForeGroundColor Green
}

# Install Nerd Fonts
Write-Host "     Installing Nerd Fonts with Oh-My-Posh"
$OMPInstallNerdFontCommand = "-command `"oh-my-posh font install`""
$OMPInstallNerdFontCode = (Start-Process -FilePath pwsh -ArgumentList $OMPInstallNerdFontCommand -PassThru -Wait).ExitCode
Write-Host "     ✔ Nerd Font installed succesfully (Exitcode: $OMPInstallNerdFontCode ) 🎉" -ForeGroundColor Green

# Add Oh-My-Posh to Windows Defender exclusion list
$OMPAddToDefender = "-command `"Add-MpPreference -ExclusionPath (Get-Command oh-my-posh).Source`""
Start-Process -FilePath pwsh -ArgumentList $OMPAddToDefender -PassThru -Wait
Write-Host "     ✔ Oh-My-Posh added to Windows Defender exclusion list 🎉" -ForeGroundColor Green

# Install Oh-My-Posh Extensions
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
        Write-Host "`r     $index)   ✔ Done! $item installed succesfully 🎉" -ForeGroundColor Green
    }
    else {
        Write-Host "     $index)   ✔ Yayy! $item already installed 🎉" -ForeGroundColor Green
    }
}

# Setup Oh-My-Posh in Powershell Profile
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
Set-Content -Path $PROFILE -Value $PowershellProfile
Write-Host ""
Write-Host "     Setting up OH-MY-POSH theme into file:"
Write-Host "     •    $PROFILE" -ForeGroundColor Green

#Install this Font manually -> https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FantasqueSansMono
# https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/FantasqueSansMono/Regular/complete/Fantasque%20Sans%20Mono%20Regular%20Nerd%20Font%20Complete.ttf
