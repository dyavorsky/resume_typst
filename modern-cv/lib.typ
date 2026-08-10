#import "@preview/fontawesome:0.6.0": *
#import "@preview/linguify:0.5.0": *

// const color
#let color-darknight = rgb("#131A28")
#let color-darkgray = rgb("#333333")
#let color-gray = rgb("#5d5d5d")
#let default-accent-color = rgb("#262F99")
#let default-location-color = rgb("#333333")

// const icons
#let linkedin-icon = box(fa-icon("linkedin", fill: color-darknight))
#let github-icon = box(fa-icon("github", fill: color-darknight))
#let gitlab-icon = box(fa-icon("gitlab", fill: color-darknight))
#let bitbucket-icon = box(fa-icon("bitbucket", fill: color-darknight))
#let twitter-icon = box(fa-icon("twitter", fill: color-darknight))
#let bluesky-icon = box(fa-icon("bluesky", fill: color-darknight))
#let mastodon-icon = box(fa-icon("mastodon", fill: color-darknight))
#let google-scholar-icon = box(fa-icon("google-scholar", fill: color-darknight))
#let orcid-icon = box(fa-icon("orcid", fill: color-darknight))
#let phone-icon = box(fa-icon("square-phone", fill: color-darknight))
#let email-icon = box(fa-icon("envelope", fill: color-darknight))
#let birth-icon = box(fa-icon("cake", fill: color-darknight))
#let homepage-icon = box(fa-icon("home", fill: color-darknight))
#let website-icon = box(fa-icon("globe", fill: color-darknight))
#let address-icon = box(fa-icon("location-crosshairs", fill: color-darknight))

// ---- LOCAL EDIT (addition — not upstream): right sidebar geometry -----------
// Single source of truth for the gray band. `resume()` DERIVES the page's right
// margin from these values, because that margin is the only thing keeping body
// text out from under the band. Never hardcode the margin — change it here and
// the reservation follows automatically.
//
// The band is 3.0in wide measured from the RIGHT PAGE EDGE, matching pagedown's
// width. Every half inch here comes straight out of the main column: at 3.0in the
// body measure is 342pt, at 2.5in it was 378pt.
//
// The inset is 0.25in / 0.45in rather than pagedown's 0.2in / 0.7in, giving a
// 2.3in text column instead of 2.1in. It was rebalanced while the band was
// narrower and kept afterwards, because the sidebar is the fuller of the two
// columns and the extra 0.2in of measure buys back wrapped lines.
#let sidebar-width = 3.0in
#let sidebar-gutter = 0.25in // white space between body text and the band edge
#let sidebar-fill = rgb("#f2f2f2") // pagedown's --sidebar-background-color
#let sidebar-inset = (left: 0.25in, right: 0.45in, top: 0.5in, bottom: 0.35in)

// Vertical gap between items WITHIN a sidebar section — between education
// entries, and between publications. One constant so the two read as the same
// rhythm. Distinct from `sidebar-heading`'s `above: 2.2em`, which separates whole
// sections.
#let sidebar-item-gap = 1.1em
#let sidebar-text-width = sidebar-width - sidebar-inset.left - sidebar-inset.right

// LOCAL EDIT (addition): sidebar content, collected from resume.qmd.
//
// `resume()`'s arguments are fixed before the document body exists (Quarto emits
// `typst-show.typ -> body`, and the body is what `#show: resume.with(...)`
// transforms), so the sidebar cannot take its content as a parameter from resume.qmd.
// A state sidesteps that: `sidebar-section` in resume.qmd appends to it, and the page
// background reads `.final()` — the value after every update — inside a context.
// Typst iterates layout until introspection converges, so the background sees the
// completed sidebar even though the updates happen "later" in the flow.
#let __sidebar_state = state("modern-cv-sidebar", [])

// Section titles carry NO icons — tried and removed by request. The contact row in
// the sidebar keeps its icons.
//
// Worth keeping if they are ever reinstated: names are safe to use again. The
// wrong-glyph problem recorded here — `screwdriver-wrench` rendering as the literal
// text "ɔy", `user` as a superscript 5, `graduation-cap` as a blank card — came
// from fontawesome 0.6.0 resolving names against Font Awesome 7's table while
// Quarto bundles FA 6. `fa-version("6")` inside `resume()` now pins both the table
// and the font family, so names and codepoints agree. Writing a codepoint directly,
// e.g. `\u{f0b1}` (briefcase) into "Font Awesome 6 Free" at weight 900, still works
// and is still the most literal option.


/// Helpers


// Common helper functions
#let __format_author_name(author, language) = {
  if language == "zh" or language == "ja" {
    str(author.lastname) + str(author.firstname)
  } else {
    str(author.firstname) + " " + str(author.lastname)
  }
}

#let __apply_smallcaps(content, use-smallcaps) = {
  if use-smallcaps {
    smallcaps(content)
  } else {
    content
  }
}

// layout utility
#let __justify_align(left_body, right_body) = {
  block[
    #left_body
    #box(width: 1fr)[
      #align(right)[
        #right_body
      ]
    ]
  ]
}

#let __justify_align_3(left_body, mid_body, right_body) = {
  block[
    #box(width: 1fr)[
      #align(left)[
        #left_body
      ]
    ]
    #box(width: 1fr)[
      #align(center)[
        #mid_body
      ]
    ]
    #box(width: 1fr)[
      #align(right)[
        #right_body
      ]
    ]
  ]
}

#let __coverletter_footer(
  author,
  language,
  date,
  lang_data,
  use-smallcaps: true,
) = {
  set text(fill: gray, size: 8pt)
  __justify_align_3[
    #__apply_smallcaps(date, use-smallcaps)
  ][
    #__apply_smallcaps(
      {
        let name = __format_author_name(author, language)
        name + " · " + linguify("cover-letter", from: lang_data)
      },
      use-smallcaps,
    )
  ][
    #context {
      counter(page).display()
    }
  ]
}

#let __resume_footer(author, language, lang_data, date, use-smallcaps: true) = {
  set text(fill: gray, size: 8pt)
  __justify_align_3[
    #__apply_smallcaps(date, use-smallcaps)
  ][
    #__apply_smallcaps(
      {
        let name = __format_author_name(author, language)
        name + " · " + linguify("resume", from: lang_data)
      },
      use-smallcaps,
    )
  ][
    #context {
      counter(page).display()
    }
  ]
}

// Helper for contact items in the header.
// - item (dictionary): The contact item with the following fields: text (string, required), icon (box, optional), link (string, optional)
// - link-prefix (string): The prefix to use for the link (e.g. "mailto:")
// - inset (dictionary): Inset of each individual contact item
#let __contact_item(item, link-prefix: "", inset: (:)) = {
  box[
    #set align(bottom)
    #if ("icon" in item) {
      [#item.icon]
    }
    // Then modify the selection to use the constant:
    #box(inset: inset)[
      // LOCAL EDIT (upstream bug): this tested only `"link" in item`. The custom
      // item handler below always inserts a `link` key, using `none` when the
      // caller omits one, so a link-less custom item reached `link(none)` and
      // failed with "URL must not be empty". Checking the value too makes
      // link-less custom items work — e.g. a plain location in the contact row.
      #if ("link" in item and item.link != none) {
        link(link-prefix + item.link)[#item.text]
      } else {
        item.text
      }
    ]
  ]
}

/// LOCAL EDIT (addition — refactor of `__format_contact_items`): collect the
/// contact items as PLAIN DATA — no rendering, no layout.
///
/// Extracted so the centered header row and the vertical sidebar column can share
/// one source of truth for which author keys exist, what icon each gets, and what
/// URL prefix each link needs. Adding a contact type should mean touching exactly
/// one place: here. Rendering lives in `__format_contact_items` (horizontal row)
/// and `__format_contact_column` (vertical stack) below.
///
/// `prefix` is part of the spec because it used to live at the call site, and the
/// two renderers both need it. `link` is `none` for items with no URL — see the
/// `__contact_item` bug note above; that fix is load-bearing here, because EVERY
/// spec now carries a `link` key whose value may be `none`.
///
/// - author (dictionary): The dictionary containing the contact item values
/// -> array (of dictionaries with keys: text, icon, link, prefix)
#let __collect_contact_specs(author) = {
  let specs = ()

  if "birth" in author {
    specs.push((text: author.birth, icon: birth-icon, link: none, prefix: ""))
  }
  if "phone" in author {
    specs.push((
      text: author.phone,
      icon: phone-icon,
      link: author.phone,
      prefix: "tel:",
    ))
  }
  if "email" in author {
    specs.push((
      text: author.email,
      icon: email-icon,
      link: author.email,
      prefix: "mailto:",
    ))
  }
  if "homepage" in author {
    specs.push((
      text: author.homepage,
      icon: homepage-icon,
      link: author.homepage,
      prefix: "",
    ))
  }
  if "github" in author {
    specs.push((
      text: author.github,
      icon: github-icon,
      link: author.github,
      prefix: "https://github.com/",
    ))
  }
  if "gitlab" in author {
    specs.push((
      text: author.gitlab,
      icon: gitlab-icon,
      link: author.gitlab,
      prefix: "https://gitlab.com/",
    ))
  }
  if "bitbucket" in author {
    specs.push((
      text: author.bitbucket,
      icon: bitbucket-icon,
      link: author.bitbucket,
      prefix: "https://bitbucket.org/",
    ))
  }
  if "linkedin" in author {
    specs.push((
      text: author.firstname + " " + author.lastname,
      icon: linkedin-icon,
      link: author.linkedin,
      prefix: "https://www.linkedin.com/in/",
    ))
  }
  if "twitter" in author {
    specs.push((
      text: "@" + author.twitter,
      icon: twitter-icon,
      link: author.twitter,
      prefix: "https://twitter.com/",
    ))
  }
  if "bluesky" in author {
    specs.push((
      text: "@" + author.bluesky,
      icon: bluesky-icon,
      link: author.bluesky,
      prefix: "https://bsky.app/profile/",
    ))
  }
  if "mastodon" in author {
    specs.push((
      text: "@" + author.mastodon,
      icon: mastodon-icon,
      link: author.mastodon,
      prefix: "https://mastodon.social/@",
    ))
  }
  if "scholar" in author {
    specs.push((
      text: str(author.firstname + " " + author.lastname),
      icon: google-scholar-icon,
      link: author.scholar,
      prefix: "https://scholar.google.com/citations?user=",
    ))
  }
  if "orcid" in author {
    specs.push((
      text: author.orcid,
      icon: orcid-icon,
      link: author.orcid,
      prefix: "https://orcid.org/",
    ))
  }
  if "website" in author {
    specs.push((
      text: author.website,
      icon: website-icon,
      link: author.website,
      prefix: "",
    ))
  }
  if "custom" in author and type(author.custom) == array {
    for item in author.custom {
      if "text" in item {
        specs.push((
          text: item.text,
          icon: if ("icon" in item) {
            box(fa-icon(item.icon, fill: color-darknight))
          } else {
            none
          },
          link: if ("link" in item) { item.link } else { none },
          prefix: "",
        ))
      }
    }
  }

  specs
}

/// Format contact items with the respective Font Awesome icon and return them as list
///
/// LOCAL EDIT: reduced to a thin map over `__collect_contact_specs`. Output is
/// unchanged — this is the horizontal row used by `coverletter()` and by
/// `resume()` when `sidebar-contacts: false`.
///
/// - author (dictionary): The dictionary containing the contact item values
/// - item-inset (dictionary): Inset of each individual contact item
/// -> array (of content)
#let __format_contact_items(author, item-inset: (:)) = {
  __collect_contact_specs(author).map(spec => __contact_item(
    (text: spec.text, icon: spec.icon, link: spec.link),
    link-prefix: spec.prefix,
    inset: item-inset,
  ))
}

/// LOCAL EDIT (addition — not upstream): contact items as a VERTICAL stack for the
/// right sidebar, replacing the centered single-line row in the header.
///
/// ONE grid with an `auto` icon column and N rows — not N separate grids. The auto
/// column is then sized to the widest icon across all rows, so the icons form a
/// clean edge and every text cell starts at the same x. Separate grids would each
/// size independently and read ragged.
///
/// The text column is `1fr`, not `auto`, so a long value wraps inside the sidebar
/// measure instead of widening the grid past it.
///
/// - author (dictionary): The dictionary containing the contact item values
/// - icon-gutter (length): Gap between the icon column and the text column
/// - row-gap (length): Vertical gap between contact rows
#let __format_contact_column(author, icon-gutter: 5pt, row-gap: 0.6em) = {
  grid(
    columns: (auto, 1fr),
    column-gutter: icon-gutter,
    row-gutter: row-gap,
    align: (center + top, left + top),
    ..__collect_contact_specs(author)
      .map(spec => (
        if spec.icon != none { spec.icon } else { [] },
        if spec.link != none {
          link(spec.prefix + spec.link)[#spec.text]
        } else {
          spec.text
        },
      ))
      .flatten()
  )
}

/// Show a link with an icon, specifically for Github projects
/// *Example*
/// #example(`resume.github-link("ptsouchlos/awesome-resume")`)
/// - github-path (string): The path to the Github project (e.g. "ptsouchlos/awesome-resume")
/// -> none
#let github-link(github-path) = {
  set box(height: 11pt)

  align(right + horizon)[
    #fa-icon("github", fill: color-darkgray) #h(2pt) #link(
      "https://github.com/" + github-path,
      github-path,
    )
  ]
}

/// Right section for the justified headers
/// - body (content): The body of the right header
#let secondary-right-header(body) = {
  // LOCAL EDIT: upstream 11pt, matching the level-2 heading on the left of the
  // same row. Dropped a half point so the date range sits just under the
  // organization name rather than competing with it.
  set text(size: 10.5pt, weight: "medium")
  body
}

/// Right section of a tertiaty headers.
/// - body (content): The body of the right header
#let tertiary-right-header(body) = {
  set text(weight: "light", size: 9pt)
  body
}

/// Justified header that takes a primary section and a secondary section. The primary section is on the left and the secondary section is on the right.
/// - primary (content): The primary section of the header
/// - secondary (content): The secondary section of the header
#let justified-header(primary, secondary) = {
  set block(above: 0.7em, below: 0.7em)
  pad[
    #__justify_align[
      == #primary
    ][
      #secondary-right-header[#secondary]
    ]
  ]
}

/// Justified header that takes a primary section and a secondary section. The primary section is on the left and the secondary section is on the right. This is a smaller header compared to the `justified-header`.
/// - primary (content): The primary section of the header
/// - secondary (content): The secondary section of the header
#let secondary-justified-header(primary, secondary) = {
  __justify_align[
    === #primary
  ][
    #tertiary-right-header[#secondary]
  ]
}
/// --- End of Helpers

/// ---- Resume Template ----

/// Resume template that is inspired by the Awesome CV Latex template by posquit0. This template can loosely be considered a port of the original Latex template.
///
/// The original template: https://github.com/posquit0/Awesome-CV
///
/// - author (dictionary): Structure that takes in all the author's information
/// - profile-picture (image): The profile picture of the author. This will be cropped to a circle and should be square in nature.
/// - contact-items-separator (content): Separator to use between the "contact" items in the header of the resume. This includes items like your email, website, Github account, phone number and so on. The default is blank spacing.
/// - contact-items-inset (dictionary): Gap between contact item icon and contact item text.
/// - date (string): The date the resume was created
/// - accent-color (color): The accent color of the resume
/// - colored-headers (boolean): Whether the headers should be colored or not
/// - language (string): The language of the resume, defaults to "en". See lang.toml for available languages
/// - use-smallcaps (boolean): Whether to use small caps formatting throughout the template
/// - show-address-icon (boolean): Whether to show the address icon
/// - description (str | none): The PDF description
/// - keywords (array | str): The PDF keywords
/// - body (content): The body of the resume
/// -> none
#let resume(
  author: (:),
  profile-picture: image,
  contact-items-separator: h(10pt),
  contact-items-inset: (left: 4pt),
  date: datetime.today().display("[month repr:long] [day], [year]"),
  accent-color: default-accent-color,
  colored-headers: true,
  show-footer: true,
  language: "en",
  font: ("Source Sans 3", "Source Sans Pro"),
  header-font: "Roboto",
  paper-size: "a4",
  use-smallcaps: true,
  show-address-icon: false,
  description: none,
  keywords: (),
  /// LOCAL EDIT (addition): move the contact items out of the centered header and
  /// into the sidebar. A revert switch, not a knob — `false` restores upstream's
  /// centered single-line row.
  sidebar-contacts: true,
  body,
) = {
  if type(accent-color) == str {
    accent-color = rgb(accent-color)
  }

  let lang_data = toml("lang.toml")

  let desc = if description == none {
    (
      lflib._linguify("resume", lang: language, from: lang_data).ok
        + " "
        + author.firstname
        + " "
        + author.lastname
    )
  } else {
    description
  }

  show: body => context {
    set document(
      author: author.firstname + " " + author.lastname,
      title: lflib._linguify("resume", lang: language, from: lang_data).ok,
      description: desc,
      keywords: keywords,
    )
    body
  }

  // LOCAL EDIT: upstream 11pt, then 10pt, now 9.5pt. This is the document body
  // size and the main knob for overall density. It used to be overridden by a
  // `set text(size: 10pt)` at the top of resume.qmd, which reached only text that
  // had no explicit size of its own — so most of the document ignored it. Setting
  // it here instead means one value governs the body, and `resume-item` now
  // inherits it (see below).
  //
  // Note this now EQUALS the level-3 heading size (9.5pt), so a job title and the
  // bullets under it are the same size and separate on style and weight alone.
  set text(
    font: font,
    lang: language,
    size: 9.5pt,
    fill: color-darkgray,
    fallback: true,
  )

  // LOCAL EDIT (addition): pin fontawesome to Font Awesome 6.
  //
  // fontawesome 0.6.0 defaults to version "7". That makes it request the font
  // families "Font Awesome 7 Free" / "Font Awesome 7 Brands" AND resolve icon
  // names against FA 7's table. Quarto ships FA *6* (see
  // share/formats/typst/fonts/) and passes only that directory to Typst, so every
  // icon fell back to the body font and rendered as an empty box — the cause of
  // the missing contact icons in the sidebar.
  //
  // Pinning to "6" fixes both halves together: the family names now match the
  // fonts Quarto actually provides, and the name -> codepoint map is FA 6's, which
  // is the drift described in the note near the top of this file.
  //
  // Must be a call in the DOCUMENT FLOW, not a top-level statement — a state
  // update at the top level of an imported module is discarded. It sits here,
  // ahead of the sidebar and header, so their `.get()` sees "6".
  //
  // The alternative is vendoring the FA 7 otfs into the repo and pointing
  // `font-paths` at them; this was chosen instead because it adds no binaries and
  // needs no font installed on the rendering machine. The cost is that it breaks
  // if Quarto ever bundles a different FA version — the warning to watch for is
  // "unknown font family: font awesome 6 free".
  fa-version("6")

  // ---- LOCAL EDIT (addition): the right sidebar ------------------------------
  //
  // Three placed pieces, all handed to `page(background:)`. Background content is
  // laid out in a region the size of the WHOLE PAGE, anchored at its top-left
  // corner — margins included — so `place(top + right)` reaches the physical page
  // edge and `height: 100%` spans top margin to bottom margin. That is what makes
  // the band full-bleed; nothing in the body flow can do this, because flow
  // content is confined to the content area.
  //
  // Background also consumes no flow space, so none of this can influence where
  // the body breaks across pages.

  // The band itself. NOT gated to page 1: Typst cannot vary `page.margin` per
  // page, so page 2 keeps the narrow column whatever we paint there — and a
  // narrow column beside an unexplained 3.25in of white reads as a bug, while the
  // same column beside the band reads as the design.
  let sidebar-band = place(
    top + right,
    rect(
      width: sidebar-width,
      height: 100%,
      fill: sidebar-fill,
      // `stroke: auto` already means "none" when a fill is given, but be explicit
      // — a 1pt black outline on a full-height band is not a subtle mistake.
      stroke: none,
    ),
  )

  // Sidebar content, page 1 only. The background is laid out afresh on every
  // page, so without the guard this repeats identically on page 2.
  //
  // HARD LIMIT: placed content cannot break across pages. If this outgrows the
  // page it is clipped SILENTLY, with no warning. Measure it after content
  // changes — see README-VENDORED.md, "The right sidebar".
  let sidebar-block = context {
    if here().page() == 1 {
      place(
        top + right,
        dx: -sidebar-inset.right,
        dy: sidebar-inset.top,
        block(width: sidebar-text-width)[
          // `place(top + right, ...)` aligns the block against the page AND
          // propagates that alignment inward, which right-aligns every paragraph
          // in the sidebar. Reset it here — the block's position is already fixed
          // by the `place`, so this only affects text inside it.
          #set align(left)
          // Set explicitly rather than inherited: the document sets
          // `justify: true`, which at a 2.3in measure produces rivers, and
          // hyphenation follows justification — which would hyphenate
          // "danyavorsky.com".
          #set text(size: 9pt, hyphenate: false)
          // `spacing` is set to `sidebar-item-gap` so a paragraph break inside a
          // section reads as the same rhythm as the gap between entries. In
          // practice this governs only the Personal section, the one place with
          // two paragraphs — every other sidebar helper separates its items with
          // blocks or line breaks, not paragraph breaks.
          #set par(justify: false, leading: 0.55em, spacing: sidebar-item-gap)
          #if sidebar-contacts { __format_contact_column(author) }
          // Sections registered by `sidebar-section` in resume.qmd. `.final()` is the
          // accumulated value after every update in the document.
          #__sidebar_state.final()
        ],
      )
    }
  }

  // Date and page number at the foot of the band, replacing the footer (below).
  // NOT gated to page 1 — the page number has to appear on every page.
  let sidebar-stamp = place(
    bottom + right,
    dx: -sidebar-inset.right,
    dy: -sidebar-inset.bottom,
    block(width: sidebar-text-width)[
      #set text(size: 8pt, fill: color-gray)
      #set par(justify: false, leading: 0.5em)
      #align(right)[
        // "Last Updated:" is hardcoded English rather than routed through
        // linguify — lang.toml has no key for it, and adding one would mean
        // editing vendored localization data for every language.
        //
        // No page number: the CV is one page, so "1 / 1" was noise. If it ever
        // goes back to two, restore it with
        //   \ #context [#counter(page).display() / #counter(page).final().first()]
        #__apply_smallcaps([Last Updated: #date], use-smallcaps)
      ]
    ],
  )

  set page(
    paper: paper-size,
    margin: (
      // LOCAL EDIT: upstream 15mm all round with a footer-dependent bottom.
      //   * left/top 0.5in — puts the layout on an inch grid, which matters once
      //     it is asymmetric, and gains 6.5pt of measure over 15mm.
      //   * right is DERIVED from the band. This margin is the only thing keeping
      //     body text out from under the sidebar, so it must never be hardcoded:
      //     change `sidebar-width` and the reservation follows.
      //   * bottom is 10mm unconditionally now that the footer moved into the
      //     band — worth 20mm - 10mm = 28.35pt of recovered body height.
      left: 0.5in,
      right: sidebar-width + sidebar-gutter,
      top: 0.5in,
      bottom: 10mm,
    ),
    // LOCAL EDIT: the sidebar. Safe to add here — this is the document's only
    // `set page` (Quarto's page.typ partial is deliberately blanked) and it sits
    // at the top of the flow, so it cannot force a page break.
    background: {
      sidebar-band
      sidebar-block
      if show-footer { sidebar-stamp }
    },
    // LOCAL EDIT: upstream emitted `date · name · page` across the content width.
    // With the right margin reserved for the band that row is narrow and visibly
    // off-centre, so `show-footer` now drives `sidebar-stamp` above instead.
    // `__resume_footer` is left defined so reverting is a one-line change.
    footer: [],
    // Inert while `footer` is empty; kept for the same reason.
    footer-descent: 35%,
  )

  // set paragraph spacing
  // LOCAL EDIT: `leading` added (upstream set only spacing and justify). This was
  // a `set par(leading: 0.55em)` in resume.qmd, which could not reach the bullet text
  // — `resume-item` does its own `set par(leading:)` and an inner `set` wins.
  // Verified: identical wrapped text measures 30.74pt under the document-level
  // rule alone but 79.74pt when a function re-sets leading inside itself.
  set par(spacing: 0.75em, leading: 0.55em, justify: true)

  set heading(numbering: none, outlined: false)

  // LOCAL EDITS in all three rules below. Upstream sizes were 16pt / 12pt / 10pt.
  // `resume-entry` routes its text through headings — the entry title is emitted
  // as `== title` (level 2) and the description line as `=== description`
  // (level 3) — so these three rules control the whole entry block.
  show heading.where(level: 1): it => block(sticky: true)[
    #set text(size: 13pt, weight: "regular")
    #set align(left)
    #set block(above: 1em)
    #let color = if colored-headers {
      accent-color
    } else {
      color-darkgray
    }
    // LOCAL EDIT: `upper()` added so section titles render as EXPERIENCE,
    // EDUCATION, and so on, while the .qmd source keeps readable `# Experience`
    // headings. Upstream emitted the body as written.
    #text[#strong[#text(color)[#upper(it.body)]]]
    // LOCAL EDIT: upstream passed no stroke, so the rule took Typst's default
    // 1pt black and outweighed the now-smaller, gray heading text.
    #box(width: 1fr, line(length: 100%, stroke: 0.5pt + color))
  ]

  show heading.where(level: 2): it => {
    set text(color-darkgray, size: 11pt, style: "normal", weight: "bold")
    it.body
  }

  show heading.where(level: 3): it => {
    set text(size: 9.5pt, weight: "regular")
    __apply_smallcaps(it.body, use-smallcaps)
  }

  // LOCAL EDIT: upstream centered the name, positions, and address. With the
  // sidebar taking the right third of the page, centering on what is now a 4.75in
  // left column reads as misalignment, so all three are left-aligned — matching
  // the pagedown layout this design is ported from.
  let header-align = if sidebar-contacts { left } else { center }

  let name = {
    align(header-align)[
      #pad(bottom: 5pt)[
        #block[
          // LOCAL EDIT: upstream 32pt. Reduced to sit better with the smaller
          // heading sizes above. This is not reachable via show rules — the
          // header block is composed inside `resume()` before the document body,
          // which is why the template had to be vendored to change it.
          #set text(size: 24pt, style: "normal", font: header-font)
          // LOCAL EDIT: upstream set the given name `thin` against a `bold`
          // family name. Both are now `bold` — the accent color alone
          // distinguishes them, which reads as one name rather than two weights
          // colliding.
          #if language == "zh" or language == "ja" [
            #text(accent-color, weight: "bold")[#author.lastname]#text(
              weight: "bold",
            )[#author.firstname]
          ] else [
            #text(accent-color, weight: "bold")[#author.firstname]
            #text(weight: "bold")[#author.lastname]
          ]
        ]
      ]
    ]
  }

  let positions = {
    set text(accent-color, size: 9pt, weight: "regular")
    align(header-align)[
      #__apply_smallcaps(
        author.positions.join(text[#"  "#sym.dot.c#"  "]),
        use-smallcaps,
      )
    ]
  }

  // LOCAL EDIT: guarded on the key being present. Upstream emitted this block
  // unconditionally, so an author dict without `address` — which is this one,
  // since the location is passed as a custom contact item instead — produced an
  // empty aligned block that still consumed vertical space.
  let address = if "address" in author {
    set text(size: 9pt, weight: "regular")
    align(header-align)[
      #if show-address-icon [
        #__contact_item(
          (
            icon: address-icon,
            text: text(author.address),
          ),
          inset: contact-items-inset,
        )
      ] else [
        #text(author.address)
      ]
    ]
  }

  // Contact section
  // LOCAL EDIT: suppressed when the contacts live in the sidebar (the default).
  // Kept behind the flag rather than deleted so upstream's centered row is one
  // argument away rather than needing to be re-derived.
  let contacts = if not sidebar-contacts {
    set box(height: 9pt)
    set text(size: 9pt, weight: "regular", style: "normal")

    let items = __format_contact_items(author, item-inset: contact-items-inset)
    align(center, items.join(contact-items-separator))
  }

  if profile-picture != none {
    grid(
      columns: (100% - 4cm, 4cm),
      rows: 100pt,
      gutter: 10pt,
      [
        #name
        #positions
        #address
        #contacts
      ],
      align(left + horizon)[
        #block(
          clip: true,
          stroke: 0pt,
          radius: 2cm,
          width: 4cm,
          height: 4cm,
          profile-picture,
        )
      ],
    )
  } else {
    name
    positions
    address
    contacts
  }

  body
}

/// The base item for resume entries.
/// This formats the item for the resume entries. Typically your body would be a bullet list of items. Could be your responsibilities at a company or your academic achievements in an educational background section.
/// - body (content): The body of the resume entry
#let resume-item(body) = {
  // LOCAL EDIT: upstream also fixed `size: 10pt` here. Dropped so bullet text
  // inherits the document size set in `resume()` — otherwise changing the body
  // size leaves every bullet behind, which is what used to happen.
  set text(style: "normal", weight: "light", fill: color-darknight)
  set block(above: 0.75em, below: 1.25em)
  // This is the EFFECTIVE leading for nearly all body text: almost everything in
  // the CV is inside a `resume-item`, and an inner `set` beats the document-level
  // `set par(leading:)` in `resume()`. Deliberately looser than the 0.55em
  // document value, giving wrapped bullets slightly more air. Change it HERE to
  // retighten bullets — the document-level value cannot reach them.
  set par(leading: 0.65em)
  // LOCAL EDIT: upstream left Typst's default round `•`. U+2023 TRIANGULAR
  // BULLET. Revert by deleting this line.
  //
  // `spacing` is the gap BETWEEN bullets, as distinct from the `leading` above,
  // which is the gap between the wrapped lines WITHIN one bullet. It has to be set
  // explicitly: the bullets come from Markdown with no blank lines between them,
  // so Typst treats the list as tight, and a tight list's default `auto` spacing
  // resolves to `leading` — which is why bullets used to sit exactly as close to
  // each other as their own wrapped lines did. Keep this above `leading` or the
  // separation between bullets disappears again.
  set list(marker: [‣], spacing: 0.95em)
  block(above: 0.5em)[
    #body
  ]
}

/// The base item for resume entries. This formats the item for the resume entries. Typically your body would be a bullet list of items. Could be your responsibilities at a company or your academic achievements in an educational background section.
/// - title (string): The title of the resume entry
/// - location (string): The location of the resume entry
/// - date (string): The date of the resume entry, this can be a range (e.g. "Jan 2020 - Dec 2020")
/// - description (content): The body of the resume entry
/// - title-link (string): The link to use for the title (can be none)
/// - accent-color (color): Override the accent color of the resume-entry
/// - location-color (color): Override the default color of the "location" for a resume entry.
#let resume-entry(
  title: none,
  location: "",
  date: "",
  description: "",
  title-link: none,
  accent-color: default-accent-color,
  location-color: default-location-color,
) = {
  let title-content
  if type(title-link) == str {
    title-content = link(title-link)[#title]
  } else {
    title-content = title
  }
  block(above: 1em, below: 0.65em, sticky: true)[
    #pad[
      #justified-header(title-content, location)
      #if description != "" or date != "" [
        #secondary-justified-header(description, date)
      ]
    ]
  ]
}

/// LOCAL EDIT (addition — not upstream): job entry with the ORGANIZATION on top.
///
/// `resume-entry` above puts the job title in the prominent first row and the
/// organization below it; this swaps them, so row 1 is organization + date range
/// and row 2 is job title + location. It reuses `justified-header` (which emits
/// `==`, the larger bold level-2 style) and `secondary-justified-header` (`===`,
/// the smaller level-3 style), so the size and weight relationship matches every
/// other entry type.
///
/// This is a separate function rather than an edit to `resume-entry` because
/// Publications and R Packages still need the original order — for those, the
/// paper title and package name belong in the prominent row, not the description.
///
/// Named parameters with defaults, not positional: Typst will not accept a
/// positional parameter supplied as a named argument at the call site.
/// - organization (content): The organization, in the prominent first row
/// - date (string): The date range, right-aligned on the first row
/// - title (string): The job title, in the smaller second row
/// - location (string): The location, right-aligned on the second row
#let job-entry(
  organization: none,
  date: "",
  title: "",
  location: "",
) = block(
  above: 1em,
  below: 0.65em,
  sticky: true,
)[
  #pad[
    #justified-header(organization, date)
    // Italic on BOTH halves of the second row, applied here rather than in
    // `secondary-justified-header`: that helper is shared with `resume-entry`,
    // where the second row is a description and should stay upright. Wrapping the
    // arguments keeps the italic to job entries only.
    #secondary-justified-header(emph(title), emph(location))
  ]
]

/// LOCAL EDIT (addition — not upstream): publication entry, styled to match
/// `edu-entry` rather than `resume-entry`.
///
/// `resume-entry` gives a publication an 11pt bold title row and a small-caps
/// description row, which reads as two headings per paper and makes the section
/// heavier than Education directly above it. This uses the same idiom as
/// `edu-entry` — medium-weight title, smaller gray venue inline, light right-aligned
/// year — so the two sections match.
///
/// Differs from `edu-entry` in two ways, both because publication titles are long
/// enough to wrap where degree names are not: the year is aligned to the TOP so it
/// sits beside the first line of a wrapped title, and there is a column gutter so a
/// full-width title cannot run into the year.
/// - title (string): The paper or book title
/// - venue (content): Journal, coauthors, or role — set smaller and gray
/// - year (string): The year or status ("In Progress"), right-aligned
/// - title-link (string): Optional URL for the title
#let pub-entry(title, venue, year, title-link: none) = block(
  above: 0.65em,
  below: 0.65em,
)[
  #grid(
    columns: (1fr, auto),
    column-gutter: 10pt,
    align: (left + top, right + top),
    [#text(size: 10.5pt, weight: "medium")[#if title-link != none {
        link(title-link)[#title]
      } else {
        title
      }]#h(5pt)#text(size: 9.5pt, fill: color-gray)[#venue]],
    text(size: 9pt, weight: "light")[#year],
  )
]

/// LOCAL EDIT (addition — not upstream): one-line education entry.
///
/// `resume-entry` always takes two lines (title + location, then description +
/// date), and Education needs neither a location nor a second line: degree and
/// school read fine together with the year at the right.
///
/// Styled deliberately UNLIKE a job entry. The degree was 11pt bold — identical to
/// a level-2 entry title — with the school in small caps, so four stacked rows read
/// as four headings and looked heavy and cramped. Medium weight, a gray school, and
/// more row spacing separate the section from Experience. The sizes here are
/// intentionally explicit rather than inherited, since the whole point is that this
/// row does not match the surrounding entry styles.
/// - degree (string): The degree or credential
/// - school (string): The granting institution, set smaller and gray
/// - year (string): The year, right-aligned
#let edu-entry(degree, school, year) = block(above: 0.65em, below: 0.65em)[
  #grid(
    columns: (1fr, auto),
    align: (left + bottom, right + bottom),
    [#text(size: 10.5pt, weight: "medium")[#degree]#h(5pt)#text(
        size: 9.5pt,
        fill: color-gray,
      )[#school]],
    text(size: 9pt, weight: "light")[#year],
  )
]

// ---- LOCAL EDIT (addition — not upstream): right sidebar content helpers -----
//
// These exist because the main-column helpers do NOT survive the sidebar's 2.3in
// measure — this is a restyle, not a move:
//   * `edu-entry` above is `grid(columns: (1fr, auto))` with the year right-
//     aligned on the same line. "PhD, Quantitative Marketing" + "UCLA Anderson"
//     + "2020" cannot share a 166pt line.
//   * `resume-skill-grid` has an `auto` label column; at 166pt the label
//     "Languages & Tools" claims most of the width and the values collapse.
// Both sidebar variants therefore STACK rather than justify across a row.

/// Section heading inside the sidebar.
///
/// Deliberately NOT the level-1 `heading` show rule, which is 13pt, accent-
/// colored, ends in a `1fr` rule, and is wrapped in `block(sticky: true)` — all
/// wrong at 2.3in, and `sticky` is meaningless for content that is placed out of
/// the flow anyway.
///
/// `above: 2.2em` is what separates the sidebar's sections; it is the one knob for
/// how much air sits between Education, Skills, and Personal.
/// - title (string): Section title; rendered uppercase
#let sidebar-heading(title) = block(above: 2.2em, below: 0.75em)[
  #set text(size: 9.5pt, weight: "bold", fill: color-darkgray)
  #upper(title)
  #v(-0.55em)
  #line(length: 100%, stroke: 0.5pt + color-gray)
]

/// Education entry for the sidebar: degree on its own line, then school and year
/// beneath it, smaller and gray. The stacked form is what makes it fit; see the
/// block comment above.
/// - degree (string): Degree or credential
/// - school (string): Granting institution
/// - year (string): Year awarded
// `above` stays tight and `below` carries the gap. Typst takes the MAX of the
// previous block's `below` and the next block's `above`, so this gives the full
// `sidebar-item-gap` between entries while leaving the heading-to-first-entry gap
// governed by `sidebar-heading`'s own `below`.
#let sidebar-edu-entry(degree, school, year) = block(
  above: 0.45em,
  below: sidebar-item-gap,
)[
  #text(weight: "medium")[#degree] \
  #text(size: 8.5pt, fill: color-gray)[#school, #year]
]

/// Skill categories for the sidebar: bold label on its own line, comma-joined
/// values beneath. Same dictionary shape as `resume-skill-grid`, so the content
/// moves across unchanged.
/// - categories-with-values (dictionary): category -> array of values
#let sidebar-skill-list(categories-with-values: (:)) = {
  for (category, values) in categories-with-values.pairs() {
    block(below: 0.85em)[
      #text(weight: "bold")[#category] \
      #values.join(", ")
    ]
  }
}

/// LOCAL EDIT (addition — not upstream): grouped list for the sidebar, one item
/// per line.
///
/// Same dictionary shape as `sidebar-skill-list` — bold group label, then the
/// values — but each item gets its own block instead of being comma-joined.
/// Skill names are short enough to run together on a line; publication titles are
/// not. At the sidebar's 2.3in measure a comma-joined title list wraps into an
/// unreadable run-on where the end of one title and the start of the next are
/// indistinguishable.
///
/// Items are CONTENT, not strings, so the call site can wrap one in `#link(...)`.
/// That is how the publications carry their URLs, and it keeps link targets in
/// resume.qmd with the rest of the content.
/// - categories-with-values (dictionary): group label -> array of content
#let sidebar-stacked-list(categories-with-values: (:)) = {
  for (category, items) in categories-with-values.pairs() {
    // Group gap must EXCEED `sidebar-item-gap`, or the next group's label sits
    // closer to the last item above it than the items sit to each other and reads
    // as belonging to that item rather than heading the list below.
    // (`sidebar-skill-list` keeps 0.85em: its values are comma-joined, so it has
    // no item gap to beat.)
    block(below: sidebar-item-gap + 0.5em)[
      #text(weight: "bold")[#category]
      // The first item hugs its group label; the rest get the full
      // `sidebar-item-gap`. Without the index test every item would sit the same
      // distance apart, and the label would float away from the list it heads.
      #for (i, item) in items.enumerate() {
        block(
          above: if i == 0 { 0.4em } else { sidebar-item-gap },
          below: 0pt,
        )[#item]
      }
    ]
  }
}

/// LOCAL EDIT (addition — not upstream): register one sidebar section from resume.qmd.
///
/// This is what keeps sidebar CONTENT in resume.qmd where the rest of the content
/// lives. `resume()` cannot take it as a parameter — its arguments are fixed
/// before the body exists — so each call appends to `__sidebar_state` and the page
/// background renders the accumulated value. Sections appear in call order.
///
/// Emits no layout of its own: a `state.update` is invisible, so these calls can
/// sit anywhere in resume.qmd without disturbing the main column.
///
/// The heading, its icon, and the spacing above it are all decided by
/// `sidebar-heading` — the call site passes only the title and the body.
/// - title (string): Section title
/// - body (content): Section content, built from the other `sidebar-*` helpers
#let sidebar-section(title, body) = __sidebar_state.update(prev => prev + [
  #sidebar-heading(title)
  #body
])

/// Show cumulative GPA.
/// *Example:*
/// #example(`resume.resume-gpa("3.5", "4.0")`)
#let resume-gpa(numerator, denominator) = {
  set text(size: 12pt, style: "italic", weight: "light")
  text[Cumulative GPA: #box[#strong[#numerator] / #denominator]]
}

/// Show a certification in the resume.
/// *Example:*
/// #example(`resume.resume-certification("AWS Certified Solutions Architect - Associate", "Jan 2020")`)
/// - certification (content): The certification
/// - date (content): The date the certification was achieved
#let resume-certification(certification, date) = {
  justified-header(certification, date)
}

/// Styling for resume skill categories.
/// - category (string): The category
#let resume-skill-category(category) = {
  // LOCAL EDIT: upstream fixed `size: 11pt`, so the Skills block rendered larger
  // than the surrounding body and ignored the document size. Dropped to inherit.
  set text(style: "normal", weight: "bold", hyphenate: false)
  category
}

/// Styling for resume skill values/items
/// - values (array): The skills to display
#let resume-skill-values(values) = {
  // LOCAL EDIT: upstream fixed `size: 11pt` and `weight: "light"`. Size dropped to
  // inherit the document size; weight dropped so values sit at regular weight,
  // which is how the Skills block has been rendering and keeps the contrast with
  // the bold category label from being overstated. `strong()` inside a values
  // array still bolds, which is how individual skills are emphasized.
  set text(style: "normal")
  // This is a list so join by comma (,)
  values.join(", ")
}

/// Show a list of skills in the resume under a given category.
/// - category (string): The category of the skills
/// - items (list): The list of skills. This can be a list of strings but you can also emphasize certain skills by using the `strong` function.
#let resume-skill-item(category, items) = {
  set block(below: 0.65em)
  set pad(top: 2pt)

  pad[
    #grid(
      columns: (3fr, 8fr),
      gutter: 10pt,
      align: left + top,
      resume-skill-category(category), resume-skill-values(items),
    )
  ]
}

/// Show a grid of skill lists with each row corresponding to a category of skills, followed by the skills themselves. The dictionary given to this function should have the skill categories as the dictionary keys and the values should be an array of values for the corresponding key.
/// - categories-with-values (dictionary): key value pairs of skill categories and it's corresponding values (skills)
#let resume-skill-grid(categories-with-values: (:)) = {
  set block(below: 1.25em)
  set pad(top: 2pt)

  pad[
    #grid(
      // LOCAL EDIT: upstream `columns: (auto, auto)` and a single `gutter: 10pt`.
      // `1fr` gives the values column all remaining width instead of sizing it to
      // its content, and splitting the gutter lets rows sit tighter than the
      // 10pt column gap. (`resume-skill-item`, the single-row variant, hardcodes
      // `columns: (3fr, 8fr)` — 27% of the width on the label, forcing values to
      // wrap. This grid is the one in use; that one is left as upstream.)
      columns: (auto, 1fr),
      column-gutter: 10pt,
      row-gutter: 0.5em,
      align: left + top,
      ..categories-with-values
        .pairs()
        .map(((key, value)) => (
          resume-skill-category(key),
          resume-skill-values(value),
        ))
        .flatten()
    )
  ]
}

/// ---- End of Resume Template ----

/// ---- Coverletter ----

/// Default signature for the cover letter template.
/// - lang-data (dictionary): Structure that contains all the language data. Used with `linguify`
/// - language (string): The language of the cover letter.
/// - author (string): The author of the cover letter.
/// - alignment (alignment): Alignment of the signature.
/// - padding (dictionary): Padding of the signature.
#let default-signature(lang-data, language, author, alignment, padding) = {
  align(alignment, pad(..padding)[
    #text(weight: "light")[#linguify("sincerely", from: lang-data)#if (
        language != "de"
      ) [#sym.comma]] \
    #if ("signature" in author) {
      author.signature
    } \
    #text(weight: "bold")[#author.firstname #author.lastname]
  ])
}

#let default-closing(lang-data) = {
  align(bottom)[
    #text(weight: "light", style: "italic")[
      #linguify("attached", from: lang-data)#sym.colon #linguify(
        "curriculum-vitae",
        from: lang-data,
      )]
  ]
}

#let default-par = (spacing: 0.75em, justify: true)

/// Cover letter template that is inspired by the Awesome CV Latex template by posquit0. This template can loosely be considered a port of the original Latex template.
/// This coverletter template is designed to be used with the resume template.
/// - author (dictionary): Structure that takes in all the author's information. The following fields are required: firstname, lastname, positions. The following fields are used if available: email, phone, github, linkedin, orcid, address, website, custom. The `custom` field is an array of additional entries with the following fields: text (string, required), icon (string, optional Font Awesome icon name), link (string, optional).
/// - profile-picture (image): The profile picture of the author. This will be cropped to a circle and should be square in nature.
/// - contact-items-separator (content): Separator to use between the "contact" items in the header of the coverletter. This includes items like your email, website, Github account, phone number and so on. The default is blank spacing.
/// - contact-items-inset (dictionary): Gap between contact item icon and contact item text.
/// - heading-padding (dictionary): Padding of the salutation line.
/// - signature-padding (dictionary): Padding of the signature.
/// - signature-alignment (alignment): Alignment of the signature.
/// - par-spacing (length): Spacing between paragraphs of the letter content.
/// - date (datetime): The date the cover letter was created. This will default to the current date.
/// - accent-color (color): The accent color of the cover letter
/// - language (string): The language of the cover letter, defaults to "en". See lang.toml for available languages
/// - font (array): The font families of the cover letter
/// - header-font (array): The font families of the cover letter header
/// - show-footer (boolean): Whether to show the footer or not
/// - signaure (content): The signature of the cover letter. You can set this to `none` to show the default signature or remove it completely.
/// - closing (content): The closing of the cover letter. This defaults to "Attached Curriculum Vitae". You can set this to `none` to show the default closing or remove it completely.
/// - use-smallcaps (boolean): Whether to use small caps formatting throughout the template
/// - show-address-icon (boolean): Whether to show the address icon
/// - description (str | none): The PDF description
/// - keywords (array | str): The PDF keywords
/// - body (content): The body of the cover letter
#let coverletter(
  author: (:),
  profile-picture: image,
  contact-items-separator: box(width: 6pt, align(center, sym.bar.v)),
  contact-items-inset: (:),
  heading-padding: (above: 2em, below: 1em),
  signature-padding: (top: 1em),
  signature-alignment: left,
  par-spacing: 1.5em,
  date: datetime.today().display("[month repr:long] [day], [year]"),
  accent-color: default-accent-color,
  language: "en",
  font: ("Source Sans 3", "Source Sans Pro"),
  header-font: "Roboto",
  show-footer: true,
  signature: none,
  closing: none,
  paper-size: "a4",
  use-smallcaps: true,
  show-address-icon: false,
  description: none,
  keywords: (),
  body,
) = {
  if type(accent-color) == str {
    accent-color = rgb(accent-color)
  }

  // language data
  let lang_data = toml("lang.toml")

  if signature == none {
    signature = default-signature(
      lang_data,
      language,
      author,
      signature-alignment,
      signature-padding,
    )
  }

  if closing == none {
    closing = default-closing(lang_data)
  }

  let desc = if description == none {
    (
      lflib._linguify("cover-letter", lang: language, from: lang_data).ok
        + " "
        + author.firstname
        + " "
        + author.lastname
    )
  } else {
    description
  }

  show: body => context {
    set document(
      author: author.firstname + " " + author.lastname,
      title: lflib
        ._linguify("cover-letter", lang: language, from: lang_data)
        .ok,
      description: desc,
      keywords: keywords,
    )
    body
  }

  set text(
    font: font,
    lang: language,
    size: 11pt,
    fill: color-darkgray,
    fallback: true,
  )

  set page(
    paper: paper-size,
    margin: (
      left: 15mm,
      right: 15mm,
      top: 10mm,
      bottom: if show-footer { 20mm } else { 10mm },
    ),
    footer: if show-footer [#__coverletter_footer(
      author,
      language,
      date,
      lang_data,
      use-smallcaps: use-smallcaps,
    )] else [],
    footer-descent: 35%,
  )

  // set paragraph spacing
  set par(..default-par)

  set heading(numbering: none, outlined: false)

  show heading: it => block(..heading-padding)[
    #set text(size: 16pt, weight: "regular")

    #align(left)[
      #text[#strong[#text(accent-color)[#it.body]]]
      #box(width: 1fr, line(length: 100%))
    ]
  ]

  let name = {
    align(right)[
      #pad(bottom: 5pt)[
        #block[
          #set text(size: 32pt, style: "normal", font: header-font)
          #if language == "zh" or language == "ja" [
            #text(accent-color, weight: "bold")[#author.lastname]#text(
              weight: "bold",
            )[#author.firstname]
          ] else [
            #text(accent-color, weight: "thin")[#author.firstname]
            #text(weight: "bold")[#author.lastname]
          ]

        ]
      ]
    ]
  }

  let positions = {
    set text(accent-color, size: 9pt, weight: "regular")
    align(right)[
      #__apply_smallcaps(
        author.positions.join(text[#"  "#sym.dot.c#"  "]),
        use-smallcaps,
      )
    ]
  }

  let address = {
    set text(size: 9pt, weight: "bold", fill: color-gray)
    align(right)[
      #if ("address" in author) [
        #if show-address-icon [
          #__contact_item(
            (
              icon: address-icon,
              text: text(author.address),
            ),
            inset: contact-items-inset,
          )
        ] else [
          #text(author.address)
        ]
      ]
    ]
  }

  let contacts = {
    set text(size: 8pt, weight: "light", style: "normal")

    let items = __format_contact_items(author)
    align(right, items.join(contact-items-separator))
  }

  let letter-heading = {
    grid(
      columns: (1fr, 2fr),
      rows: 100pt,
      align(left + horizon)[
        #block(
          clip: true,
          stroke: 0pt,
          radius: 2cm,
          width: 4cm,
          height: 4cm,
          profile-picture,
        )
      ],
      [
        #name
        #positions
        #address
        #contacts
      ],
    )
  }

  // actual content
  letter-heading
  {
    set par(spacing: par-spacing)
    set text(weight: "light")
    body
  }
  signature
  closing
}

/// Cover letter heading that takes in the information for the hiring company and formats it properly.
/// - entity-info (content): The information of the hiring entity including the company name, the target (who's attention to), street address, and city
/// - date (date): The date the letter was written (defaults to the current date)
#let hiring-entity-info(
  entity-info: (:),
  date: datetime.today().display("[month repr:long] [day], [year]"),
  use-smallcaps: true,
) = {
  set par(leading: 1em, ..default-par)
  pad(top: 1.5em, bottom: 1.5em)[
    #__justify_align[
      #text(weight: "bold", size: 12pt)[#entity-info.target]
    ][
      #text(weight: "light", style: "italic", size: 9pt)[#date]
    ]

    #pad(top: 0.65em, bottom: 0.65em)[
      #text(weight: "regular", fill: color-gray, size: 9pt)[
        #__apply_smallcaps(entity-info.name, use-smallcaps) \
        #entity-info.street-address \
        #entity-info.city \
      ]
    ]
  ]
}

/// Letter heading for a given job position and addressee.
/// - job-position (string): The job position you are applying for
/// - addressee (string): The person you are addressing the letter to
/// - dear (string): optional field for redefining the "dear" variable
/// - padding (dictionary): Padding of the heading line
#let letter-heading(
  job-position: "",
  addressee: "",
  dear: "",
  padding: (top: 1em, bottom: 1em),
) = {
  set par(..default-par)
  let lang_data = toml("lang.toml")

  // TODO: Make this adaptable to content
  underline(evade: false, stroke: 0.5pt, offset: 0.3em)[
    #text(weight: "bold", size: 12pt)[#linguify(
        "letter-position-pretext",
        from: lang_data,
      ) #job-position]
  ]
  pad(..padding)[
    #text(weight: "light", fill: color-gray)[
      #if dear == "" [
        #linguify("dear", from: lang_data)
      ] else [
        #dear
      ]
      #addressee,
    ]
  ]
}

/// ---- End of Coverletter ----
