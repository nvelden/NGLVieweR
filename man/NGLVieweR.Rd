% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/NGLVieweR.R
\name{NGLVieweR}
\alias{NGLVieweR}
\title{Create a NGLVieweR}
\usage{
NGLVieweR(data, format = NULL, width = NULL, height = NULL, elementId = NULL)
}
\arguments{
\item{data}{PDB file or PDB entry code}

\item{format}{Input format (.mmcif, .cif, .mcif, .pdb, .ent, .pqr,
.gro, .sdf, .sd, .mol2, .mmtf). Needed when no file extension is provided.}

\item{width, height}{Must be a valid CSS unit (like \code{'100\%'},
\code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
string and have \code{'px'} appended.}

\item{elementId}{optional element Id}
}
\value{
A \code{NGLVieweR} \code{htmlwidgets} object.
}
\description{
NGLVieweR can be used to visualize and interact with Protein Data Bank (PDB) and structural files in R and Shiny applications.
It includes a set of API functions to manipulate the viewer after creation in Shiny.
}
\details{
The package is based on the \href{http://nglviewer.org/ngl/api/}{NGL.js} JavaScript library.
To see the full set of features please read the official manual of NGL.js.
}
\examples{

# Example 1: Most Basic
NGLVieweR("7CID") \%>\%
 addRepresentation("cartoon", param = list(name = "cartoon", colorScheme="residueindex"))

# Example 2: Advanced
NGLVieweR("7CID") \%>\%
  stageParameters(backgroundColor = "white") \%>\%
  setQuality("high") \%>\%
  setSpin(FALSE) \%>\%
  addRepresentation("cartoon",
    param = list(
      name = "cartoon",
      colorScheme = "residueindex"
    )
  ) \%>\%
  addRepresentation("ball+stick",
    param = list(
      name = "ball+stick",
      colorValue = "red",
      colorScheme = "element",
      sele = "200"
    )
  ) \%>\%
  addRepresentation("label",
    param = list(
      name = "label", sele = "200:A.O",
      showBackground = TRUE,
      backgroundColor = "black",
      backgroundMargin = 2,
      backgroundOpacity = 0.5,
      showBorder = TRUE,
      colorValue = "white"
    )
  ) \%>\%
  addRepresentation("surface",
    param = list(
      name = "surface",
      colorValue = "white",
      opacity = 0.1
    )
  ) \%>\%
  zoomMove("200", "200", 2000, -20)

#---------------------Using Shiny-------------------------

# App 1: Basic Example
if (interactive()) {
  library(shiny)
  ui <- fluidPage(NGLVieweROutput("structure"))
  server <- function(input, output) {
    output$structure <- renderNGLVieweR({
      NGLVieweR("7CID") \%>\%
        addRepresentation("cartoon",
          param = list(
            name = "cartoon",
            colorScheme = "residueindex"
          )
        ) \%>\%
        addRepresentation("ball+stick",
          param = list(
            name = "cartoon",
            sele = "1-20",
            colorScheme = "element"
          )
        ) \%>\%
        stageParameters(backgroundColor = "black") \%>\%
        setQuality("high") \%>\%
        setFocus(0) \%>\%
        setSpin(TRUE)
    })
  }
  shinyApp(ui, server)
}

# App 2: Example with API calls
if (interactive()) {
library(shiny)

ui <- fluidPage(
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
server <- function(input, output) {
  output$structure <- renderNGLVieweR({
    NGLVieweR("7CID") \%>\%
      addRepresentation("cartoon",
        param = list(name = "cartoon", colorScheme = "residueindex")
      ) \%>\%
      stageParameters(backgroundColor = input$backgroundColor) \%>\%
      setQuality("high") \%>\%
      setFocus(0) \%>\%
      setSpin(TRUE)
  })
  observeEvent(input$add, {
    NGLVieweR_proxy("structure") \%>\%
      addSelection(isolate(input$type),
        param =
          list(
            name = "sel1",
            sele = isolate(input$selection),
            colorValue = isolate(input$color)
          )
      )
  })

  observeEvent(input$remove, {
    NGLVieweR_proxy("structure") \%>\%
      removeSelection("sel1")
  })
}
shinyApp(ui, server)
}

}
\seealso{
\itemize{
\item \code{\link[=NGLVieweR_proxy]{NGLVieweR_proxy()}} for handling of API calls after rendering.
\item \code{\link[=NGLVieweR_example]{NGLVieweR_example()}} See example "API" and "basic".
}
}
