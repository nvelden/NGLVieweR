library(shiny)
library(NGLVieweR)

ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      actionButton("enter", "Enter fullscreen"),
      actionButton("exit", "Exit fullscreen")
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

  observeEvent(input$enter, {
    NGLVieweR_proxy("structure") %>% updateFullscreen(TRUE)
  })

  observeEvent(input$exit, {
    NGLVieweR_proxy("structure") %>% updateFullscreen(FALSE)
  })
}

shinyApp(ui, server)

