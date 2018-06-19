\mainmatter

# (PART) Get Started {-}

# Installation

We assume you have already installed R (https://www.r-project.org) [@R-base] and the RStudio IDE (https://www.rstudio.com). RStudio is not required but recommended, because it makes it easier for an average user to work with R Markdown. If you do not have RStudio IDE installed, you will have to install Pandoc\index{Pandoc} (http://pandoc.org), otherwise there is no need to install Pandoc separately because RStudio has bundled it. Next you can install the **rmarkdown** package in R:

```{r eval=FALSE, tidy=FALSE}
# Install from CRAN
install.packages('rmarkdown')

# Or if you want to test the development version,
# install from GitHub
if (!requireNamespace("devtools"))
  install.packages('devtools')
devtools::install_github('rstudio/rmarkdown')
```

If you want to generate PDF output, you will need to install LaTeX. For R Markdown users who have not installed LaTeX before, we recommend that you install TinyTeX (https://yihui.name/tinytex/):

```{r eval=FALSE}
install.packages('tinytex')
tinytex::install_tinytex()  # install TinyTeX
```

TinyTeX\index{TinyTeX} is a lightweight, portable, cross-platform, and easy-to-maintain LaTeX distribution. The R companion package **tinytex** [@R-tinytex]\index{tinytex} can help you automatically install missing LaTeX packages when compiling LaTeX or R Markdown documents to PDF, and also ensures a LaTeX document is compiled for the correct number of times to resolve all cross-references. If you do not understand what these two things mean, you should probably follow our recommendation to install TinyTeX, because these details are often not worth your time or attention.

With the **rmarkdown** package, RStudio/Pandoc, and LaTeX, you should be able to compile most R Markdown documents. In some cases, you may need other software packages, and we will mention them when necessary.
