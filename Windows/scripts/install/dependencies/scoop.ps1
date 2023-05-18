Write-Host "     Installing Scoop - A command-line installer for Windows (https://scoop.sh)"
Write-Host ""
$ScoopCommand = "-ExecutionPolicy Bypass -command `"iwr -useb get.scoop.sh | iex`""
$ScoopCode = (Start-Process -FilePath pwsh -ArgumentList $ScoopCommand -PassThru -Wait).ExitCode
Write-Host ""
Write-Host "     ✔ Scoop installed succesfully (Exitcode: $ScoopCode ) 🎉" -ForeGroundColor Green
Write-Host ""