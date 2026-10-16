<#
.SYNOPSIS
    Checks and installs everything needed to write LaTeX in VS Code on Windows,
    and optionally creates a new LocalLeaf project.

.DESCRIPTION
    Checks each tool of the toolchain and installs the missing ones with winget:
      - Visual Studio Code
      - MiKTeX (pdflatex, latexmk, biber)
      - Strawberry Perl (latexmk is a Perl script)
      - the LaTeX Workshop extension for VS Code
      - uv and Pygments, only for projects that use minted (the example report)
    Nothing is installed without asking, unless -Yes is given.

    Run it without downloading anything first:
      iex "& { $(irm https://raw.githubusercontent.com/Ghorbel37/LocalLeaf/example/setup.ps1) } -Init my-report"

.PARAMETER Init
    Create a new project in this folder (relative to the current directory)
    and open it in VS Code.

.PARAMETER Example
    With -Init, start from the example report instead of the empty one.

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
    [string]$Init,
    [switch]$Example,
    [switch]$CheckOnly,
    [switch]$Yes,
    [switch]$Test
)

$ErrorActionPreference = 'Stop'
$Repo = 'Ghorbel37/LocalLeaf'
# Run from a file (-File) or from memory (irm | iex): never close the terminal in the second case
$FromFile = [bool]$PSCommandPath

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

# Download a branch of the repository into a new folder, without its Git history
function New-Project($Name, $Branch) {
    $target = Join-Path (Get-Location) $Name
    if (Test-Path $target) {
        Write-Err "The folder '$target' already exists, pick another name."
        return $null
    }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("localleaf-" + [guid]::NewGuid())
    New-Item -ItemType Directory $tmp | Out-Null
    try {
        $zip = Join-Path $tmp 'repo.zip'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest "https://github.com/$Repo/archive/refs/heads/$Branch.zip" -OutFile $zip -UseBasicParsing
        Expand-Archive $zip -DestinationPath $tmp
        $extracted = Get-ChildItem $tmp -Directory | Select-Object -First 1
        Move-Item $extracted.FullName $target
    } finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
    # The setup scripts are not part of a project
    Remove-Item (Join-Path $target 'setup.ps1'), (Join-Path $target 'setup.sh') -ErrorAction SilentlyContinue
    if (Find-Command 'git') {
        git -C $target init --quiet
        Write-Ok "Created $target (new Git repository)"
    } else {
        Write-Ok "Created $target"
    }
    return $target
}

Write-Host 'LocalLeaf: LaTeX in VS Code, set up on Windows' -ForegroundColor Cyan
if ($CheckOnly) { Write-Host '(check only, nothing will be installed)' }

# Run from memory with no project name: offer to create one
if (-not $FromFile -and -not $Init -and -not $CheckOnly) {
    $Init = Read-Host "`nName of the project folder to create here (leave empty to only install the tools)"
}

# Pygments is only needed by minted, which the example report uses
$projectDir = if ($Init) { $null } elseif ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$needsMinted = [bool]$Example
if (-not $Init) {
    $mainTex = Join-Path $projectDir 'main.tex'
    $needsMinted = (Test-Path $mainTex) -and (Select-String -Path $mainTex -Pattern '\{minted\}' -Quiet)
}

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

if ($needsMinted) {
    Write-Step 'Code highlighting (minted, used by the example report)'
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

if ($Init -and -not $CheckOnly) {
    Write-Step 'New project'
    $branch = if ($Example) { 'example' } else { 'main' }
    $projectDir = New-Project $Init $branch
}

if ($Test -and $projectDir) {
    Write-Step 'Test build'
    if ($notReady.Count -gt 0) {
        Write-Err 'Skipping the test build: some tools are missing.'
    } else {
        Push-Location $projectDir
        try {
            $latexmkArgs = @('-pdf', '-interaction=nonstopmode', '-quiet')
            if ($needsMinted) { $latexmkArgs += '-shell-escape' }
            latexmk @latexmkArgs main.tex | Out-Host
            if ($LASTEXITCODE -eq 0) { Write-Ok "main.pdf built in $projectDir" }
            else { Write-Err 'The build failed, see main.log for details.' }
        } finally { Pop-Location }
    }
}

if ($notReady.Count -gt 0) {
    if ($FromFile) { exit 1 }
    return
}

if ($Init -and $projectDir) {
    if (Find-Command 'code') { code $projectDir }
    Write-Host "`nAll set. VS Code is opening ${projectDir}: open main.tex and press Ctrl+Alt+B." -ForegroundColor Green
} else {
    Write-Host "`nAll set. Open your project folder in VS Code and press Ctrl+Alt+B to build main.tex." -ForegroundColor Green
}
