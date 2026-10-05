# Usage (one UAC prompt, everything after is unattended):
#   irm setup-windows.ritik.me | iex
#   powershell -ExecutionPolicy Bypass -File Windows\index.ps1 [task...]
param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Tasks)

$ProgressPreference = 'SilentlyContinue'
$Script = 'https://raw.githubusercontent.com/itzzritik/XtremeSetup/main/Windows/index.ps1'
$Repo = 'https://github.com/itzzritik/XtremeSetup/archive/HEAD.tar.gz'
$WorkDir = Join-Path $env:TEMP 'jarvis-setup'
$Log = Join-Path $env:TEMP 'jarvis-setup.log'
$Order = 'system', 'apps', 'toolchain', 'shell', 'git'

if (-not $Tasks) { $Tasks = $Order }
$unknown = $Tasks | Where-Object { $_ -notin $Order }
if ($unknown) { throw "Unknown tasks: $($unknown -join ', '). Available: $($Order -join ', ')" }
$Tasks = $Order | Where-Object { $_ -in $Tasks }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

$identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $run = if ($PSCommandPath) { "& '$PSCommandPath' $Tasks" } else { "& ([scriptblock]::Create((irm '$Script'))) $Tasks" }
    Start-Process powershell -Verb RunAs -ArgumentList '-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $run
    Write-Host 'Setup continues in the admin window; nothing else needs input.' -ForegroundColor Cyan
    return
}

[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = $PSScriptRoot
$downloaded = -not $root -or -not (Test-Path (Join-Path $root 'tasks'))
try {
    if ($downloaded) {
        Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $WorkDir -ErrorAction Stop | Out-Null
        Invoke-WebRequest $Repo -OutFile "$WorkDir\repo.tar.gz" -UseBasicParsing -ErrorAction Stop
        tar -xzf "$WorkDir\repo.tar.gz" -C $WorkDir --strip-components=2 '*/Windows'
        if ($LASTEXITCODE) { throw "tar exited with $LASTEXITCODE" }
        $root = $WorkDir
    }

    if ((winget configure list 2>&1 | Out-String) -match 'Extended features are not enabled') {
        winget configure --enable | Out-Null
        winget configure list 2>&1 | Out-Null
    }

    $failed = @()
    "XtremeSetup run $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-File $Log -Encoding utf8
    foreach ($task in $Tasks) {
        Write-Host "`n==> $task" -ForegroundColor Cyan
        winget configure -f (Join-Path $root "tasks\$task.winget") --accept-configuration-agreements --disable-interactivity --suppress-initial-details | Tee-Object -Variable output
        if ($LASTEXITCODE) { $failed += $task }
        "`n==> $task", $output | Out-File $Log -Append -Encoding utf8
    }
}
finally {
    if ($downloaded) { Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($failed) {
    $summary, $color = "Failed: $($failed -join ', '). Re-run just those with: index.ps1 $($failed -join ' ')", 'Red'
}
else {
    $summary, $color = 'All tasks are in the desired state.', 'Green'
}
"`n$summary" | Out-File $Log -Append -Encoding utf8
Write-Host "`n$summary" -ForegroundColor $color
Write-Host "Log: $Log"
