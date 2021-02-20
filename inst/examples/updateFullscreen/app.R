library(shiny)
library(NGLVieweR)

if (interactive()) {
library(shiny)

ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      actionButton("fullscreen", "Fullscreen"),
    ),
    mainPanel(
      NGLVieweROutput("structure")
    )
  )
)
server = function(input, output) {
  output$structure <- renderNGLVieweR({
    NGLVieweR("7CID") %>%
      addRepresentation("cartoon", param = list(name = "cartoon", color="red"))
  })

  observeEvent(input$fullscreen,{

    NGLVieweR_proxy("structure") %>% updateFullscreen()

  })
}
  shinyApp(ui, server)
}

