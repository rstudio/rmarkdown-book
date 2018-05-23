all:
	BOOKDOWN_FULL_PDF=false Rscript --quiet _render.R

pdf:
	Rscript --quiet _render.R "bookdown::pdf_book" &&\
	mv _book/rmarkdown.pdf rmarkdown-full.pdf

gitbook:
	Rscript --quiet _render.R "bookdown::gitbook"
