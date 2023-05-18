Write-Host "     Installing Doppler CLI (https://docs.doppler.com/docs/install-cli)"
Write-Host ""
$DopplerExistsCommand = "-command `"doppler --version`""
$DopplerExistsCode = (Start-Process -FilePath pwsh -ArgumentList $DopplerExistsCommand -PassThru -Wait).ExitCode
if ($DopplerExistsCode) {
    $DopplerAddCommand = "-command `"scoop bucket add doppler https://github.com/DopplerHQ/scoop-doppler.git`""
    $DopplerAddCode = (Start-Process -FilePath pwsh -ArgumentList $DopplerAddCommand -PassThru -Wait).ExitCode
    $DopplerInstallCommand = "-command `"scoop install doppler`""
    $DopplerInstallCode = (Start-Process -FilePath pwsh -ArgumentList $DopplerInstallCommand -PassThru -Wait).ExitCode
    Write-Host "     ✔ Done! Doppler CLI installed succesfully (Exitcode: $DopplerInstallCode ) 🎉" -ForeGroundColor Green
}
else {
    Write-Host "     ✔ Yayy! Doppler already installed 🎉" -ForeGroundColor Green
}