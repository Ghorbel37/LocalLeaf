# LocalLeaf (bare)

**Overleaf, but local, in VS Code.** This is the bare flavor: an empty report and the VS Code config, nothing else.

Looking for the setup scripts, the install guide or an example report? They are on the [`main`](../../tree/main) branch.

## What's inside

| File | What it does |
|---|---|
| [`.vscode/settings.json`](.vscode/settings.json) | LaTeX Workshop config: build with `latexmk` on save, SyncTeX (double-click in the PDF jumps to the source), PDF preview in a tab |
| [`.vscode/extensions.json`](.vscode/extensions.json) | VS Code offers to install [LaTeX Workshop](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) when you open the folder |
| [`main.tex`](main.tex) | Report structure: packages, page style, document outline |
| [`metadata.tex`](metadata.tex) | Title, author, institution, supervisor, date |
| [`chapters/`](chapters/) | Title page, abstract, introduction, conclusion, appendix, all empty |
| [`acronyms.tex`](acronyms.tex) / [`references.bib`](references.bib) | Acronyms and bibliography, empty |
| [`.gitignore`](.gitignore) | Ignores every LaTeX build file |

It only needs a standard TeX distribution ([MiKTeX](https://miktex.org/download) with [Strawberry Perl](https://strawberryperl.com/) on Windows, [TeX Live](https://tug.org/texlive/) on Linux) and no external tool: code blocks use the built-in `listings` package, so there is no Pygments and no `-shell-escape`.

## Use it

1. Clone it: `git clone -b bare https://github.com/Ghorbel37/LocalLeaf.git my-report`, or [download the ZIP](../../archive/refs/heads/bare.zip).
2. Open the folder in VS Code and press **Ctrl+Alt+B**.
3. Fill in `metadata.tex`, then write in `chapters/`.

## License

[MIT](LICENSE)
