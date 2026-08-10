// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

// Quarto partial override: replaces the default `article` template definition.
//
// Quarto assembles the generated .typ in this order:
//   numbering.typ -> definitions.typ -> typst-template.typ -> page.typ
//   -> typst-show.typ -> body
//
// So this file only needs to make modern-cv's functions available; the actual
// document setup happens in typst-show.typ. We deliberately do NOT define
// `article` here, because typst-show.typ no longer calls it.
//
// modern-cv is VENDORED at modern-cv/lib.typ rather than imported from
// @preview/modern-cv:0.10.0. The registry copy lives in Typst's read-only
// download cache, which is shared across projects, re-fetched on demand, and not
// under version control — so template internals such as the 32pt name size could
// not be edited there in any durable way. The local copy is editable and
// committed. See modern-cv/README-VENDORED.md for what was changed and why.
#import "modern-cv/lib.typ": *

// Quarto partial override: intentionally empty.
//
// Quarto's default page.typ emits `#set page(paper: ..., margin: (x: 1.25in,
// y: 1.25in), ...)` before the show rule. modern-cv's `resume()` owns page
// setup (paper-size, margins, and the footer), so leaving Quarto's version in
// place means two competing `set page` rules. Blanking it lets the template win.
//
// Consequence: the `papersize` and `margin` YAML keys have no effect. Set the
// paper via `paper-size:` in typst-show.typ instead.
// Quarto partial override: applies modern-cv's `resume` show rule instead of
// Quarto's default `article`. Everything after this in the generated .typ (i.e.
// the document body) is transformed by the template.
//
// Contact details live here rather than in the YAML because modern-cv takes
// them as a single `author` dictionary. Every optional key is guarded upstream
// by `if "key" in author`, so listing only the ones we want is safe.
#show: resume.with(
  author: (
    firstname: "Dan",
    lastname: "Yavorsky",
    // `phone` is auto-prefixed with tel:, `email` with mailto:, and
    // `github` with https://github.com/ — so pass bare values for those.
    phone: "(+1) 951-201-0927",
    email: "dyavorsky@gmail.com",
    github: "dyavorsky",
    // `address` is deliberately NOT set. modern-cv renders it as its own centered
    // block between the positions line and the contact row; passing it as a custom
    // contact item instead puts it inline with phone/email/github/website.
    //
    // A `homepage` entry would display the full URL including the scheme, so the
    // website is a custom item too — clean label, correct link. Custom items are
    // appended after the built-in ones, so these land at the end of the row.
    custom: (
      (
        text: "danyavorsky.com",
        icon: "globe",
        link: "https://www.danyavorsky.com",
      ),
      // Encino rather than Los Angeles — more specific without disclosing a street
      // address. The `link` key is optional now that the upstream
      // `__contact_item` bug is fixed in the vendored template; drop it to render
      // the location as plain, unlinked text.
      (
        text: "Los Angeles, CA",
        icon: "location-dot",
        link: "https://www.google.com/maps/place/Encino,+Los+Angeles,+CA",
      ),
    ),
    positions: (
      "Analytics at GBK Collective",
      "Adjunct Professor at UCLA & UCSD",
    ),
  ),
  // Default is the `image` function itself, so this must be set explicitly.
  profile-picture: none,
  paper-size: "us-letter",
  // Muted gray in place of modern-cv's rgb("#262F99") accent. This single
  // parameter drives three things together — the first name, the positions line
  // under it, and the level-1 section headings — so it cannot be set lighter for
  // headings while keeping the name dark. Note it is lighter than the #333333
  // body text. The contact icons are separate `#let` constants fixed at
  // rgb("#131A28") and stay near-black regardless.
  accent-color: rgb("#333333"),
  // Segoe UI preferred, Avenir as the fallback. Both are humanist/geometric sans
  // faces, rounder and wider than the grotesques this template shipped with
  // (Source Sans 3, then Fira Sans).
  //
  // These two are PLATFORM-SPLIT, and Typst picks per machine with no way to force
  // the choice: Segoe UI is a Windows system font and is not on macOS (Office for
  // Mac does not install it), while Avenir is a macOS system font absent from
  // Windows. So a Windows render gets Segoe UI and a Mac render gets Avenir — the
  // order here decides only which one wins where BOTH are present, which in
  // practice is neither machine.
  //
  // This matters because the PDF is rendered locally and committed; the website's
  // sync-resume workflow only copies the committed file. Whichever machine renders
  // last decides the typeface that ships. Render on Windows for Segoe UI.
  //
  // Typst warns "unknown font family: segoe ui" on macOS. That is expected and
  // harmless — it warns for every unmatched name in a fallback list even when a
  // later entry matches.
  //
  // Avenir must be named exactly "Avenir". The installed faces are Light / Book /
  // Roman / Medium / Heavy / Black, and Typst groups them into one family under
  // that name, giving a real bold at 700 despite there being no face literally
  // called Bold. "Avenir Book" is registered as a SEPARATE family that ignores
  // `weight:` entirely — every weight renders identically — so it must not be
  // named here.
  //
  // Caveat: Avenir's 300–600 faces sit close together, so `light`, `regular`, and
  // `medium` look nearly alike; only the bold contrast is strong. Fira Sans and
  // Source Sans 3 both have fuller ladders if that flatness becomes a problem.
  font: ("Segoe UI", "Avenir", "Arial"),
  // Matched to the body font, rather than the Roboto default.
  header-font: ("Segoe UI", "Avenir", "Arial"),
  colored-headers: true,
  show-address-icon: true,
  // `show-footer` now drives the date/page stamp at the FOOT OF THE SIDEBAR, not
  // a footer in the bottom margin — see the LOCAL EDIT on `set page` in
  // modern-cv/lib.typ. `datetime.today()` is resolved by Typst at render time, so
  // it replaces the `Sys.Date()` call the pagedown version used.
  show-footer: true,
  date: datetime.today().display("[month repr:long] [day], [year]"),
  // The sidebar's CONTENT is not passed here — it lives in resume.qmd, registered
  // with `sidebar-section()`. Only the contact block comes from the `author` dict
  // above, and only because modern-cv takes contacts that way.
)

// ---- Right sidebar --------------------------------------------------------
// Content for the gray band. `sidebar-section` registers each block with the
// template, which renders them in call order beneath the contact details.
//
// These calls emit no layout of their own, so their position in this file does
// not affect the main column — they sit at the top because that is the reading
// order of the finished page. Headings, icons, and spacing are all decided by
// `sidebar-heading` in modern-cv/lib.typ; pass only the title and the body.

#sidebar-section("Education")[
  #sidebar-edu-entry("PhD, Quantitative Marketing", "UCLA Anderson", "2020")
  #sidebar-edu-entry("MBA, Management", "UCLA Anderson", "2014")
  #sidebar-edu-entry("CFA Charterholder (inactive)", "CFA Institute", "2012")
  #sidebar-edu-entry("BA, Economics & Mathematics", "Claremont McKenna College", "2006")
]

// `sidebar-stacked-list`, not `sidebar-skill-list`: the latter comma-joins its
// values, which runs titles together illegibly at this width. Each item is
// content, so the whole title doubles as its own link.
#sidebar-section("Publications")[
  #sidebar-stacked-list(categories-with-values: (
    "Author": (
      link("https://link.springer.com/content/pdf/10.1007/s11129-020-09229-4.pdf")[
        Consumer Search in the US Auto Industry (QME, 2020)
      ],
      link("https://dyavorsky.github.io/likert_dualresponse/")[
        Ordinal Dual Response in Choice-Based Conjoint (article, in progress)
      ],
      link("http://dcme-r.danyavorsky.com/")[
        Discrete Choice Model Estimation with R (book, in progress)
      ],
    ),
    // Research assistance and package contributions — not authored work. The
    // "Contributor" label is what keeps that distinction honest, so it should not
    // be merged into "Co-author" above.
    "Contributor": (
      link("https://www.journals.uchicago.edu/doi/10.1086/702171")[
        Chen, Chevalier, Rossi & Oehlsen, The Value of Flexible Work (JPE, 2019)
      ],
      link("https://link.springer.com/article/10.1007/s11129-024-09291-2")[
        Ursu, Seiler & Honka, The Sequential Search Model (QME, 2024)
      ],
      link("https://cran.r-project.org/package=bayesm")[
        bayesm R package — posterior samplers, vignettes, documentation
      ],
    ),
  ))
]

#sidebar-section("Skills")[
  #sidebar-skill-list(categories-with-values: (
    "Methods": (
      "Statistics",
      "Econometrics",
      "Causal Inference",
      "Bayesian Methods",
      "Discrete Choice",
      "Machine Learning",
    ),
    "Languages & Tools": (
      "R",
      "SQL",
      "Tableau",
      "Quarto",
      "LaTeX",
      "Git",
    ),
    "Developing": (
      "Python",
      "Julia",
      "Vim",
    ),
    "Interests": (
      "Applied Econometrics","Quantitative Marketing",
      "Customer Analytics",
      "Structural Models of Demand",
    ),
  ))
]

// Two paragraphs, not one: the blank line separates the biographical facts from
// the hobbies. Spacing comes from the sidebar's own `par(spacing:)`, so this needs
// no `#v()`.
#sidebar-section("Personal")[
  US citizen, married, two children

  Train dogs, cycle, collect pocket knives, build mechanical keyboards, patinate boots, sip bourbon, lament ManUnited
]
= Experience
<experience>
#job-entry(
  organization: "GBK Collective",
  date: "2022 – Present",
  title: "Head of Analytics",
  location: "Los Angeles, CA",
)

#resume-item[
  - Lead the Marketing Science and Analytics function for all client engagements, from proposal to design, data collection, analysis, and reporting.
  - Apply econometric, statistical, and machine learning methods to derive consumer insights and inform marketing strategy for clients such as Amazon, Charter, Google, and T-Mobile, often in collaboration with academic experts, including Eric Bradlow (Wharton), Mike Hanssens (UCLA), and Sam Hui (UH).
  - Develop and maintain R packages and AI skills to implement and extend core analytic methods in survey-based research: #link("https://github.com/dyavorsky/maxdiff")[`maxdiff`] adapts `bayesm`'s hierarchical Bayesian MNL for varying choice-set sizes; #link("https://github.com/dyavorsky/shapley")[`shapley`] extends R-squared contribution over all predictor orderings to logit and ordered logit outcomes; #link("https://github.com/dyavorsky/keydrivers")[`keydrivers`] adds bootstrapped confidence intervals across eight complementary importance methods; and #link("https://github.com/dyavorsky/turf")[`turf`] makes exhaustive bundle search tractable via #box[C++] and parallel computation.
]

#job-entry(
  organization: "Bain & Co.",
  date: "2020 – 2021",
  title: "Manager, Advanced Analytics",
  location: "Los Angeles, CA",
)

#resume-item[
  - Performed marketing analytics to support strategic management consulting engagements, including conjoint analysis, maximum-difference scaling, customer segmentation, perceptual mapping, factor analysis, structural equation modeling, and other statistical and econometric analyses.
  - Engineered ecosystem of statistical and machine learning models to enable media conglomerate to value content on its streaming platforms and optimize media licensing decisions.
]

#job-entry(
  organization: "UCLA Anderson",
  date: "2015 – 2019",
  title: "Graduate Student Researcher",
  location: "Los Angeles, CA",
)

#resume-item[
  - Supported Professors Rossi, Chen, and Honka on several research projects.
  - Maintained and extended Prof. Rossi's `bayesm` R package, which implements Bayesian estimation of common microeconometric models in marketing.
]

#job-entry(
  organization: "Cornerstone Research",
  date: "2006 – 2014",
  title: "Analyst, Senior Analyst, Research Associate",
  location: "San Francisco, CA",
)

#resume-item[
  - Performed economic, financial, statistical, and causal impact analyses to support professors engaged as expert witnesses in over 100 commercial litigation matters related to consumer fraud, bankruptcy, forensic accounting, asset pricing, and other matters.
  - Led substantial internal initiatives including firm-wide analyst training and West Coast analyst recruiting.
]
= Teaching
<teaching>
#job-entry(
  organization: "UCLA Anderson & UCSD Rady",
  date: "2021 – Present",
  title: "Adjunct Professor",
  location: "Los Angeles & San Diego, CA",
)

#resume-item[
  - Developed and teach masters-level (MFE and MSBA) courses in econometrics, R programming, and marketing analytics, as well as undergraduate courses in customer analytics and tools for data science. 
  - Slides, syllabi, and student evaluations are available on my #link("https://dyavorsky.github.io/teaching")[`website`].
]




