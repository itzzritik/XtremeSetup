Write-Host "     Installing Git (https://git-scm.com)"
Write-Host ""
# Install Git
winget install --id Git.Git -e --source winget

# Setup Git Config
git config --global user.name "Ritik Srivastava"
git config --global user.email "ritik.space@gmail.com"
git config --global gpg.format ssh
git config --global commit.gpgsign true

Write-Host "     ✔ Git installed and setup succesfully 🎉" -ForeGroundColor Green