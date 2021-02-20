library(shiny)
library(NGLVieweR)

ui = fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      textInput("selection", "Selection", "1-20"),
      actionButton("update", "Update")
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
      addRepresentation("ball+stick", param = list(name = "ball+stick",
                                                   colorValue="yellow",
                                                   colorScheme="element",
                                                   sele="1-20"))
  })
  observeEvent(input$update, {
    NGLVieweR_proxy("structure") %>%
      updateSelection("ball+stick", sele =isolate(input$selection))
  })
}
shinyApp(ui, server)

