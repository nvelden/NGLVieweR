#' Shiny bindings for NGLVieweR
#'
#' Output and render functions for using NGLVieweR within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a NGLVieweR.
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#' @param id single-element character vector indicating the output ID of the
#'   chart to modify (if invoked from a Shiny module, the namespace will be added
#'   automatically)
#' @param session The Shiny session object to which the map belongs; usually
#' the default value will suffice.
#' @name NGLVieweR-shiny
#'
#' @examples
#'if (interactive()) {
#' library(shiny)
#' 
#' ui <- fluidPage(
#'   titlePanel("Viewer with API inputs"),
#'   sidebarLayout(
#'     sidebarPanel(
#'       textInput("selection", "Selection", "1-20"),
#'       selectInput("type", "Type", c("ball+stick", "cartoon", "backbone")),
#'       selectInput("color", "Color", c("orange", "grey", "white")),
#'       actionButton("add", "Add"),
#'       actionButton("remove", "Remove")
#'     ),
#'     mainPanel(
#'       NGLVieweROutput("structure")
#'     )
#'   )
#' )
#' server <- function(input, output) {
#'   output$structure <- renderNGLVieweR({
#'     NGLVieweR("7CID") %>%
#'       addRepresentation("cartoon",
#'         param = list(name = "cartoon", color = "residueindex")
#'       ) %>%
#'       stageParameters(backgroundColor = input$backgroundColor) %>%
#'       setQuality("high") %>%
#'       setFocus(0) %>%
#'       setSpin(TRUE)
#'   })
#'   observeEvent(input$add, {
#'     NGLVieweR_proxy("structure") %>%
#'       addSelection(isolate(input$type),
#'         param =
#'           list(
#'             name = "sel1",
#'             sele = isolate(input$selection),
#'             color = isolate(input$color)
#'           )
#'       )
#'   })
#' 
#'   observeEvent(input$remove, {
#'     NGLVieweR_proxy("structure") %>%
#'       removeSelection("sel1")
#'   })
#' }
#' shinyApp(ui, server)
#'}
#' @seealso
#' [NGLVieweR_example()]
#' @importFrom htmlwidgets shinyWidgetOutput shinyRenderWidget
#' @export
NGLVieweROutput <- function(outputId, width = '100%', height = '400px'){
  htmlwidgets::shinyWidgetOutput(outputId, 'NGLVieweR', width, height, package = 'NGLVieweR')
}

#' @rdname NGLVieweR-shiny
#' @export
renderNGLVieweR <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, NGLVieweROutput, env, quoted = TRUE)
}

#' @rdname NGLVieweR-shiny
#' @export
NGLVieweR_proxy <- function(id, session = shiny::getDefaultReactiveDomain()){

  if (is.null(session)) {
    stop("NGLVieweR_proxy must be called from the server function of a Shiny app")
  }

  if (!is.null(session$ns) && nzchar(session$ns(NULL)) && substring(id, 1, nchar(session$ns(""))) != session$ns("")) {
    id <- session$ns(id)
  }

  proxy <- list(id = id, session = session)
  class(proxy) <- "NGLVieweR_proxy"

  return(proxy)
}
