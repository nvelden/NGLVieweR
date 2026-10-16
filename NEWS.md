# NGLVieweR (development version)

* Updated the bundled NGL.js from 2.0.0 to 2.4.0.
* Fixed event handlers piling up when `renderNGLVieweR()` re-runs in Shiny: each re-render added another click, rendering-status and window-resize handler, so one click computed `_selection`/`_selAround` once per render so far, using the `selectionParameters()` of older renders. Handlers are now registered once and always use the latest options.
* The viewer now also resizes when its container changes size without a window resize, e.g. when a tab is shown or a sidebar collapses.
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