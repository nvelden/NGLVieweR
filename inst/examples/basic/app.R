library(shiny)
library(NGLVieweR)

ui = fluidPage(NGLVieweROutput("structure"))
server = function(input, output) {
  output$structure <- renderNGLVieweR({
    NGLVieweR("7CID") %>%
      addRepresentation("cartoon", param = list(name = "cartoon", color =
                                                  "residueindex")) %>%
      addRepresentation("ball+stick",
                        param = list(
                          name = "cartoon",
                          sele = '1-20',
                          colorScheme = "element"
                        )) %>%
      stageParameters(backgroundColor = "black") %>%
      setQuality("high") %>%
      setFocus(0) %>%
      setSpin(TRUE)
  })
}
shinyApp(ui, server)

