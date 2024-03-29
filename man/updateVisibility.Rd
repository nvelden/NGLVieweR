% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/api.R
\name{updateVisibility}
\alias{updateVisibility}
\title{Update visibility}
\usage{
updateVisibility(NGLVieweR_proxy, name, value = FALSE)
}
\arguments{
\item{NGLVieweR_proxy}{A NGLVieweR object.}

\item{name}{Name of selection to alter the color.}

\item{value}{Hide \code{FALSE} or show \code{TRUE} selection.
For a full description see "setVisibility" in the official \href{http://nglviewer.org/ngl/api/}{NGL.js} manual.}
}
\value{
API call containing \code{NGLVieweR} \code{id} and list of message parameters.
}
\description{
Hide or show an existing NGLVieweR selection in Shinymode.
}
\examples{
\dontrun{
NGLVieweR_proxy("structure") \%>\%
 updateVisibility("cartoon", value = TRUE)
}

if (interactive()) {
library(shiny)

ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      actionButton("show", "Show"),
      actionButton("hide", "Hide"),
    ),
    mainPanel(
      NGLVieweROutput("structure")
    )
  )
)
server = function(input, output) {
  output$structure <- renderNGLVieweR({
    NGLVieweR("7CID") \%>\%
      addRepresentation("cartoon", 
                        param = list(name = "cartoon", color="residueindex"))
  })
  observeEvent(input$show, {
    NGLVieweR_proxy("structure") \%>\%
      updateVisibility("cartoon", value = TRUE)

  })
  observeEvent(input$hide, {
    NGLVieweR_proxy("structure") \%>\%
      updateVisibility("cartoon", value = FALSE)

  })
}
shinyApp(ui, server)
}
}
\seealso{
\code{\link[=NGLVieweR_example]{NGLVieweR_example()}} See example "updateVisibility".

Other updates: 
\code{\link{updateColor}()},
\code{\link{updateRepresentation}()},
\code{\link{updateStage}()}
}
\concept{updates}
