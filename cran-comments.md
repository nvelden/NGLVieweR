# Version 1.5.0 Submission
19.10.2026

### Test environments
- Local macOS (arm64), R 4.4.0
- macOS (on GitHub Actions), R release
- Windows (on GitHub Actions), R-devel
- Ubuntu (on GitHub Actions), R-devel
- Win-builder (devel), R Under development (2026-10-18 r90707 ucrt): Status OK

### R CMD check results
0 errors | 0 warnings | 0 notes on win-builder and GitHub Actions.

Locally there is 1 note: checking for future file timestamps: unable to
verify current time. This comes from the local environment (time server),
not the package.

### Submission comments
- Updated the bundled 'NGL.js' library from 2.0.0 to 2.5.0. The copyright and
  license notices of 'NGL.js' and of the libraries compiled into it are now
  included in inst/COPYRIGHTS and inst/htmlwidgets/lib/NGL-2.5.0/LICENSE, and
  their copyright holders are listed in Authors@R with role "cph".
- New function colorByValue() and new Shiny inputs; many bug fixes (see NEWS.md).

### Reverse dependencies
- RiboCrypt (Bioconductor): checked its use of NGLVieweR (NGLVieweR(),
  stageParameters(), the Shiny output functions and the re-exported
  file_ext()). All of these are unchanged in this version.

# Version 1.4 Submission
22.11.2024

### Test environments
- Local R installation, R 4.4.0
- Ubuntu 24.04 (on GitHub Actions), R 4.4.0
- Win-builder (devel)

### Submission comments
- Added addStructure and setSuperpose functions to load and overlap multiple 
structures in the same stage.
- Updated internal logic with R 4.3.0's stricter && and || evaluations to 
prevent errors with multi-element vectors.

# Round 3

## Test environments
-   local R installation, R 4.0.4
-   ubuntu 16.04 (on travis-ci), R 4.0.4
-   win-builder (devel)

## Submission comments
-   Provided \\value to remaining functions

## Reviewer comments

-   Please add \\value to .Rd files regarding exported methods and explain
the functions results in the documentation. Please write about the
structure of the output (class) and also what the output means. (If a
function does not return a value, please document that too, e.g.
\\value{No return value, called for side effects} or similar)
Missing Rd-tags:
      addRepresentation.Rd: \\value
      setFocus.Rd: \\value
      setQuality.Rd: \\value
      setRock.Rd: \\value
      setSpin.Rd: \\value
      stageParameters.Rd: \\value
      zoomMove.Rd: \\value

# Round 2
26.05.21

## Test environments
-   local R installation, R 4.0.4
-   ubuntu 16.04 (on travis-ci), R 4.0.4
-   win-builder (devel)

## Submission comments

-   Reduced the length of the title
-   Provided \\value to applicable methods
-   Added single quotes if applicable in description
-   Added link to htmlwidgets and NGL website in description

## Reviewer comments

-   Please reduce the length of the tile to less than 65 characters
                             .
-   Please add \\value to .Rd files regarding exported methods and explain
the functions results in the documentation. Please write about the
structure of the output (class) and also what the output means. (If a
function does not return a value, please document that too, e.g.
\\value{No return value, called for side effects} or similar)
Missing Rd-tags in up to 23 .Rd files, e.g.:
      addRepresentation.Rd: \\value
      addSelection.Rd: \\value
      NGLVieweR_example.Rd: \\value
      NGLVieweR-shiny.Rd: \\value
      NGLVieweR.Rd: \\value
      removeSelection.Rd: \\value
      ...

-   Please always write package names, software names and API (application
programming interface) names in single quotes in title and description.
e.g: --> 'NGLvieweR'

-   Please provide a link to the used webservices to the description field
of your DESCRIPTION file in the form
'<http:...>' or '<https:...>'
with angle brackets for auto-linking and no space after 'http:' and
'https:'.

# Round 1
25.05.2021

## Test environments

-   local R installation, R 4.0.4
-   ubuntu 16.04 (on travis-ci), R 4.0.4
-   win-builder (devel)

## Submission comments

-   'LazyData' is specified without a 'data' directory

**Error fixed by removing LazyData from DESCRIPTION**

## R CMD check results

0 errors \| 0 warnings \| 3 notes

-   This is a new release.

-   Possibly mis-spelled words in DESCRIPTION: Databank (2:30) NGL
    (3:13) NGLvieweR (9:5) PDB (2:40, 9:76) databank (9:66) js (3:17)

**These are abbreviations.**

-   Found the following (possibly) invalid URLs: URL:
    <https://nvelden.github.io/shinyliveNGLVieweR/> From:
    inst/doc/NGLVieweR.html README.md Status: Error Message: libcurl
    error code 35: schannel: next InitializeSecurityContext failed:
    SEC_E\_ILLEGAL_MESSAGE (0x80090326) - This error usually occurs when
    a fatal SSL/TLS alert is received (e.g. handshake failed).

**I checked the URL and the website loads fine.**
