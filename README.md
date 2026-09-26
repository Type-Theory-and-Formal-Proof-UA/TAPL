# Типи та мови програмування (переклад)

Ukrainian translation of *Types and Programming Languages* (Benjamin C. Pierce,
MIT Press, 2001), typeset with [Typst](https://typst.app/).

**Read online:** <https://type-theory-and-formal-proof-ua.github.io/TAPL/>
(HTML edition, one page per chapter; PDF: [`tapl-uk.pdf`](https://type-theory-and-formal-proof-ua.github.io/TAPL/tapl-uk.pdf)).

The translation is in progress. A chapter appears in the published book only
when every part of it is translated; the rest is left out until it is finished.

## Layout

```
out/<part>/uk.typ        the translation, one file per part of the book
templates/preamble.typ   shared Typst preamble: page and text setup, chapter
                         and section headings, numbered statement environments
                         (#thm, #lem, #defn, #exr, …), #code, #rules, #rule,
                         #figure, #tbl, #eqn — each with a PDF and an HTML mode
manifest.json            the parts of the book, in order, with their titles
fonts/                   STIX Two Text (SIL OFL), bundled for reproducible builds
scripts/build_site.py    assembles the book from finished parts and builds it
scripts/split_html.py    cuts Typst's single-page HTML export into pages
```

The original book and the text extracted from it are copyrighted and are not
part of this repository.

## Building

Requires the [Typst CLI](https://github.com/typst/typst) 0.15 and Python 3.

```sh
python3 scripts/build_site.py   # -> site/index.html, site/ch01.html, …, site/tapl-uk.pdf
```

Code listings in the PDF are typeset with [codly](https://typst.app/universe/package/codly)
(`@preview/codly:1.3.0`, fetched by Typst on first build, so the first build needs
network access); OCaml listings are syntax-highlighted. The HTML edition uses a
plain highlighted `<pre>` block instead, because codly's grids cannot be exported
to HTML.

The script includes every chapter whose parts all exist, builds the PDF, builds
the HTML edition (`typst compile --features html`, still experimental in Typst;
math is emitted as MathML, block layouts such as inference rules and tables as
inline SVG) and splits it into `index.html` (contents), `preface.html`,
`ch01.html`, … `appB.html`.

## Publishing

`.github/workflows/pages.yml` runs the build on every push to `main` and deploys
`site/` to GitHub Pages (repository **Settings → Pages → Source: GitHub
Actions**). The Typst version is pinned in the workflow's `TYPST_VERSION`.
