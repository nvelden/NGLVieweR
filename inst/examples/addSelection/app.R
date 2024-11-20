library(shiny)
library(NGLVieweR)

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
    NGLVieweR("7CID") %>%
      addRepresentation("cartoon",
                        param = list(name = "cartoon", colorScheme = "residueindex")
      ) %>%
      stageParameters(backgroundColor = input$backgroundColor) %>%
      setQuality("high") %>%
      setFocus(0) %>%
      setSpin(TRUE)
  })
  
  observeEvent(input$add, {
    if (isolate(input$type) == "cartoon") {
      # For cartoon, use the color parameter
      NGLVieweR_proxy("structure") %>%
        addSelection(isolate(input$type),
                     param = list(
                       name = "sel1",
                       sele = isolate(input$selection),
                       color = isolate(input$color)
                     )
        )
    } else {
      # For other types, use colorValue
      NGLVieweR_proxy("structure") %>%
        addSelection(isolate(input$type),
                     param = list(
                       name = "sel1",
                       sele = isolate(input$selection),
                       colorValue = isolate(input$color)
                     )
        )
    }
  })
  
  observeEvent(input$remove, {
    NGLVieweR_proxy("structure") %>%
      removeSelection("sel1")
  })
}

shinyApp(ui, server)
