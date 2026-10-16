#!/usr/bin/env bash
# LocalLeaf: checks and installs everything needed to write LaTeX in VS Code
# on Linux, and optionally creates a new project.
#
#   ./setup.sh                    check, then install what is missing (asks first)
#   ./setup.sh --init my-report   also create a new project and open it in VS Code
#   ./setup.sh --init             same, and ask for the project name
#   ./setup.sh --example          with --init, start from the example report
#   ./setup.sh --enis             with --init, start from the ENIS report template (by Jacem Chaieb)
#   ./setup.sh --check            only report what is installed
#   ./setup.sh --yes              install what is missing without asking
#   ./setup.sh --test             also build main.tex at the end
#
# Run it without downloading anything first:
#   curl -fsSL https://raw.githubusercontent.com/Ghorbel37/LocalLeaf/example/setup.sh | bash -s -- --init my-report
#
# Supports apt (Debian, Ubuntu, Mint), dnf (Fedora) and pacman (Arch, Manjaro).
# On Linux, Perl is already installed and TeX Live replaces MiKTeX.

set -u

REPO="Ghorbel37/LocalLeaf"
INIT=""
ASK_NAME=0
EXAMPLE=0
ENIS=0
CHECK_ONLY=0
YES=0
TEST=0
while [ $# -gt 0 ]; do
    case "$1" in
        --init)
            ASK_NAME=1
            case "${2:-}" in ""|-*) ;; *) INIT="$2"; shift ;; esac ;;
        --example) EXAMPLE=1 ;;
        --enis) ENIS=1 ;;
        --check) CHECK_ONLY=1 ;;
        --yes) YES=1 ;;
        --test) TEST=1 ;;
        -h|--help) sed -n '2,18p' "$0" 2>/dev/null; exit 0 ;;
        *) echo "Unknown option: $1"; exit 2 ;;
    esac
    shift
done

# When piped from curl, stdin is the script itself: read answers from the terminal
# ask PROMPT FALLBACK: FALLBACK is the answer when there is no terminal (CI, scripts)
ask() {
    local prompt="$1" answer="$2"
    if (exec </dev/tty) 2>/dev/null; then
        read -r -p "$prompt" answer </dev/tty || answer="$2"
    fi
    printf '%s' "$answer"
}

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
MINTED_WARNING=0

confirm() {
    [ "$YES" -eq 1 ] && return 0
    case "$(ask "  Install $1 now? [Y/n] " no)" in ""|[yYoO]*) return 0 ;; *) return 1 ;; esac
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
    echo "  Install it from https://code.visualstudio.com/download, then run this script again."
    return 1
}
install_texlive() { need_pm && install_pkgs $TEX_PACKAGES; }
install_pygments() { need_pm && install_pkgs $PYGMENTS_PACKAGE; }
install_extension() { command -v code >/dev/null 2>&1 && code --install-extension james-yu.latex-workshop; }

# new_project NAME BRANCH: download a branch of the repository without its Git history
new_project() {
    local target="$PWD/$1" branch="$2"
    if [ -e "$target" ]; then
        red "  [ERROR]   The folder $target already exists, pick another name."
        return 1
    fi
    mkdir -p "$target"
    if ! curl -fsSL "https://github.com/$REPO/archive/refs/heads/$branch.tar.gz" | tar -xz -C "$target" --strip-components=1; then
        red "  [ERROR]   Could not download the template."
        rm -rf "$target"
        return 1
    fi
    rm -f "$target/setup.ps1" "$target/setup.sh"
    rm -rf "$target/.github"
    if command -v git >/dev/null 2>&1; then
        git -C "$target" init --quiet
        green "  [OK]      Created $target (new Git repository)"
    else
        green "  [OK]      Created $target"
    fi
    PROJECT_DIR="$target"
}

echo "LocalLeaf: LaTeX in VS Code, set up on Linux (package manager: $PM)"
[ "$CHECK_ONLY" -eq 1 ] && echo "(check only, nothing will be installed)"

# --init without a name: ask for it
if [ "$ASK_NAME" -eq 1 ] && [ -z "$INIT" ] && [ "$CHECK_ONLY" -eq 0 ]; then
    echo
    for _ in 1 2 3; do
        INIT="$(ask "Name of your report (a folder with this name is created here): " "")"
        [ -n "$INIT" ] && break
    done
    if [ -z "$INIT" ]; then
        red "No project name given, run again with --init NAME."
        exit 2
    fi
fi

# Piped from curl with no option at all: offer to create a project
if [ ! -f "$0" ] && [ "$ASK_NAME" -eq 0 ] && [ -z "$INIT" ] && [ "$CHECK_ONLY" -eq 0 ]; then
    echo
    INIT="$(ask "Name of your report (leave empty to only install the tools): " "")"
fi

# Pygments is only needed by minted, which the example report uses
PROJECT_DIR=""
NEEDS_MINTED=$EXAMPLE
[ "$ENIS" -eq 1 ] && NEEDS_MINTED=1
if [ -z "$INIT" ]; then
    if [ -f "$0" ]; then PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"; else PROJECT_DIR="$PWD"; fi
    grep -q '{minted}' "$PROJECT_DIR/main.tex" 2>/dev/null && NEEDS_MINTED=1
fi

step "Editor"
check_tool "Visual Studio Code" "command -v code" install_vscode "https://code.visualstudio.com/download"

step "TeX distribution"
check_tool "Perl" "command -v perl" "false" "https://www.perl.org/get.html"
check_tool "TeX Live (pdflatex, latexmk, biber)" \
    "command -v pdflatex && command -v latexmk && command -v biber && kpsewhich acro.sty" \
    install_texlive "https://tug.org/texlive/"

step "VS Code extension"
check_tool "LaTeX Workshop" "code --list-extensions | grep -qx james-yu.latex-workshop" install_extension \
    "https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop"

if [ "$NEEDS_MINTED" -eq 1 ]; then
    step "Code highlighting (minted, used by the example and ENIS reports)"
    check_tool "Pygments" "command -v pygmentize && kpsewhich minted.sty" install_pygments "https://pygments.org/"
fi

# minted is the part that most often breaks: compile a tiny document to be sure it works
test_minted() {
    local dir rc
    dir="$(mktemp -d)"
    cat > "$dir/test.tex" <<'TEX'
\documentclass{article}
\usepackage{minted}
\begin{document}
\begin{minted}{python}
print("minted works")
\end{minted}
\end{document}
TEX
    (cd "$dir" && pdflatex -shell-escape -interaction=nonstopmode -halt-on-error test.tex >/dev/null 2>&1 && [ -f test.pdf ])
    rc=$?
    [ $rc -ne 0 ] && MINTED_ERROR="$(grep -m1 '^! ' "$dir/test.log" 2>/dev/null | sed 's/^! //')"
    rm -rf "$dir"
    return $rc
}

if [ "$NEEDS_MINTED" -eq 1 ] && command -v pdflatex >/dev/null 2>&1 && kpsewhich minted.sty >/dev/null 2>&1; then
    step "minted test (compiling a small code block)"
    MINTED_ERROR=""
    if test_minted; then
        green "  [OK]      minted works: code blocks are highlighted"
    else
        MINTED_WARNING=1
        yellow "  [WARNING] minted does not work yet: ${MINTED_ERROR:-pdflatex failed}"
        yellow "            Common fixes:"
        yellow "            - Restart VS Code and your terminal (PATH changes need a restart)"
        yellow "            - Install Pygments (${PYGMENTS_PACKAGE:-Pygments}) and Python 3"
        yellow "            - Delete the _minted folder next to your .tex file, it caches old results"
        yellow "            More: https://github.com/Ghorbel37/LocalLeaf#minted-troubleshooting"
    fi
fi

if [ "$JUST_INSTALLED" -eq 1 ]; then
    echo
    echo "  Some tools were just installed: restart VS Code so it sees them."
fi

if [ -n "$INIT" ] && [ "$CHECK_ONLY" -eq 0 ]; then
    step "New project"
    if [ "$ENIS" -eq 1 ]; then new_project "$INIT" enis
    elif [ "$EXAMPLE" -eq 1 ]; then new_project "$INIT" example
    else new_project "$INIT" main; fi
fi

if [ "$TEST" -eq 1 ] && [ -n "$PROJECT_DIR" ]; then
    step "Test build"
    LATEXMK_ARGS="-pdf -interaction=nonstopmode -quiet"
    [ "$NEEDS_MINTED" -eq 1 ] && LATEXMK_ARGS="$LATEXMK_ARGS -shell-escape"
    if [ "$MISSING" -eq 1 ]; then
        red "  Skipping the test build: some tools are missing."
    elif (cd "$PROJECT_DIR" && f=main.tex && { [ -f "$f" ] || f=001-report.tex; } && latexmk $LATEXMK_ARGS "$f"); then
        green "  [OK]      PDF built in $PROJECT_DIR"
    else
        red "  [ERROR]   The build failed, see main.log for details."
    fi
fi

[ "$MISSING" -eq 1 ] && exit 1

echo
if [ "$MINTED_WARNING" -eq 1 ]; then
    yellow "Almost set: everything is installed, but code blocks (minted) will fail until the warning above is fixed."
fi
if [ -n "$INIT" ] && [ -n "$PROJECT_DIR" ]; then
    command -v code >/dev/null 2>&1 && code "$PROJECT_DIR"
    green "All set. VS Code is opening $PROJECT_DIR: open the main .tex file and press Ctrl+Alt+B."
else
    green "All set. Open your project folder in VS Code and press Ctrl+Alt+B to build main.tex."
fi
