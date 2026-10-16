# LocalLeaf

**Overleaf, but local, in VS Code. Batteries included.**

Write LaTeX in VS Code with everything you liked about Overleaf: the PDF rebuilds on every save and sits next to your source, double-click in the PDF jumps to the matching line, and bibliography and cross references just work. No internet, no compile timeout, your files stay in Git.

One command installs the toolchain on **Windows** or **Linux** and creates a ready-to-fill report.

## Quick start

You only need **[Visual Studio Code](https://code.visualstudio.com/download)**. Open a terminal in the folder where you keep your projects and run the command for your system. It checks what is installed, asks before installing anything missing, creates the project folder and opens it in VS Code.

**Windows** (PowerShell):

```powershell
iex "& { $(irm https://raw.githubusercontent.com/Ghorbel37/LocalLeaf/example/setup.ps1) } -Init my-report"
```

**Linux** (bash):

```bash
curl -fsSL https://raw.githubusercontent.com/Ghorbel37/LocalLeaf/example/setup.sh | bash -s -- --init my-report
```

Replace `my-report` with your project name. Then open `main.tex` and press **Ctrl+Alt+B**.

### Options

| Windows | Linux | Effect |
|---|---|---|
| `-Init NAME` | `--init NAME` | Create a project in the folder `NAME` and open it in VS Code |
| `-Example` | `--example` | With init, start from the example report instead of the empty one |
| `-CheckOnly` | `--check` | Only report what is installed, change nothing |
| `-Yes` | `--yes` | Install everything missing without asking |
| `-Test` | `--test` | Build `main.tex` at the end to prove everything works |

Leave out the init option to only install the tools. The Windows script installs with [winget](https://learn.microsoft.com/windows/package-manager/winget/), which ships with Windows 10 and 11, and tells MiKTeX to download missing LaTeX packages automatically. The Linux script works with apt (Debian, Ubuntu, Mint), dnf (Fedora) and pacman (Arch, Manjaro), and uses `sudo` for the packages.

## Two flavors

| Branch | What's inside | Pick it if |
|---|---|---|
| [`main`](../../tree/main) | The VS Code config, a `.gitignore` and the report structure **with empty chapters**. Code blocks use the built-in `listings` package, so no extra tool is needed | You want a clean start (this is what **Use this template** gives you) |
| [`example`](../../tree/example) | The same report **filled with an example**: a cheat-sheet chapter showing figures, tables, highlighted code (`minted`), equations, citations and acronyms. Also holds the setup scripts | You want to see what it can do, or keep the examples at hand while writing |

Without the setup script: click **Use this template** for `main`, or clone a flavor with `git clone -b example https://github.com/Ghorbel37/LocalLeaf.git`, or download the [`main`](../../archive/refs/heads/main.zip) or [`example`](../../archive/refs/heads/example.zip) ZIP.

## What's in a project

| File | What it does |
|---|---|
| [`.vscode/settings.json`](.vscode/settings.json) | LaTeX Workshop config: build with `latexmk` on save, SyncTeX (double-click in the PDF jumps to the source), PDF preview in a tab |
| [`.vscode/extensions.json`](.vscode/extensions.json) | VS Code offers to install LaTeX Workshop when you open the folder |
| [`main.tex`](main.tex) | Report structure: packages, page style, document outline |
| [`metadata.tex`](metadata.tex) | Title, author, institution, supervisor, date: edit this first |
| [`chapters/`](chapters/) | Title page, abstract, introduction, conclusion, appendix |
| [`acronyms.tex`](acronyms.tex) | Acronym list, printed automatically |
| [`references.bib`](references.bib) | Bibliography |
| [`images/`](images/) | Your figures |
| [`.gitignore`](.gitignore) | Ignores every LaTeX build file (`.aux`, `.log`, `.synctex.gz`, ...) |

## Manual installation

Prefer to install things yourself? The only real difference between the two systems is that Windows needs MiKTeX and Strawberry Perl, while Linux uses TeX Live and already has Perl.

| Tool | Why | Windows | Linux |
|---|---|---|---|
| VS Code | The editor | [Download](https://code.visualstudio.com/download) | [Download](https://code.visualstudio.com/download) |
| TeX distribution | `pdflatex`, `latexmk`, `biber` and the LaTeX packages | [MiKTeX](https://miktex.org/download) | [TeX Live](https://tug.org/texlive/), from your package manager (see below) |
| Perl | `latexmk` is a Perl script | [Strawberry Perl](https://strawberryperl.com/) | Already installed |
| LaTeX Workshop | VS Code extension: build, preview, SyncTeX, autocompletion | [Marketplace](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) | [Marketplace](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) |
| Pygments | Only for the `example` branch: code highlighting with `minted` | [uv](https://docs.astral.sh/uv/getting-started/installation/), then `uv tool install pygments` | `python3-pygments` from your package manager |

**Windows:** after installing MiKTeX, open the **MiKTeX Console**, go to **Settings** and set "Install missing packages on-the-fly" to **Always**. Install Strawberry Perl after MiKTeX and restart VS Code so it finds both.

**Linux packages:**

```bash
# Debian, Ubuntu, Mint
sudo apt install texlive-latex-extra texlive-fonts-recommended texlive-bibtex-extra lmodern latexmk biber

# Fedora
sudo dnf install texlive-scheme-medium texlive-acro texlive-biblatex latexmk biber

# Arch, Manjaro
sudo pacman -S texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra texlive-fontsrecommended texlive-bibtexextra texlive-pictures texlive-binextra biber
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
latexmk -pdf main.tex    # build
latexmk -c               # remove build files, keep the PDF
latexmk -C               # remove build files and the PDF
```

### Making it yours

- Fill in [`metadata.tex`](metadata.tex). To show a logo on the title page, put it in `images/` and set `\reportLogo`.
- Each chapter is a file in [`chapters/`](chapters/), included from `main.tex` with `\input{chapters/...}`. Add, remove or rename them freely.
- Need an example of a figure, table, equation or citation? See the [example chapter](../../blob/example/chapters/03-example-chapter.tex).
- For a French report, change `\usepackage[english]{babel}` to `\usepackage[french]{babel}` in `main.tex`.
- The `example` branch builds with `-shell-escape`, because `minted` needs it to call Pygments. Only build documents you trust with it.

## Troubleshooting

| Problem | Fix |
|---|---|
| `latexmk` cannot find Perl (Windows) | Install [Strawberry Perl](https://strawberryperl.com/), then restart VS Code |
| `File 'xyz.sty' not found` (Linux) | Install the missing package, or `texlive-full` to never see this again |
| Citations show as **[?]** or bold keys | Build again with `latexmk`, it runs Biber for you |
| A tool was just installed but VS Code does not see it | Close every VS Code window and reopen it so it picks up the new PATH |
| MiKTeX opens a popup for each package | Run `initexmf --set-config-value [MPM]AutoInstall=1`, or set it in the MiKTeX Console |
| `minted` errors (`example` branch) | Install Pygments (see above), build with the provided recipe, and restart VS Code |

## Useful links

- [LaTeX Workshop wiki](https://github.com/James-Yu/LaTeX-Workshop/wiki)
- [Overleaf's LaTeX guides](https://www.overleaf.com/learn), still the best place to learn LaTeX
- [biblatex](https://ctan.org/pkg/biblatex), [acro](https://ctan.org/pkg/acro), [listings](https://ctan.org/pkg/listings), [minted](https://ctan.org/pkg/minted) and [latexmk](https://ctan.org/pkg/latexmk) documentation

## License

[MIT](LICENSE)
