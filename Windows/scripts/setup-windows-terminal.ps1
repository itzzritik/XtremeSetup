Write-Host "     Setting up Windows Terminal 'Settings.json' file as a Symbolic Link"
Write-Host ""

# Create Projects Directory
New-Item -ItemType Directory -Force -Path "D:/Projects" | Out-Null

# Initialize Windows Terminal Settings Directories
$GlobalWindowsSettings = "$Env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$LocalWindowsSettings = Resolve-Path("$PSScriptRoot\..\config\windows_terminal\settings")

Write-Host "     1)  Deleting default windows terminal settings located at:"
Write-Host "          •   $GlobalWindowsSettings" -ForeGroundColor Green

Remove-Item -Path $GlobalWindowsSettings -Force -Recurse | out-null

Write-Host ""
Write-Host "     2)  Setting up symbolic link for windows terminal settings as:"
Write-Host "          •   $LocalWindowsSettings" -ForeGroundColor Green

New-Item -ItemType SymbolicLink -Path $GlobalWindowsSettings -Target $LocalWindowsSettings | out-null
Write-Host "     Yayy! Windows Terminal setup successfull 🎉" -ForeGroundColor Green