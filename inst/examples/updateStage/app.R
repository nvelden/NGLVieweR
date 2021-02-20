library(shiny)
library(NGLVieweR)

ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      selectInput("background", "Background", c("black", "white", "blue")),
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
      addRepresentation("cartoon", param = list(name = "cartoon", color="red")) %>%
      stageParameters(backgroundColor = "black")
  })
  observeEvent(input$update, {
    NGLVieweR_proxy("structure") %>%
      updateStage(param = list("backgroundColor" = isolate(input$background)))
  })
}
shinyApp(ui, server)




