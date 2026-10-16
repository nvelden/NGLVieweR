# A stand-in for NGLVieweR_proxy() that records custom messages instead of
# sending them. Proxy functions only use `proxy$id` and
# `proxy$session$sendCustomMessage`, so no Shiny session is needed.
fake_proxy <- function(id = "viewer") {
  sent <- new.env()
  sent$msgs <- list()
  session <- list(sendCustomMessage = function(type, message) {
    sent$msgs[[length(sent$msgs) + 1]] <- list(type = type, message = message)
  })
  structure(list(id = id, session = session, sent = sent), class = "NGLVieweR_proxy")
}

# The last message a fake proxy sent.
last_msg <- function(proxy) {
  proxy$sent$msgs[[length(proxy$sent$msgs)]]
}

fixture <- function(...) test_path("fixtures", ...)
