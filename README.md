<p align="center">
  <img src=".github/assets/logo.png" alt="LocalLeaf logo" width="110">
</p>

<h1 align="center">LocalLeaf: ENIS report</h1>

<p align="center"><b>The ENIS graduation report template, ready to build in VS Code.</b></p>

## Credit

This report template was created by **[Jacem Chaieb](https://jacem.ch)** ([kidager/enis-report-latex](https://github.com/kidager/enis-report-latex), also on [Overleaf](https://www.overleaf.com/latex/templates/national-school-of-engineers-of-sfax-enis-report/xjrnfvzfxqrn) under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)). All the credit for its design goes to him: if you use it, keep his name in the file headers and credit him.

LocalLeaf only adds the VS Code setup around it and two small fixes so it builds with current LaTeX distributions:

- `\usepackage[francais,english]{babel}` became `[french,english]`, since recent babel versions removed the `francais` option.
- `\printacronyms[header=...]` became `[heading=...]`, the option's new name in recent versions of `acro`.

## What's inside

| File | What it does |
|---|---|
| [`001-report.tex`](001-report.tex) | Main file: packages and the list of chapters |
| [`000-commands.tex`](000-commands.tex) | Your details: name, title, supervisors, jury, dates |
| [`002-top_matter.tex`](002-top_matter.tex) | The official ENIS cover page |
| [`003-thanks.tex`](003-thanks.tex) | Acknowledgements |
| [`004-chapter0-introduction.tex`](004-chapter0-introduction.tex), [`004-chapter1.tex`](004-chapter1.tex) | Introduction and chapters. For more chapters, copy `004-chapter1.tex` and add it to `001-report.tex` |
| [`005-conclusion.tex`](005-conclusion.tex), [`006-appendix.tex`](006-appendix.tex), [`007-references.tex`](007-references.tex) | Conclusion, appendix and references |
| [`001-report.bib`](001-report.bib) | Bibliography |
| [`008-abstract.pdf`](008-abstract.pdf) | Back cover with the abstract, added as a PDF |
| [`enis-pfe-report.cls`](enis-pfe-report.cls) | The ENIS report style |
| [`.vscode/`](.vscode/), [`.latexmkrc`](.latexmkrc) | LocalLeaf build setup: build on save, SyncTeX, `latexmk` from the terminal |

## Use it

Install the tools and create a project from this template in one command:

```powershell
iex "& { $(irm https://raw.githubusercontent.com/Ghorbel37/LocalLeaf/example/setup.ps1) } -Init my-report -Enis"
```

```bash
curl -fsSL https://raw.githubusercontent.com/Ghorbel37/LocalLeaf/example/setup.sh | bash -s -- --init my-report --enis
```

You can also run the short command from the [main README](https://github.com/Ghorbel37/LocalLeaf#quick-start) and pick the ENIS template when it asks. Then open `001-report.tex` and press **Ctrl+Alt+B**. In a terminal, `latexmk` builds it.

> [!WARNING]
> This template uses `minted` for code, so it builds with `-shell-escape` and is the part most likely to break. If code blocks fail, follow the [minted troubleshooting guide](https://github.com/Ghorbel37/LocalLeaf#minted-troubleshooting). The [main README](https://github.com/Ghorbel37/LocalLeaf#readme) also covers manual installation.

## Support

If LocalLeaf helped you, a star or a mention is appreciated. And credit Jacem Chaieb for the template itself.

## License

The template files are by Jacem Chaieb, under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The LocalLeaf setup files (`.vscode/`, `.latexmkrc`, `.gitignore`, setup scripts) are under the [MIT license](LICENSE).
