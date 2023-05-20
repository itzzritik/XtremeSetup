Write-Host "     Setting up Git (https://git-scm.com)"
Write-Host ""

# Install Git if not installed
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitInstalled) {
    winget install --id Git.Git -e --source winget
}

# Setup Git Config
git config --global user.name "Ritik Srivastava"
git config --global user.email "ritik.space@gmail.com"
git config --global gpg.format ssh
git config --global commit.gpgsign true

# Setup SSH Agent
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"

Write-Host "     ✔ Git setup succesfully 🎉" -ForeGroundColor Green