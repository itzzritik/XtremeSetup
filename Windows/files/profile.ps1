# Managed by XtremeSetup (Windows/files/profile.ps1). Edit it there; changes here are overwritten.

$env:EDITOR = 'code --wait'

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config space --strict | Invoke-Expression
}

if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --version-file-strategy recursive --shell powershell | Out-String | Invoke-Expression
}

if ((Get-Module PSReadLine) -and -not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

Import-Module posh-git -ErrorAction SilentlyContinue
Import-Module git-aliases -DisableNameChecking -ErrorAction SilentlyContinue

Set-Alias cc claude

if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza --icons @args }
    function ll { eza -la --icons --git @args }
}

function kp {
    if (-not $args) {
        'kp - kill processes on given ports'
        'Usage: kp <port>...   e.g. kp 8080 8081'
        return
    }
    $ids = Get-NetTCPConnection -State Listen -LocalPort $args -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
    if (-not $ids) { "No processes on: $args"; return }
    Stop-Process -Id $ids -Force
    "Killed: $ids"
}

function bios { sudo shutdown /r /fw /t 0 }

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
