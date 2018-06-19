# Community Formats {#community}

Most output formats introduced in this book are created and maintained by the RStudio team. In fact, other members in the R community have also created a number of R Markdown output formats.\index{output formats} We mention those formats that we are aware of in this chapter. If you have developed or know other formats, please feel free to suggest that we add them to the page https://rmarkdown.rstudio.com/formats.html.

## Lightweight Pretty HTML Documents {#prettydoc}

When designing the **rmarkdown** package, we wished it could produce output documents that look pleasant by default, especially for HTML documents. Pandoc does not really style the HTML documents when converting Markdown to HTML, but **rmarkdown** does. As we mentioned in Section \@ref(appearance-and-style), the themes of HTML documents are based on Bootswatch, which actually relies on the Bootstrap library (https://getbootstrap.com). Although these themes look pretty, the major disadvantage is that their file sizes are relatively large. The size of an HTML document created from an empty R Markdown document with the `html_document` format is about 600Kb, which is roughly the total size of all CSS, JavaScript, and font files in the default theme.

If you are concerned about the file size but still want a fancy theme, you may consider the **prettydoc** package [@R-prettydoc], which has bundled a few pretty themes (yet small in size). This package provides an output format `prettydoc::html_pretty`. An empty R Markdown document with this format generates an HTML file of about 70Kb.

### Usage {#prettydoc-usage}

The usage of `prettydoc::html_pretty` is very similar to `html_document`, with two major differences:

- The `theme` option takes different values. The currently supported themes are `"cayman"`, `"tactile"`, `"architect"`, `"leonids"`, and `"hpstr"`. Figure \@ref(fig:prettydoc) shows the appearance of the `leonids` theme. See https://github.com/yixuan/prettydoc for screenshots of more themes.

- The `highlight` option takes `null`, `"github"`, or `"vignette"`.

Below is an example of the YAML metadata of an R Markdown document that uses the `prettydoc::html_pretty` output format:

```yaml
---
title: "Your Document Title"
author: "Document Author"
date: "2018-04-16"
output:
  prettydoc::html_pretty:
    theme: leonids
    highlight: github
---
```

```{r prettydoc, echo=FALSE, fig.cap='The leonids theme of the prettydoc package.', out.width='100%'}
knitr::include_graphics('images/prettydoc.png', dpi = NA)
```

### Package vignettes {#prettydoc-vignettes}

The `prettydoc::html_pretty` can be particularly useful for R package vignettes.\index{R package vignette} We have mentioned the `html_vignette` format in Section \@ref(r-package-vignette) that also aims at smaller file sizes, but that format is not as stylish. To apply the `prettydoc::html_pretty` format to a package vignette, you may use the YAML metadata below:

```yaml
---
title: "Vignette Title"
author: "Vignette Author"
output: prettydoc::html_pretty
vignette: >
  %\VignetteIndexEntry{Vignette Title}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---
```

Do not forget to change the vignette title, author, and the index entry. You should also add `prettydoc` to the `Suggests` field of your package `DESCRIPTION` file, and the two package names `knitr, rmarkdown` to the `VignetteBuilder` field.

## The rmdformats package {#rmdformats}

The **rmdformats** package [@R-rmdformats] provides several HTML output formats of unique and attractive styles, including:

- `material`: A format based on the [Material design theme for Bootstrap 3](https://github.com/FezVrasta/bootstrap-material-design). With this format, every first-level section will become a separate page. See Figure \@ref(fig:rmdformats-material) for what this format looks like ("Introduction" and "Including Plots" are two first-level sections).

- `readthedown`: It features a sidebar layout. The table of contents is displayed in the sidebar on the left. As you scroll on the page, the current section header will be automatically highlighted (and expanded if necessary) in the sidebar.

- `html_clean`: A simple and clean HTML template, with a dynamic table of contents at the top-right of the page.

- `html_docco`: A simple template inspired by [the Docco project](https://github.com/jashkenas/docco).

Do not forget the `rmdformats::` prefix when you use these formats, e.g.,

```yaml
---
output: rmdformats::material
---
```

```{r rmdformats-material, echo=FALSE, fig.cap='The Material Design theme in the rmdformats package.', out.width='100%'}
knitr::include_graphics('images/rmdformats-material.png', dpi = NA)
```

These output formats have some additional features such as responsiveness and code folding. Please refer to the GitHub repository of the **rmdformats** package for more information: https://github.com/juba/rmdformats.

## Shower presentations

Shower (https://github.com/shower/shower) is a popular and customizable HTML5 presentation\index{HTML5 slides} framework. See Figure \@ref(fig:shower) for what it looks like.

```{r shower, echo=FALSE, fig.cap='A few sample slides created via the Shower presentation framework.', out.width='100%'}
knitr::include_graphics('images/shower.png', dpi = NA)
```

The R package **rmdshower** (https://github.com/mangothecat/rmdshower) is built on top of Shower. You may install it from GitHub:

```{r eval=FALSE}
devtools::install_github("mangothecat/rmdshower")
```

You can create a Shower presentation with the output format `rmdshower::shower_presentation`, e.g.,

```yaml
---
title: "Hello Shower"
author: "John Doe"
output: rmdshower::shower_presentation
---
```

See the help page `?rmdshower::shower_presentation` for all possible options of this format.
