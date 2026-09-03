# Readme

Dan Yavorsky's resume. Built with Quarto and Typst. 

## Credit

The layout descends from **[modern-cv](https://typst.app/universe/package/modern-cv/)**
by **Paul Tsouchlos** ([DeveloperPaul123](https://github.com/DeveloperPaul123/modern-cv)),
which is itself a Typst port of [Awesome-CV](https://github.com/posquit0/Awesome-CV). 
This project is an extension of modern-cv, not a plain use of it. Version 0.10.0 is
vendored into [modern-cv/](modern-cv/) rather than pulled from `@preview`, because
several things worth changing are hardcoded inside the template's `resume()` function:

- A full-height **gray sidebar** down the right edge, carrying contact details,
  education, publications, skills, and personal notes. Adapted from the
  [pagedown](https://github.com/rstudio/pagedown) `html_resume` layout.
- **Entry helpers** the upstream template does not have — `job-entry` (organization above
  job title, reversing `resume-entry`'s order) and stacked `sidebar-*` variants, since
  the upstream row-justified helpers are not compatible with the narrow sidebar.
- A refactor of the contact block so one source of truth feeds both a horizontal header
  row and the vertical sidebar column.
- Assorted resizing, recoloring, and a fix for a crash on link-less custom contact items.

## To render

```
quarto render resume.qmd --to typst
```

## Publishing to danyavorsky.com

The resume at [danyavorsky.com/cv/resume](https://www.danyavorsky.com/cv/resume/) is a
copy of this repo's `resume.pdf`, **synced automatically.** Rendering, committing, and
pushing `resume.pdf` to `main` here is the entire publish step — nothing on the website
needs updating by hand.

It moved on 2026-09-03: `/cv/` used to *be* the resume. There are now two documents —
this resume at `/cv/resume/`, and the academic CV (from
[`dyavorsky/cv_typst`](https://github.com/dyavorsky/cv_typst)) at `/cv/vita/` — reached
from a **Resume/CV dropdown** in the site navbar rather than a landing page.

Old `/cv/` links still work: that URL redirects here, via an `aliases:` key in the
resume page's front matter. So the URL printed on applications and linked from LinkedIn
is safe, but it is a redirect rather than a page — worth knowing if the resume's path
ever changes again, since the alias has to move with it.

The machinery lives in the website repo:
[`dyavorsky/quarto_website`](https://github.com/dyavorsky/quarto_website) →
`.github/workflows/sync-docs.yml` (was `sync-resume.yml`; it now handles both documents
in one job). It runs nightly at 03:12 PT, fetches `resume.pdf` from this repo's `main`,
renames it to `cv/resume/yavorsky_dan_resume_<yyyymmdd>.pdf`, updates the resume page's
"Last updated" date, and redeploys the site. To skip the wait, I can always trigger it
from that repo: **Actions → Sync resume and CV → Run workflow**.

To update the website by hand:

```bash
# 1. read the render date out of the PDF itself
# whitespace class matters: Typst 0.15 writes `(D:`, 0.13 writes ` (D:`
grep -aoE '/CreationDate[[:space:]]*\(D:[0-9]{8}' resume.pdf | head -1

# 2. copy the new PDF to website directory with dated name; remove old one
cp resume.pdf ../quarto_website/cv/resume/yavorsky_dan_resume_20260729.pdf
cd ../quarto_website
git rm cv/resume/yavorsky_dan_resume_20260728.pdf

# 3. update the two keys in quarto_website/cv/resume/index.qmd that name it:
#      date: 2026-07-29
#      cv:
#        pdf: "yavorsky_dan_resume_20260729.pdf"

# 4. commit and push to main; publish.yml renders and deploys
```



