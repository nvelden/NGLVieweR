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
| 10 | #11 Sequence inputs change shape | committed (2026-10-16); explained; repro confirmed headless (2 structures: _sequence chr[2] joined, _resno chr "1,2,3,...", length(seq) 2, seq[5] NA, resno + 1 errors; _chainname joined without separator loses multi-letter chain names). Decision (user, after discussing options): keep _sequence/_resno/_chainname unchanged; add input$<id>_residues, a data frame with one row per residue (structure, chain, resno, inscode, resname, letter), same shape for 1 or many structures. Built by a registered input handler (Shiny flattens nested arrays). Implemented (R/zzz.R .onLoad/.onUnload, .residues_input in R/utils.R; missing values become NA). Verified (2026-10-16): 454 pass / 0 skip; rcmdcheck = baseline; repro: 46 rows (1 structure) / 92 rows (2), same columns | see `git log --grep "Fix #11"` |
| 11 | #13 `updateSelection(name = name)` self-default | committed (2026-10-16); explained; repro (R console): "promise already under evaluation: recursive default argument reference"; failing test written. Verified (2026-10-16): clear error when name is missing; also fixed the unfinished ?updateSelection description | see `git log --grep "Fix #13"` |
| 12 | #14 Dead code and build config cleanup | committed (2026-10-16); explained: addStructure per-structure setRock/setSpin/toggleRock/toggleSpin, commented-out block in NGLVieweR(), .Rbuildignore (^pkgdown$ twice, .gitignore unanchored, ^LICENSE\.md without $); failing test written. Verified (2026-10-16): JS reads only opts.setRock/setSpin (stage-wide); tarball 123 files, no stray files; 461 pass / 0 skip; rcmdcheck = baseline | see `git log --grep "Fix #14"` |
| 13 | #15 `structureIndex` leaks into NGL parameters | committed with Step 9b | see `git log --grep "Fix #18"` |
| 14 | #12 0- vs 1-based indexing (breaking, decide last) | committed with Step 9b (decision: 1-based `structure`, `structureIndex` deprecated) | see `git log --grep "Fix #18"` |
| 15 | #20 PDB codes without a legacy PDB file cannot be loaded (GitHub #17) | explained (2026-10-18); repro confirmed headless (3J9M and 4V6X: `_error` "could not load structure 1 (rcsb://3J9M.pdb)", also with `format = "cif"`; 1CRN loads). Risk test of mmCIF default done (22 entries; see section). Decision (user): C — `.pdb` first, `.cif` fallback; `format` picks the file. Fixed (2026-10-18): `fallback` field from `.parse_structure_input()`, JS retries with it; failing tests written first (parse-input: fallback/format; browser-pdb-code: fallback, both fail, no fallback, 3J9M). Verified: 639 pass / 0 fail / 0 skip; rcmdcheck = baseline; /code-review: no bugs, cleanups done. User checked repro (2026-10-18; skipped the example app). Committed and pushed; GitHub #17 commented with the fix (stays closed) | see `git log --grep "Fix #20"` |
| 16 | #21 Update functions reset `_rendering` too early | explained (2026-10-18); repro confirmed headless (snapshot + updateColor: `false` at 16 ms, PNG at 152 ms; surface rebuild: `false` at 15 ms with 1 task running; updateColor alone correct). Also found: countChanged handler read NGL's delta as the count (2 -> 1 sent `false`). Decision (user): include it. Fixed (2026-10-18): `renderingDone()` helper (false only when tasks 0 and no snapshot pending) used by countChanged, snapShot and the 4 update handlers. Making the count trustworthy exposed an NGL 2.5.0 leak (unlisten keeps a removed representation's open tasks: mid-build removal or failed build) -> `fixTaskCounter()` wraps stage.tasks.unlisten (takes off only what NGL left, so safe if NGL fixes it). Failing tests first (test-browser-rendering.R: 6 fail before, leak tests fail without the wrapper). Verified: 659 pass / 0 fail / 0 skip; rcmdcheck = baseline; stress script 17 cases settle (tasks 0, no false while busy); user's shinyNGLVieweR app: loader ends hidden in all 11 phases (old code: NGL count leaked to 15, snapshot never downloaded, loader stuck); /code-review findings addressed (see Found during the work). User checked repro (2026-10-18). Committed and pushed | see `git log --grep "Fix #21"` |
| 17 | #27 `_PDB` holds pre-superpose coordinates | committed; explained (2026-10-18); repro confirmed headless (`dev/repro/27-pdb-superpose`: target exported vs displayed CA RMSD 17.56 A, exported = file 0.00 A; superpose off: 0.00). Fixed (2026-10-18, user go-ahead): PDB text written after superpose (`structures.map(PdbWriter)` in the Shiny block). Failing tests first (test-browser-superpose.R: 3 fail before, targets 17.56/51.28 A). Verified: 671 tests, 670 pass + 1 flaky (test-browser-pdb-code.R:93, 1CRN.pdb listed twice; 3/3 reruns pass, see Found during the work); rcmdcheck = baseline; repro 0.00 A; /code-review: 4 minor findings addressed. Committed and pushed (2026-10-18) | see `git log --grep "Fix #27"` |
| 18 | #28 `setFocus()`/`setQuality()` defaults override clip, fog and quality from `stageParameters()` | committed; explained (2026-10-19); repro confirmed headless (`dev/repro/28-focus-overrides-stage`): stageParameters(clipNear = 45) -> actual 0; fogNear 0/fogFar 30 -> 50/100; quality "high" -> "medium"; updateStage() with the same values applies them (45; 0/30; high); no console errors. Decisions (user): stageParameters() wins (shortcuts after it, named keys put back); re-render reset yes. Fixed (2026-10-19): no setQuality/setFocus defaults in NGLVieweR(); renderValue applies them only when used. Failing tests first (test-NGLVieweR.R 2, test-browser-stage-state.R 5 fail before). Verified: 165 tests / 689 expectations pass, 0 skip; rcmdcheck = baseline (1 local time NOTE; a transient GitHub 502 URL NOTE once); repro: render gives 45; 0/30; high; /code-review: 8 findings, 6 addressed (comment, docs, guard, order test, NEWS), re-render after updateFocus() kept by design (NEWS), absolute-scale focus before load noted in Found during the work. Repro extended with sliders on user request; user checked it (2026-10-19). Committed and pushed | see `git log --grep "Fix #28"` |
| 19 | #22 `colorByValue()`: NA gets the middle color when the domain ends are equal | committed; explained (2026-10-19); repro confirmed headless (`dev/repro/22-colorbyvalue-na`): one score + NA -> NGL colors residue 30 (NA) #ffffff instead of na_color; NaN same; two scores -> na_color (correct); no console errors. Fixed (2026-10-19, user go-ahead): equal ends use `(sign(value - domain[1]) + 1) / 2`, so NA/NaN stay NA (na_color) and, from /code-review, values outside the domain (incl. Inf) get the nearest end as documented. Failing tests first (test-colorByValue.R: 4 fail before). Verified: 167 tests / 694 expectations pass, 0 skip (one earlier run had 1 skip + 1 warning, not reproduced in 2 reruns: chromote start, see Found during the work); rcmdcheck = baseline; /code-review: 6 findings, out-of-domain + tests addressed, `ok` from pos kept (sign() carries NA). User checked repro (2026-10-19). Committed and pushed | see `git log --grep "Fix #22"` |
| 20 | #25 `colorByValue()` accepts number strings and "transparent" as colors | deferred (2026-10-19, user: edge case, leave as is for 1.5.0); explained (2026-10-19); repro confirmed headless (repro app removed): c("1","2") -> #000000/#DF536B, "8" -> #9E9E9E, "transparent" -> #FFFFFF, all without error; no console errors | |
| 21 | #29 `NGLVieweR.yaml` copies the whole htmlwidgets folder per dependency | committed; explained (2026-10-19); confirmed: `saveWidget(selfcontained = FALSE)` writes ngl.js (1.29 MB) twice, NGLVieweR.js 3x, NGLVieweR.yaml 2x (and a local .DS_Store); self-contained HTML (1.36 MB) and the CRAN tarball are not affected. User asked for the fix with extensive testing. Fixed (2026-10-19): `all_files: false` on both yaml dependencies (no files moved). Failing tests first (test-dependencies.R: 3 fail before; test-browser-static.R R Markdown: ngl.js written twice). Verified: 174 tests / 725 expectations pass, 0 skip (one earlier full run: known flaky test-browser-pdb-code.R:93, passed alone and in the rerun); rcmdcheck 0/0/1 (local time NOTE); INSTALLED package (tarball -> temp library): saveWidget lib folder = each script once, self-contained, R Markdown both modes, Quarto both modes all render 327 atoms, NGL 2.5.0, 0 errors; all 15 Shiny examples load, 0 console errors; pkgdown (scratch destination) reference + article: 18/18 viewers load, ngl.js once per page folder. /code-review: 7 findings on the tests (pandoc skip, htmltools/callr in Suggests, no %||%, binding all_files only checked for recent htmlwidgets, moved page checks errors) addressed; duplicated chromote helper in test-browser-static.R kept. Found: the system library has NGLVieweR 1.4.0, and pkgdown builds articles from the installed package -> install 1.5.0 before rebuilding the site (done 2026-10-19: devtools::install() to the user library). Committed and pushed | see `git log --grep "Fix #29"` |
| 22 | #26 Shiny examples use a missing `input$backgroundColor`; App 1 names ball+stick "cartoon"; `tools::file_ext` re-exported | committed; verified (2026-10-19). User go-ahead; decision: remove the re-export in 1.5.0 (no reverse dependencies on CRAN). Scan of all Rd examples: only `?NGLVieweR` and `?NGLVieweR-shiny` used an undefined input. Fixed: `backgroundColor = "black"` (the missing input was NULL, so the background was black anyway), ball+stick named "ball+stick", re-export and `importFrom(tools, file_ext)` removed (code uses `tools::file_ext()`). Failing test first (test-NGLVieweR.R: file_ext exported). Verified: the 3 help-page apps run headless (Add/Remove work, 0 console errors); 175 tests / 727 expectations pass, 0 skip; rcmdcheck 0/0/1 (local time NOTE); check_pkgdown OK; /code-review: no bugs, 4 minor points (deprecation: user decision; `color` vs `colorScheme` in the other example works in NGL; `%>%` check kept on purpose; docs/ rebuilt after CRAN). Committed and pushed | see `git log --grep "Fix #26"` |

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

## Step 15 — #20 PDB codes without a legacy PDB file cannot be loaded (GitHub #17)

From the second code review (2026-10-18). Reported by a user as GitHub
issue #17 (closed, but only half fixed).

**Where.** `.parse_structure_input()` in `R/utils.R` (~94-97): a PDB code
always becomes `rcsb://<code>.pdb`, and `format` is stored but never used
for codes (`NGLVieweR.js` calls `stage.loadFile(structureOpts.data)`).

**What happens.** RCSB has no legacy PDB-format file for large entries
(ribosomes, big cryo-EM assemblies: more than 99,999 atoms or 62 chains).
`https://files.rcsb.org/download/3J9M.pdb` and `4V6X.pdb` return 404, the
`.cif` files return 200. So `NGLVieweR("3J9M")` fails with
`_error` "could not load structure 1 (rcsb://3J9M.pdb): error loading
file: ''", and `format = "cif"` is silently ignored. The other half of
GitHub #17 (local `.cif` files) is fixed by NGL.js 2.5.0: 3J9M.cif
(17 MB, 158,384 atoms, 220 chains) loads as a path, as `.cif.gz` and as
contents with `format = "cif"` (checked 2026-10-18).

**Measured (risk of switching codes to mmCIF, 2026-10-18).** 22 entries
loaded from RCSB as `.pdb` and `.cif` in headless Chrome and compared field
by field: the 7 codes in docs/tests (1CRN, 7CID, 1GZM, 1U19, 3RY2, 3J9M,
4V6X; the last two have no .pdb) plus 4HHB, 1HSG, 3PTB, 1CA2, 1EMA, 1BNA,
1EHZ, 1D3Z, 1L2Y, 1EJG, 3NIR, 1IGT, 2FBJ, 3HFM, 1STP, 1AON, 6VXX.
Scripts: scratchpad `i17/fingerprint.js`, `risk.R`, `dig.js` (not kept).
- Identical in all 22: every atom (coordinates, B-factor, occupancy,
  element, altloc), residues and their order, chain names, residue numbers,
  insertion codes, models, secondary structure, `_sequence`, `_PDB`
  output, polymer fragments (cartoon), disulfides drawn.
- Better in mmCIF: ligand double bonds (biotin in 3RY2, GFP chromophore),
  modified nucleotides count as `nucleic` (1EHZ), the chromophore as
  `protein` (1EMA), 1L2Y no longer classed as `ligand`, no bogus HEM
  O1A-O2A bond (4HHB), `structure.header` has resolution and dates.
- Worse in mmCIF (NGL's CIF parser):
  (1) atoms with an alternate location lose all bonds: in ball+stick
  3RY2 residue 22 (in our docs) has 36 sticks from .pdb, 24 from .cif;
  1EJG 856 -> 672. Common in high-resolution X-ray structures.
  (2) `sugar` selects nothing for glycans (6VXX NAG: 882 -> 0 atoms;
  still `ligand`/`hetero`). (3) no unit cell, so the `UNITCELL` and
  `SUPERCELL` assemblies are gone. (4) N-terminal H1/H2/H3 unbonded in
  some entries (1IGT, 1L2Y). Disulfide/metal bonds have order 0 but are
  drawn.
- Selections can match different atom sets in entries with modified
  residues (`protein`, `nucleic`, `ligand`, `polymer`, `sidechain`,
  `backbone`), mostly more correct.
- mmCIF downloads are 15-75% larger (4HHB: 107 kB -> 189 kB compressed).

**Repro `dev/repro/20-pdb-code-cif`.** Radio buttons: 1CRN, 3J9M,
3J9M with `format = "cif"`, 4V6X. Debug panel: the URL R sends,
`input$viewer_error`, residues loaded (`nrow(input$viewer_residues)`).
Needs network (RCSB). **Look for:** 1CRN loads; 3J9M/4V6X show an error
and an empty viewer, also with `format = "cif"`.

**Decision.** (A) use `format` for codes only (`"pdb"`/`"cif"`), default
stays `.pdb`, so `NGLVieweR("3J9M")` still fails without `format`;
(B) fetch codes as mmCIF by default, `format = "pdb"` keeps the old file;
(C) try `.pdb` and fall back to `.cif` when it fails.

**Proposed fix.** User first preferred (B); after the risk test above,
(C) with an explicit `format` is the zero-risk option: without `format`,
load `.pdb` and only if that fails load `.cif` (entries that load today
are unchanged; only entries that fail today change); `format = "pdb"` or
`"cif"` (aliases `"mmcif"`, `"mcif"`) picks the file, no fallback; clear
R error for any other format. NEWS bullet referencing GitHub #17;
`?NGLVieweR` `format` docs. **Decision (user, 2026-10-18): C.** `"ent"`
is accepted as `"pdb"` (documented format, so it must not start failing).

**Known limits (from /code-review, accepted).** The fallback runs on any
`.pdb` load failure, not only a 404 (NGL's rejection carries no HTTP
status; a network error would usually fail the `.cif` too). When both
fail, `_error` names both URLs but carries only the `.cif` error (NGL's
messages are the same empty "error loading file: ''"). A `.pdb` that loads
with 0 atoms does not fall back. A large entry or a mistyped code costs
two requests; `format = "cif"` avoids it (documented).

**Tests.** Unit (test-parse-input.R): code without format -> `.pdb` data
and `.cif` fallback; `format` `pdb`/`PDB`/`.pdb`/`ent` -> `.pdb`,
`cif`/`CIF`/`.cif`/`mmcif`/`mcif` -> `.cif`, both without fallback; other
format -> error; files get no fallback; all for `NGLVieweR()` and
`addStructure()`. Browser test-browser-pdb-code.R: fallback without
network (fixtures served with `addResourcePath`, `data` pointing at a
missing file): loads from the fallback; both fail -> `_error` names both;
no fallback -> only the given file. With network (skip_if_offline): 1CRN
requests only the `.pdb`; 3J9M loads (158,384 atoms) with and without
`format = "cif"`.

---

## Step 16 — #21 Update functions reset `_rendering` too early

**Where.** `NGLVieweR.js` handlers `NGLVieweR:updateColor`,
`updateVisibility`, `updateRepresentation`, `updateStage` (each sets
`_rendering` true, runs its work in a 10 ms `setTimeout`, then sets it
false unconditionally); and the `countChanged` handler at the top of the
Shiny inputs block.

**What happens.** (a) The handlers set `_rendering` false right after
their synchronous work, even if NGL started a rebuild (a surface
recalculates for a changed probe radius) or a snapshot is still running
(undoes #10). (b) NGL's `Counter` dispatches `countChanged(delta, count)`;
the handler names the first argument `count`, so every decrement sends
`false`, including 2 -> 1 while a task still runs.

**Repro `dev/repro/21-update-rendering`.** Three buttons (snapshot +
updateColor, updateRepresentation surface rebuild, updateColor only) and a
log of `_rendering` values and NGL task counts. **Look for:** lines marked
WRONG; the debug panel counts them.

**Proposed fix.** One helper that reports `false` only when
`stage.tasks.count === 0` and no snapshot is pending; the four handlers
call it instead of sending `false`; the countChanged handler uses the
second argument (`count`) and the same helper.

**Tests.** Browser: snapshot + updateColor (order: true, PNG, false);
updateRepresentation with a rebuild (no `false` while tasks > 0);
updateColor alone still ends with `false`; overlapping tasks (2 -> 1 sends
no `false`).

---

## Step 17 — #27 `input$<id>_PDB` holds the coordinates from before superposition

**Where.** `NGLVieweR.js` `renderValue`: `new NGL.PdbWriter(o.structure)`
runs per structure inside the load loop; the `NGL.superpose()` block runs
after the loop.

**What happens.** `NGL.superpose(target, ref, true, ...)` rewrites the
target's atom coordinates in place, but the PDB text was already written,
so `_PDB` of every target holds its file coordinates. Apps that export
`_PDB` get unaligned structures although the viewer shows them aligned.
(Already noted under #4 point 4 and in "Found during the work".)

**Repro `dev/repro/27-pdb-superpose`.** 1crn.pdb + 1crn_moved.pdb with
setSuperpose on/off; debug panel: CA RMSD exported `_PDB` vs displayed, and
vs file; download button for the exported PDBs. **Look for:** structure 2
"exported vs displayed" 17.56 A with superpose on; 0.00 with it off.

**Proposed fix.** Write the PDB text after the superpose block (one loop
over `structures` before the inputs are sent). The reference and
non-superposed loads are unchanged (coordinates not touched). Component
transforms (`setPosition`/`setRotation`/`setScale`) stay out of `_PDB`, as
before (they are not atom coordinates).

**Tests.** Browser (test-browser-superpose.R): for each superpose case,
CA from `_PDB` matches the displayed CA (RMSD < 0.01) for every structure;
without superpose `_PDB` equals the file coordinates.

---

## Step 18 — #28 `setFocus()`/`setQuality()` defaults override `stageParameters()`

Found in the pre-submission review (2026-10-19). Already listed under
"Found during the work" (from /code-review in Step 2); it now matters
because `?stageParameters` and the vignette (commit 03adf3c) document
clipping, fog and quality there, with a fog example that does not work.

**Where.** `R/NGLVieweR.R` `NGLVieweR()`: `x$setQuality <- "medium"` and
`x$setFocus <- 0` are always set. `inst/htmlwidgets/NGLVieweR.js`
`renderValue`: after `stage.setParameters(stageParams)` it always calls
`stage.setQuality(opts.setQuality)` and `stage.setFocus(opts.setFocus)`.

**What happens.** In NGL.js 2.5.0, `Stage.setFocus(f)` (clipMode "scene")
computes and sets `clipNear`, `clipFar`, `fogNear` and `fogFar`; for f = 0
with clipScale "relative" these are NGL's defaults 0/100/50/100.
`Stage.setQuality()` sets `quality`. Both run after `stageParameters()`, so
`stageParameters(clipNear =, clipFar =, fogNear =, fogFar =, quality =)`
is silently replaced, even when the user never called `setFocus()` or
`setQuality()`. `updateStage()` is not affected (it only calls
`setParameters`), and `updateFocus()` overriding clip/fog is expected.

**Repro `dev/repro/28-focus-overrides-stage`.** 1crn.pdb (offline). Cases
A clipNear = 45, B fogNear = 0 / fogFar = 30, C quality = "high", each set
only via `stageParameters()`; debug table requested vs NGL's actual stage
parameters; button applies the same via `updateStage()` (shows the
expected look); checkbox adds `setFocus(50)`. **Look for:** actual stays at
0 / 50,100 / medium; the updateStage button gives 45 / 0,30 / high and the
front of the protein is cut away (A) or fogged (B).

**Proposed fix.** `NGLVieweR()` no longer sets `setQuality`/`setFocus`
defaults; `renderValue` calls `stage.setQuality()`/`stage.setFocus()` only
when `setQuality()`/`setFocus()` were used. Without them the stage starts
from NGL's defaults (quality "medium", focus 0 = clip 0/100, fog 50/100),
so viewers that do not use these options look the same as now. For
re-renders (as #3): when the previous render used `setFocus()` the keys
`clipNear`, `clipFar`, `fogNear`, `fogFar` are added to the keys that
return to their default; for `setQuality()` the key `quality`.

**Decisions (user, 2026-10-19).**
1. `stageParameters()` wins over `setFocus()`/`setQuality()`: the stage
   applies `setQuality()`/`setFocus()` first and `stageParameters()` on top,
   so named values are used and the rest comes from the shortcut (e.g.
   `setFocus(50) %>% stageParameters(fogFar = 60)` keeps focus-50 clipping
   with fogFar 60). Changes the old order (focus last), which never let
   these `stageParameters()` keys through, so nothing can rely on it.
   `updateStage()`/`updateFocus()` are unchanged: the last call wins.
2. Re-render reset: yes (same rule as #3).

**Tests.** Unit (test-builders.R): `NGLVieweR()` has no `setFocus`/
`setQuality` in `x`; `setFocus()`/`setQuality()` still set them. Browser
(test-browser-stage-state.R): stageParameters clipNear/clipFar, fogNear/
fogFar and quality reach `stage.parameters`; with `setFocus(50)` the
`stageParameters()` keys win and the other focus values stay (decision 1); re-render from `setFocus(50)` / `setQuality("high")`
to neither returns clip/fog/quality to NGL's defaults; default viewer has
NGL's default clip/fog/quality.

---

## Step 19 — #22 `colorByValue()` colors NA like a value when the domain ends are equal

From the second code review (2026-10-18, "Found during the work").

**Where.** `R/colorByValue.R` `colorByValue()`: `pos <- if (domain[1] == domain[2]) rep(0.5, length(value)) else (value - domain[1]) / (domain[2] - domain[1])`.

**What happens.** With equal ends every row gets position 0.5, also rows
whose value is `NA`/`NaN`, so `ok <- !is.na(pos)` is TRUE for them and they
get the middle palette color instead of `na_color`. Equal ends happen
whenever the data has a single distinct finite value and `domain` is taken
from the data, e.g. `colorByValue(c("A:1" = 5, "A:2" = NA))`, or a
`_residues` table where only a few residues have the same score; also with
an explicit `domain = c(x, x)`. Residues *not listed* are unaffected (the JS
side gives them `na_color`).

**Repro `dev/repro/22-colorbyvalue-na`.** 1crn.pdb, scores for residues
1-23, none for 24-46, `na_color = "green"`. **Look for:** case A (one
score) and C (NaN) show residues 24-46 white; B (two scores) green.

**Proposed fix.** Equal ends give 0.5 only for non-missing values:
`rep(0.5, length(value))` -> `ifelse(is.na(value), NA, 0.5)`.

**Tests.** Unit (test-colorByValue.R): one distinct value + NA/NaN, from
data and with `domain = c(x, x)`: the missing rows get `na_color`, the
others the middle color; unequal ends unchanged.

---

## Step 20 — #25 `colorByValue()` accepts number strings and "transparent" as colors

From the second code review (2026-10-18, "Found during the work").

**Where.** `R/colorByValue.R` `.hex_colors()`, used for `palette` and
`na_color`.

**What happens.** Numbers are already rejected (`is.character()` check),
but strings go straight to `grDevices::col2rgb()`, which reads number
strings as indices into `palette()` ("1" = black, "2" = #DF536B, "8" =
grey; "0" errors) and accepts "transparent" (white with alpha 0; alpha is
dropped, so it becomes white). None of these is what a user means; a number
string typically comes from a data column or a text input.

**Repro `dev/repro/25-colorbyvalue-number-colors`.** Residues colored 1-46
with four palettes. **Look for:** A `c("1", "2")` black to pink, B "8"
grey, C "transparent" white, all without an error; D blue-red works.

**Proposed fix.** In `.hex_colors()`, reject strings that are only digits
(after trimming) and "transparent" with the existing message ("contains a
color that is not a color name or HEX code"). HEX codes with an alpha part
stay accepted (alpha is dropped, as documented).

**Decision.** Reject "transparent" too (proposed: yes), or keep it as white?

**Status.** Deferred by the user (2026-10-19): an input mistake with a
visible result, not needed for 1.5.0. No code or tests changed.

**Tests.** Unit (test-colorByValue.R): `palette = c("1", "2")`,
`c("blue", "8")`, `c("transparent", "red")` and `na_color = "1"` error;
`"#FF000080"`, names and HEX codes still work.

---

## Step 21 — #29 `NGLVieweR.yaml` copies the whole htmlwidgets folder per dependency

Listed under "Found during the work" (Step 1); re-checked 2026-10-19.

**Where.** `inst/htmlwidgets/NGLVieweR.yaml`: both dependencies (`NGLVieweR`
= NGL.js 2.5.0, `helperFunctions` 1.0) have `src: htmlwidgets`, and
htmltools' default `all_files = TRUE` copies the whole source folder.

**What happens.** Every place that copies dependencies to disk
(`saveWidget(selfcontained = FALSE)`, R Markdown/Quarto with
`self_contained: false`, pkgdown) gets the whole `inst/htmlwidgets` folder
twice: `ngl.js` (1.29 MB) twice, the binding `NGLVieweR.js` three times,
the yaml twice. Self-contained output embeds only the listed scripts and is
not affected (1.36 MB); the CRAN tarball has every file once. Shiny serves
the folder without copying (not affected). (The older note that
self-contained output is larger was wrong.)

**Proposed fix.** `all_files: false` on both dependencies. htmlwidgets
passes every yaml field to `htmltools::htmlDependency()` (htmltools >=
0.3.6; htmlwidgets requires >= 0.5.7), and the binding dependency already
uses `all_files = FALSE`. No file moves and no path changes, so script URLs
stay the same. (Alternative: a separate folder per dependency; more files
move, more risk.)

**Tests.** Unit (test-dependencies.R): each dependency is listed with
`all_files = FALSE` and its script exists; `saveWidget(selfcontained =
FALSE)` writes each of ngl.js, helperFunctions.js and NGLVieweR.js exactly
once and no yaml; self-contained HTML embeds NGL.js, the helpers and the
binding. Browser (test-browser-static.R): saved widget renders (327 atoms)
with `selfcontained` FALSE and TRUE; R Markdown `html_document` with
`self_contained` true and false renders and loads the structure.
Extra (manual, because the layout of an installed package differs from
`load_all()`): install to a temporary library and repeat saveWidget (both
modes) + Shiny example in Chrome; Quarto html; pkgdown reference page;
tarball file list; full suite; rcmdcheck.

---

## Found during the work

(Add anything new discovered while fixing; do not fix it inside another bug's step.)

- From Step 18 (#28) /code-review, not fixed (pre-existing): `setFocus()`
  with `clipScale = "absolute"` runs in renderValue before the structures
  are loaded, so NGL's relativeToAbsolute() uses the empty/previous scene;
  `updateFocus()` after loading gives the right values. Could re-apply the
  focus after loading (as zoomMove does).
- **Second code review (2026-10-18), not yet scheduled.** #20 and #21 have
  their own steps above. The others:
  - #19 `colorByValue(input$<id>_residues + value)` fails for multi-model
    (NMR) structures: `_residues` has one row per residue per model, so
    rows repeat and colorByValue() stops with "a residue is given more than
    once" (confirmed headless, 2-model 1CRN: 92 rows, 46 duplicates).
    `_sequence`/`_resno`/`_chainname` also repeat per model.
  - #21 `updateColor`/`updateVisibility`/`updateRepresentation`/
    `updateStage` set `_rendering` FALSE after 10 ms regardless of a
    pending snapshot or running NGL tasks (undoes part of #10).
  - #22 `colorByValue()`: with equal domain ends, NA values get the middle
    color instead of `na_color` (confirmed: `c("A:1" = 5, "A:2" = NA)`).
  - #23 A click on a bond (ball+stick/licorice stick) gives `_selection`
    but no `_selAround`: `pickingProxy.atom` is undefined for bonds; use
    `pickingProxy.atom || pickingProxy.closestBondAtom`.
  - #24 `selectionParameters(level = "atom")` still returns whole residues
    (`getAtomSetWithinGroup()` always runs); only the seed changes. Check
    intent.
  - #25 `colorByValue()` accepts number strings as colors (`"1"` is
    `palette()[1]`, black).
  - #26 Docs: "App 2" examples in `?NGLVieweR` and `?NGLVieweR-shiny` use a
    non-existent `input$backgroundColor`; App 1 names a ball+stick
    representation "cartoon"; `tools::file_ext` is re-exported
    (accidental; removing it changes the API). -> Step 22.

- From Step 16 (#21) /code-review and testing, not fixed: (a) an NGL build
  that throws (e.g. `updateRepresentation(..., param = list(subdiv = -1))`)
  never closes its NGL task; `_rendering` now stays TRUE (and NGL's
  makeImage() waits) until that representation is removed or the viewer
  re-renders (`fixTaskCounter()` then clears it). Before #21 the next update
  reset `_rendering` to FALSE, but snapshots were already blocked.
  (b) An exception inside an update handler's setTimeout skips
  renderingDone() (pre-existing; the next update or finished task resets
  it). (c) countChanged sends TRUE on every change above 0, also 3 -> 2
  (harmless: Shiny drops repeated values; same as before for +1).
  (d) shinyNGLVieweR (user's app) logs 7 console errors with and without
  the fix: `sequenceOutput.js` "div is not defined" and Shiny "output in an
  unexpected state" messages for the viewer output -- in the app, not the
  package.

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

- Flaky (from Step 17): `test-browser-pdb-code.R:93` once saw `1CRN.pdb` twice in `performance.getEntriesByType('resource')` during the full suite (passed 3/3 alone). Probably a browser re-request; consider deduplicating `rcsb_requests()` or checking `length(unique())`.
- The `_PDB` input is written before superposition (see #4, point 4). Now Step 17 (#27).
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
- Test infrastructure: chromote failed to start Chrome again in Step 18 (while a second Chrome ran) and Step 19 (one skip + warning in a full run, not reproduced). Once (Step 9) chromote failed to start Chrome
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
- _residues (from /code-review, Step 10): (a) an error after loading (e.g.
  unknown representation type) leaves _residues -- like _sequence/_PDB --
  at the previous render's values, because the inputs are sent after the
  representations; (b) every residue incl. water is sent on each render
  (large for ~100k-residue assemblies; the structure column could be sent
  as counts); (c) the old _sequence/_resno/_chainname could be derived from
  the same residue walk instead of a second set of arrays.
- `setFocus()`/`setQuality()` override `stageParameters()` (from /code-review
  in Step 2). `renderValue` always calls `stage.setQuality(opts.setQuality)`
  and `stage.setFocus(opts.setFocus)` after `setParameters`, with defaults
  "medium" and 0, so `stageParameters(quality = "high")` or clip/fog values
  are silently replaced. Pre-existing.
- `inst/htmlwidgets/NGLVieweR.yaml`: both dependencies (`NGLVieweR`,
  `helperFunctions`) use `src: htmlwidgets`, i.e. the whole folder. A saved
  widget (`saveWidget(selfcontained = FALSE)`) therefore contains the folder
  twice, incl. `ngl.js` (~1.3 MB) twice and stray copies of `NGLVieweR.js`;
  self-contained output is NOT larger (checked 2026-10-19, see #29). Fix: `src: htmlwidgets/lib/NGL-2.4.0` etc. Found in Step 1.
- `inst/examples/multiStructureSelection/app.R` has no final newline
  (cosmetic; `readLines()` warns). Found in Step 0.
