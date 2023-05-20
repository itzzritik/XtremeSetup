Write-Host "     Installing Node (https://nodejs.org/)"
Write-Host ""
# Install Node if not installed
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeInstalled) {
    winget install OpenJS.NodeJS.LTS
}

$InstallToolsCode = (Start-Process -FilePath pwsh -ArgumentList "-File `"$Env:Programfiles`"/nodejs/install_tools.bat" -PassThru -Wait).ExitCode
Write-Host "     Tools Installed Successfully (Exitcode: $InstallToolsCode )" -ForeGroundColor Green
npm install -g npm
Write-Host "     Node installed and setup succesfully 🎉" -ForeGroundColor Green