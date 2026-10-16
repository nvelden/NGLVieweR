# NGLVieweR bug-fix plan

Source: code review of 2026-10-16 (NGLVieweR 1.4.0, NGL.js 2.4.0 pending).
This file is the single source of truth for the bug-fix work. Each new chat
should read it first and update the **Status** table when a step is done.

## How to use this plan in a new chat

Start the chat with something like:

> Read `dev/BUGFIX_PLAN.md` and follow the per-bug protocol. We are on step <N>.

## Status

| Step | Item | State | Commit |
|---|---|---|---|
| 0 | Baseline: NGL 2.4.0 packaging (#1), test infrastructure (#16), fixtures, baseline run | verified (2026-10-16; see dev/baseline-check.md). Test deps in Suggests (user chose option 1). Not committed | |
| 1 | #2 Handlers pile up on re-render | committed (2026-10-16): 139 pass / 1 known skip; rcmdcheck = baseline. Decision: resize via htmlwidgets `resize()` only (window listener removed) | see `git log --grep "Fix #2"` |
| 2 | #3 Spin/rock never switch off on re-render | committed (2026-10-16): 160 pass / 1 known skip. Decisions: spin wins (documented); stageParameters keys set by the previous render (only those) reset to NGL defaults | see `git log --grep "Fix #3"` |
| 2b | #17 Content strings fail on R-devel (`file_ext` → `basename`), see Found during the work | committed (2026-10-16): 170 pass / 1 known skip; rcmdcheck = baseline. Helpers `.could_be_path()`/`.file_ext()` in R/utils.R | see `git log --grep "Fix #17"` |
| 3 | #4 Superpose moves the wrong structure | committed (2026-10-16): 209 pass / 1 known skip; rcmdcheck = baseline; vignette example checked (reference 0.000 Å, target 63 Å). Decision: reference stays put (NEWS note) | see `git log --grep "Fix #4"` |
| 4 | #5 `updateFullscreen()` ignores its argument | committed (2026-10-16); explained; repro confirmed headless with trusted clicks (FALSE enters, TRUE exits, element BODY). Decision: new `element = c("page", "viewer")`, default "page"; also fix the example's if (interactive()). Verified (2026-10-16): 234 pass / 0 skip; rcmdcheck = baseline; trusted-click check: page and viewer enter/leave correctly, sizes restored. Example now has Enter/Exit buttons | see `git log --grep "Fix #5"` |
| 5 | #6 `addStructure()` / `NGLVieweR()` parse input differently | committed (2026-10-16); explained; repro confirmed headless (2 of 5 inputs differ: 8-char file name, format with leading dot); failing test written (4 expectations fail as expected). Verified (2026-10-16): shared `.parse_structure_input()` in R/utils.R; 243 pass / 0 skip; rcmdcheck = baseline; repro: all 5 inputs same, both viewers load | see `git log --grep "Fix #6"` |
| 6 | #7 Missing files, line vectors, binary formats | committed (2026-10-16); explained; repro confirmed headless (7a, 7b throw JS errors that also break other Shiny outputs; 7c gz: `ext 'gz' unknown`). Decisions: binary (mmtf) dropped from docs with a clear error; .gz/.bz2/.xz supported; rules table as proposed (missing path -> 'file not found', line vector/line breaks -> contents, validate format and data). Failing tests in test-parse-input.R (8 of 10 tests fail/error as expected). Verified (2026-10-16): 343 pass / 0 skip; rcmdcheck = baseline; repro: 7a R error, 7b/7c load 327 atoms, 0 console errors | see `git log --grep "Fix #7"` |
| 7 | #8 Structure load failures are silent | committed (2026-10-16); explained; repro confirmed headless (bad code: stale 46-residue _sequence, no error; broken.pdb loads as 0 atoms without error; good+bad: nothing shown; console only says "error loading file: ''"). Decisions: all-or-nothing + _error; clear _sequence/_resno/_chainname/_PDB on failure; 0 atoms = error. Failing tests in test-browser-load-error.R (4/4 time out waiting for _error). Verified (2026-10-16): all loads awaited (no partial display), every failing structure named, errors after loading keep the structure, _error sent as event, stale renders ignored (render counter); 366 pass / 0 skip; rcmdcheck = baseline | see `git log --grep "Fix #8"` |
| 8 | #10 `snapShot` resets `_rendering` too early | committed (2026-10-16); explained; repro confirmed headless (false at 19 ms, PNG at 164 ms); failing tests in test-browser-snapshot.R (order wrong; no error on failure). Verified (2026-10-16): snapshots counted on the stage (stage.pendingSnapshots), countChanged leaves the final false to the snapshot, which sends it after the download if no other task runs; tested with the real makeImage and overlapping snapshots; 372 pass / 0 skip; rcmdcheck = baseline | see `git log --grep "Fix #10"` |
| 9 | #9 `zoomMove()` overridden with several structures | committed (2026-10-16); explained; repro confirmed headless: duration 0 (default) with 2 structures always lost (camera 24 A off); duration 1000 works by animation timing; with superpose, zoomMove on a target aims at its pre-superpose position (47 A off). Failing tests in test-browser-zoommove.R (5 of 7 fail; the 2 duration-1000 cases without superpose already pass). Verified (2026-10-16): zoomMove applied after superpose, autoView and the Shiny inputs; shared zoomMoveTo() also used by updateZoomMove; R warns for zoomMove on several structures; repro all 10 cases 0.0 A; 386 pass / 0 skip; rcmdcheck = baseline | see `git log --grep "Fix #9"` |
| 9b | #18 click structure + #12 1-based numbering + #15 structureIndex in param | committed (2026-10-16); explained; repro confirmed headless (click on structure 2 zooms to structure 1, 42 A off; highlight on both). Decision (user): 1-based now — new `structure` argument, `structureIndex` deprecated (warning, still works), new input `_selectionStructure` (1-based). #15 included (same lines). Failing tests: test-proxy.R (structure arg, deprecation, validation) and test-browser-click-structure.R (no _selectionStructure). Verified (2026-10-16): click inputs sent as events (same residue in another copy now fires); `structure` placed after `structureIndex` (positional calls unchanged); invalid structureIndex warns and applies to all as before; 424 pass / 0 skip; rcmdcheck = baseline; repro: both clicks OK, highlight only on clicked structure | see `git log --grep "Fix #18"` |
| 10 | #11 Sequence inputs change shape | todo | |
| 11 | #13 `updateSelection(name = name)` self-default | todo | |
| 12 | #14 Dead code and build config cleanup | todo | |
| 13 | #15 `structureIndex` leaks into NGL parameters | committed with Step 9b | see `git log --grep "Fix #18"` |
| 14 | #12 0- vs 1-based indexing (breaking, decide last) | committed with Step 9b (decision: 1-based `structure`, `structureIndex` deprecated) | see `git log --grep "Fix #18"` |

States: `todo` → `explained` → `observed` (user confirmed seeing it) → `fixed` → `verified` → `committed`.

The `#N` numbers match the original review so findings stay traceable. Steps are
ordered so that changes to the same code region happen one after another
(#2 and #3 both restructure `renderValue`), and the one breaking API change
comes last.

---

## Per-bug protocol (follow exactly)

**Do not change package code (`R/`, `inst/`) for a bug until the user says
"fix bug #N".** Explaining and reproducing come first.

1. **Explain.** Present the bug section below to the user in your own words:
   what goes wrong, why (mechanism), when a user would hit it, and the
   proposed fix. Re-read the cited code first; line numbers drift as fixes
   land, so cite current lines. Answer questions until the user understands.
2. **Reproduce.** Build the repro app described in the bug section at
   `dev/repro/<NN>-<slug>/app.R` (see "Repro app conventions"). Run it
   yourself in headless Chrome (shinytest2) to confirm it really shows the bug
   *before* handing it over. If it does not reproduce, stop and tell the user;
   the bug description may be wrong.
   Tell the user how to launch it, what to click, and what to look for.
3. **Wait** for the user to confirm they observed it. Set state `observed`.
   If the bug section lists a **Decision**, get the answer now.
4. **Write the failing test first.** Add the automated test(s) listed in the
   bug section. Run them against the *unfixed* code and show they fail for
   the right reason. A test that passes before the fix does not prove anything.
5. **Fix** (only after "fix bug #N"). Smallest change that fixes the root
   cause. Match the surrounding code style. No drive-by refactors; if you spot
   something else, add it to "Found during the work" at the bottom.
6. **Verify** (see "Double-check protocol"). Every check must pass, and report
   the actual output. Set state `verified`.
7. **User check.** User reloads the same repro app (it loads the working-tree
   package, so it now shows the fixed behaviour) and one related example app.
8. **Record.** Add a `NEWS.md` bullet under a new development heading,
   update roxygen docs/vignette if behaviour visible to users changed, run
   `devtools::document()` if roxygen changed, update the Status table.
   Commit only when the user asks (message: `Fix #N: <summary>`).

## Double-check protocol (after every fix)

Run all of these and report the results; do not summarise a failure as a pass.

1. New test(s) for this bug: failed before the fix, pass after.
2. Full unit suite: `devtools::test()` — all green, no new warnings.
3. Browser suite: `devtools::test(filter = "browser")` — all green.
4. Example smoke test: all 15 apps in `inst/examples/` load with no browser
   console errors (part of the browser suite, needs network for RCSB).
5. `rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "warning")`
   — compare against the Step 0 baseline: no new ERROR/WARNING/NOTE.
6. Blast radius: list every function/handler you changed, then `grep` for all
   callers and all example apps/vignette chunks that use them, and state for
   each why it is unaffected or how it was tested.
7. Independent review: run the `/code-review` skill on the uncommitted diff
   and address or explain every finding.
8. Re-read the full diff once more yourself before reporting done.

---

## Step 0 — Baseline and test infrastructure (#1, #16)

Nothing can be verified until this exists. No bug fixes in this step.

### 0a. NGL 2.4.0 packaging (#1)

**Situation.** The working tree has `inst/htmlwidgets/NGLVieweR.yaml` pointing
at `lib/NGL-2.4.0/ngl.js`, but `inst/htmlwidgets/lib/NGL-2.4.0/` is untracked.
`lib/NGL-2.0.0/` (1.3 MB) is still tracked. Committing the YAML alone would
ship a package that cannot load its JavaScript. Both folders also contain an
unused `1crn.pdb` and a `.DS_Store`.

**Why it matters here.** All repros and tests must run against the NGL
version that will ship, otherwise "fixed" may not mean fixed. The bug
analysis in this plan was checked against the 2.4.0 source.

**Actions** (confirm with user first: are they committed to 2.4.0?):
- `git add inst/htmlwidgets/lib/NGL-2.4.0/ngl.js`, `git rm -r inst/htmlwidgets/lib/NGL-2.0.0`.
- Move `1crn.pdb` to `tests/testthat/fixtures/1crn.pdb`; drop it from `lib/`.
- Add `.DS_Store` to `.gitignore`; `git rm --cached` all tracked `.DS_Store` files.
- Add `^dev$` to `.Rbuildignore` (already done when this plan was written).

### 0b. Test infrastructure (#16)

- `usethis::use_testthat(3)`.
- Install and add to Suggests: `shinytest2`, `chromote` (`testthat` too).
  Chrome is installed at `/Applications/Google Chrome.app`.
- **Fixtures** (`tests/testthat/fixtures/`), generated by a committed script
  `dev/make-fixtures.R` so they can be regenerated:
  - `1crn.pdb` (crambin, 1 chain, 46 residues).
  - `1crn_moved.pdb`: the same atoms with a known rotation (e.g. 40° about z)
    and translation (e.g. +25 Å x) applied. Superposing it onto `1crn.pdb`
    must give CA RMSD ≈ 0, which makes superpose testable without network.
  - `1crn_lines.rds`: `readLines("1crn.pdb")` (for #7).
- **R unit tests** (no browser, CRAN-safe). Proxy functions only use
  `proxy$id` and `proxy$session$sendCustomMessage`, so use a fake session:

  ```r
  fake_proxy <- function(id = "viewer") {
    sent <- new.env(); sent$msgs <- list()
    session <- list(sendCustomMessage = function(type, message)
      sent$msgs[[length(sent$msgs) + 1]] <- list(type = type, message = message))
    structure(list(id = id, session = session, sent = sent), class = "NGLVieweR_proxy")
  }
  ```

- **Browser tests** (`tests/testthat/test-browser-*.R`) with test apps in
  `tests/testthat/apps/<name>/app.R`. Every browser test starts with
  `skip_on_cran(); skip_if_not_installed("shinytest2")`; tests that hit RCSB
  also `skip_if_offline()`. Read NGL state through JS, e.g.

  ```r
  app$wait_for_js("HTMLWidgets.find('#viewer') && HTMLWidgets.find('#viewer').getStructure() !== null")
  app$get_js("HTMLWidgets.find('#viewer').getStage().spinAnimation.paused")
  ```

  Collect console errors with `app$get_logs()` and fail on any `error` entry.

### 0c. Characterisation tests (lock in current *correct* behaviour)

Write these before any fix so regressions show up. They must all pass on
the current code:

- `NGLVieweR()` with a PDB code, a file path, a text string + `format`:
  check `widget$x$structures[[1]]` (`type`, `file_ext`, `data` prefix).
- Each builder (`addRepresentation`, `setScale`, `setRotation` incl. degree
  → radian conversion, `setPosition`, `zoomMove`, `stageParameters`,
  `selectionParameters`, `setQuality`, `setFocus`, `setRock`, `setSpin`,
  `setSuperpose`, `addStructure`) writes the expected fields, and the
  "last structure" functions target the last added structure.
- Each of the 14 proxy functions sends the expected message type and payload.
- Existing error messages (missing `data`, missing format for long strings,
  missing `sele_*` in `setSuperpose`).
- Browser: widget renders 1crn fixture; `_sequence`, `_resno`,
  `_chainname`, `_PDB` arrive; clicking (via `stage.signals.clicked.dispatch`
  with a picking proxy, or `app$click` on the canvas) sets `_selection`.
- Browser smoke: every example in `inst/examples/` loads without console errors.

### 0d. Baseline run

Run the full double-check protocol once and save the output in
`dev/baseline-check.md` (test counts, rcmdcheck NOTEs). Later steps compare
against it.

### Repro app conventions

- Path: `dev/repro/<NN>-<slug>/app.R`. Launch from the project root:
  `shiny::runApp("dev/repro/02-handler-leak", launch.browser = TRUE)`.
- First line loads the **working-tree** package, so the same app shows the
  bug before the fix and the fixed behaviour after:
  `pkgload::load_all(normalizePath("../../.."), quiet = TRUE)`
  (`runApp` sets the working directory to the app folder).
- Use the fixtures in `tests/testthat/fixtures/` where possible so the repro
  does not depend on the network.
- Each repro has a **"What to look for"** text box at the top of the page, and
  a live **debug panel** that shows the measured value that proves the bug
  (a counter, a flag, an RMSD), so the bug is visible as a number, not just
  "it looks wrong".

---

## Step 1 — #2 Event handlers pile up on every re-render

**Where.** `inst/htmlwidgets/NGLVieweR.js`, `renderValue` (lines ~19-27 and ~170-213 at review time).

**What happens.** htmlwidgets calls `factory()` once per widget and keeps the
returned object. The NGL `stage` is created in `factory`, so it lives for the
whole page. `renderValue()` runs on the first render **and every time the
Shiny `renderNGLVieweR()` expression re-runs** (any reactive it depends on
changes). Each call to `renderValue()`:

- adds a new `window` resize listener (`$(window).resize(...)` / `addEventListener`);
- adds a new `stage.tasks.signals.countChanged` handler;
- adds a new `stage.signals.clicked` handler.

None of them are ever removed. After N renders there are N copies of each.

**Consequences.**
- One click calls `Shiny.onInputChange` for `_selection` and `_selAround`
  N times. *Correction after the repro (Step 1):* the server's
  `observeEvent` runs only **once**, because Shiny batches inputs set in the
  same tick and sends only the last value. So the server does not see
  duplicates; the cost is in the browser.
- Each click handler closes over the `opts` of the render that created it.
  Measured: after renders with proximity 3, 1, 8, one click computed
  `_selAround` three times with 26, 7 and 125 atoms. The server gets 125
  (correct) only because the newest handler runs last and Shiny keeps the
  last value. All N handlers still do the neighbour search.
- Memory and CPU grow with every re-render (each resize also calls
  `handleResize` N times).
- The `resize()` method htmlwidgets provides is empty, so container resizes
  that are not window resizes (e.g. a tab or sidebar collapsing) are not
  handled.

**When a user hits it.** Any Shiny app whose `renderNGLVieweR()` depends on an
input (e.g. choosing a PDB code from a dropdown). Static R Markdown output
renders once and is not affected.

**Repro `dev/repro/02-handler-leak`.**
- A `selectInput` ("cartoon" / "ball+stick") that the `renderNGLVieweR()`
  depends on, so changing it re-renders.
- A `numericInput` for `selectionParameters(proximity = ...)`.
- Debug panel showing, polled every 500 ms from JS:
  `stage.signals.clicked.getNumListeners()`,
  `stage.tasks.signals.countChanged.getNumListeners()`.
- A server-side counter: how many times `input$viewer_selection` changed
  per click (use `observeEvent(input$viewer_selection, ..., ignoreInit = TRUE)`
  with a counter, and Shiny's `priority = "event"` in the JS so identical
  values still count — or have the debug JS wrap `Shiny.setInputValue` and
  count calls per click).
- **Look for:** listener counts go 1 → 2 → 3 as you switch the dropdown; one
  click produces N `_selection` sends.

**Proposed fix.**
- Register the resize listener and both signal handlers **once** in
  `factory`, not in `renderValue`.
- Keep the current options in a variable in the factory closure
  (`var currentOpts = null;`, assigned at the start of `renderValue`) and
  have the click handler read `currentOpts.selectionParameters`.
- Implement `resize: function(width, height) { stage.handleResize(); }`.
- Keep the "already removed" try/catch in the countChanged handler.

**Risks / what else it touches.** Everything in `renderValue` runs after
`stage.removeAllComponents()`. Moving handlers to `factory` means they exist
before the first structure loads; the click handler must cope with
`currentOpts` being `null` and `pickingProxy` being for a removed component.
Step 2 (#3) edits the same function — do it right after this one.

**Tests.**
- Browser: render, re-render 3× (change the input), assert
  `getNumListeners()` is 1 for both signals.
- Browser: after 3 re-renders, one synthetic click produces exactly one
  `_selection` update (count `Shiny.setInputValue` calls via a JS wrapper).
- Browser: after re-render with a different `selectionParameters`,
  `_selAround` reflects the new proximity.
- Browser: `resize()` calls `handleResize` (spy on it, call
  `HTMLWidgets.find('#viewer').resize(...)` or change container size).

---

## Step 2 — #3 Spin and rock never switch off on re-render

**Where.** `NGLVieweR.js`, end of `renderValue` (~218-232).

**What happens.** The code only does something when the option is `true`:

```js
if (opts.setSpin === true) { stage.setSpin(true); }
```

When it is `false`, nothing runs. Because the stage survives re-renders (see
#2), a spin started by an earlier render keeps running. NGL 2.4.0's
`setSpin(true)` also pauses rock and vice versa, so "rock then no animation"
leaves rock on.

The `toggleRock` / `toggleSpin` branches can never be reached: `NGLVieweR()`
sets them to `FALSE` and no exported R function changes them. NGL's
`toggleSpin()` takes no argument (the `true` passed is ignored).

**When a user hits it.** A Shiny app where a checkbox controls
`setSpin(input$spin)` inside `renderNGLVieweR()`. Unchecking it re-renders
but the molecule keeps spinning. (`updateSpin()` through the proxy works,
because it calls `stage.setSpin(message.spin)` with the real value.)

**Repro `dev/repro/03-spin-rock`.**
- Checkboxes "spin" and "rock" used inside `renderNGLVieweR()`.
- Debug panel: `stage.spinAnimation.paused`, `stage.rockAnimation.paused`.
- **Look for:** check "spin" → spins; uncheck → still spinning, `paused` stays `false`.

**Proposed fix.** Replace the four `if` blocks with:

```js
stage.setRock(!!opts.setRock);
stage.setSpin(!!opts.setSpin);
```

Order matters: NGL's `setRock(false)` only pauses rock, `setSpin(false)` only
pauses spin, and `setX(true)` pauses the other. Today's code calls rock
first and spin second, so `spin = TRUE, rock = TRUE` ends with **spin**
(confirmed in the repro; this plan originally said rock and had the order
reversed). The order above keeps that. Write it down in the roxygen of
`setSpin`/`setRock` or make it an error — ask the user.

Related (from /code-review in Step 1, confirmed in the repro): stage
settings from `stageParameters()` also survive re-renders; a
`backgroundColor = "white"` stays after it is removed from the R code.
Possible fix: remember `stage.getParameters()` once in `factory` and apply
`Object.assign({}, defaults, opts.stageParameters)` in `renderValue`.
Remove the dead `toggleRock`/`toggleSpin` fields from `NGLVieweR()` and the
JS (also listed in #14).

**Tests.**
- R: `NGLVieweR()` no longer contains `toggleRock`/`toggleSpin` (only if removed).
- Browser: render with spin → `spinAnimation.paused === false`; re-render
  with spin FALSE → `true`. Same for rock. Spin+rock → documented result.
- Browser: `updateSpin`/`updateRock` proxies still work after a re-render.

---

## Step 3 — #4 Superpose moves the wrong structure

**Where.** `NGLVieweR.js`, superpose block (~127-145).

**What happens.** This is worse than described in the original review.
In NGL 2.4.0, `NGL.superpose(a, b, align, seleA, seleB)` **moves `a` onto `b`**
(it ends with `new Superposition(...).transform(a); a.refreshPosition()`).
NGL's own `StructureComponent.superpose(other)` confirms this: it calls
`superpose(this.structureView, other.structureView, ...)` and then updates
its own representations.

NGLVieweR calls:

```js
NGL.superpose(sRef, sTarget, true, seleRef, seleTarget);   // inside the loop over targets
...
structures[0].updateRepresentations({ position: true });   // after the loop
```

So:
1. It moves the **reference** onto each target, the opposite of the
   documented "superpose onto the reference".
2. With 3+ structures, the reference is moved onto target 1, then onto
   target 2, … It ends aligned with the **last** target only; the other
   targets are not aligned with anything.
3. Only `structures[0]` has its representations refreshed. With
   `reference = 2`, the structure that actually moved (structure 2) is never
   refreshed, so on screen it may stay where it was. Whether it visibly
   moves depends on whether its representations were still being built
   (NGL builds them asynchronously), so the result can vary between runs.
   *Repro (Step 3): not observed* — with the 1crn fixtures the drawings
   always matched the moved coordinates. Still refresh every moved
   structure in the fix; do not rely on async timing.
4. `_PDB` is written before superposition, so it never contains the
   superposed coordinates (note only; may be intentional).

The vignette example (`reference = 1`, two structures) *looks* right because
with two structures both directions produce an overlay and `structures[0]`
is the one that moved. The structure the user picked as the fixed reference
moved instead.

**Repro `dev/repro/04-superpose`.**
- Load `1crn.pdb` + `1crn_moved.pdb` + a third copy moved differently
  (generate in the app with a different transform).
- Controls: `reference` (1/2/3), number of structures (2/3).
- Debug panel per structure: CA RMSD to the reference **as displayed**
  (computed in JS from `component.structure` positions), plus "did the
  reference move?" (first CA coordinate before vs after).
- **Look for:** with 2 structures/reference 1: reference moved = yes.
  With 3 structures: RMSD of structure 2 to reference ≫ 0. With reference 2:
  overlay not visible / RMSD shown ≠ visual.

**Decision.** After the fix the reference stays put and targets move. That
matches the docs but changes the absolute coordinates users saw before
(camera, `setPosition` interplay). Confirm with the user; add a NEWS note.

**Proposed fix.**

```js
for (var i = 0; i < structures.length; i++) {
  if (i === refIndex) continue;
  NGL.superpose(structures[i].structure, sRef, true, seleTarget, seleRef);
  structures[i].updateRepresentations({ position: true });
}
```

Note the selection arguments swap too (`seleA` belongs to the moved structure).
Also validate `refIndex` (1 ≤ reference ≤ number of structures) in R in
`setSuperpose()`, with a clear error, because R cannot know the count until
render — so check in JS too and `console.error` if out of range.

**Tests.**
- Browser: 2 and 3 structures with the moved fixtures, `reference` 1 and 2:
  every target's CA RMSD to the reference < 0.1 Å; reference's first CA
  coordinate unchanged.
- R: `setSuperpose()` stores the selections unchanged (characterisation),
  and errors for `reference < 1` or non-integer.
- Smoke: vignette superpose chunk still renders (needs network).

---

## Step 4 — #5 `updateFullscreen()` ignores its argument

**Where.** `NGLVieweR.js` handler `NGLVieweR:updateFullscreen` (~294-301);
`R/api.R` `updateFullscreen()`.

**What happens.** R sends `fullscreen = TRUE/FALSE`, but the JS handler never
reads it. It always calls `stage.toggleFullscreen(document.body)`:

- `updateFullscreen(proxy, FALSE)` while *not* fullscreen → **enters** fullscreen.
- `updateFullscreen(proxy, TRUE)` while already fullscreen → **exits**.
- The element made fullscreen is the whole page (`document.body`), not the
  viewer. NGL's default (no argument) is the viewer container.

**Repro `dev/repro/05-fullscreen`.**
- Buttons "fullscreen TRUE" and "fullscreen FALSE".
- Debug panel: `document.fullscreenElement` (tag/id or "none").
- **Look for:** clicking FALSE enters fullscreen; the fullscreen element is `BODY`.
- Note: browsers only allow fullscreen from a user gesture. The Shiny round
  trip usually still counts in Chrome, but if not, explain this to the user;
  headless verification may need `--enable-features` flags or a mocked
  `requestFullscreen`.

**Decision.** Fullscreen the whole page (current behaviour; keeps Shiny
controls visible) or the viewer only (NGL default)? Ask the user.

**Proposed fix.**

```js
var isFull = !!(document.fullscreenElement || document.webkitFullscreenElement);
if (!!message.fullscreen !== isFull) stage.toggleFullscreen(<chosen element>);
```

**Tests.**
- R: `updateFullscreen(p, FALSE)` sends `fullscreen = FALSE` (characterisation).
- Browser: stub `stage.toggleFullscreen` with a spy and fake
  `document.fullscreenElement`; assert: FALSE while not fullscreen → no call;
  TRUE while not fullscreen → one call; FALSE while fullscreen → one call.

---

## Step 5 — #6 `addStructure()` and `NGLVieweR()` parse input differently

**Where.** `R/NGLVieweR.R`: `NGLVieweR()` (~154-194) and `addStructure()` (~390-422).

**What happens.** Both functions decide whether `data` is a PDB code, a file
path, or file contents, but with different rules:

| Check | `NGLVieweR()` | `addStructure()` |
|---|---|---|
| File path | `file.exists(data)` | `file.exists(data) && nchar(data) > 8` |
| Contents | `nchar > 8` | `nchar > 8 && file_ext(data) == ""` |
| Vector input guard | `length(data) == 1` | none (R ≥ 4.3 `&&` error on length > 1) |

Also (found in the Step 5 repro): `NGLVieweR()` strips a leading dot from
`format` (".pdb" -> "pdb"), `addStructure()` does not, so
`addStructure("1crn.pdb", format = ".pdb")` is a code with file_ext ".pdb".

Example: a file `1crn.pdb` in the working directory (8 characters).
`NGLVieweR("1crn.pdb")` reads the file. `addStructure("1crn.pdb")` fails the
`nchar > 8` test and is treated as a PDB code, so NGL requests
`rcsb://1crn.pdb.pdb` and nothing appears.

**Repro `dev/repro/06-addstructure-parse`.** Copies `1crn.pdb` into a temp
dir, `setwd` there, renders `NGLVieweR("1crn.pdb")` next to
`NGLVieweR(<other>) %>% addStructure("1crn.pdb")`. Debug panel prints the
`type`/`data` prefix that R produced for each structure.
**Look for:** left loads; right shows `type = "code"`, `rcsb://1crn.pdb.pdb`, empty.

**Proposed fix.** One internal helper, e.g. `R/utils.R`:
`.parse_structure_input(data, format, caller)` returning
`list(type, data, file_ext)`; both functions call it. Steps 5 and 6 together
define its rules. For this step keep `NGLVieweR()`'s current rules exactly
(they are the more correct ones) so the only behaviour change is in
`addStructure()`.

**Tests.** A table-driven test calling both functions with the same inputs
(PDB code, short file name, long file path, content string + format, content
without format) and asserting identical `type`/`file_ext`/`data`.

---

## Step 6 — #7 Missing files, line vectors and binary formats

**Where.** The new `.parse_structure_input()` (originally `NGLVieweR()` ~163-194).

Three separate problems; fix them one at a time inside this step, with a
repro panel each.

**7a. A path to a file that does not exist is sent as file contents.**
`NGLVieweR("data/model.pdb")` with a typo: not a file → `nchar > 8` → treated
as contents, `file_ext <- format` = `NULL`. The widget gets the literal text
`"data/model.pdb"` as a structure with no extension; NGL fails silently and
the viewer is blank. The user gets no error.
*Fix:* if `data` has a known structure extension or contains `/` or `\` and
the file does not exist, `stop("NGLVieweR: file not found: <path>")`.

**7b. A character vector of lines is treated as a PDB code.**
The code comments say "vector of strings", but the check is `length(data) == 1`.
`NGLVieweR(readLines("1crn.pdb"), format = "pdb")` skips both branches,
reaches `sprintf("rcsb://%s.pdb", data)`, and builds a vector of thousands
of URLs.
*Fix:* `length(data) > 1` → treat as contents, `paste(collapse = "\n")`,
require `format`.

**7c. Binary formats are corrupted.** The docs list `.mmtf` (MessagePack,
binary). `readLines()` + `paste()` + `new Blob([...], {type: 'text/plain'})`
corrupts it. `.gz` files have the same issue, and `file_ext("x.pdb.gz")` is `"gz"`.
**Decision:** support binary (R: `readBin` + base64; JS: decode to
`Uint8Array` for the Blob, pass `compressed`/`binary` options) or remove
`.mmtf` from the docs and error clearly on binary extensions. Ask the user.

**More parser edge cases** (from /code-review in Step 5; decide the rules
together here, in `.parse_structure_input()`):
- a short file name without extension that exists ("model") passes the
  "specify the format" check (only runs for nchar > 8) and is sent with
  file_ext "";
- short contents with an explicit format (`"C\nO"`, format = "sdf") become a
  PDB code because nchar <= 8; a given `format` or a line break should mean
  contents/file;
- `format` is not validated (NA, "", ".", c("pdb", "cif"));
- `NA` data becomes "rcsb://NA.pdb" (also listed under Found during the work).

**Measured in Step 6:** 7a and 7b do not just fail silently: the bad data
makes `stage.loadFile()` throw synchronously in `renderValue`, which Shiny
reports as a client error and which also stops the other outputs updated
in the same flush. `.gz` files are read correctly by `readLines()` (R
decompresses them) but get file_ext "gz", which NGL rejects ("autoLoad: ext
'gz' unknown"); using the extension before `.gz` is enough. RCSB retired
MMTF in July 2024.

**Repro `dev/repro/07-input-parsing`.** Three tabs, one per sub-bug, each
showing the R call, the resulting `widget$x$structures[[1]]` summary, and the
viewer. **Look for:** blank viewer without an error; vector of URLs; mmtf garbage.

**Tests.** R: `expect_error(NGLVieweR("nope/missing.pdb"), "file not found")`;
line-vector input gives `type = "file"` and one string; binary per decision.
Make sure a 4-character PDB code that happens to look like a file name
(`"1crn"`) is still a code, and that existing calls in the vignette, README
and `inst/examples` are unchanged (grep them all).

---

## Step 7 — #8 Structure load failures are silent

**Where.** `NGLVieweR.js` `Promise.all(...).then(...)` (~38-167) — no `.catch`.

**What happens.** If any `stage.loadFile()` rejects (wrong PDB code, network
down, unparseable file), the whole `then` block is skipped. The browser
console shows an unhandled rejection; Shiny gets nothing: `_sequence` etc.
keep their old values from a previous render, and the user's app cannot tell
the load failed. With several structures, one bad one stops all of them.

**Repro `dev/repro/08-load-failure`.** Text input for a PDB code feeding
`renderNGLVieweR()`. Debug panel shows `input$viewer_sequence` length and any
error input. **Look for:** enter `1CRN` (loads), then `XXXX` → viewer blank,
`_sequence` still shows 1CRN's data.

**Measured in Step 7:** a file NGL cannot parse (broken.pdb) does not
reject at all: it "loads" as a structure with 0 atoms, `_sequence` becomes
empty and no error is reported. NGL's rejection message is just
`error loading file: ''`, without saying which structure failed. After a
failed load `getStructure()` still returns the removed components of the
previous render (see Found during the work), so proxy calls act on them.

**Proposed fix.** Add `.catch(function(err) { console.error(...); if (shinyMode) Shiny.setInputValue(el.id + "_error", String(err), {priority: "event"}); })`.
Decide with the user: also clear `_sequence`/`_PDB` on failure? Document the
new `_error` input in the vignette's "Retrieving data" list.

**Tests.** Browser: render a deliberately broken file (fixture
`broken.pdb` = random text, format pdb) → `_error` is set, no uncaught
console error; then a good render clears it.

---

## Step 8 — #10 `snapShot` resets `_rendering` too early

**Where.** `NGLVieweR.js` handler `NGLVieweR:snapShot` (~267-283).

**What happens.** Inside the `setTimeout` it starts `stage.makeImage()`
(asynchronous, returns a Promise) and immediately sets `_rendering` to
`false`. The image is produced later. Apps that show a spinner or disable a
button while `_rendering` is TRUE re-enable it before the PNG exists. If
`makeImage` fails, nothing reports it.

**Repro `dev/repro/10-snapshot`.** Snapshot button with
`param = list(factor = 4, antialias = TRUE)` (slow), and a log of
`_rendering` changes with timestamps plus a JS timestamp when the download fires.
**Look for:** `_rendering = FALSE` logged before the download timestamp.

**Proposed fix.** Move `Shiny.onInputChange(... false)` into `.then()` after
`NGL.download`, add `.catch` that also resets it and logs. Also handle the
stage-undefined branch (reset to false there).

**Tests.** Browser: stub `NGL.download`, record order of events: rendering
true → download → rendering false.

---

## Step 9 — #9 `zoomMove()` overridden when there are several structures

**Where.** `NGLVieweR.js` `renderValue` (~72-73, ~90-96, ~147-149).

**What happens (to confirm in the repro).** For each structure the loop calls
`stage.autoView()`, then starts that structure's `zoomMove`. Two things can
then override it:
1. the next loop iteration's `stage.autoView()` (if `zoomMove()` was applied
   to an earlier structure), and
2. the final `if (structures.length > 1) stage.autoView();`.

NGL's `autoView()` is itself an `animationControls.zoomMove(...)`. With
`duration = 0` both are applied immediately and the later `autoView` wins.
With `duration > 0` the animations run at the same time and the result may
depend on timing. The repro must establish which cases actually fail.

**Repro `dev/repro/09-zoommove-multi`.** One vs two structures, `duration`
0 / 1000, `zoomMove` on structure 1 vs 2. Debug panel: camera position
(`stage.viewerControls.position`) after 2 s vs the expected center.
**Look for:** with two structures the camera ends at the overall center, not
the `zoomMove` center.

**Measured in Step 9:** with the default `duration = 0`, zoomMove is always
overridden by the final `stage.autoView()` when there are 2+ structures.
With `duration > 0` it survives (the running animation overrides the
immediate autoView), i.e. by timing. New: zoomMove's center is computed
before superpose, so `zoomMove()` on a superposed target aims at where it
was before it moved (47 A off in the repro).

**Proposed fix.** Apply camera moves after all structures are loaded and
superposed: first one `stage.autoView()`, then the (last) requested `zoomMove`.

**Tests.** Browser: two fixtures far apart, `zoomMove(center = "1-5")` on
structure 2, duration 0 → camera center within ~1 Å of the selection center.

---

## Step 9b — #18 A click does not say which structure was clicked

**Raised by the user in Step 9** ("will click-to-zoom pick the right
molecule with several structures?").

**What happens.** The click handler sends `_selection` =
`pickingProxy.getLabel()`, e.g. `atom: [LYS]3:A.CB (7CID.pdb)` for a PDB
code and `atom: [CYS]4:A.N ()` for a file or file contents (the component
has no name). Nothing gives the structure's number. A click-to-zoom app
calls `updateZoomMove(center = resi)` without `structureIndex`, so it
zooms to that residue in structure 1 even when structure 2 was clicked.
`_selAround` is a list of atom indices of the clicked structure
(`@0,1,2...`); passed to `addSelection()` without `structureIndex` it is
applied to every structure, highlighting unrelated atoms there.

**Proposed fix.** New input `input$<id>_selectionStructure`: the number of
the clicked structure, sent with `_selection`/`_selAround`. Its base (0 or 1)
must match whatever #12 decides for `structureIndex`.

**Tests.** Browser: two structures; a click on structure 2 sends 2 (or 1,
per decision); click-to-zoom using it ends on the clicked residue.

**Combined with #12 and #15 (decided 2026-10-16).**
- `addSelection(..., structure = NULL, structureIndex = NULL)` and
  `updateZoomMove(..., structure = NULL, structureIndex = NULL)`: `structure`
  counts from 1. `structureIndex` (0-based) still works but warns that it is
  deprecated and is converted (`structure = structureIndex + 1`).
- The structure number is sent as a top-level message field, not inside
  `param` (#15); the JS converts it to an array index.
- A structure number larger than the number of structures logs a console
  error instead of silently applying to all/first.
- New input `input$<id>_selectionStructure` (1-based), sent on every click.
- Update `multiStructureSelection` example, ?addSelection, ?updateZoomMove,
  vignette input list, NEWS.

---

## Step 10 — #11 Sequence inputs change shape with the number of structures

**Where.** `NGLVieweR.js` ~156-164.

**What happens.** Measured with Shiny's input decoding:

- 1 structure: `input$viewer_sequence` = `c("T","T","C",...)` (one element per
  residue); `_resno` integer vector; `_chainname` one per residue.
- 2+ structures: the arrays are joined, so `_sequence` = `c("TTCC...", "TTCC...")`
  (one string per **structure**); `_resno` = `c("1,2,3,...", "1,2,3,...")`
  (strings, not numbers); `_chainname` = `c("AAAA...", ...)`.

The vignette documents only the one-structure shape. Code written for one
structure silently misbehaves after `addStructure()` (e.g. `length(seq)`
becomes 2).

**Repro `dev/repro/11-input-shapes`.** Toggle 1/2 structures; print
`str()` of the four inputs. **Look for:** the type and length flip.

**Decision.** (a) Keep as is, document both shapes (no break); (b) always
send per-structure lists (breaking for one-structure apps); (c) keep the
current inputs for one structure and add new `_sequences` etc. inputs with a
consistent list-per-structure shape. Recommended: (c), or (a) if the user
prefers no API growth.

**Tests.** Browser: shapes for 1 and 2 structures match the chosen spec.

---

## Step 11 — #13 `updateSelection(name = name)` defaults to itself

**Where.** `R/api.R` `updateSelection()` (~214).

**What happens.** `name = name` is a self-reference. Calling
`updateSelection(proxy, sele = "1-10")` without `name` fails with
"promise already under evaluation: recursive default argument reference"
instead of saying `name` is required.

**Repro.** Not a viewer bug; show it in the R console:
`updateSelection(fake_proxy(), sele = "1-10")`.

**Proposed fix.** Remove the default (`name,`). Optionally `if (missing(name)) stop(...)`
with a clear message, matching other functions.

**Tests.** `expect_error(updateSelection(p, sele = "1"), "name")`;
characterisation test for the normal call still passes.

---

## Step 12 — #14 Dead code and build config

Low risk; one commit. Repro: not applicable. Items:

- `addStructure()` sets per-structure `setRock`, `setSpin`, `toggleRock`,
  `toggleSpin` that the JS never reads (rock/spin are stage-wide). Remove.
- Commented-out block in `NGLVieweR()` (~229-250). Remove.
- `.Rbuildignore`: `^pkgdown$` listed twice; `.gitignore` entry is unanchored
  (works, but should be `^\.gitignore$`).
- `toggleRock`/`toggleSpin` if not already removed in Step 2.

**Tests.** Full suite + rcmdcheck; R characterisation test updated for removed fields.

---

## Step 13 — #15 `structureIndex` leaks into NGL representation parameters

**Where.** `R/api.R` `addSelection()` puts `structureIndex` into `param`;
JS `NGLVieweR:addSelection` passes `param` to `addRepresentation`.

**What happens.** NGL receives an unknown `structureIndex` representation
parameter. Today it is ignored, but it ends up stored on the representation
and could collide with a future NGL parameter. `updateZoomMove()` already
sends it as a separate message field, which is the cleaner pattern.

**Repro.** Debug panel showing `Object.keys(repr.repr.parameters)` or
`repr.getParameters()` for the added selection; `structureIndex` is present.

**Proposed fix.** R: `message$structureIndex <- structureIndex`; JS: read
`message.structureIndex`. Keep accepting the old location for one release?
(Only internal, so no.)

**Tests.** R: message has top-level `structureIndex`, `param` does not.
Browser: selection lands on the right structure (multiStructureSelection example still works).

---

## Step 14 — #12 0- vs 1-based indexing (breaking; decide last)

**What happens.** `setSuperpose(reference = 1)` is 1-based (JS subtracts 1).
`addSelection(structureIndex = 0)` and `updateZoomMove(structureIndex = 0)`
are 0-based. R users expect 1-based. The `multiStructureSelection` example
uses `ifelse(..., 0, 1)`.

**Decision.** (a) leave it, improve docs; (b) switch to 1-based with a
deprecation period (e.g. new argument name `structure`, keep `structureIndex`
with a deprecation warning); (c) switch outright (breaking). Recommend (b).
Version 1.4.0 has been submitted to CRAN (`CRAN-SUBMISSION` exists), so
users may already depend on 0-based.

**Tests.** Per decision; examples updated; old argument still works under (b).

---

## Found during the work

(Add anything new discovered while fixing; do not fix it inside another bug's step.)

- **#17 (Step 2b), high priority — content strings fail on R-devel** (found by CI on
  2026-10-16, ubuntu R-devel, run 38921922335). `NGLVieweR(<file contents>,
  format = "pdb")` errors with "basename(x): path too long": R-devel's
  `tools::file_ext()` calls `basename()`, which errors for strings longer
  than PATH_MAX (4096). The first check in `NGLVieweR()` and both checks in
  `addStructure()` call `tools::file_ext(data)` on the raw input, and
  `file.exists(data)` may follow. Every real PDB passed as text is longer
  than 4096 characters. Breaks the test `test-NGLVieweR.R` "a content string
  with a format", so CRAN's R-devel check would ERROR on the next
  submission. Belongs with Step 5/6 (input parsing), but should be done
  before them.
- `NGLVieweR(NA_character_)` / `addStructure(v, NA)` fail with "missing value
  where TRUE/FALSE needed" instead of a clear message (from /code-review in
  Step 2b). Pre-existing; fold into Step 5/6.
- CI macOS R-devel failed in `setup-r-dependencies` (no CRAN binaries for
  R 4.7 on macOS; dependencies built from source). Probably a new Suggests
  (chromote → websocket) failing to compile; not confirmed.

- The `_PDB` input is written before superposition (see #4, point 4).
- (Fixed in Step 4 with #5.) `inst/examples/updateFullscreen/app.R` wrapped the whole app in
  `if (interactive()) { ... }`, so `app.R` returns `NULL` in a non-interactive
  R process (shinytest2, shiny-server, Rscript) and the app cannot start. It
  is the only example that does this. Its smoke test is skipped
  (`known_broken` in `test-browser-examples.R`) until fixed; good candidate
  to fix together with #5 (Step 4). Found in Step 0.
- Overlapping re-renders (from /code-review in Step 1). `renderValue` starts
  `Promise.all(loadFile...)` without a render token. If a second render
  starts before the first load resolves, the first render's components are
  added after `removeAllComponents()` and its `.then` overwrites
  `structures` and sends stale `_PDB`/`_sequence`. Fix: a render counter;
  ignore results of stale renders. Pre-existing.
- Stage settings survive re-renders (from /code-review in Step 1).
  `stage.setParameters(opts.stageParameters)` only sets the keys given, so a
  `backgroundColor` from an earlier render stays after it is removed from
  the R code. Same family as #3; consider handling in Step 2. Pre-existing.
- `structures` points to removed components between `removeAllComponents()`
  and the new load resolving, so proxy calls (`updateZoomMove`,
  `addSelection`) in that window act on disposed components. Fix: set
  `structures = null` after `removeAllComponents()`. Pre-existing.
- Click handler applies defaults only when `selectionParameters` is absent,
  not per field (e.g. proximity `NA` from a cleared `numericInput`).
  Pre-existing, minor.
- `_PDB` is still written before superposition (see #4 point 4). After the
  #4 fix the stale coordinates are those of the moved targets, not the
  reference. Decide: send `_PDB` after superpose? (from /code-review, Step 3)
- `setPosition()`/`setRotation()`/`setScale()` on a structure are component
  transforms; superpose works on atom coordinates and ignores them, so a
  transformed target is not visually on the reference. Pre-existing.
- An exception inside `NGL.superpose()` (e.g. selection matching no atoms)
  aborts the rest of the `.then` (no `_PDB`/`_sequence`, no autoView).
  Handle with #8 (Step 7). Pre-existing.
- Fullscreen edge cases (from /code-review, Step 4), not fixed: (a) if the
  browser rejects requestFullscreen (no user gesture), NGL's
  toggleFullscreen still sets the element to screen size and never undoes
  it; repeated calls overwrite the saved size. NGL behaviour. (b) With
  several widgets or a fullscreen video on the page, "is fullscreen" is
  page-wide, so one widget's TRUE/FALSE acts on another's fullscreen.
- Input parsing ideas / known limits (from /code-review, Step 6): (a) URL
  support would be easy (NGL loads URLs; pass as type "code" with the URL
  as data) -- today a clear "URLs are not supported" error; (b) extended
  PDB IDs (`pdb_00001crn`, 12 chars) are treated as contents ("specify the
  file format"), as before -- revisit when wwPDB starts using them;
  (c) an extensionless file named like a code (`./1CRN`) wins over the code
  and gives "specify the file format"; (d) unknown formats ("xyz") are not
  checked in R, because NGL supports more than the documented list.
- Load errors (from /code-review, Step 7): (a) for file input the message
  says "file contents, format ..." and not the file name, because R does
  not send the path to the browser (could pass a label from R); (b) proxy
  calls that arrive while structures are loading are dropped with a
  console.log (before #8 they acted on already removed components).
- Overlapping renders: partly fixed in Step 7 (#8): results of an older
  render that finishes after a newer one are discarded (render counter).
- Snapshot (from /code-review, Step 8): if NGL's makeImage() promise never
  settles (e.g. a task that never finishes), `_rendering` stays TRUE; no
  timeout fallback (NGL's own task counter would be stuck as well).
- Test infrastructure: once (Step 9) chromote failed to start Chrome
  ("cannot open the connection to http://127.0.0.1:<port>/json/version");
  the test then ran under different conditions. Not reproduced in two
  reruns. Watch for flakiness.
- zoomMove (from /code-review, Step 9): (a) the center ignores component
  transforms from setPosition()/setRotation()/setScale() (same family as the
  superpose limit); documented in ?zoomMove; (b) the per-structure and final
  stage.autoView() calls still run before a zoomMove replaces them; could
  be skipped when a zoomMove is set (cosmetic, not done).
- Click inputs (from /code-review, Step 9b): (a) a click on a component
  that is not one of the loaded structures gives _selectionStructure NULL,
  which means "all" for addSelection(); NGLVieweR only creates structure
  components, so not reachable today; (b) the superpose range check and
  structureFromMessage() report out-of-range numbers separately (different
  messages); could share one helper.
- `setFocus()`/`setQuality()` override `stageParameters()` (from /code-review
  in Step 2). `renderValue` always calls `stage.setQuality(opts.setQuality)`
  and `stage.setFocus(opts.setFocus)` after `setParameters`, with defaults
  "medium" and 0, so `stageParameters(quality = "high")` or clip/fog values
  are silently replaced. Pre-existing.
- `inst/htmlwidgets/NGLVieweR.yaml`: both dependencies (`NGLVieweR`,
  `helperFunctions`) use `src: htmlwidgets`, i.e. the whole folder. A saved
  widget (`saveWidget(selfcontained = FALSE)`) therefore contains the folder
  twice, incl. `ngl.js` (~1.3 MB) twice and stray copies of `NGLVieweR.js`;
  self-contained HTML and R Markdown output may be ~1.3 MB larger than
  needed. Fix: `src: htmlwidgets/lib/NGL-2.4.0` etc. Found in Step 1.
- `inst/examples/multiStructureSelection/app.R` has no final newline
  (cosmetic; `readLines()` warns). Found in Step 0.
