# Baseline check (Step 0, 2026-10-16)

Unfixed code, NGL.js 2.4.0, R 4.4.0 on macOS (arm64), Chrome headless via chromote.
Later steps compare against this.

## Unit tests — `devtools::test(filter = "^(NGLVieweR|builders|proxy)$")`

| File | Expectations |
|---|---|
| test-NGLVieweR.R | 33 pass |
| test-builders.R | 21 pass |
| test-proxy.R | 37 pass |
| **Total** | **91 pass, 0 fail, 0 warn** |

## Browser tests — `NOT_CRAN=true` + `devtools::test(filter = "browser")`

| File | Result |
|---|---|
| test-browser-basic.R | 15 pass (render 1crn fixture, NGL.Version 2.4.0, `_sequence`/`_resno`/`_chainname`/`_PDB`, click → `_selection`/`_selAround`, no console errors) |
| test-browser-examples.R | 14 of 15 examples load with no console errors; `updateFullscreen` skipped (wrapped in `if (interactive())`, see "Found during the work") |

Full suite: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 119 ]`, ~24 s (needs network for RCSB).

## R CMD check — `rcmdcheck(args = c("--as-cran", "--no-manual"))`

```
0 errors | 1 warning | 1 note

WARNING  checking CRAN incoming feasibility
         Insufficient package version (submitted: 1.4.0, existing: 1.4.0)
         -> expected; goes away when the version is bumped to a dev version.
NOTE     checking for future file timestamps: unable to verify current time
         -> local environment (time server), not the package.
```

Inside the check the browser tests skip ("On CRAN") and the 91 unit tests pass.
One "empty test" skip comes from `test-browser-examples.R`: the check's copy
of the tests has no package source, so no example tests are generated.

## Environment notes

- Installed for this work: shinytest2, chromote (+ deps), webshot, markdown.
  Installing markdown upgraded xfun to 0.57, which broke knitr 1.49;
  knitr (1.51) and rmarkdown (2.30) were updated to fix it.
- "package X was built under R version 4.4.3" warnings come from the local
  R 4.4.0 install, not the package.
