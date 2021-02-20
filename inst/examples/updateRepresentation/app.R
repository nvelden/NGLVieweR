library(shiny)
library(NGLVieweR)

ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      selectInput("color", "Color", c("red", "white", "blue")),
      sliderInput("opacity", "Opacity", 0, 1, 1),
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
      addRepresentation("cartoon", param = list(name = "cartoon", color="red"))
  })
  observeEvent(input$update, {
    NGLVieweR_proxy("structure") %>%
      updateRepresentation("cartoon", param = list(
                                               color=isolate(input$color),
                                               opacity=isolate(input$opacity)))
   })
 }
shinyApp(ui, server)



