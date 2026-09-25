#!/usr/bin/env python3
"""Split Typst's single-page HTML export into one page per chapter.

    typst compile --features html --format html book/tapl-uk.typ build/book.html
    python3 scripts/split_html.py build/book.html site/

Typst emits every top-level heading as an <h2>; the table of contents is a
single <nav role="doc-toc"> and footnotes are collected in one
<section role="doc-endnotes"> at the end. This script

  * cuts the body at each <h2> into its own page (front matter, chapters,
    appendices, references),
  * turns the table of contents into index.html,
  * rewrites every intra-book `#anchor` link to `page.html#anchor`,
  * moves each footnote to the page that cites it,
  * adds previous / contents / next navigation and a small stylesheet.
"""
import html
import re
import sys
from pathlib import Path

PDF_NAME = "tapl-uk.pdf"

CSS = """
body { max-width: 46rem; margin: 0 auto; padding: 1rem 1rem 4rem;
       font: 18px/1.6 "Latin Modern Roman", "New Computer Modern", Georgia, serif; }
h2 { font-size: 1.9rem; margin: 1.5rem 0 1.2rem; }
h3 { font-size: 1.4rem; margin-top: 2rem; }
h4 { font-size: 1.15rem; }
a { color: #1a5fb4; }
table { border-collapse: collapse; margin: 1rem auto; }
/* long inline formulas cannot wrap: scroll them instead of widening the page;
   the vertical padding keeps tall math from triggering a vertical scrollbar */
div.scroll, div.al, p { overflow-x: auto; overflow-y: hidden; }
p, div.al { padding: .35em 0; }
p { margin: .65em 0; }
td, th { padding: .2rem .7rem; }
math[display] { overflow-x: auto; max-width: 100%; }
figure { margin: 1rem 0; }
svg { max-width: 100%; }
nav.pager { display: flex; justify-content: space-between; gap: 1rem;
            font-family: system-ui, sans-serif; font-size: .9rem; margin: 1rem 0; }
nav.pager span { flex: 1; }
nav.pager span:nth-child(2) { text-align: center; }
nav.pager span:last-child { text-align: right; }
nav[role=doc-toc] ol { padding-left: 1.4rem; }
nav[role=doc-toc] > ol > li { margin-top: .4rem; }
section[role=doc-endnotes] { border-top: 1px solid #999; margin-top: 3rem;
                             font-size: .9rem; }
h1.title { font-size: 2.3rem; margin-bottom: .3rem; }
p.authors { font-size: 1.2rem; margin-top: 0; }
"""


def text_of(fragment):
    return html.unescape(re.sub(r"<[^>]+>", "", fragment)).strip()


def wrap_tables(fragment):
    """Put every outermost <table> in a horizontally scrollable div (long
    formulas in table cells cannot wrap)."""
    out, depth, last = [], 0, 0
    for m in re.finditer(r"<table[ >]|</table>", fragment):
        if m.group(0).startswith("</"):
            depth -= 1
            if depth == 0:
                out += [fragment[last : m.end()], "</div>"]
                last = m.end()
        else:
            if depth == 0:
                out += [fragment[last : m.start()], '<div class="scroll">']
                last = m.start()
            depth += 1
    out.append(fragment[last:])
    return "".join(out)


UNNUMBERED = {
    "Передмова": "preface",
    "Розв’язки до вибраних вправ": "appA",
    "Список джерел": "refs",
    "Покажчик": "subject-index",
}

def slug_for(heading, seen_toc, front_index):
    """Page file name: chapters by their number (ch01…), appendices by their
    letter (appB); the unnumbered parts (preface, appendix A, references,
    index) by title."""
    title = text_of(heading)
    m = re.match(r"\s*([0-9]+|[A-Z])\s", title + " ")
    if not m:
        return UNNUMBERED.get(title, f"page-{front_index}")
    label = m.group(1)
    return f"ch{int(label):02d}" if label.isdigit() else f"app{label}"

def main(src, out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    doc = Path(src).read_text(encoding="utf-8")

    head_end = doc.index("</head>")
    head = doc[:head_end]
    title = html.unescape(re.search(r"<title>(.*?)</title>", head, re.S).group(1))
    authors = re.search(r'<meta name="authors" content="(.*?)"', head)
    authors = html.unescape(authors.group(1)) if authors else ""
    head = head.replace("<style>", f"<style>{CSS}\n", 1)  # ours first, Typst's math CSS after
    body = doc[doc.index("<body>") + 6 : doc.rindex("</body>")]

    # html.frame figures are inline SVGs whose glyph <symbol>s are defined once
    # in whichever SVG comes first and reused by <use> everywhere after it.
    # Every page needs its own copy of the symbols it references.
    symbols = {m.group(1): m.group(0)
               for m in re.finditer(r'<symbol id="([^"]+)".*?</symbol>', body, re.S)}

    toc = re.search(r'<nav role="doc-toc">.*?</nav>', body, re.S)
    toc_html = toc.group(0)
    body = body.replace(toc_html, "<!--TOC-->", 1)

    endnotes = re.search(r'<section role="doc-endnotes">(.*?)</section>', body, re.S)
    notes = []
    if endnotes:
        body = body.replace(endnotes.group(0), "")
        for li in re.finditer(r'<li id="([^"]+)">(.*?)</li>', endnotes.group(1), re.S):
            back = re.search(r'href="#([^"]+)"', li.group(2))
            notes.append((li.group(1), back.group(1), li.group(0)))

    # cut at <h2>; the marker for the TOC decides which side of it we are on
    starts = [m.start() for m in re.finditer(r"<h2[ >]", body)]
    toc_marker = body.index("<!--TOC-->")
    pages = []  # [slug, title, html]
    front = 0
    for i, s in enumerate(starts):
        e = starts[i + 1] if i + 1 < len(starts) else len(body)
        chunk = body[s:e]
        after_toc = s > toc_marker
        h = re.match(r"<h2[^>]*>(.*?)</h2>", chunk, re.S).group(1)
        if "<!--TOC-->" in chunk:  # the TOC sits at the tail of the last front-matter page
            chunk = chunk.replace("<!--TOC-->", "")
        front += not after_toc
        slug = slug_for(h, after_toc, front + i)
        assert all(slug != p[0] for p in pages), f"duplicate page name {slug}"
        pages.append([slug, h, chunk])

    # ids -> page file
    where = {}
    for slug, _, chunk in pages:
        for m in re.finditer(r'\bid="([^"]+)"', chunk):
            where[m.group(1)] = f"{slug}.html"
    # footnotes go to the page holding their citation
    by_page = {}
    for note_id, back_id, li in notes:
        by_page.setdefault(where[back_id], []).append(li)
        where[note_id] = where[back_id]

    def rewrite(fragment, current):
        def sub(m):
            target = where.get(m.group(1))
            if target is None:
                print(f"warning: dangling link #{m.group(1)}", file=sys.stderr)
                return m.group(0)
            return f'href="{"" if target == current else target}#{m.group(1)}"'

        return re.sub(r'(?<=\s)href="#([^"]+)"', sub, fragment)

    def with_symbols(fragment):
        defined = set(re.findall(r'<symbol id="([^"]+)"', fragment))
        missing = []
        todo = re.findall(r'xlink:href="#([^"]+)"', fragment)
        while todo:
            sid = todo.pop()
            if sid in defined or sid not in symbols:
                continue
            defined.add(sid)
            missing.append(symbols[sid])
            todo += re.findall(r'xlink:href="#([^"]+)"', symbols[sid])
        if not missing:
            return fragment
        return ('<svg width="0" height="0" style="position:absolute" aria-hidden="true">'
                f'<defs>{"".join(missing)}</defs></svg>{fragment}')

    def pager(i):
        def link(j, fmt):
            if not 0 <= j < len(pages):
                return "<span></span>"
            label = html.escape(text_of(pages[j][1]))
            return f'<span><a href="{pages[j][0]}.html">{fmt.format(label)}</a></span>'

        mid = '<span><a href="index.html">Зміст</a></span>'
        return f'<nav class="pager">{link(i - 1, "← {}")}{mid}{link(i + 1, "{} →")}</nav>'

    def page(page_title, content, nav):
        return (
            f"{head}</head><body>{nav}{content}{nav}</body></html>"
        ).replace(f"<title>{html.escape(title, quote=False)}</title>",
                  f"<title>{html.escape(page_title, quote=False)} — {html.escape(title, quote=False)}</title>", 1)

    for i, (slug, h, chunk) in enumerate(pages):
        content = chunk
        if f"{slug}.html" in by_page:
            content += '<section role="doc-endnotes"><ol style="list-style-type: none">' + "".join(
                by_page[f"{slug}.html"]) + "</ol></section>"
        content = with_symbols(wrap_tables(rewrite(content, f"{slug}.html")))
        (out / f"{slug}.html").write_text(
            page(text_of(h), content, pager(i)), encoding="utf-8")

    index_toc = rewrite(toc_html, "index.html")
    index_body = (
        f'<h1 class="title">{html.escape(title)}</h1>'
        f'<p class="authors">{html.escape(authors)}</p>'
        f'<p><a href="{PDF_NAME}">PDF</a></p>'
        f"{index_toc}"
    )
    (out / "index.html").write_text(f"{head}</head><body>{index_body}</body></html>", encoding="utf-8")
    print(f"wrote {len(pages) + 1} pages to {out}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(*sys.argv[1:])
