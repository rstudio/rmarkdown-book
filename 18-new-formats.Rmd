# Creating New Formats {#new-formats}

The **rmarkdown** package has included many built-in document and presentation formats. At their core, these formats are just R functions. When you include an output format in the YAML metadata of a document, you are essentially specifying the format function to call and the parameters to pass to it.

We can create new formats for R Markdown, which makes it easy to customize output formats to use specific options or refer to external files. Defining a new function can be particularly beneficial if you have generated a new template as described in Chapter \@ref(document-templates), as it allows you to use your custom templates without having to copy any files to your local directory.

## Deriving from built-in formats {#format-derive}

The easiest way to create a new format is to write a function that calls one of the built-in formats. These built-in formats are designed to be extensible enough to serve as the foundation of custom formats. The following example, `quarterly_report`, is based on `html_document` but alters the default options:

```{r, eval=FALSE, tidy=FALSE}
quarterly_report = function(toc = TRUE) {
  # locations of resource files in the package
  pkg_resource = function(...) {
    system.file(..., package = "mypackage")
  }

  css    = pkg_resource("reports/styles.css")
  header = pkg_resource("reports/quarterly/header.html")

  # call the base html_document function
  rmarkdown::html_document(
    toc = toc, fig_width = 6.5, fig_height = 4,
    theme = NULL, css = css,
    includes = rmarkdown::includes(before_body = header)
  )
}
```

The new format defined has the following behavior:

1. Provides an option to determine whether a table of contents should be generated (implemented by passing `toc` through to the base format).

2. Sets a default height and width for figures (note that this is intentionally not user-customizable so as to encourage a standard for all reports of this type).

3. Disables the default Bootstrap theme and provides custom CSS in its place.

4. Adds a standard header to every document.

Note that (3) and (4) are implemented using external files that are stored within the package that defines the custom format, so their locations need to be looked up using the  `system.file()` function.

## Fully custom formats {#format-custom}

Another lower-level approach is to define a format directly by explicitly specifying **knitr** options and Pandoc command-line arguments. At its core, an R Markdown format consists of:

1. A set of **knitr** options that govern how Rmd is converted to Markdown.

2. A set of Pandoc options that govern how Markdown is converted to the final output format (e.g., HTML).

3. Some optional flags and filters (typically used to control handling of supporting files).

You can create a new format using the `output_format()` function in **rmarkdown**. Here is an example of a simple format definition:

```{r, eval=FALSE, tidy=FALSE}
#' @importFrom rmarkdown output_format knitr_options pandoc_options
simple_html_format = function() {
  # if you don't use roxygen2 (see above), you need to either
  # library(rmarkdown) or use rmarkdown::
  output_format(
    knitr = knitr_options(opts_chunk = list(dev = 'png')),
    pandoc = pandoc_options(to = "html"),
    clean_supporting = FALSE
  )
}
```

The **knitr** and Pandoc options can get considerably complicated (see help pages `?rmarkdown::knitr_options` and `?rmarkdown::pandoc_options` for details). The `clean_supporting` option indicates that you are not creating self-contained output (like a PDF or HTML document with base64 encoded resources), and therefore want to preserve supporting files like R plots generated during knitting.

You can also pass a `base_format` to the `output_format()` function if you want to inherit all of the behavior of an existing format but tweak a subset of its options.

If there are supporting files required for your format that cannot be easily handled by the `includes` option (see Section \@ref(includes)), you will also need to use the other arguments to `output_format` to ensure they are handled correctly (e.g., use the `intermediates_generator` to copy them into the place alongside the generated document).

The best way to learn more about creating fully custom formats is to study the source code of the existing built-in formats (e.g., `html_document` and `pdf_document`): https://github.com/rstudio/rmarkdown/tree/master/R. In some cases, a custom format will define its own Pandoc template, which was discussed in Section \@ref(template-pandoc).

## Using a new format {#format-use}

New formats should be stored within a package and installed onto your local system. This allows the format to be provided to the document YAML. Assuming our example format `quarterly_report` is in a package named **mypackage**, we can use it as follows:

```markdown
---
title: "Habits"
output:
  mypackage::quarterly_report:
    toc: true
---
```

This means to use the `quarterly_report()` function defined in **mypackage** as the output format, and to pass `toc = TRUE` as a parameter to the function.
