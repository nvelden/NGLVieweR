library(shiny)
library(NGLVieweR)

  ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      actionButton("snapshot", "Snapshot"),
    ),
    mainPanel(
      NGLVieweROutput("structure")
    )
  )
)
server = function(input, output) {
  output$structure <- renderNGLVieweR({
    NGLVieweR("7CID") %>%
      addRepresentation("cartoon", param = list(
                                               name = "cartoon",
                                               color= "residueindex"))
  })
  observeEvent(input$snapshot, {
    NGLVieweR_proxy("structure") %>%
      snapShot("Snapshot", param = list(antialias = TRUE,
                                        trim = TRUE,
                                        transparent = TRUE,
                                        scale = 1))
    })
}
shinyApp(ui, server)


