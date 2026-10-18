# NGLVieweR feature plan

Source: comparison of NGLVieweR 1.4.0 (development version, NGL.js 2.5.0
bundled) with the official NGL.js API (Stage, Component, StructureComponent,
Shape, Trajectory, ViewerControls, AnimationControls, MouseControls), done
2026-10-18. This file is the single source of truth for the feature work.
Each new chat should read it first and update the **Status** table when a
step is done.

Representation types and their parameters (`colorScheme`, `assembly`,
`opacity`, `clipNear`, …) and all stage parameters are already passed through
to NGL unchanged, so they are **not** in this plan. The plan covers NGL
*methods and events* the package does not call yet.

## How to use this plan in a new chat

Start the chat with something like:

> Read `dev/FEATURE_PLAN.md` and follow the per-feature protocol. We are on step F<N>.

## Status

| Step | Feature | State | Commit |
|---|---|---|---|
| F1 | Color by values from R (custom color scheme) | committed (2026-10-18); signed off without an example app or vignette section (user did not want one) | see `git log --grep "Add F1"` |
| F2 | Camera: save/restore orientation, reset view | todo | |
| F3 | Hover input and double-click | todo | |
| F4 | Mouse and keyboard controls (e.g. turn off scroll-zoom) | todo | |
| F5 | Proxy parity: structure visibility, transforms, assembly | todo | |
| F6 | Annotations (HTML labels at 3D positions) | todo | |
| F7 | Measurements (distance, angle, dihedral) and `_measurements` input | todo | |
| F8 | Load options: `name`, `firstModelOnly`, `assembly` | todo | |
| F9 | Add and remove structures at runtime (proxy) | todo | |
| F10 | Shapes (spheres, arrows, cylinders, text, …) | todo | |
| F11 | Binary formats and URLs (MMTF, BCIF, CCP4/MRC, …) | todo | |
| F12 | Density maps and other volumes | todo | |
| F13 | Trajectories and a frame player | todo | |

States: `todo` → `explained` → `agreed` (user agreed on the R API and
decisions) → `built` → `verified` → `demoed` (user tried the demo app) →
`signed off` → `committed`.

Order: features that give the most for the least risk come first. F1-F8 only
add code next to what exists. F9 changes how the `structures` list and the
Shiny inputs are kept up to date, so it comes after the smaller proxy work.
F11 changes how data reaches the browser and is a prerequisite for F12 and
F13, so those three come last, in that order.

---

## Per-feature protocol (follow exactly)

**Do not change package code (`R/`, `inst/`) for a feature until the user
says "build feature F<N>".**

1. **Explain.** Present the feature section below in your own words: what it
   is, what a user of the package could do with it that they can't today,
   which NGL.js API it uses, and the proposed R API with a short usage
   example. Re-read the cited code first (line numbers drift) and check the
   NGL API in the bundled source `inst/htmlwidgets/lib/NGL-2.5.0/ngl.js` or
   the official docs (https://nglviewer.org/ngl/api/). If the NGL API does not
   behave as described here, say so before going on. Set state `explained`.
2. **Agree on the API.** Go through every **Decision** listed in the section
   and get the user's answer. Write the agreed function names, arguments and
   input names into the section ("Agreed API"). Set state `agreed`.
3. **Write tests first.** Add the R unit tests (builder fields, proxy
   messages, argument checks) and browser tests listed in the section. Run
   them and show that they fail because the feature does not exist yet.
4. **Build** (only after "build feature F<N>"). Match the surrounding code
   style: R builders in `R/NGLVieweR.R`, proxy functions in `R/api.R`, JS in
   `inst/htmlwidgets/NGLVieweR.js` / `lib/helperFunctions.js`, structures
   counted from 1 (`structure =`, as in `addSelection()`), roxygen docs with
   an example and a `@seealso`. No unrelated refactors; anything else you
   notice goes into "Found during the work". Set state `built`.
5. **Verify** with the double-check protocol from `dev/BUGFIX_PLAN.md`
   (new tests pass, full unit and browser suites, example smoke test,
   rcmdcheck against the baseline, blast radius, `/code-review`, re-read the
   diff). Report the actual output. Set state `verified`.
6. **Demo app.** Build the app described in the section at
   `dev/features/F<NN>-<slug>/app.R` (see "Demo app conventions"). Run it
   yourself in headless Chrome (shinytest2) first, check that it shows the
   feature working and has no console errors. Then tell the user how to
   launch it, what to try and what they should see. Set state `demoed` once
   the user has tried it.
7. **Sign-off.** Make the changes the user asks for after trying the demo
   (repeat 5-6 for those). The feature is done only when the user says it is
   signed off. Set state `signed off`.
8. **Record.** Add a `NEWS.md` bullet under the development heading, add the
   new functions to `_pkgdown.yml` if it lists reference topics, run
   `devtools::document()`. Ask whether the feature should also get an example
   app in `inst/examples/` (then also add it to `NGLVieweR_example()` and the
   smoke test) or a vignette section. Commit only when the user asks
   (message: `Add F<N>: <summary>`). Update the Status table.

### Demo app conventions

- Path: `dev/features/F<NN>-<slug>/app.R`. Launch from the project root:
  `shiny::runApp("dev/features/F01-color-by-values", launch.browser = TRUE)`.
- First line loads the **working-tree** package:
  `pkgload::load_all(normalizePath("../../.."), quiet = TRUE)`.
- Use the fixtures in `tests/testthat/fixtures/` where possible so the demo
  works offline. Add a new fixture (generated by `dev/make-fixtures.R`) if
  the feature needs one, e.g. a small trajectory or density map.
- Each demo has a **"What to try"** box at the top (steps to follow and what
  should happen), controls that exercise every new argument, and a live
  **state panel** that shows the values the feature produces or reads back
  (an input value, an orientation matrix, a measured distance), so it is
  visible that it works rather than only that it looks right.
- If the feature also works outside Shiny, the demo has a second tab (or a
  note with code to paste in the console) showing the static widget.

---

## F1 — Color by values from R

**What.** Color residues (or atoms) by a numeric value computed in R: a
conservation score, B-factor from another model, a mutation effect, a
p-value. Today the only option is a selection scheme
(`color = list(c("red", "10-20"), c("blue", "30")) ...`), so a gradient needs
one entry per residue and the user has to do the color mapping themselves.

**NGL API.** `NGL.ColormakerRegistry.addScheme(function (params) { this.atomColor = function (atom) { return 0xRRGGBB } })`
returns a scheme id that is used as `color` in any representation. The
current code only uses `addSelectionScheme`
(`lib/helperFunctions.js`, `colorMaker()`), called for every `color` that is
an object (`arrHandler()`, `addSelection`, `updateColor`,
`updateRepresentation` handlers).

**Proposed R API.**

```r
scores <- data.frame(chain = "A", resno = 1:46, value = runif(46))
NGLVieweR("1crn.pdb") %>%
  addRepresentation("cartoon",
    param = list(color = colorByValue(scores, palette = c("blue", "white", "red"),
                                      domain = c(0, 1), na_color = "grey")))
```

`colorByValue()` maps values to hex colors in R (`grDevices::colorRamp`)
and returns a small classed list (e.g. `list(type = "values", keys = "A:12", colors = "#ff0000")`).
The JS side recognises `type == "values"`, builds a lookup keyed on
`chain:resno` (plus `inscode`), and registers a scheme with `addScheme`.
Works everywhere `color` is accepted: `addRepresentation`, `addSelection`,
`updateColor`, `updateRepresentation`.

**Decisions.**
- Level: residue only, or also atom (`atomindex`)? Proposed: residue, with
  an optional `atom` column later.
- With several structures: optional `structure` column, or apply the same
  map to every structure? Proposed: optional column, default all.
- Accept a plain named vector (`c("A:12" = 0.3)`) as well as a data frame?
- Should a color legend be possible? (Not from NGL; would be an R/HTML
  element. Proposed: out of scope, mention in docs.)

**Agreed API** (2026-10-18, all proposed decisions accepted).

`colorByValue(values, palette = c("blue", "white", "red"), domain = NULL, na_color = "grey")`

- `values`: a data frame with columns `resno` and `value`, and optionally
  `chain`, `inscode` and `structure` (so `input$<id>_residues` with an added
  `value` column works as is); or a named numeric vector with names
  `"chain:resno"` (`"A:12"`, `"A:12B"` with insertion code, or `"12"` for any
  chain). A missing `chain` / `structure` means any chain / every structure.
- Residue level only (no atom column yet).
- `domain` defaults to the range of the values; values outside it get the end
  colors; `NA` values and residues not in `values` get `na_color`.
- Returns a classed list (`NGLVieweR_colorByValue`) usable as `color` in
  `addRepresentation`, `addSelection`, `updateColor` and
  `updateRepresentation`. It carries `palette` and `domain`, so a legend can
  be drawn in R (no legend in the viewer).
- Errors for: no `resno`/`value` column, non-numeric values, malformed names,
  a residue given twice, an unknown color, a bad `domain`, a `structure` that
  is not a whole number >= 1.
- JS: each value scheme is registered with `addScheme`; schemes a stage no
  longer uses (after `updateColor`, `updateRepresentation`, `addSelection`
  and re-render) are removed from NGL's registry. Selection schemes keep the
  old behaviour (see "Found during the work").

**Tests.** Unit: value → color mapping, `domain` clipping, NA →
`na_color`, argument checks, classed object survives JSON. Browser: after
render, read `atomColor` of the representation's colormaker for 2-3 atoms and
compare to the expected hex; `updateColor()` with a new map changes them.

**Demo app.** 1crn fixture in cartoon. Slider "score = sin(resno / k)" and a
palette chooser; a table of the residue scores next to the viewer. State
panel: the color NGL reports for the clicked residue next to the expected
color from R.

---

## F2 — Camera: save/restore orientation, reset view

**What.** Get the exact current view and put it back later: reproducible
figures, a "home" button, keeping the view when `renderNGLVieweR()`
re-renders, or syncing two viewers.

**NGL API.** `stage.viewerControls.getOrientation()` (returns a 4x4 matrix,
16 numbers), `stage.viewerControls.orient(matrix)`,
`stage.animationControls.orient(matrix, duration)`,
`stage.autoView(duration)` / `component.autoView(sele, duration)`,
`stage.viewerControls.signals.changed` (fires on every camera change).

**Proposed R API.**
- Input `input$<id>_orientation`: numeric vector of 16, sent when the camera
  stops changing (debounced, ~250 ms).
- `setOrientation(NGLVieweR, orientation)` (static, applied last in
  `renderValue`, after `zoomMove`).
- `updateOrientation(proxy, orientation, duration = 0)`.
- `updateAutoView(proxy, sele = "", structure = NULL, duration = 0)`
  ("reset view" / "zoom to selection").

**Decisions.**
- Debounce time, and whether `_orientation` is always sent or only when
  switched on (it fires often while the user drags).
- If both `zoomMove()` and `setOrientation()` are given: orientation wins?
- Name: `updateAutoView` vs `resetView`.

**Tests.** Unit: argument checks (length 16, numeric), proxy message.
Browser: set an orientation, read `getOrientation()` back (equal within
1e-6); change the camera from JS and wait for `_orientation`;
`updateAutoView` returns to the default view.

**Demo app.** Two viewers side by side. Buttons "Save view", "Restore view",
"Reset view", "Copy view to right viewer", and a "Re-render" button showing
that the saved view survives a re-render. State panel: the 16 numbers.

---

## F3 — Hover input and double-click

**What.** Shiny input for the atom/residue under the mouse, e.g. to show
residue details in a side panel or highlight it in a sequence or plot.
Currently only `clicked` is sent (`NGLVieweR.js`, `stage.signals.clicked`
handler in `factory`).

**NGL API.** `stage.signals.hovered` (picking proxy or nothing),
`stage.signals.doubleClicked`. `stage.setParameters({ tooltip })` already
works through `stageParameters()`.

**Proposed R API.** Inputs `input$<id>_hover` (same label format as
`_selection`, `NULL` when leaving the structure) and
`input$<id>_hoverStructure`; optional `input$<id>_doubleClick`. Turned on
with `selectionParameters(hover = TRUE)` or a new `hoverParameters()`, so apps
that don't use it don't get a message per mouse move.

**Decisions.** Opt-in or always on; throttle interval; whether to include
double-click and "click on empty space" (`_selection` set to `NULL`, which
is now never sent).

**Tests.** Browser: dispatch `stage.signals.hovered` with a picking proxy
(as the click tests do), check the input; dispatch with nothing, check
`NULL`; check nothing is sent when switched off.

**Demo app.** Viewer plus a panel that follows the hovered residue (name,
number, chain) and a sequence strip where the hovered residue lights up.

---

## F4 — Mouse and keyboard controls

**What.** Turn off or change mouse actions. The common need: in a long Shiny
page or R Markdown document, scrolling over the viewer zooms the molecule
instead of scrolling the page. Also: a read-only viewer (no rotate) or
different button mapping.

**NGL API.** `stage.mouseControls.remove(triggerPattern)`,
`stage.mouseControls.add(trigger, action)`, `NGL.MouseActions.*`,
`stage.keyControls.remove/add`.

**Proposed R API.** `mouseControls(NGLVieweR, scroll = c("zoom", "none", "ctrl-zoom"), drag = TRUE, ...)`
for the common cases, plus an escape hatch `mouseControls(remove = "scroll")`
using NGL trigger strings. Proxy: `updateMouseControls(proxy, ...)`.

**Decisions.** Simple named options vs raw NGL trigger strings (or both);
whether to offer "ctrl+scroll to zoom" as a one-word option (it is the usual
fix for page-scroll trapping).

**Tests.** Browser: after setting `scroll = "none"`, the `scroll` trigger is
not in `stage.mouseControls.actionList`; re-render restores defaults when
the option is dropped (same rule as `stageParameters`, see Fix #3).

**Demo app.** A tall page with the viewer in the middle; a radio button for
the scroll behaviour. What to try: scroll the page over the viewer.

---

## F5 — Proxy parity: structure visibility, transforms, assembly

**What.** Things the static API can do but a running app cannot: move,
rotate or scale a structure (`setPosition`, `setRotation`, `setScale`), hide
a whole structure (today `updateVisibility()` works per representation
name), switch the biological assembly.

**NGL API.** `component.setPosition/setRotation/setScale/setTransform`,
`component.setVisibility`, `structureComponent.setDefaultAssembly(name)`,
`structure.biomolDict` (names of the available assemblies).

**Proposed R API.** `updatePosition(proxy, x, y, z, structure)`,
`updateRotation(proxy, x, y, z, degrees = TRUE, structure)`,
`updateScale(proxy, scale, structure)`,
`updateStructureVisibility(proxy, value, structure)`,
`updateAssembly(proxy, assembly, structure)`; new input
`input$<id>_assemblies` (list of available assembly names per structure).

**Decisions.** One `updateTransform()` vs three functions mirroring the
static ones (proposed: mirror the static names); whether to add a static
`setAssembly()` too.

**Tests.** Unit: proxy messages, argument checks shared with the static
functions. Browser: component position/rotation/scale/visibility after each
call; assembly change changes the atom count shown.

**Demo app.** Two structures; sliders for position/rotation/scale of
structure 2, a checkbox per structure for visibility, and an assembly
dropdown filled from `_assemblies` (needs a small PDB entry with more than
one assembly; choose and check one in step 1 and save it as a fixture).

---

## F6 — Annotations

**What.** HTML labels attached to 3D positions that move with the
structure: name a binding site, mark a mutation, show a value. The `label`
representation covers plain text on atoms; annotations allow any HTML
(bold, colors, links, small tables) and can be placed at the center of a
selection.

**NGL API.** `component.addAnnotation(position, content, params)` (position
an `NGL.Vector3`, content a string or HTML element; params `offsetX`,
`offsetY`, `visible`), `component.removeAnnotation`,
`component.removeAllAnnotations`, `component.getCenter(sele)`.

**Proposed R API.**
`addAnnotation(NGLVieweR, sele, content, structure = 1, offsetX, offsetY, name)`
(position = center of `sele`); proxy `addAnnotation`-style
`updateAnnotation(proxy, ...)` and `removeAnnotation(proxy, name)`.

**Decisions.** Trust model for HTML content: escape by default and allow
raw HTML with `html = TRUE` (or `htmltools::HTML()`)? Proposed: escape unless
the content is `htmltools::HTML()`. Naming of proxy functions (the package
uses `add*` for static and `update*`/`addSelection` for proxy).

**Tests.** Unit: escaping, arguments. Browser: annotation count on the
component, its position equals `getCenter(sele)`, removal by name,
re-render clears old annotations.

**Demo app.** Text box for a selection and HTML content, "Add" and "Remove"
buttons, list of current annotations. Rotate to see labels follow.

---

## F7 — Measurements

**What.** Distances, angles and dihedrals between atoms, both set from R
and picked by clicking, with the values available in Shiny. The
`distance`/`angle`/`dihedral` representations already work through
`addRepresentation()`, but the values are not readable and there is no
click-to-measure mode.

**NGL API.** `structureComponent.addMeasurement(atomIndices)`,
`removeMeasurement`, `removeAllMeasurements(type)`, `measureData()`
(returns `{ distance, angle, dihedral }`), `measurePick(atom)`; the default
NGL mouse binding for measuring is `clickPick-left` with shift/ctrl
modifiers (check the 2.5.0 source in step 1).

**Proposed R API.** `addMeasurement(NGLVieweR or proxy, sele, structure)`
where `sele` is 2-4 single-atom selections; `updateMeasureMode(proxy, TRUE)`
(clicks pick atoms for measuring); `removeMeasurements(proxy, type)`; input
`input$<id>_measurements`, a data frame (type, atoms, value in Å or
degrees).

**Decisions.** Selection strings vs atom indices from R (proposed:
selections, checked to match exactly one atom each); whether measure mode is
a toggle or uses NGL's modifier-click; one input data frame for all types.

**Tests.** Unit: selection count checks. Browser: distance between two known
1crn atoms equals the value computed in R from the fixture coordinates
(within 1e-3 Å); angle and dihedral likewise; removal empties the input.

**Demo app.** Measure-mode toggle, "Clear" button, and a table bound to
`_measurements`. A second button adds a fixed CA-CA distance from R and the
panel shows the R-computed value next to NGL's.

---

## F8 — Load options

**What.** Options of `stage.loadFile` the package does not expose:
`name` (makes components findable by name, and is used by F9),
`firstModelOnly` (NMR ensembles), `assembly` (default biological assembly),
`defaultRepresentation`.

**NGL API.** `stage.loadFile(path, { ext, name, firstModelOnly, asTrajectory, defaultRepresentation, assembly })`
(check the exact option names in 2.5.0). Currently only `ext` is passed
(`NGLVieweR.js`, `renderValue`, `stage.loadFile` calls).

**Proposed R API.** New arguments on `NGLVieweR()` and `addStructure()`:
`name = NULL, firstModelOnly = FALSE, assembly = NULL` (or a `loadParameters`
list). `asTrajectory` waits for F13.

**Decisions.** Explicit arguments vs a `param = list()` like
`addRepresentation()`; default `name` (e.g. the PDB code or file name).

**Tests.** Unit: fields written, argument checks. Browser: component name,
model count with `firstModelOnly`, assembly applied.

**Demo app.** An NMR fixture (multi-model PDB, generated or a small entry
such as 1D3Z / 2K39 saved to fixtures) with a `firstModelOnly` toggle and an
assembly dropdown; state panel shows models and atom count.

---

## F9 — Add and remove structures at runtime

**What.** Load another structure into a running viewer, or remove one,
without re-rendering (which resets the camera and all proxy changes).

**NGL API.** `stage.loadFile`, `stage.removeComponent`,
`component.dispose`.

**Current state to respect.** `structures` is a closure variable in
`factory` set in `renderValue`; click handling uses
`structures.indexOf(component)`; `_sequence`, `_resno`, `_chainname`,
`_PDB`, `_residues` are sent once per render; `structure =` numbers are
positions in that list.

**Proposed R API.** `addStructure(proxy, data, format, ...)` (the same name
dispatching on the first argument's class, or `updateAddStructure()`);
`removeStructure(proxy, structure)`. After either, all residue/sequence
inputs are re-sent.

**Decisions.** Numbering after removal: shift down (structure 3 becomes 2)
or keep numbers stable (gaps)? Function names. Whether representations for
the new structure are given in the same call.

**Tests.** Browser: count of components and `getStructure().length`;
`_residues` contains the new structure; click on the new structure gives the
right `_selectionStructure`; removal shifts (or not) as decided; a load
error sends `_error` and keeps the existing structures.

**Demo app.** Text box for a PDB code / file upload, "Add" and "Remove
structure N" buttons, table of loaded structures from `_residues`.

---

## F10 — Shapes

**What.** Draw geometry: spheres, arrows, cylinders, cones, boxes, ellipsoids,
text, simple meshes. Use cases: mark a pocket center, show a dipole or
principal axes, draw a membrane plane, place a box around a region.

**NGL API.** `new NGL.Shape(name)`, `shape.addSphere/addArrow/addCylinder/addCone/addBox/addEllipsoid/addText/addMesh`,
`stage.addComponentFromObject(shape)`, `shapeComponent.addRepresentation("buffer")`.

**Proposed R API.** `addShape(NGLVieweR, type, ..., name)` with one call per
primitive (positions as numeric `c(x, y, z)` or a selection whose center is
used), proxy `updateShape`/`removeShape(proxy, name)`.

**Decisions.** One `addShape(type = )` vs one function per primitive;
whether positions can be selections; how shapes count in `structure =`
numbering (proposed: shapes are kept separate and never counted).

**Tests.** Browser: shape component exists with the expected number of
primitives and positions; removal; shapes do not appear in `_residues` or
click `_selectionStructure`.

**Demo app.** Arrow from the N- to the C-terminus, a sphere at a chosen
residue center, and a box around a selection, each with controls.

---

## F11 — Binary formats and URLs

**What.** Load MMTF, BCIF, binary CCP4/MRC maps, DCD/XTC trajectories and
other binary files, and files from a URL. Today files are read with
`readLines()` and sent as text, so binary formats are refused with an error
(Fix #7), and URLs are refused too (`.parse_structure_input()` in
`R/utils.R`).

**How.** Read binary files with `readBin()`, send them base64 encoded (or as
an htmlwidgets attachment), turn them back into a `Uint8Array` Blob in JS.
URLs can be passed to NGL directly (it fetches them), which needs CORS on
the server; RCSB supports it.

**Decisions.** base64 in the widget data (simple, ~33% larger) vs an
`htmlDependency` file attachment; whether to allow URLs or keep requiring a
download (and how to report CORS failures through `_error`); which formats
to list as supported.

**Tests.** Unit: format detection, binary read, size limit message.
Browser: an MMTF/BCIF fixture loads with the same atom count as the PDB
version; a binary CCP4 fixture loads; a bad URL gives `_error`.

**Demo app.** Load the same structure as PDB, BCIF and MMTF; table of atom
counts per format; a URL input.

---

## F12 — Density maps and other volumes

**What.** Show electron density / cryo-EM maps (CCP4, MRC, DX, CUBE) as
surfaces at a chosen contour level, alone or next to the model.

**Current state.** A volume loads as a `VolumeComponent`, which has no
`.structure`; in Shiny mode `renderValue` calls `o.structure.eachResidue`
and `new NGL.PdbWriter(o.structure)` on every component, which would throw
(check in step 1).

**NGL API.** `volumeComponent.addRepresentation("surface", { isolevel, isolevelType: "sigma", color, opacity, wireframe })`,
`"dot"` and `"slice"` representations; `boxSize` / `useWorker`.

**Proposed R API.** Volumes load through `NGLVieweR()`/`addStructure()`
like structures (format detected from the extension) and take
`addRepresentation("surface", param = list(isolevel = 1.5))`. Shiny residue
inputs skip volume components. `updateRepresentation()` already covers
changing the contour level.

**Decisions.** Do volumes count in `structure =` numbering? Should there be
a convenience `addMap()`?

**Tests.** Browser: a small CCP4 or DX fixture (generated in
`dev/make-fixtures.R` from 1crn) loads, surface representation present,
no console errors in Shiny mode, `_residues` lists only the structure.

**Demo app.** 1crn with a generated density map; a contour-level slider
and wireframe toggle.

---

## F13 — Trajectories

**What.** Play molecular dynamics trajectories and multi-model files as
frames: a play/pause control, go to frame N, and the current frame as a
Shiny input (to sync a plot of energy or RMSD with the 3D view).

**NGL API.** `structureComponent.addTrajectory(trajData, params)` returns a
`TrajectoryElement`; `trajectory.setFrame(i)`, `trajectory.signals.frameChanged`;
`new NGL.TrajectoryPlayer(trajectory, { step, timeout, mode, direction })`
with `play()`, `pause()`, `stop()`. Multi-model PDB files can be loaded with
`asTrajectory: true`.

**Depends on.** F11 (binary DCD/XTC/TRR), F8 (`asTrajectory`).

**Proposed R API.** `addTrajectory(NGLVieweR, data, format, structure = 1)`;
`updateFrame(proxy, frame)`, `updatePlayer(proxy, play = TRUE, step, timeout, mode)`;
input `input$<id>_frame`.

**Decisions.** Frames counted from 1 (like structures) or 0 (NGL);
whether to offer a built-in player UI or leave controls to Shiny (proposed:
Shiny controls only).

**Tests.** Browser: frame count, `setFrame` moves atom coordinates to the
fixture values, `_frame` input follows `frameChanged`, player plays and
pauses.

**Demo app.** A small multi-model fixture (e.g. 1crn with 10 generated
frames) as trajectory; play/pause, frame slider, and a line plot whose
marker follows `_frame`.

---

## Considered, not planned

- **Static `snapShot()` outside Shiny.** NGL can make images
  (`stage.makeImage`), but a static widget has no R-side trigger; users can
  use the browser or `webshot2`. Revisit if asked.
- **Movie/GIF export.** Not part of NGL core.
- **Representation types and parameters.** Already passed through
  unchanged.

## Found during the work

(Add issues found while building features here, with the step where they
were found.)

- **F1 (fixed, in NEWS):** Selection color schemes
  (`color = list(c("red", "1-10"), ...)`) were registered in NGL's page-wide
  registry on every render, `addSelection()`, `updateColor()` and
  `updateRepresentation()` and never removed (leak, existed before F1). Now
  `colorMaker()` tracks every scheme it makes per stage and
  `releaseColorSchemes()` frees both kinds once unused. Test:
  "selection color schemes are freed when no longer used".
- **F1:** NGL passes a representation's colormaker a *view* of the structure
  (`params.structure`), not the component's `Structure`; compare via
  `getStructure()`. Tests that read colors must use
  `repr.repr.getColorParams()` unchanged, or they hide this (found by
  `/code-review`).
- **F1:** `na_color = "transparent"` becomes opaque white (alpha is dropped;
  NGL colors are opaque). Documented as "names or HEX codes"; not rejected.
- **F1:** During verification one full-suite run reported 1 skip and 1
  warning in `test-browser-basic.R` that did not reproduce (file alone: 14
  pass; next full run: 550 pass, 0 skip, 0 warn). Probably a headless
  Chrome start-up timeout; watch for it.
