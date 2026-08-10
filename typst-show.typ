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
