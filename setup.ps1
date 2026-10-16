<#
.SYNOPSIS
    Checks and installs everything needed to write LaTeX in VS Code on Windows.

.DESCRIPTION
    Checks each tool of the toolchain and installs the missing ones with winget:
      - Visual Studio Code
      - MiKTeX (pdflatex, latexmk, biber)
      - Strawberry Perl (latexmk is a Perl script)
      - uv, then Pygments through uv (needed by minted)
      - the LaTeX Workshop extension for VS Code
    Nothing is installed without asking, unless -Yes is given.

.PARAMETER CheckOnly
    Only report what is installed, change nothing.

.PARAMETER Yes
    Install everything that is missing without asking.

.PARAMETER Test
    After the checks, compile main.tex with latexmk to prove the setup works.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\setup.ps1 -CheckOnly
#>
[CmdletBinding()]
param(
    [switch]$CheckOnly,
    [switch]$Yes,
    [switch]$Test
)

$ErrorActionPreference = 'Stop'

function Write-Step($Text) { Write-Host "`n== $Text" -ForegroundColor Cyan }
function Write-Ok($Text)   { Write-Host "  [OK]      $Text" -ForegroundColor Green }
function Write-Miss($Text) { Write-Host "  [MISSING] $Text" -ForegroundColor Yellow }
function Write-Err($Text)  { Write-Host "  [ERROR]   $Text" -ForegroundColor Red }

# Reload PATH from the registry so tools installed by this script are found right away
function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

function Find-Command($Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    return $null
}

# Perl shipped with Git for Windows is not enough for MiKTeX's latexmk, so ignore it
function Find-Perl {
    $all = Get-Command perl -All -ErrorAction SilentlyContinue
    foreach ($p in $all) {
        if ($p.Source -notmatch '\\Git\\') { return $p.Source }
    }
    return $null
}

function Confirm-Install($Name) {
    if ($Yes) { return $true }
    $answer = Read-Host "  Install $Name now? [Y/n]"
    return ($answer -eq '' -or $answer -match '^[yYoO]')
}

function Install-WithWinget($Id, $Name) {
    if (-not (Find-Command 'winget')) {
        Write-Err "winget is not available. Install 'App Installer' from the Microsoft Store: https://apps.microsoft.com/detail/9NBLGGH4NNS1"
        return $false
    }
    Write-Host "  Installing $Name with winget ($Id)..."
    winget install --id $Id --exact --source winget --accept-package-agreements --accept-source-agreements | Out-Host
    $ok = ($LASTEXITCODE -eq 0)
    Update-SessionPath
    if (-not $ok) { Write-Err "winget could not install $Name (exit code $LASTEXITCODE)." }
    return $ok
}

$results = [ordered]@{}

function Test-Tool {
    param($Name, [scriptblock]$Detect, [scriptblock]$Install, $Url)
    $found = & $Detect
    if ($found) {
        Write-Ok "$Name ($found)"
        $results[$Name] = 'installed'
        return
    }
    Write-Miss "$Name  ->  $Url"
    if ($CheckOnly) { $results[$Name] = 'missing'; return }
    if (-not (Confirm-Install $Name)) { $results[$Name] = 'skipped'; return }
    $null = & $Install
    $found = & $Detect
    if ($found) {
        Write-Ok "$Name ($found)"
        $results[$Name] = 'just installed'
    } else {
        Write-Err "$Name is still not found. Open a new terminal and run this script again, or install it from $Url"
        $results[$Name] = 'failed'
    }
}

Write-Host 'TeXready setup: LaTeX + VS Code on Windows' -ForegroundColor Cyan
if ($CheckOnly) { Write-Host '(check only, nothing will be installed)' }

Write-Step 'Editor'
Test-Tool -Name 'Visual Studio Code' -Url 'https://code.visualstudio.com/download' `
    -Detect { Find-Command 'code' } `
    -Install { Install-WithWinget 'Microsoft.VisualStudioCode' 'Visual Studio Code' }

Write-Step 'TeX distribution'
Test-Tool -Name 'MiKTeX' -Url 'https://miktex.org/download' `
    -Detect { Find-Command 'pdflatex' } `
    -Install { Install-WithWinget 'MiKTeX.MiKTeX' 'MiKTeX' }

Test-Tool -Name 'Strawberry Perl' -Url 'https://strawberryperl.com/' `
    -Detect { Find-Perl } `
    -Install { Install-WithWinget 'StrawberryPerl.StrawberryPerl' 'Strawberry Perl' }

Write-Step 'Code highlighting (minted)'
Test-Tool -Name 'uv' -Url 'https://docs.astral.sh/uv/getting-started/installation/' `
    -Detect { Find-Command 'uv' } `
    -Install { Install-WithWinget 'astral-sh.uv' 'uv' }

Test-Tool -Name 'Pygments' -Url 'https://pygments.org/' `
    -Detect { Find-Command 'pygmentize' } `
    -Install {
        if (-not (Find-Command 'uv')) { Write-Err 'uv is needed to install Pygments.'; return }
        uv tool install pygments | Out-Host
        uv tool update-shell | Out-Host
        Update-SessionPath
        $uvBin = Join-Path $env:USERPROFILE '.local\bin'
        if ($env:Path -notlike "*$uvBin*") { $env:Path = "$env:Path;$uvBin" }
    }

Write-Step 'VS Code extension'
Test-Tool -Name 'LaTeX Workshop' -Url 'https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop' `
    -Detect {
        if (-not (Find-Command 'code')) { return $null }
        $ext = code --list-extensions 2>$null | Where-Object { $_ -eq 'james-yu.latex-workshop' }
        if ($ext) { return 'james-yu.latex-workshop' }
        return $null
    } `
    -Install {
        if (-not (Find-Command 'code')) { Write-Err 'VS Code is needed to install the extension.'; return }
        code --install-extension james-yu.latex-workshop | Out-Host
    }

# Let MiKTeX download missing LaTeX packages on the fly instead of opening a popup
if ((Find-Command 'initexmf') -and -not $CheckOnly) {
    Write-Step 'MiKTeX settings'
    initexmf --set-config-value '[MPM]AutoInstall=1' | Out-Null
    Write-Ok 'MiKTeX installs missing packages automatically'
}

Write-Step 'Summary'
$results.GetEnumerator() | ForEach-Object {
    $color = 'Green'
    if ($_.Value -in @('missing', 'skipped')) { $color = 'Yellow' }
    if ($_.Value -eq 'failed') { $color = 'Red' }
    Write-Host ('  {0,-20} {1}' -f $_.Key, $_.Value) -ForegroundColor $color
}

$notReady = @($results.Values | Where-Object { $_ -in @('missing', 'skipped', 'failed') })
if ($results.Values -contains 'just installed') {
    Write-Host "`n  Some tools were just installed: restart VS Code (and any open terminal) so it sees them."
}

if ($Test) {
    Write-Step 'Test build'
    if ($notReady.Count -gt 0) {
        Write-Err 'Skipping the test build: some tools are missing.'
    } else {
        Push-Location $PSScriptRoot
        try {
            latexmk -quiet main.tex
            if ($LASTEXITCODE -eq 0) { Write-Ok "main.pdf built in $PSScriptRoot" }
            else { Write-Err 'The build failed, see main.log for details.' }
        } finally { Pop-Location }
    }
}

if ($notReady.Count -gt 0) { exit 1 }
Write-Host "`nAll set. Open this folder in VS Code and press Ctrl+Alt+B to build main.tex." -ForegroundColor Green
