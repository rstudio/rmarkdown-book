# HTML Widgets

We briefly mentioned HTML widgets\index{HTML widgets} in the beginning of this book in Section \@ref(intro-widgets). The **htmlwidgets** package [@R-htmlwidgets] provides a framework for creating R bindings to JavaScript libraries. HTML Widgets can be:

- Used at the R console for data analysis just like conventional R plots.

- Embedded within R Markdown documents.^[Note that interactivity only works when the output format is HTML, including HTML documents and presentations. If the output format is not HTML, it is possible to automatically create and embed a static screenshot of the widget instead. See Section \@ref(intro-widgets) for more information.]

- Incorporated into Shiny web applications.

- Saved as standalone web pages for ad-hoc sharing via Email and Dropbox, etc.

There have been many R packages developed based on the HTML widgets framework, to make it easy for R users to create JavaScript applications using pure R syntax and data. It is not possible to introduce all these R packages in this chapter. Readers should read the documentation of specific widget packages for the usage. This chapter is mainly for developers who want to bring more JavaScript libraries into R, and it requires reasonable familiarity with the JavaScript language.

## Overview {#htmlwidgets-overview}

By following a small set of conventions, it is possible to create HTML widgets with very little code. All widgets include the following components:

1. **Dependencies**. These are the JavaScript and CSS assets used by the widget (e.g., the library for which you are creating a wrapper).

3. **R binding**. This is the function that end-users will call to provide input data to the widget and specify various options for how the widget should render. This also includes some short boilerplate functions required to use the widget within Shiny applications.

3. **JavaScript binding**. This is the JavaScript\index{JavaScript} code that glues everything together, passing the data and options gathered in the R binding to the underlying JavaScript library.

HTML widgets are always hosted within an R package, and should include all of the source code for their dependencies. This is to ensure that R code that renders widgets is fully reproducible (i.e., it does not require an Internet connection or the ongoing availability of an Internet service to run).

## A widget example (sigma.js) {#htmlwidgets-sigma}

To start with, we will walk through the creation of a simple widget that wraps the [sigma.js](http://sigmajs.org) graph visualization library. When we are done, we will be able to use it to display interactive visualizations of [GEXF](http://gexf.net) (Graph Exchange XML Format) data files. For example (see Figure \@ref(fig:sigma) for the output, which is interactive if you are reading the HTML version of this book):

```{r, sigma, fig.cap='A graph generated using the sigma.js library and the sigma package.', out.width='100%', message=FALSE, cache=TRUE}
library(sigma)
d = system.file("examples/ediaspora.gexf.xml", package = "sigma")
sigma(d)
```

There is remarkably little code required to create this binding. Next we will go through all of the components step by step. Then we will describe how you can create your own widgets, including automatically generating basic scaffolding for all of the core components.

### File layout

Let's assume that our widget is named **sigma** and is located within an R package of the same name. Our JavaScript binding source code file is named sigma.js. Since our widget will read GEXF data files, we will also need to include both the base `sigma.min.js` library and its GEXF plugin. Here are the files that we will add to the package:

```markdown
R/
| sigma.R

inst/
|-- htmlwidgets/
|   |-- sigma.js
|   |-- sigma.yaml
|   |-- lib/
|   |   |-- sigma-1.0.3/
|   |   |   |-- sigma.min.js
|   |   |   |-- plugins/
|   |   |   |   |-- sigma.parsers.gexf.min.js
```

Note the convention that the JavaScript, YAML, and other dependencies are all contained within the `inst/htmlwidgets` directory, which will subsequently be installed into a package sub-directory named `htmlwidgets`.

### Dependencies

Dependencies are the JavaScript and CSS assets used by a widget, included within the `inst/htmlwidgets/lib` directory. They are specified using a YAML configuration file that uses the name of the widget as its base filename. Here is what our **sigma.yaml** file looks like:

```yaml
dependencies:
  - name: sigma
    version: 1.0.3
    src: htmlwidgets/lib/sigma-1.0.3
    script:
      - sigma.min.js
      - plugins/sigma.parsers.gexf.min.js
```

The dependency `src` specification refers to the directory that contains the library, and `script` refers to specific JavaScript files. If your library contains multiple JavaScript files specify each one on a line beginning with `-` as shown above. You can also add `stylesheet` entries, and even `meta` or `head` entries. Multiple dependencies may be specified in one YAML file. See the documentation on the `htmlDependency()` function in the **htmltools** package for additional details.

### R binding

We need to provide users with an R function that invokes our widget. Typically this function will accept input data as well as various options that control the widget's display. Here is the R function for the `sigma` widget:

```{r eval=FALSE, tidy=FALSE}
#' @import htmlwidgets
#' @export
sigma = function(
  gexf, drawEdges = TRUE, drawNodes = TRUE, width = NULL,
  height = NULL
) {

  # read the gexf file
  data = paste(readLines(gexf), collapse = "\n")

  # create a list that contains the settings
  settings = list(drawEdges = drawEdges, drawNodes = drawNodes)

  # pass the data and settings using 'x'
  x = list(data = data, settings = settings)

  # create the widget
  htmlwidgets::createWidget(
    "sigma", x, width = width, height = height
  )
}
```

The function takes two classes of input: the GEXF data file to render, and some additional settings that control how it is rendered. This input is collected into a list named `x`, which is then passed on to the `htmlwidgets::createWidget()` function. This `x` variable will subsequently be made available to the JavaScript binding for `sigma` (to be described in the next section). Any width or height parameter specified is also forwarded to the widget (widgets size themselves automatically by default, so typically do not require an explicit width or height).

We want our sigma widget to also work in Shiny applications, so we add the following boilerplate Shiny output and render functions (these are always the same for all widgets):

```{r, eval=FALSE, tidy=FALSE}
#' @export
sigmaOutput = function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(
    outputId, "sigma", width, height, package = "sigma"
  )
}
#' @export
renderSigma = function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr = substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(
    expr, sigmaOutput, env, quoted = TRUE
  )
}
```

### JavaScript binding

The third piece in the puzzle is the JavaScript required to activate the widget. By convention, we will define our JavaScript binding in the file `inst/htmlwidgets/sigma.js`. Here is the full source code of the binding:

```js
HTMLWidgets.widget({

  name: "sigma",

  type: "output",

  factory: function(el, width, height) {

    // create our sigma object and bind it to the element
    var sig = new sigma(el.id);

    return {
      renderValue: function(x) {

        // parse gexf data
        var parser = new DOMParser();
        var data = parser.parseFromString(x.data, "application/xml");

        // apply settings
        for (var name in x.settings)
          sig.settings(name, x.settings[name]);

        // update the sigma object
        sigma.parsers.gexf(
          data,          // parsed gexf data
          sig,           // sigma object
          function() {
            // need to call refresh to reflect new settings
            // and data
            sig.refresh();
          }
        );
      },

      resize: function(width, height) {

        // forward resize on to sigma renderers
        for (var name in sig.renderers)
          sig.renderers[name].resize(width, height);  
      },

      // make the sigma object available as a property on the
      // widget instance we are returning from factory(). This
      // is generally a good idea for extensibility -- it helps
      // users of this widget interact directly with sigma,
      // if needed.
      s: sig
    };
  }
});
```

We provide a name and type for the widget, plus a `factory` function that takes `el` (the HTML element that will host this widget), `width`, and `height` (width and height of the HTML element, in pixels --- you can always use `offsetWidth` and `offsetHeight` for this).

The `factory` function should prepare the HTML element to start receiving values. In this case, we create a new `sigma` element and pass it to the `id` of the DOM element that hosts the widget on the page.

We are going to need access to the `sigma` object later (to update its data and settings), so we save it as a variable `sig`. Note that variables declared directly inside of the `factory` function are tied to a particular widget instance (`el`).

The return value of the `factory` function is called a _widget instance object_. It is a bridge between the htmlwidgets runtime, and the JavaScript visualization that you are wrapping. As the name implies, each widget instance object is responsible for managing a single widget instance on a page.

The widget instance object you create must have one required method, and may have one optional method:

1. The required `renderValue` method actually pours our dynamic data and settings into the widget's DOM element. The `x` parameter contains the widget data and settings. We parse and update the GEXF data, apply the settings to our previously-created `sig` object, and finally call `refresh` to reflect the new values on-screen. This method may be called repeatedly with different data (i.e., in Shiny), so be sure to account for that possibility. If it makes sense for your widget, consider making your visualization transition smoothly from one value of `x` to another.

2. The optional `resize` method is called whenever the element containing the widget is resized. The only reason not to implement this method is if your widget naturally scales (without additional JavaScript code needing to be invoked) when its element size changes. In the case of sigma.js, we forward the sizing information on to each of the underlying sigma renderers.

All JavaScript libraries handle initialization, binding to DOM elements, dynamically updating data, and resizing slightly differently. Most of the work on the JavaScript side of creating widgets is mapping these three functions, `factory`, `renderValue`, and `resize`, correctly onto the behavior of the underlying library.

The sigma.js example uses a simple object literal to create its widget instance object, but you can also use [class based objects](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes) or any other style of object, as long as `obj.renderValue(x)` and `obj.resize(width, height)` can be invoked on it.

You can add additional methods and properties on the widget instance object. Although they will not be called by htmlwidgets itself, they might be useful to users of your widget that know some JavaScript and want to further customize your widget by adding custom JS code (e.g., using the R function `htmlwidgets::onRender()`). In this case, we add a property `s` to make the sigma object itself available.

```{r eval=FALSE, tidy=FALSE}
library(sigma)
library(htmlwidgets)
library(magrittr)
d = system.file("examples/ediaspora.gexf.xml", package = "sigma")
sigma(d) %>% onRender("function(el, x) {
  // this.s is the sigma object
  console.log(this.s);
}")
```

### Demo

Our widget is now complete! If you want to test drive it without reproducing all of the code locally you can install it from GitHub as follows:

```r
devtools::install_github('jjallaire/sigma')
```

Here is the code to try it out with some sample data included with the package:

```r
library(sigma)
sigma(system.file("examples/ediaspora.gexf.xml", package = "sigma"))
```

If you execute this code in the R console, you will see the widget displayed in the RStudio Viewer (or in an external browser if you are not running RStudio). If you include it within an R Markdown document, the widget will be embedded into the document.

We can also use the widget in a Shiny application:

```{r eval=FALSE, tidy=FALSE}
library(shiny)
library(sigma)

gexf = system.file("examples/ediaspora.gexf.xml", package = "sigma")

ui = shinyUI(fluidPage(
  checkboxInput("drawEdges", "Draw Edges", value = TRUE),
  checkboxInput("drawNodes", "Draw Nodes", value = TRUE),
  sigmaOutput('sigma')
))

server = function(input, output) {
  output$sigma = renderSigma(
    sigma(gexf,
          drawEdges = input$drawEdges,
          drawNodes = input$drawNodes)
  )
}

shinyApp(ui = ui, server = server)
```

## Creating your own widgets {#htmlwidgets-create}

### Requirements

To implement a widget, you can create a new R package that in turn depends on the **htmlwidgets** package. You can install the package from CRAN as follows:

```r
install.packages("htmlwidgets")
```

While it is not strictly required, the step-by-step instructions below for getting started also make use of the **devtools** package, which you can also install from CRAN:

```r
install.packages("devtools")
```

It is also possible to implement a widget without creating an R package, but it requires you to understand more about HTML dependencies (`htmltools::htmlDependency()`). We have given an example in Section \@ref(htmlwidgets-advanced).

### Scaffolding

To create a new widget, you can call the `scaffoldWidget()` function to generate the basic structure for your widget. This function will:

* Create the `.R`, `.js`, and `.yaml` files required for your widget;

* If provided, take a [Bower](https://bower.io) package name and automatically download the JavaScript library (and its dependencies) and add the required entries to the `.yaml` file.

This method is highly recommended, as it ensures that you get started with the right file structure. Here is an example that assumes you want to create a widget named 'mywidget' in a new package of the same name:

```{r eval=FALSE}
# create package using devtools
devtools::create("mywidget")

# navigate to package dir
setwd("mywidget")

# create widget scaffolding
htmlwidgets::scaffoldWidget("mywidget")

# install the package so we can try it
devtools::install()
```

This creates a simple widget that takes a single `text` argument and displays that text within the widgets HTML element. You can try it like this:

```{r eval=FALSE}
library(mywidget)
mywidget("hello, world")
```

This is the most minimal widget possible, and does not yet include a JavaScript library to interface to (note that `scaffoldWidget()` can optionally include JavaScript library dependencies via the `bowerPkg` argument). Before getting started with development, you should review the introductory example above to make sure you understand the various components, and also review the additional articles and examples linked to in the next section.

### Other packages

Studying the source code of other packages is a great way to learn more about creating widgets:

1. The [**networkD3**](https://github.com/christophergandrud/networkD3) package illustrates creating a widget on top of [D3](http://d3js.org), using a custom sizing policy for a larger widget, and providing multiple widgets from a single package.

2. The [**dygraphs**](https://github.com/rstudio/dygraphs/) package illustrates using widget instance data, handling dynamic re-sizing, and using **magrittr** to decompose a large and flat JavaScript API into a more modular and pipeable R API.

3. The [**sparkline**](https://github.com/htmlwidgets/sparkline) package illustrates providing a custom HTML generation function (since sparklines must be housed in `<span>` rather than `<div>` elements).

If you have questions about developing widgets or run into problems during development, please do not hesitate to post an issue on the project's GitHub repository: https://github.com/ramnathv/htmlwidgets/issues.

## Widget sizing {#htmlwidgets-size}

In the spirit of HTML widgets working just like plots in R, it is important that HTML widgets intelligently size themselves to their container, be it the RStudio Viewer, a figure in a **knitr** document, or a UI panel within a Shiny application. The **htmlwidgets** framework provides a rich mechanism for specifying the sizing behavior of widgets.

This sizing mechanism is designed to address the following constraints that affect the natural size of a widget:

- **The kind of widget it is.** Some widgets may only be designed to look good at small, fixed sizes (like sparklines) while other widgets may want every pixel that can be spared (like network graphs).

- **The context into which the widget is rendered.** While a given widget might look great at 960px by 480px in an R Markdown document, the same widget would look silly at that size in the RStudio Viewer pane, which is typically much smaller.

Widget sizing is handled in two steps:

1. First, a sizing policy is specified for the widget. This is done via the `sizingPolicy` argument to the `createWidget` function. Most widgets can accept the default sizing policy (or override only one or two aspects of it) and get satisfactory sizing behavior (see details below).

2. The sizing policy is used by the framework to compute the correct width and height for a widget given where it is being rendered. This size information is then passed to the `factory` and `resize` methods of the widget's JavaScript binding. It is up to the widget to forward this size information to the underlying JavaScript library.

### Specifying a sizing policy

The default HTML widget sizing policy treats the widget with the same sizing semantics as an R plot. When printed at the R console, the widget is displayed within the RStudio Viewer and sized to fill the Viewer pane (modulo any padding). When rendered inside an R Markdown document, the widget is sized based on the default size of figures in the document.

Note that for most widgets the default sizing behavior is fine, and you will not need to create a custom sizing policy. If you need a slightly different behavior than the default, you can also selectively override the default behavior by calling the `sizingPolicy()` function and passing the result to `createWidget()`. For example:

```{r eval=FALSE, tidy=FALSE}
htmlwidgets::createWidget(
  "sigma",
  x,
  width = width,
  height = height,
  sizingPolicy = htmlwidgets::sizingPolicy(
    viewer.padding = 0,
    viewer.paneHeight = 500,
    browser.fill = TRUE
  )
)
```

Below are two examples:

- The **networkD3** package uses custom sizing policies for all of its widgets. The `simpleNetwork` widget eliminates padding (as D3.js is already providing padding), and specifies that it wants to fill up as much space as possible when displayed in a standalone web browser:

    ```{r eval=FALSE}
    sizingPolicy(padding = 0, browser.fill = TRUE)
    ```

- The `sankeyNetwork` widget requires much more space than is afforded by the RStudio Viewer or a typical **knitr** figure, so it disables those automatic sizing behaviors. It also provides a more reasonable default width and height for **knitr** documents:

    ```{r eval=FALSE, tidy=FALSE}
    sizingPolicy(viewer.suppress = TRUE,
                 knitr.figure = FALSE,
                 browser.fill = TRUE,
                 browser.padding = 75,
                 knitr.defaultWidth = 800,
                 knitr.defaultHeight = 500)
    ```

Table \@ref(tab:sizing-policy) shows the various options that can be specified within a sizing policy. Note that the default width, height, and padding will be overridden if their values for a specific viewing context are provided (e.g., `browser.defaultWidth` will override `defaultWidth` when the widget is viewed in a web browser). Also note that when you want a widget to fill a viewer, the padding is still applied.

Table: (\#tab:sizing-policy) Options that can be specified within a sizing policy.

| Option | Description |
|---|---|
| **defaultWidth** | Default widget width in all contexts (browser, viewer, and knitr). |
| **defaultHeight** | Similar to `defaultWidth`, but for heights instead. |
| **padding** | The padding (in pixels) in all contexts. |
| **viewer.defaultWidth** | Default widget width within the RStudio Viewer. |
| **viewer.defaultHeight** | Similar to `viewer.defaultWidth`. |
| **viewer.padding** | Padding around the widget in the RStudio Viewer (defaults to 15 pixels). |
| **viewer.fill** | When displayed in the RStudio Viewer, automatically size the widget to the viewer dimensions. Default to `TRUE`. |
| **viewer.suppress** | Never display the widget within the RStudio Viewer (useful for widgets that require a large amount of space for rendering). Defaults to `FALSE`. |
| **viewer.paneHeight** | Request that the RStudio Viewer be forced to a specific height when displaying this widget. |
| **browser.defaultWidth** | Default widget width within a standalone web browser. |
| **browser.defaultHeight** | Similar to `browser.defaultWidth`. |
| **browser.padding** | Padding in a standalone browser (defaults to 40 pixels). |
| **browser.fill** | When displayed in a standalone web browser, automatically size the widget to the browser dimensions. Defaults to `FALSE`. |
| **browser.external** |  Always use an external browser (via `browseURL()`). Defaults to `FALSE`, which will result in the use of an internal browser within RStudio v1.1 and higher. |
| **knitr.defaultWidth** | Default widget width within documents generated by **knitr** (e.g., R Markdown). |
| **knitr.defaultHeight** | Similar to `knitr.defaultWidth`. |
| **knitr.figure** | Apply the default **knitr** `fig.width` and `fig.height` to the widget rendered in R Markdown. Defaults to `TRUE`. |

### JavaScript resize method

Specifying a sizing policy allows **htmlwidgets** to calculate the width and height of your widget based on where it is being displayed. However, you still need to forward this sizing information on to the underlying JavaScript library for your widget.

Every JavaScript library handles dynamic sizing a bit differently. Some do it automatically, some have a `resize()` call to force a layout, and some require that size be set only along with data and other options. Whatever the case it is, the **htmlwidgets** framework will pass the computed sizes to both your `factory` function and `resize` function. Here is a sketch of a JavaScript binding:

```js
HTMLWidgets.widget({

  name: "demo",

  type: "output",

  factory: function(el, width, height) {

    return {
      renderValue: function(x) {

      },

      resize: function(width, height) {

      }
    };
  }
});
```

What you do with the passed width and height is up to you, and depends on the re-sizing semantics of the underlying JavaScript library. A couple of illustrative examples are included below:

- In the `dygraphs` widget (https://rstudio.github.io/dygraphs), the implementation of re-sizing is relatively simple, since the **dygraphs** library includes a `resize()` method to automatically size the graph to its enclosing HTML element:

    ```js
    resize: function(width, height) {
      if (dygraph)
        dygraph.resize();
    }
    ```

- In the `forceNetwork` widget (https://christophergandrud.github.io/networkD3/#force), the passed width and height are applied to the `<svg>` element that hosts the D3 network visualization, as well as forwarded on to the underlying D3 force simulation object:

    ```js
    factory: function(el, width, height) {

      var force = d3.layout.force();

      d3.select(el).append("svg")
        .attr("width", width)
        .attr("height", height);

      return {
        renderValue: function(x) {
          // implementation excluded
        },

        resize: function(width, height) {

          d3.select(el).select("svg")
            .attr("width", width)
            .attr("height", height);

          force.size([width, height]).resume();
        }
      };
    }
    ```

As you can see, re-sizing is handled in a wide variety of fashions in different JavaScript libraries. The `resize` method is intended to provide a flexible way to map the automatic sizing logic of **htmlwidgets** directly into the underlying library.

## Advanced topics {#htmlwidgets-advanced}

This section covers several aspects of creating widgets that are not required by all widgets, but are an essential part of getting bindings to certain types of JavaScript libraries to work properly. Topics covered include:

- Transforming JSON representations of R objects into representations required by JavaScript libraries (e.g., an R data frame to a D3 dataset).

- Passing JavaScript functions from R to JavaScript (e.g., a user-provided formatting or drawing function)

- Generating custom HTML to enclose a widget (the default is a `<div>`, but some libraries require a different element, e.g., a `<span>`).

- Creating a widget without creating an R package in the first place.

### Data transformation

R objects passed as part of the `x` parameter to the `createWidget()` function are transformed to JSON using the internal function `htmlwidgets:::toJSON()`^[Note that it is not exported from **htmlwidgets**, so you are not supposed to call this function directly.], which is basically a wrapper function of `jsonlite::toJSON()` by default. However, sometimes this representation is not what is required by the JavaScript library you are interfacing with. There are two JavaScript functions that you can use to transform the JSON data.

#### HTMLWidgets.dataframeToD3()

R data frames are represented in "long" form (an array of named vectors) whereas D3 typically requires "wide" form (an array of objects each of which includes all names and values). Since the R representation is smaller in size and much faster to transmit over the network, we create the long-form representation of R data, and then transform the data in JavaScript using the `dataframeToD3()` helper function.

Here is an example of the long-form representation of an R data frame:

```{r echo=FALSE, comment='', class.output='json'}
htmlwidgets:::toJSON2(head(iris, 3), pretty = TRUE)
```

After we apply `HTMLWidgets.dataframeToD3()`, it will become:

```{r echo=FALSE, comment='', class.output='json'}
htmlwidgets:::toJSON2(head(iris, 3), dataframe = 'row', pretty = TRUE)
```

As a real example, the `simpleNetwork` (https://christophergandrud.github.io/networkD3/#simple) widget accepts a data frame containing network links on the R side, and transforms it to a D3 representation within the JavaScript `renderValue` function:

```js
renderValue: function(x) {

  // convert links data frame to d3 friendly format
  var links = HTMLWidgets.dataframeToD3(x.links);

  // ... use the links, etc ...

}
```

#### HTMLWidgets.transposeArray2D()

Sometimes a 2-dimensional array requires a similar transposition. For this the `transposeArray2D()` function is provided. Here is an example array:

```{r echo=FALSE, comment='', class.output='json'}
htmlwidgets:::toJSON2(unname(head(iris, 6)), dataframe = 'column', pretty = TRUE)
```

`HTMLWidgets.transposeArray2D()` can transpose it to:

```{r echo=FALSE, comment='', class.output='json'}
htmlwidgets:::toJSON2(head(iris, 6), dataframe = 'values', pretty = TRUE)
```

As a real example, the [dygraphs](https://rstudio.github.io/dygraphs) widget uses this function to transpose the "file" (data) argument it gets from the R side before passing it on to the dygraphs library:

```javascript
renderValue: function(x) {

    // ... code excluded ...

    // transpose array
    x.attrs.file = HTMLWidgets.transposeArray2D(x.attrs.file);

    // ... more code excluded ...
}
```

#### Custom JSON serializer

You may find it necessary to customize the JSON serialization of widget data when the default serializer in **htmlwidgets** does not work in the way you have expected. For widget package authors, there are two levels of customization for the JSON serialization: you can either customize the default values of arguments for `jsonlite::toJSON()`, or just customize the whole function.

1. `jsonlite::toJSON()` has a lot of arguments, and we have already changed some of its default values. Below is the JSON serializer we use in **htmlwidgets** at the moment:

    ```{r eval=FALSE, code=head(capture.output(htmlwidgets:::toJSON2),-2), tidy.opts=list(width=39)}
    ```

    For example, we convert data frames to JSON by columns instead of rows (the latter is `jsonlite::toJSON`'s default). If you want to change the default values of any arguments, you can attach an attribute `TOJSON_ARGS` to the widget data to be passed to `createWidget()`, e.g.,

    ```{r eval=FALSE, tidy=FALSE}
    fooWidget = function(data, name, ...) {
      # ... process the data ...
      params = list(foo = data, bar = TRUE)
      # customize toJSON() argument values
      attr(params, 'TOJSON_ARGS') = list(
        digits = 7, na = 'string'
      )
      htmlwidgets::createWidget(name, x = params, ...)
    }
    ```

    We changed the default value of `digits` from 16 to 7, and `na` from `null` to `string` in the above example. It is up to you, the package author, whether you want to expose such customization to users. For example, you can leave an extra argument in your widget function so that users can customize the behavior of the JSON serializer:

    ```{r eval=FALSE, tidy=FALSE}
    fooWidget = function(
      data, name, ..., JSONArgs = list(digits = 7)
    ) {
      # ... process the data ...
      params = list(foo = data, bar = TRUE)
      # customize toJSON() argument values
      attr(params, 'TOJSON_ARGS') = JSONArgs
      htmlwidgets::createWidget(name, x = params, ...)
    }
    ```

    You can also use a global option `htmlwidgets.TOJSON_ARGS` to customize the JSON serializer arguments for all widgets in the current R session, e.g.

    ```{r eval=FALSE, tidy=FALSE}
    options(htmlwidgets.TOJSON_ARGS = list(
      digits = 7, pretty = TRUE
    ))
    ```

1. If you do not want to use **jsonlite**, you can completely override the serializer function by attaching an attribute `TOJSON_FUNC` to the widget data, e.g.,

    ```{r eval=FALSE, tidy=FALSE}
    fooWidget = function(data, name, ...) {
      # ... process the data ...
      params = list(foo = data, bar = TRUE)
      # customize the JSON serializer
      attr(params, 'TOJSON_FUNC') = MY_OWN_JSON_FUNCTION
      htmlwidgets::createWidget(name, x = params, ...)
    }
    ```

    Here `MY_OWN_JSON_FUNCTION` can be an arbitrary R function that converts R objects to JSON. If you have also specified the `TOJSON_ARGS` attribute, it will be passed to your custom JSON function, too.

### Passing JavaScript functions

As you would expect, character vectors passed from R to JavaScript are converted to JavaScript strings. However, what if you want to allow users to provide custom JavaScript functions for formatting, drawing, or event handling? For this case, the **htmlwidgets** package includes a `JS()` function that allows you to request that a character value is evaluated as JavaScript when it is received on the client.

For example, the `dygraphs` widget (https://rstudio.github.io/dygraphs) includes a `dyCallbacks` function that allows the user to provide callback functions for a variety of contexts. These callbacks are "marked" as containing JavaScript so that they can be converted to actual JavaScript functions on the client:

```{r eval=FALSE, tidy=FALSE}
library(dygraphs)
dyCallbacks(
  clickCallback = JS(...)
  drawCallback = JS(...)
  highlightCallback = JS(...)
  pointClickCallback = JS(...)
  underlayCallback = JS(...)
)
```

Another example is in the `DT` (DataTables) widget (https://rstudio.github.io/DT), where users can specify an `initComplete` with JavaScript to execute after the table is loaded and initialized:

```{r eval=FALSE, tidy=FALSE}
datatable(head(iris, 20), options = list(
  initComplete = JS(
    "function(settings, json) {",
    "$(this.api().table().header()).css({
      'background-color': '#000',
      'color': '#fff'
     });",
    "}")
))
```

If multiple arguments are passed to `JS()` (as in the above example), they will be concatenated into a single string separated by `\n`.

### Custom widget HTML

Typically the HTML "housing" for a widget is just a `<div>` element, and this is correspondingly the default behavior for new widgets that do not specify otherwise. However, sometimes you need a different element type. For example, the `sparkline` widget (https://github.com/htmlwidgets/sparkline) requires a `<span>` element, so it implements the following custom HTML generation function:

```r
sparkline_html = function(id, style, class, ...){
  htmltools::tags$span(id = id, class = class)
}
```

Note that this function is looked up within the package implementing the widget by the convention `widgetname_html`, so it need not be formally exported from your package or otherwise registered with **htmlwidgets**.

Most widgets will not need a custom HTML function, but if you need to generate custom HTML for your widget (e.g., you need an `<input>` or a `<span>` rather than a `<div>`), you should use the **htmltools** package (as demonstrated by the code above).

### Create a widget without an R package

As we mentioned in Section \@ref(htmlwidgets-create), it is possible to create a widget without creating an R package in the first place. Below is an example:

```{r eval=FALSE, tidy=FALSE}
#' @param text A character string.
#' @param interval A time interval (in seconds).
blink = function(text, interval = 1) {
  htmlwidgets::createWidget(
    'blink', list(text = text, interval = interval),
    dependencies = htmltools::htmlDependency(
      'blink', '0.1', src = c(href = ''), head = '
<script>
HTMLWidgets.widget({
  name: "blink",
  type: "output",
  factory: function(el, width, height) {
    return {
      renderValue: function(x) {
        setInterval(function() {
          el.innerText = el.innerText == "" ? x.text : "";
        }, x.interval * 1000);
      },
      resize: function(width, height) {}
    };
  }
});
</script>'
    )
  )
}

blink('Hello htmlwidgets!', .5)
```

The widget simply shows a blinking character string, and you can specify the time interval. The key of the implementation is the HTML dependency, in which we used the `head` argument to embed the JavaScript binding. The value of the `src` argument is a little hackish due to the current restrictions in **htmltools** (which might be removed in the future). In the `renderValue` method, we show or hide the text periodically using the JavaScript function `setInterval()`.
