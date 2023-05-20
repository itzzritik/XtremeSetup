Write-Host "     Installing Recommended Apps"
Write-Host ""

function ConvertKebabToStartCase($inputString) {
    $words = $inputString -split "-" | ForEach-Object { $_.ToLower() }
    $outputString = ($words | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join " "
    return $outputString
}
function InstallApps($folderPath) {
    # Get the list of files in the directory
    $fileList = Get-ChildItem -Path $folderPath -File

    # Loop through each file in the list
    foreach ($file in $fileList) {
        $AppName = ConvertKebabToStartCase -inputString $file.BaseName
        $FilePath = $file.FullName
        $AppInstallCode = (Start-Process -FilePath pwsh -ArgumentList "-File `"$FilePath`"" -PassThru -Wait).ExitCode
        Write-Host "     $AppName Installed Successfully (Exitcode: $AppInstallCode )" -ForeGroundColor Green
        Write-Host ""
    }
}

InstallApps -folderPath "$PSScriptRoot\install\dependencies"
InstallApps -folderPath "$PSScriptRoot\install"
