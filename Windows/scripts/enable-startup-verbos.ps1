Write-Host "     Enabling verbose on startup, shutdown, logon, and logoff status screens"

# Enable verbose startup, shutdown, logon, and logoff status messages
$VerboseStatusRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$VerboseStatusRegistryValue = "VerboseStatus"

# Check if the registry path exists, create it if not
if (!(Test-Path $VerboseStatusRegistryPath)) {
    New-Item -Path $VerboseStatusRegistryPath -Force | Out-Null
}

# Set the registry value to enable verbose status messages
Set-ItemProperty -Path $VerboseStatusRegistryPath -Name $VerboseStatusRegistryValue -Value 1
Write-Host ""
Write-Host "     ✔ Done! Please restart your computer for the changes to take effect"
