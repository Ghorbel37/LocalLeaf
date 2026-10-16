# latexmk configuration, used both by VS Code (LaTeX Workshop) and the command line.
# From a folder containing main.tex, just run:  latexmk

$pdf_mode = 1;    # build a PDF with pdflatex
$pdflatex = 'pdflatex --max-print-line=10000 -shell-escape -synctex=1 -interaction=nonstopmode -file-line-error -recorder %O %S';
$bibtex_use = 2;  # run bibtex/biber when needed, and clean its files with latexmk -c
@default_files = ('001-report.tex');

# Also remove these with "latexmk -c"
$clean_ext = 'run.xml synctex.gz %R-blx.bib _minted-%R';
