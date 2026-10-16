# NGLVieweR (development version)

* Updated the bundled NGL.js from 2.0.0 to 2.4.0.
* Fixed `zoomMove()` being overridden when several structures are loaded: with the default `duration = 0` the camera ended on the center of all structures, and with `setSuperpose()` it aimed at a structure's position before superposition. The camera now moves after all structures are loaded and superposed; if `zoomMove()` is used for several structures, the last one is used.
* Fixed `snapShot()` setting `input$<outputId>_rendering` to `FALSE` before the image was made, so a spinner tied to it stopped too early. It now changes to `FALSE` after the PNG is handed to the download, and a failed snapshot is reported in the browser console.
* Structure load failures are no longer silent. A new Shiny input `input$<outputId>_error` reports which structure could not be loaded and why (e.g. a PDB code that does not exist, a network error, or a file that contains no atoms), and is `NULL` after a successful load. After a failure the viewer is empty and the `_sequence`, `_resno`, `_chainname` and `_PDB` inputs are cleared, instead of keeping the values of the previous structure. Previously one failing structure also stopped all others without any message.
* `NGLVieweR()` and `addStructure()` give clear R errors instead of an empty viewer (or a JavaScript error that could also stop other Shiny outputs) for input they cannot use: a file path that does not exist ("file not found"), file contents or an extensionless file without `format`, a malformed `format` (e.g. `NA` or `""`), `data` that is empty or not text, or a URL (not supported; download the file first).
* File contents can now also be given as a vector of lines, e.g. `NGLVieweR(readLines("1crn.pdb"), format = "pdb")`. Text with line breaks is always treated as file contents.
* Structure files compressed with gzip, bzip2 or xz (e.g. `1crn.cif.gz`) can now be loaded; the format is taken from the extension before `.gz`.
* Formats are passed to NGL.js in lower case, so files such as `1CRN.PDB` load.
* Binary formats such as MMTF were listed as supported but were corrupted when read; they are removed from the documentation and now give a clear error.
* Fixed `addStructure()` reading its input differently from `NGLVieweR()`: a short file name such as `"1crn.pdb"` was treated as a PDB code, and a `format` with a leading dot (`".pdb"`) was not accepted. Both functions now use the same rules.
* Fixed `NGLVieweR()` and `addStructure()` failing with "path too long" on R-devel when given file contents (e.g. `NGLVieweR(pdb_text, format = "pdb")`): file contents are no longer passed to `tools::file_ext()` and `file.exists()`.
* Fixed event handlers piling up when `renderNGLVieweR()` re-runs in Shiny: each re-render added another click, rendering-status and window-resize handler, so one click computed `_selection`/`_selAround` once per render so far, using the `selectionParameters()` of older renders. Handlers are now registered once and always use the latest options.
* The viewer now also resizes when its container changes size without a window resize, e.g. when a tab is shown or a sidebar collapses.
* Fixed `setSuperpose()` moving the wrong structure. The reference structure now keeps its coordinates and every other structure is moved onto it, as documented. Previously the reference was moved onto the other structures, so with three or more structures only the last one ended up aligned. Note that the superposed scene is now in the coordinate frame of the reference.
* `setSuperpose()` now gives an error for an invalid `reference` (not a whole number of 1 or more), and the viewer logs a clear console error when `reference` is larger than the number of structures.
* Fixed `updateFullscreen()` ignoring its `fullscreen` argument: it always toggled, so `updateFullscreen(FALSE)` could enter fullscreen and `updateFullscreen(TRUE)` could leave it. It now only changes the state when it differs from the requested one.
* `updateFullscreen()` has a new `element` argument: `"page"` (default, the whole page as before) or `"viewer"` (only the viewer).
* The `updateFullscreen` example app now also runs outside an interactive R session.
* Fixed `setSpin()` and `setRock()` not switching off when `renderNGLVieweR()` re-runs with `FALSE`: an animation started by an earlier render kept running. If both are `TRUE`, the structure spins (now documented).
* `stageParameters()` options set in an earlier render but not in the current one now return to their NGL.js defaults on re-render, instead of staying in effect (e.g. a background color). Stage options that no render set (for example ones changed only with `updateStage()`) are left as they are.

# NGLVieweR 1.4.0

* Added `addStructure` and `setSuperpose` functions to load and overlap multiple structures in the same stage.
* Updated internal logic with R 4.3.0's stricter && and || evaluations to prevent errors with multi-element vectors.

# NGLVieweR 1.3.4

* Added `setScale`, `setRotation`, and `setPosition` functions for controlling scale, rotation, and position of representations.

# NGLVieweR 1.3.3

* Added API call that returns a list of atoms surrounding a selection.
* Added `selectionParameters` function to control proximity and level for selection. 

* Updated `addSelection` and `updateRepresentation` to handle color arrays

# NGLVieweR 1.3.2

* Updated `addSelection` and `updateRepresentation` to handle color arrays

# NGLVieweR 1.3.1

* Added a `NEWS.md` file to track changes to the package.
* Made package ready for CRAN release
* Updated pkgdown
* Re-formatted code examples