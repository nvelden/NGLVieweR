library(shiny)
library(NGLVieweR)

ui <- fluidPage(
  titlePanel("Viewer with API inputs"),
  sidebarLayout(
    sidebarPanel(
      selectInput("selStructure", "Structure", c("blue", "orange")),
      textInput("selection", "Selection", "1-20"),
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
    NGLVieweR("1CRN") %>%
      addRepresentation("cartoon", param = list(color = "blue")) %>%
      addStructure("1CRN") %>%
      addRepresentation("cartoon", param = list(color = "orange")) %>%
      setPosition(x = 20, y = 0, z = 0) %>%
      setRotation(x = 2, y = 0, z = 0, degrees = FALSE) %>%
      setScale(0.5) %>%
      setSpin(TRUE)
  })
  
  observeEvent(input$add, {
    
    structureIndex <- ifelse(input$selStructure == "blue", 0, 1)
    
    NGLVieweR_proxy("structure") %>%
      addSelection("ball+stick",
                   param = list(
                     name = paste0("sel", structureIndex),
                     structureIndex = structureIndex,  
                     sele = isolate(input$selection),
                     colorScheme = "element"  
                   )
      )
  })
  
  observeEvent(input$remove, {
    
    selectionName <- ifelse(input$selStructure == "blue", "sel0", "sel1")
    
    NGLVieweR_proxy("structure") %>%
      removeSelection(selectionName)
  })
}

shinyApp(ui, server)