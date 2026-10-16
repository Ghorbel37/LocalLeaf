# TeXready

A ready-to-use setup for writing LaTeX documents in **VS Code on Windows**: one click to build, PDF preview side by side, jump between source and PDF, code highlighting with `minted`, and a bibliography with `biblatex`.

It comes with a PowerShell script that checks what is already installed on your machine and installs the rest for you.

## What you get

| File | What it does |
|---|---|
| [`.vscode/settings.json`](.vscode/settings.json) | LaTeX Workshop config: build with `latexmk` on save, SyncTeX (double-click in the PDF jumps to the source), PDF preview in a tab |
| [`.vscode/extensions.json`](.vscode/extensions.json) | VS Code suggests installing LaTeX Workshop when you open the folder |
| [`.latexmkrc`](.latexmkrc) | Same build options for the command line, so `latexmk` alone is enough |
| [`main.tex`](main.tex) | Starter document using `minted`, `biblatex`, tables and images: if it builds, your setup works |
| [`references.bib`](references.bib) | Example bibliography |
| [`setup.ps1`](setup.ps1) | Checks and installs the whole toolchain |
| [`.gitignore`](.gitignore) | Ignores every LaTeX build file (`.aux`, `.log`, `_minted`, ...) |

## Quick start

1. Click **Use this template** on GitHub (or [download the ZIP](../../archive/refs/heads/main.zip)) to get your own copy.
2. Open PowerShell in the folder and run the setup script:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup.ps1
   ```

   It checks each tool, tells you what is missing and asks before installing anything.
3. Open the folder in VS Code and press **Ctrl+Alt+B**. `main.pdf` appears next to `main.tex`.

### Setup script options

| Command | Effect |
|---|---|
| `.\setup.ps1 -CheckOnly` | Only reports what is installed, changes nothing |
| `.\setup.ps1 -Yes` | Installs everything missing without asking |
| `.\setup.ps1 -Test` | After the checks, builds `main.tex` to prove everything works |

The script uses [winget](https://learn.microsoft.com/windows/package-manager/winget/), which ships with Windows 10 and 11. If it is missing, install [App Installer](https://apps.microsoft.com/detail/9NBLGGH4NNS1) from the Microsoft Store. It also tells MiKTeX to download missing LaTeX packages automatically instead of showing a popup for each one.

## Manual installation

Prefer to install things yourself? Here is everything the script installs, in order:

| Tool | Why | Download |
|---|---|---|
| Visual Studio Code | The editor | [code.visualstudio.com](https://code.visualstudio.com/download) |
| MiKTeX | The TeX distribution: `pdflatex`, `latexmk`, `biber` | [miktex.org/download](https://miktex.org/download) |
| Strawberry Perl | `latexmk` is a Perl script, Windows has no Perl by default | [strawberryperl.com](https://strawberryperl.com/) |
| uv | Python tool installer, used to install Pygments | [docs.astral.sh/uv](https://docs.astral.sh/uv/getting-started/installation/) |
| Pygments | Code highlighting engine used by `minted` | `uv tool install pygments` ([pygments.org](https://pygments.org/)) |
| LaTeX Workshop | VS Code extension: build, preview, SyncTeX, autocompletion | [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) |

After installing MiKTeX, open the **MiKTeX Console**, go to **Settings** and set "Install missing packages on-the-fly" to **Always**.

## Building

### In VS Code

- **Ctrl+Alt+B**: build (also runs automatically on save)
- **Ctrl+Alt+V**: open the PDF preview
- **Double-click in the PDF**: jump to the matching line in the source
- **Ctrl+Alt+J** in the source: jump to the matching place in the PDF

Two recipes are available from the TeX sidebar: `latexmk (pdflatex)` (default, runs as many passes as needed, bibliography included) and `pdflatex (single pass)` (quick rebuild).

### From a terminal

```powershell
latexmk          # build main.tex
latexmk -c       # remove build files, keep the PDF
latexmk -C       # remove build files and the PDF
```

## Adapting it to your document

- Replace the content of `main.tex` with your own, and put images in [`images/`](images/).
- For a French document, change `\usepackage[english]{babel}` to `\usepackage[french]{babel}`.
- Splitting a long document into chapters works out of the box: create `chapters/intro.tex` and add `\input{chapters/intro}` in `main.tex`.
- If your main file is not called `main.tex`, update `@default_files` in [`.latexmkrc`](.latexmkrc).
- `-shell-escape` is enabled because `minted` needs it to call Pygments. Only build documents you trust with this setup.

## Troubleshooting

| Problem | Fix |
|---|---|
| `latexmk` says it cannot find Perl | Install [Strawberry Perl](https://strawberryperl.com/), then restart VS Code |
| `minted` error: "You must invoke LaTeX with the -shell-escape flag" | Build with the provided recipe or `latexmk`, both enable it |
| `minted` error about `pygmentize` / `latexminted` | Run `uv tool install pygments` and restart VS Code |
| Citations show as **[?]** or bold keys | Build again with `latexmk`, it runs Biber for you |
| A tool was just installed but VS Code does not see it | Close every VS Code window and reopen it so it picks up the new PATH |
| MiKTeX opens a popup for each package | Run `initexmf --set-config-value [MPM]AutoInstall=1`, or set it in the MiKTeX Console |

## Useful links

- [LaTeX Workshop wiki](https://github.com/James-Yu/LaTeX-Workshop/wiki)
- [minted documentation](https://ctan.org/pkg/minted)
- [biblatex documentation](https://ctan.org/pkg/biblatex)
- [latexmk documentation](https://ctan.org/pkg/latexmk)
- [Overleaf's LaTeX guides](https://www.overleaf.com/learn), useful even when working locally

## License

[MIT](LICENSE)
