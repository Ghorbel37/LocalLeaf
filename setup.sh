#!/usr/bin/env bash
# Checks and installs everything needed to write LaTeX in VS Code on Linux.
#
#   ./setup.sh             check, then install what is missing (asks first)
#   ./setup.sh --check     only report what is installed
#   ./setup.sh --yes       install what is missing without asking
#   ./setup.sh --test      also build main.tex at the end
#
# Supports apt (Debian, Ubuntu, Mint), dnf (Fedora) and pacman (Arch, Manjaro).
# On Linux, Perl is already installed and TeX Live replaces MiKTeX.

set -u

CHECK_ONLY=0
YES=0
TEST=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        --yes) YES=1 ;;
        --test) TEST=1 ;;
        -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg"; exit 2 ;;
    esac
done

green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red() { printf '\033[31m%s\033[0m\n' "$1"; }
step() { printf '\n\033[36m== %s\033[0m\n' "$1"; }

if command -v apt-get >/dev/null 2>&1; then
    PM=apt
    TEX_PACKAGES="texlive-latex-extra texlive-fonts-recommended texlive-bibtex-extra lmodern latexmk biber"
    PYGMENTS_PACKAGE="python3-pygments"
    install_pkgs() { sudo apt-get update && sudo apt-get install -y "$@"; }
elif command -v dnf >/dev/null 2>&1; then
    PM=dnf
    TEX_PACKAGES="texlive-scheme-medium texlive-minted texlive-acro texlive-biblatex latexmk biber"
    PYGMENTS_PACKAGE="python3-pygments"
    install_pkgs() { sudo dnf install -y "$@"; }
elif command -v pacman >/dev/null 2>&1; then
    PM=pacman
    TEX_PACKAGES="texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra texlive-fontsrecommended texlive-bibtexextra texlive-pictures texlive-binextra biber"
    PYGMENTS_PACKAGE="python-pygments"
    install_pkgs() { sudo pacman -S --needed --noconfirm "$@"; }
else
    PM=none
fi

MISSING=0
JUST_INSTALLED=0

confirm() {
    [ "$YES" -eq 1 ] && return 0
    read -r -p "  Install $1 now? [Y/n] " answer
    case "$answer" in ""|[yYoO]*) return 0 ;; *) return 1 ;; esac
}

# check_tool NAME DETECT_COMMAND INSTALL_FUNCTION URL
check_tool() {
    local name="$1" detect="$2" install="$3" url="$4"
    if eval "$detect" >/dev/null 2>&1; then
        green "  [OK]      $name"
        return
    fi
    yellow "  [MISSING] $name  ->  $url"
    if [ "$CHECK_ONLY" -eq 1 ] || ! confirm "$name"; then
        MISSING=1
        return
    fi
    if "$install" && eval "$detect" >/dev/null 2>&1; then
        green "  [OK]      $name (just installed)"
        JUST_INSTALLED=1
    else
        red "  [ERROR]   $name could not be installed, see $url"
        MISSING=1
    fi
}

need_pm() {
    if [ "$PM" = none ]; then
        red "  No supported package manager found (apt, dnf or pacman), install it manually."
        return 1
    fi
}

install_vscode() {
    red "  VS Code is not in the default repositories of most distributions."
    echo "  Download the .deb or .rpm from https://code.visualstudio.com/download"
    echo "  (or run: sudo snap install code --classic), then run this script again."
    return 1
}
install_texlive() { need_pm && install_pkgs $TEX_PACKAGES; }
install_pygments() { need_pm && install_pkgs $PYGMENTS_PACKAGE; }
install_extension() { command -v code >/dev/null 2>&1 && code --install-extension james-yu.latex-workshop; }

echo "Local LaTeX setup for VS Code on Linux (package manager: $PM)"
[ "$CHECK_ONLY" -eq 1 ] && echo "(check only, nothing will be installed)"

step "Editor"
check_tool "Visual Studio Code" "command -v code" install_vscode "https://code.visualstudio.com/download"

step "TeX distribution"
check_tool "Perl" "command -v perl" "false" "https://www.perl.org/get.html"
check_tool "TeX Live (pdflatex, latexmk, biber)" \
    "command -v pdflatex && command -v latexmk && command -v biber && kpsewhich minted.sty && kpsewhich acro.sty" \
    install_texlive "https://tug.org/texlive/"

step "Code highlighting (minted)"
check_tool "Pygments" "command -v pygmentize" install_pygments "https://pygments.org/"

step "VS Code extension"
check_tool "LaTeX Workshop" "code --list-extensions | grep -qx james-yu.latex-workshop" install_extension \
    "https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop"

if [ "$JUST_INSTALLED" -eq 1 ]; then
    echo
    echo "  Some tools were just installed: restart VS Code so it sees them."
fi

if [ "$TEST" -eq 1 ]; then
    step "Test build"
    if [ "$MISSING" -eq 1 ]; then
        red "  Skipping the test build: some tools are missing."
    elif (cd "$(dirname "$0")" && latexmk -quiet main.tex); then
        green "  [OK]      main.pdf built"
    else
        red "  [ERROR]   The build failed, see main.log for details."
    fi
fi

if [ "$MISSING" -eq 1 ]; then
    exit 1
fi
echo
green "All set. Open this folder in VS Code and press Ctrl+Alt+B to build main.tex."
