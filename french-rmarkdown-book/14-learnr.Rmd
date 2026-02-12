# Interactive Tutorials {#learnr}

The **learnr** package [@R-learnr]\index{learnr} makes it easy to turn any R Markdown document into an interactive tutorial. Tutorials consist of content along with interactive components for checking and reinforcing understanding. Tutorials can include any or all of the following:

1. Narrative, figures, illustrations, and equations.

1. Code exercises (R code chunks that users can edit and execute directly).

1. Quiz questions.

1. Videos (currently supported services include YouTube and Vimeo).

1. Interactive Shiny components.

Tutorials automatically preserve work done within them, so if a user works on a few exercises or questions and returns to the tutorial later, they can pick up right where they left off.

This chapter is only a brief summary of **learnr**'s full documentation at https://rstudio.github.io/learnr/. If you are interested in building more sophisticated tutorials, we recommend that you read the full documentation.

## Get started {#learnr-start}

To create a **learnr** tutorial, first install the **learnr** package with:

```r
install.packages("learnr")
```

Then you can select the "Interactive Tutorial" template from the "New R Markdown" dialog in the RStudio IDE (see Figure \@ref(fig:learnr-template)).

```{r learnr-template, echo=FALSE, out.width='100%', fig.cap='Create an interactive tutorial in RStudio.'}
knitr::include_graphics('images/learnr-template.png', dpi = NA)
```

If you do not use RStudio, it is also easy to create a tutorial: add `runtime: shiny_prerendered` and the output format `learnr::tutorial` to the YAML metadata, use `library(learnr)` within your Rmd file to activate the tutorial mode, and then add the chunk option `exercise = TRUE` to turn code chunks into exercises. Your tutorial users can edit and execute the R code and see the results right within their web browser.

Below is a minimal tutorial example:

````markdown
`r xfun::file_string('examples/hello-tutorial.Rmd')`
````

To run this tutorial, you may hit the button "Run Document" in RStudio, or call the function `rmarkdown::run()` on this Rmd file. Figure \@ref(fig:learnr-hello) shows what the tutorial looks like in the browser. Users can do the exercise by editing the code and running it live in the browser.

```{r learnr-hello, echo=FALSE, out.width='100%', fig.cap='A simple example tutorial.'}
knitr::include_graphics('images/learnr-hello.png', dpi = NA)
```

We strongly recommend that you assign unique chunk labels to exercises (e.g., the above example used the label `addition`), because chunk labels will be used as identifiers for **learnr** to save and restore user work. Without these identifiers, users could possibly lose their work in progress the next time when they pick up the tutorial.

## Tutorial types {#learnr-types}

There are two main types of tutorial documents:

1. Tutorials that are mostly narrative and/or video content, and also include some runnable code chunks. These documents are very similar to package vignettes in that their principal goal is communicating concepts. The interactive tutorial features are then used to allow further experimentation by the reader.

1. Tutorials that provide a structured learning experience with multiple exercises, quiz questions, and tailored feedback.

The first type of tutorial is much easier to author while still being very useful. These documents will typically add `exercise = TRUE` to selected code chunks, and also set `exercise.eval = TRUE` so the chunk output is visible by default. The reader can simply look at the R code and move on, or play with it to reinforce their understanding.

The second type of tutorial provides much richer feedback and assessment, but also requires considerably more effort to author. If you are primarily interested in this sort of tutorial, there are many features in **learnr** to support it, including exercise hints and solutions, automated exercise checkers, and multiple choice quizzes with custom feedback.

The most straightforward path is to start with the first type of tutorial (executable chunks with pre-evaluated output), and then move into more sophisticated assessment and feedback over time.

## Exercises {#learnr-exercises}

Exercises are interactive R code chunks that allow readers to directly execute R code and see its results. We have shown a simple exercise in Figure \@ref(fig:learnr-hello).

Exercises can include hints or solutions as well as custom checking code to provide feedback on user answers.

### Solutions

To create a solution to an exercise in a code chunk with the chunk label `foo`, you add a new code chunk with the chunk label `foo-solution`, e.g.,

````markdown
`r ''````{r filter, exercise=TRUE}
# Change the filter to select February rather than January
nycflights <- filter(nycflights, month == 1)
```

`r ''````{r filter-solution}
nycflights <- filter(nycflights, month == 2)
```
````

When a solution code chunk is provided, there will be a `Solution` button on the exercise (see Figure \@ref(fig:learnr-solution)). Users can click this button to see the solution.

```{r learnr-solution, echo=FALSE, out.width='100%', fig.cap='A solution to an exercise.'}
knitr::include_graphics('images/learnr-solution.png', dpi = NA)
```

### Hints

Sometimes you may not want to give the solutions directly to students, but provide hints instead to guide them. Hints can be either Markdown-based text content or code snippets.

To create a hint based on custom Markdown content, add a `<div>` tag with an `id` attribute that marks it as hint for your exercise (e.g., `filter-hint`). For example:

````markdown
`r ''````{r filter, exercise=TRUE}
# filter the flights table to include only United and
# American flights
flights
```

<div id="filter-hint">
**Hint:** You may want to use the dplyr `filter` function.
</div>
````

The content within the `<div>` will be displayed underneath the R code editor for the exercise whenever the user presses the `Hint` button.

If your Pandoc version is higher than 2.0 (check `rmarkdown::pandoc_version()`), you can also use the alternative syntax to write the `<div>`:

```markdown
:::{#filter-hint}
**Hint:** You may want to use the dplyr `filter` function.
:::
```

To create a hint with a code snippet, you add a new code chunk with the label suffix `-hint`, e.g.,

````markdown
`r ''````{r filter, exercise=TRUE}
# filter the flights table to include only United and
# American flights
flights
```

`r ''````{r filter-hint}
filter(flights, ...)
```
````

You can also provide a sequence of hints that reveal progressively more of the solution as desired by the user. To do this, create a sequence of indexed hint chunks (e.g., `-hint-1`, `-hint-2`, `-hint-3`, etc.) for your exercise chunk. For example:

````markdown
`r ''````{r filter, exercise=TRUE}
# filter the flights table to include only United and
# American flights
flights
```

`r ''````{r filter-hint-1}
filter(flights, ...)
```

`r ''````{r filter-hint-2}
filter(flights, UniqueCarrier == "AA")
```

`r ''````{r filter-hint-3}
filter(flights, UniqueCarrier == "AA" | UniqueCarrier == "UA")
```
````

## Quiz questions {#learnr-quiz}

You can include one or more multiple-choice quiz questions within a tutorial to help verify that readers understand the concepts presented. Questions can either have a single or multiple correct answers.

Include a question by calling the `question()` function within an R code chunk, e.g.,

````markdown
`r ''````{r letter-a, echo=FALSE}
question("What number is the letter A in the English alphabet?",
  answer("8"),
  answer("14"),
  answer("1", correct = TRUE),
  answer("23")
)
```
````

Figure \@ref(fig:learnr-question) shows what the above question would look like within a tutorial.

```{r learnr-question, echo=FALSE, out.width='100%', fig.cap='A question in a tutorial.'}
knitr::include_graphics('images/learnr-question.png', dpi = NA)
```

The functions `question()` and `answer()` have several other arguments for more features that allow you to customize the questions and answers, such as custom error messages when the user's answer is wrong, allowing users to retry a question, multiple-choice questions, and multiple questions in a group. See their help pages in R for more information.

## Videos {#learnr-videos}

You can include videos published on either YouTube or Vimeo within a tutorial using the standard Markdown image syntax. Note that any valid YouTube or Vimeo URL will work. For example, the following are all valid examples of video embedding:

```markdown
![](https://youtu.be/zNzZ1PfUDNk)
![](https://www.youtube.com/watch?v=zNzZ1PfUDNk)

![](https://vimeo.com/142172484)
![](https://player.vimeo.com/video/142172484)
```

Videos are responsively displayed at 100% of their container's width (with height automatically determined based on a 16x9 aspect ratio). You can change this behavior by adding attributes to the Markdown code where you reference the video.

You can specify an alternate percentage for the video's width or an alternate fixed width and height. For example:

```markdown
![](https://youtu.be/zNzZ1PfUDNk){width="90%"}

![](https://youtu.be/zNzZ1PfUDNk){width="560" height="315"}
```

## Shiny components {#learnr-shiny}

Tutorials are essentially Shiny documents, which we will introduce in Chapter \@ref(shiny-documents). For that reason, you are free to use any interactive Shiny components in tutorials, not limited to exercises and quiz questions.

The Shiny UI components can be written in normal R code chunks. For the Shiny server logic code (rendering output), you need to add a chunk option `context="server"` to code chunks. For example:

````markdown
`r ''````{r, echo=FALSE}
sliderInput("bins", "Number of bins:", 30, min = 1, max = 50)
plotOutput("distPlot")
```

`r ''````{r, context="server"}
output$distPlot = renderPlot({
  x = faithful[, 2]  # Old Faithful Geyser data
  bins = seq(min(x), max(x), length.out = input$bins + 1)
  hist(x, breaks = bins, col = 'darkgray', border = 'white')
})
```
````

Again, since tutorials are Shiny applications, they can be deployed using the same methods mentioned in Section \@ref(shiny-deploy).

## Navigation and progress tracking {#learnr-nav}

Each **learnr** tutorial includes a table of contents on the left that tracks student progress (see Figure \@ref(fig:learnr-progress)). Your browser will remember which sections of a tutorial a student has completed, and return a student to where he/she left off when the tutorial is reopened.

```{r learnr-progress, echo=FALSE, out.width='100%', fig.cap="Keeping track of the student's progress in a tutorial."}
knitr::include_graphics('images/learnr-progress.png', dpi = NA)
```

You can optionally reveal content by one sub-section at a time. You can use this feature to let students set their own pace, or to hide information that would spoil an exercise or question that appears just before it.

To use progressive reveal, set the `progressive` option to `true` in the `learnr::tutorial` output format in the YAML metadata, e.g.,

```yaml
---
title: "Programming basics"
output:
  learnr::tutorial:
    progressive: true
    allow_skip: true
runtime: shiny_prerendered
---
```

The `allow_skip` option above indicates that students can skip any sections, and move directly to the next section without completing exercises in the previous section.
