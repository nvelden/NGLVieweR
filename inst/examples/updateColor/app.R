library(shiny)
library(NGLVieweR)

ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      colourInput("color", "red", "red"),
      actionButton("update", "Update"),
    ),
    mainPanel(
      NGLVieweROutput("structure")
    )
  )
)
server = function(input, output) {
  output$structure <- renderNGLVieweR({
    NGLVieweR("7CID") %>%
      addRepresentation("cartoon", param = list(name = "cartoon", color="residueindex"))
  })
  observeEvent(input$update, {
    NGLVieweR_proxy("structure") %>%
      updateColor("cartoon", isolate(input$color))

  })
}
shinyApp(ui, server)


