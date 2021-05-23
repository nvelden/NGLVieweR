library(hexSticker)
library(showtext)
library(magick)

# add font
font_add_google("Courier Prime", "courier")

# logo output path
logo_path <- "man/figures/logo.png"

# create the high resolution logo
sticker(
  subplot = "man/figures/logo_background.png",
  package = "NGLVieweR",
  s_x = 1,
  s_y = 1,
  s_width = 1,
  s_height = 1,
  white_around_sticker = T,
  dpi = 1000,
  p_family = "courier",
  p_size = 75,
  p_y = 1,
  filename = logo_path,
  p_color = "white",
  h_color = "black",
  h_fill = "black",
  h_size = 1
)

# load the logo png back
logo <- image_read(logo_path)

# resizing
logo.min <- image_scale(logo, 640)

# output the mini size file
image_write(image = logo.min, path = logo_path)