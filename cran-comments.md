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
    <https://niels-van-der-velden.shinyapps.io/shinyNGLVieweR/> From:
    inst/doc/NGLVieweR.html README.md Status: Error Message: libcurl
    error code 35: schannel: next InitializeSecurityContext failed:
    SEC_E\_ILLEGAL_MESSAGE (0x80090326) - This error usually occurs when
    a fatal SSL/TLS alert is received (e.g. handshake failed).

**I checked the URL and the website loads fine.**
