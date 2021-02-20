---
title: "Get Started"
author: "Niels van der Velden"
date: "`r Sys.Date()`"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Get Started}
  %\VignetteEngine{knitr::rmarkdown}
  %\usepackage[utf8]{inputenc}
---

<h3 id="demo">
Demo
</h3>

[Click here](https://nielsvandervelden.com) to view a Shiny application integrating most features of **NGLVieweR**.

<h3 id="description">
Description
</h3>

**NGLvieweR** provides an R interface to the [NGL.js](http://nglviewer.org/ngl/api/) JavaScript library. It can be used to visualize and interact with protein data bank files (PDB) in R and Shiny applications. It includes a set of API functions to manipulate the viewer after creation and makes it possible to retrieve data from the visualization into R.   

<h3 id="installation">
Installation
</h3>

**NGLVieweR** is available through GitHub


``` r
install.packages("remotes")
remotes::install_github("nvelden/NGLVieweR")
```

<h3 id="start">
Getting started
</h3>

You can load a PDB file directly or use a PDB code of a structure on [RCSB.org](https://www.rcsb.org/). The below minimal example loads the PDB file and displays the structure in a "cartoon" representation.

``` r
#Load local pdb file
NGLVieweR("C:/7CID.pdb") %>%
addRepresentation("cartoon")

#Load protein by PDB code
NGLVieweR("7CID") %>%
addRepresentation("cartoon")
```

<img src="man/figures/cartoon_representation.png" class="screenshot" width="50%">

You can view a "basic" **NGLVieweR** Shiny application by running the below code. Use "API" for an example using API calls or any of the function names (e.g "addSelection"") for function specific examples.

``` r
library(NGLVieweR)
library(shiny)
NGLVieweR_example("basic") 
```

<h3 id="representations">
Representations
</h3>

You can load the structure as a "cartoon", "ball+stick", "line", "surface", "ribbon", or any other representation listed in the [NGL.js](http://nglviewer.org/ngl/api/) manual under "StructureRepresentation". Multiple representations of the same structure can be overlaid by chaining the `addSelection()` function. Also see the "structure" tab in the [demo](https://nielsvandervelden.com) app for a list of possible representations.  

``` r
NGLVieweR("7CID") %>%
addRepresentation("cartoon") %>%
addRepresentation("ball+stick")
```

<img src="man/figures/overlay_representation.png" class="screenshot" width="50%">

You can alter the appearance of select residues using the `param` argument. For a full list of options see the [NGL.js](http://nglviewer.org/ngl/api/) "RepresentationParameters" and the "Selection language" section.

``` r
NGLVieweR("7CID") %>%
  addRepresentation("cartoon", param=list(colorScheme = "residueindex")) %>%
  addRepresentation("ball+stick", param=list(sele="233-248", 
                                             colorValue="red", 
                                             colorScheme="element")) %>%
  addRepresentation("surface", param=list(colorValue = "white", 
                                          opacity=0.1))
``` 

<img src="man/figures/cartoon_parameters.png" class="screenshot" width="50%">

<h3 id="stage">
Stage
</h3>

You can alter the background color or set the zoom or rotation speed using the `stageParameters()` function. For a full list of options, see the "StageParameters" method in the official NGL.js manual. **Note**: Changes in background color are not visible in the RStudio viewer. 

```r
NGLVieweR("7CID") %>%
 stageParameters(backgroundColor = "white", zoomSpeed = 1) %>%
 addRepresentation("cartoon", param = list(name = "cartoon", colorScheme="residueindex"))
``` 

<img src="man/figures/stage_parameters.png" class="screenshot" width="50%">

<h3 id="labels">
Labels
</h3>

Labels can be addded by setting the `addRepresentation()` type parameter to "label". For a full list of of options, see the LabelRepresentationParameters section in the [NGL.js](http://nglviewer.org/ngl/api/) manual. Also see the "label" tab in the [demo](https://nielsvandervelden.com) app for possible label settings.  


``` r
NGLVieweR("7CID") %>%
  addRepresentation("cartoon") %>%
  addRepresentation("ball+stick", param=list(colorScheme = "element",
                                             colorValue = "yellow",
                                             sele = "20")) %>%
  addRepresentation("label", param=list(sele="20",
                                        labelType="format",
                                        labelFormat='[%(resname)s]%(resno)s', #or enter custom text
                                        labelGrouping="residue", #or "atom" (eg. sele = "20:A.CB")
                                        color="white",
                                        fontFamiliy="sans-serif",
                                        xOffset = 1,
                                        yOffset = 0,
                                        zOffset = 0,
                                        fixedSize = TRUE,
                                        radiusType = 1,
                                        radiusSize = 1.5, #Label size
                                        showBackground=FALSE
                                        #backgroundColor="black",
                                        #backgroundOpacity=0.5,)
  )
``` 

<img src="man/figures/label_representation.png" class="screenshot" width="50%">

<h3 id="zoom">
Zoom
</h3>

You can zoom into specific residues using the `ZoomMove()` function.

``` r
NGLVieweR("7CID") %>%
  addRepresentation("cartoon") %>%
  addRepresentation("ball+stick", param=list(colorScheme = "element",
                                             colorValue = "yellow",
                                             sele = "20")) %>%
  addRepresentation("label", param=list(sele="20",
                                        labelType="format",
                                        labelFormat='[%(resname)s]%(resno)s', #or enter custom text
                                        labelGrouping="residue", #or "atom" (eg. sele = "20:A.CB")
                                        color="white",
                                        xOffset = 1,
                                        fixedSize = TRUE,
                                        radiusType = 1,
                                        radiusSize = 1.5) #Label size
  ) %>%
  zoomMove(center = "20", 
           zoom = "20", 
           duration = 0, #animation time in ms 
           z_offSet = -20)
``` 

<img src="man/figures/zoomMove.png" class="screenshot" width="50%">

<h3 id="shiny">
Shiny
</h3>

The `NGLVieweROutput()` and `renderNGLVieweR()` functions enable you to visualize PDB files within Shiny applications. See the `NGLVieweR_example("basic")` and "API" for live examples.

``` r
library(shiny)
library(NGLVieweR)

ui = fluidPage(NGLVieweROutput("structure"))
server = function(input, output) {
  output$structure <- renderNGLVieweR({
    NGLVieweR("7CID") %>%
      addRepresentation("cartoon", param = list(name = "cartoon", color =
                                                  "residueindex")) %>%
      addRepresentation("ball+stick",
                        param = list(
                          name = "cartoon",
                          sele = '1-20',
                          colorScheme = "element"
                        )) %>%
      stageParameters(backgroundColor = "black") %>%
      setQuality("high") %>%
      setFocus(0) %>%
      setSpin(TRUE)
  })
}
shinyApp(ui, server)
``` 
<img src="man/figures/basic_shiny.gif" class="screenshot" width="50%">

<h3 id="api">
API
</h3>

In Shiny apps, you can manipulate the **NGLVieweR** widget after creation using specific "API" calls. You can for instance add or remove representations by refering to their name using the `addSelection()` or `removeSelection()` functions.

``` r
library(shiny)
library(NGLVieweR)

ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      textInput("selection", "Selection", "1-20"),
      selectInput("type", "Type", c("ball+stick", "cartoon", "backbone")),
      selectInput("color", "Color", c("orange", "grey", "white")),
      actionButton("add", "Add"),
      actionButton("remove", "Remove")
    ),
    mainPanel(
      NGLVieweROutput("structure")
    )
  )
)
server = function(input, output) {
  output$structure <- renderNGLVieweR({
    NGLVieweR("7CID") %>%
      addRepresentation("cartoon", param = list(name = "cartoon", colorScheme="residueindex")) %>%
      stageParameters(backgroundColor = input$backgroundColor) %>%
      setQuality("high") %>%
      setFocus(0) %>%
      setSpin(TRUE)
  })
  observeEvent(input$add, {
    NGLVieweR_proxy("structure") %>%
      addSelection(isolate(input$type),
                   param =
                     list(name="sel1",
                          sele=isolate(input$selection),
                          colorValue=isolate(input$color)))
  })

  observeEvent(input$remove, {
    NGLVieweR_proxy("structure") %>%
      removeSelection("sel1")
  })
}
shinyApp(ui, server)
```

<img src="man/figures/API_shiny.gif" class="screenshot" width="50%">


<h4 id="api">Possible API functions are:</h3>
<li>`addSelection()`</li>
<li>`removeSelection()`</li>
<li>`snapShot()`</li>
<li>`updateColor()`</li>
<li>`updateFocus()`</li>
<li>`updateFullscreen()`</li>
<li>`updateRepresentation()`</li>
<li>`updateRock()`</li>
<li>`updateSelection()`</li>
<li>`updateSpin()`</li>
<li>`updateStage()`</li>
<li>`updateVisibility()`</li>
<li>`updateZoomMove()`</li>



