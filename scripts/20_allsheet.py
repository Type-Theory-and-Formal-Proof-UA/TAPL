#!/usr/bin/env python3
"""ONE tall contact sheet: every mangled (code point, font) with a high-zoom crop
of the glyph in context, labelled.  Single page, so one look identifies all."""
import fitz, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
OUT = ROOT / "raw" / "glyphs"

WANT = collections.defaultdict(list)
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for s in line["spans"]:
                for c in s["text"]:
                    o = ord(c)
                    if o < 32 or 0xE000 <= o <= 0xF8FF:
                        WANT[(o, s["font"])].append((pno, fitz.Rect(s["bbox"])))

items = sorted(WANT.items())
scale = 8.0
ROWS = len(items)
RH = 54
PW = 900
PH = ROWS * RH + 30
out = fitz.open()
page = out.new_page(width=PW, height=PH)
for i, ((o, f), hits) in enumerate(items):
    y = 20 + i * RH
    page.insert_text((8, y + 26), f"U+{o:04X} {f} n={len(hits)}", fontsize=8)
    pno, rect = hits[0]
    clip = fitz.Rect(rect.x0 - 42, rect.y0 - 6, rect.x0 + 62, rect.y1 + 6) & doc[pno].rect
    png = doc[pno].get_pixmap(matrix=fitz.Matrix(scale, scale), clip=clip).tobytes("png")
    w = (clip.x1 - clip.x0) * scale * 0.55
    h = (clip.y1 - clip.y0) * scale * 0.55
    page.insert_image(fitz.Rect(210, y, 210 + w, y + h), stream=png)
    page.insert_text((620, y + 26), f"p{pno+1}", fontsize=7)

png = out[0].get_pixmap(matrix=fitz.Matrix(1.6, 1.6))
name = OUT / "allsheet.png"
name.write_bytes(png.tobytes("png"))
print(name, f"{PW*1.6:.0f}x{PH*1.6:.0f}", "rows", ROWS)
