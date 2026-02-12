---
title: "Dashboard Value Boxes"
output:
  flexdashboard::flex_dashboard:
    orientation: rows
---

```{r setup, include=FALSE}
library(flexdashboard)
# these computing functions are only toy examples
computeArticles = function(...) return(45)
computeComments = function(...) return(126)
computeSpam = function(...) return(15)
```

### Articles per Day

```{r}
articles = computeArticles()
valueBox(articles, icon = "fa-pencil")
```

### Comments per Day

```{r}
comments = computeComments()
valueBox(comments, icon = "fa-comments")
```

### Spam per Day

```{r}
spam = computeSpam()
valueBox(
  spam, icon = "fa-trash",
  color = ifelse(spam > 10, "warning", "primary")
)
```
