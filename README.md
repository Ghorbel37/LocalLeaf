# LocalLeaf

**Overleaf, but local, in VS Code. Batteries included.**

Write LaTeX in VS Code with everything you liked about Overleaf: the PDF rebuilds on every save and sits next to your source, double-click in the PDF jumps to the matching line, and code blocks, bibliography and cross references just work. No internet, no compile timeout, your files stay in Git.

It comes with a ready-to-fill report template, a `.gitignore` made for LaTeX, and a setup script for **Windows** and **Linux** that checks what is installed and installs the rest.

## What you get

| File | What it does |
|---|---|
| [`.vscode/settings.json`](.vscode/settings.json) | LaTeX Workshop config: build with `latexmk` on save, SyncTeX (double-click in the PDF jumps to the source), PDF preview in a tab |
| [`.vscode/extensions.json`](.vscode/extensions.json) | VS Code offers to install LaTeX Workshop when you open the folder |
| [`.latexmkrc`](.latexmkrc) | Same build options for the terminal, so `latexmk` alone is enough |
| [`main.tex`](main.tex) | Report template: packages, page style, document outline |
| [`metadata.tex`](metadata.tex) | Title, author, institution, supervisor, date: edit this first |
| [`chapters/`](chapters/) | Title page, abstract, introduction, an example chapter (cheat sheet), conclusion, appendix |
| [`acronyms.tex`](acronyms.tex) | Acronym list, printed automatically |
| [`references.bib`](references.bib) | Bibliography |
| [`images/`](images/) | Your figures |
| [`setup.ps1`](setup.ps1) / [`setup.sh`](setup.sh) | Check and install the whole toolchain on Windows / Linux |
| [`.gitignore`](.gitignore) | Ignores every LaTeX build file (`.aux`, `.log`, `.synctex.gz`, `_minted`, ...) |

## Prerequisites

You only need **[Visual Studio Code](https://code.visualstudio.com/download)** and **[Git](https://git-scm.com/downloads)** to get the files. The setup script handles everything else (on Windows it can even install VS Code for you).

## Quick start

1. Click **Use this template** on GitHub to create your own copy, then clone it. Or [download the ZIP](../../archive/refs/heads/main.zip).
2. Run the setup script for your system (see below). It tells you what is missing and asks before installing anything.
3. Open the folder in VS Code (**File > Open Folder**), open `main.tex` and press **Ctrl+Alt+B**. The PDF appears in a tab next to the source.
4. Edit [`metadata.tex`](metadata.tex), then start writing in [`chapters/`](chapters/).

### Windows

Open PowerShell in the folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

| Option | Effect |
|---|---|
| `-CheckOnly` | Only report what is installed, change nothing |
| `-Yes` | Install everything missing without asking |
| `-Test` | After the checks, build `main.tex` to prove everything works |

It installs with [winget](https://learn.microsoft.com/windows/package-manager/winget/), which ships with Windows 10 and 11 (if it is missing, get [App Installer](https://apps.microsoft.com/detail/9NBLGGH4NNS1) from the Microsoft Store). It also tells MiKTeX to download missing LaTeX packages automatically instead of showing a popup for each one.

### Linux

Open a terminal in the folder and run:

```bash
chmod +x setup.sh
./setup.sh
```

| Option | Effect |
|---|---|
| `--check` | Only report what is installed, change nothing |
| `--yes` | Install everything missing without asking |
| `--test` | After the checks, build `main.tex` to prove everything works |

It works with apt (Debian, Ubuntu, Mint), dnf (Fedora) and pacman (Arch, Manjaro), and uses `sudo` for the packages.

## Manual installation

Prefer to install things yourself? Here is what each OS needs. The only real difference is that Windows needs MiKTeX and Strawberry Perl, while Linux uses TeX Live and already has Perl.

| Tool | Why | Windows | Linux |
|---|---|---|---|
| VS Code | The editor | [Download](https://code.visualstudio.com/download) | [Download](https://code.visualstudio.com/download) the `.deb`/`.rpm`, or `sudo snap install code --classic` |
| TeX distribution | `pdflatex`, `latexmk`, `biber` and the LaTeX packages | [MiKTeX](https://miktex.org/download) | [TeX Live](https://tug.org/texlive/), from your package manager (see below) |
| Perl | `latexmk` is a Perl script | [Strawberry Perl](https://strawberryperl.com/) | Already installed |
| Pygments | Code highlighting engine used by `minted` | [uv](https://docs.astral.sh/uv/getting-started/installation/), then `uv tool install pygments` | `python3-pygments` from your package manager |
| LaTeX Workshop | VS Code extension: build, preview, SyncTeX, autocompletion | [Marketplace](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) | [Marketplace](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) |

**Windows:** after installing MiKTeX, open the **MiKTeX Console**, go to **Settings** and set "Install missing packages on-the-fly" to **Always**. Install Strawberry Perl after MiKTeX and restart VS Code so it finds both.

**Linux packages:**

```bash
# Debian, Ubuntu, Mint
sudo apt install texlive-latex-extra texlive-fonts-recommended texlive-bibtex-extra lmodern latexmk biber python3-pygments

# Fedora
sudo dnf install texlive-scheme-medium texlive-minted texlive-acro texlive-biblatex latexmk biber python3-pygments

# Arch, Manjaro
sudo pacman -S texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra texlive-fontsrecommended texlive-bibtexextra texlive-pictures texlive-binextra biber python-pygments
```

Want every LaTeX package at once? Install `texlive-full` (Debian, Ubuntu), `texlive-scheme-full` (Fedora) or `texlive` (Arch). It is several GB.

## Using it

### In VS Code

| Shortcut | Action |
|---|---|
| **Ctrl+S** | Save and rebuild |
| **Ctrl+Alt+B** | Build manually |
| **Ctrl+Alt+V** | Open the PDF preview |
| **Double-click in the PDF** | Jump to the matching line in the source |
| **Ctrl+Alt+J** in the source | Jump to the matching place in the PDF |

The TeX icon in the sidebar shows the document outline, the build recipes and the error list. Two recipes are available: `latexmk (pdflatex)` (default, runs as many passes as needed, bibliography included) and `pdflatex (single pass)` (quick rebuild).

### From a terminal

```bash
latexmk          # build main.tex
latexmk -c       # remove build files, keep the PDF
latexmk -C       # remove build files and the PDF
```

### Making it yours

- Fill in [`metadata.tex`](metadata.tex). To show a logo on the title page, put it in `images/` and set `\reportLogo`.
- Each chapter is a file in [`chapters/`](chapters/), included from `main.tex` with `\input{chapters/...}`. Add, remove or rename them freely.
- [`chapters/03-example-chapter.tex`](chapters/03-example-chapter.tex) shows figures, tables, code, equations, citations, acronyms and lists. Keep it as a cheat sheet, then remove it from `main.tex`.
- For a French report, change `\usepackage[english]{babel}` to `\usepackage[french]{babel}` in `main.tex`.
- `-shell-escape` is enabled because `minted` needs it to call Pygments. Only build documents you trust with this setup.

## Troubleshooting

| Problem | Fix |
|---|---|
| `latexmk` cannot find Perl (Windows) | Install [Strawberry Perl](https://strawberryperl.com/), then restart VS Code |
| `minted` error: "You must invoke LaTeX with the -shell-escape flag" | Build with the provided recipe or `latexmk`, both enable it |
| `minted` error about `pygmentize` or `latexminted` | Install Pygments (`uv tool install pygments` on Windows, `python3-pygments` on Linux) and restart VS Code |
| `File 'xyz.sty' not found` (Linux) | Install the missing package, or `texlive-full` to never see this again |
| Citations show as **[?]** or bold keys | Build again with `latexmk`, it runs Biber for you |
| A tool was just installed but VS Code does not see it | Close every VS Code window and reopen it so it picks up the new PATH |
| MiKTeX opens a popup for each package | Run `initexmf --set-config-value [MPM]AutoInstall=1`, or set it in the MiKTeX Console |

## Useful links

- [LaTeX Workshop wiki](https://github.com/James-Yu/LaTeX-Workshop/wiki)
- [Overleaf's LaTeX guides](https://www.overleaf.com/learn), still the best place to learn LaTeX
- [minted](https://ctan.org/pkg/minted), [biblatex](https://ctan.org/pkg/biblatex), [acro](https://ctan.org/pkg/acro) and [latexmk](https://ctan.org/pkg/latexmk) documentation

## License

[MIT](LICENSE)
