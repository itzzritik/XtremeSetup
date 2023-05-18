Write-Host "     Installing Node (https://nodejs.org/)"
Write-Host ""
winget install OpenJS.NodeJS.LTS
Start-Process -FilePath "$Env:Programfiles/nodejs/install_tools.bat" -Wait -passthru;$a.ExitCode
npm install -g npm
Write-Host "     Node installed and setup succesfully 🎉" -ForeGroundColor Green