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
    Create a new project in the current directory and open it in VS Code.
    Give the project name right after it (-Init my-report), or leave it out
    and the script asks for it.

.PARAMETER Name
    Name of the project folder to create (implies -Init).

.PARAMETER Example
    With -Init, start from the example report instead of the empty one.

.PARAMETER Enis
    With -Init, start from the ENIS graduation report template by Jacem Chaieb.

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
    [switch]$Init,
    [Parameter(Position = 0)]
    [string]$Name,
    [switch]$Example,
    [switch]$Enis,
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
    # The setup scripts and the repository images are not part of a project
    Remove-Item (Join-Path $target 'setup.ps1'), (Join-Path $target 'setup.sh') -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force (Join-Path $target '.github') -ErrorAction SilentlyContinue
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

# -Init without a name: ask for it
if ($Init -and -not $Name -and -not $CheckOnly) {
    while (-not $Name) {
        $Name = (Read-Host "`nName of your report (a folder with this name is created here)").Trim()
    }
}

# Run from memory with no option at all: offer to create a project
if (-not $FromFile -and -not $Init -and -not $Name -and -not $CheckOnly) {
    $Name = (Read-Host "`nName of your report (leave empty to only install the tools)").Trim()
}

# Pygments is only needed by minted, which the example report uses
$projectDir = if ($Name) { $null } elseif ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$needsMinted = $Example -or $Enis
if (-not $Name) {
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
    Write-Step 'Code highlighting (minted, used by the example and ENIS reports)'
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

# minted is the part that most often breaks: compile a tiny document to be sure it works
function Test-Minted {
    $dir = Join-Path ([IO.Path]::GetTempPath()) ("localleaf-minted-" + [guid]::NewGuid())
    New-Item -ItemType Directory $dir | Out-Null
    $tex = @'
\documentclass{article}
\usepackage{minted}
\begin{document}
\begin{minted}{python}
print("minted works")
\end{minted}
\end{document}
'@
    Set-Content -Path (Join-Path $dir 'test.tex') -Value $tex -Encoding ascii
    Push-Location $dir
    try {
        pdflatex -shell-escape -interaction=nonstopmode -halt-on-error test.tex 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path 'test.pdf')) { return $null }
        $firstError = Select-String -Path 'test.log' -Pattern '^! ' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($firstError) { return $firstError.Line.TrimStart('!', ' ') }
        return 'pdflatex failed, no error message found'
    } finally {
        Pop-Location
        Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
    }
}

if ($needsMinted -and (Find-Command 'pdflatex')) {
    Write-Step 'minted test (compiling a small code block)'
    $mintedError = Test-Minted
    if ($mintedError) {
        Write-Host "  [WARNING] minted does not work yet: $mintedError" -ForegroundColor Yellow
        Write-Host '            Common fixes:' -ForegroundColor Yellow
        Write-Host '            - Close every VS Code window and terminal, then try again (PATH changes need a restart)' -ForegroundColor Yellow
        Write-Host '            - Install Pygments: uv tool install pygments' -ForegroundColor Yellow
        Write-Host '            - Update MiKTeX in the MiKTeX Console (Updates tab), minted 3 needs a recent latexminted' -ForegroundColor Yellow
        Write-Host '            - Delete the _minted folder next to your .tex file, it caches old results' -ForegroundColor Yellow
        Write-Host '            More: https://github.com/Ghorbel37/LocalLeaf#minted-troubleshooting' -ForegroundColor Yellow
        $results['minted'] = 'warning'
    } else {
        Write-Ok 'minted works: code blocks are highlighted'
        $results['minted'] = 'works'
    }
}

Write-Step 'Summary'
$results.GetEnumerator() | ForEach-Object {
    $color = 'Green'
    if ($_.Value -in @('missing', 'skipped', 'warning')) { $color = 'Yellow' }
    if ($_.Value -eq 'failed') { $color = 'Red' }
    Write-Host ('  {0,-20} {1}' -f $_.Key, $_.Value) -ForegroundColor $color
}

$notReady = @($results.Values | Where-Object { $_ -in @('missing', 'skipped', 'failed') })
if ($results.Values -contains 'just installed') {
    Write-Host "`n  Some tools were just installed: restart VS Code (and any open terminal) so it sees them."
}

if ($Name -and -not $CheckOnly) {
    Write-Step 'New project'
    $branch = if ($Enis) { 'enis' } elseif ($Example) { 'example' } else { 'main' }
    $projectDir = New-Project $Name $branch
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
            $mainFile = if (Test-Path 'main.tex') { 'main.tex' } else { '001-report.tex' }
            latexmk @latexmkArgs $mainFile | Out-Host
            if ($LASTEXITCODE -eq 0) { Write-Ok "PDF built in $projectDir" }
            else { Write-Err 'The build failed, see main.log for details.' }
        } finally { Pop-Location }
    }
}

if ($notReady.Count -gt 0) {
    if ($FromFile) { exit 1 }
    return
}

if ($results['minted'] -eq 'warning') {
    Write-Host "`nAlmost set: everything is installed, but code blocks (minted) will fail until the warning above is fixed." -ForegroundColor Yellow
}

if ($Name -and $projectDir) {
    if (Find-Command 'code') { code $projectDir }
    Write-Host "`nAll set. VS Code is opening ${projectDir}: open the main .tex file and press Ctrl+Alt+B." -ForegroundColor Green
} else {
    Write-Host "`nAll set. Open your project folder in VS Code and press Ctrl+Alt+B to build main.tex." -ForegroundColor Green
}
