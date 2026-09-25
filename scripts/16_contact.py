#!/usr/bin/env python3
"""Build ONE contact sheet of every mangled glyph, labelled, as a single PDF page
rendered to PNG.  Each row: the code point + font, then up to 3 crops of the
glyph in context at 6x, each crop including ~30pt of preceding text so the
glyph can be read in situ.
"""
import fitz, pathlib, collections, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
OUT = ROOT / "raw" / "glyphs"
OUT.mkdir(parents=True, exist_ok=True)

WANT = collections.defaultdict(list)
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for s in line["spans"]:
                for c in s["text"]:
                    o = ord(c)
                    if o < 32 or 0xE000 <= o <= 0xF8FF:
                        WANT[(o, s["font"])].append((pno, fitz.Rect(s["bbox"]), c))

items = sorted(WANT.items())
rows = []
for (o, f), hits in items:
    # prefer a hit whose neighbours look text-like; take up to 2 distinct pages
    seen_pages, picks = set(), []
    for pno, rect, c in hits:
        if pno in seen_pages:
            continue
        seen_pages.add(pno)
        picks.append((pno, rect))
        if len(picks) == 2:
            break
    rows.append(((o, f), len(hits), picks))

PAGE_W, PAGE_H = 700, 100
out_doc = fitz.open()
page = out_doc.new_page(width=PAGE_W, height=PAGE_H)
y = 12
scale = 5.0
for (o, f), n, picks in rows:
    y += 46
    if y > PAGE_H - 60:
        page = out_doc.new_page(width=PAGE_W, height=PAGE_H)
        y = 40
    page.insert_text((10, y - 30), f"U+{o:04X}  {f}  n={n}", fontsize=9)
    x = 10
    for pno, rect in picks:
        clip = fitz.Rect(max(0, rect.x0 - 115), rect.y0 - 7, rect.x1 + 22, rect.y1 + 7)
        clip &= doc[pno].rect
        png = doc[pno].get_pixmap(matrix=fitz.Matrix(scale, scale), clip=clip).tobytes("png")
        w = (clip.x1 - clip.x0) * scale * 0.42      # fit into the row
        h = (clip.y1 - clip.y0) * scale * 0.42
        page.insert_image(fitz.Rect(x, y - 24, x + w, y - 24 + h), stream=png)
        page.insert_text((x, y + h - 18), f"p{pno+1}", fontsize=6)
        x += w + 8
        if x > PAGE_W - 120:
            break

out = OUT / "contact.pdf"
out_doc.save(out)
png = out_doc[0].get_pixmap(matrix=fitz.Matrix(2.0, 2.0))
name = OUT / "contact.png"
name.write_bytes(png.tobytes("png"))
print("rows:", len(rows), "pages:", len(out_doc), "->", name)
