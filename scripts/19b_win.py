#!/usr/bin/env python3
"""Crop a generous window around the Nth occurrence of a code point, at high
zoom, so the glyph can be read together with its neighbours.
    python3 19b_win.py CODE [N] [halfwidth] [scale]
"""
import fitz, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
OUT = ROOT / "raw" / "glyphwin"
OUT.mkdir(parents=True, exist_ok=True)

code = int(sys.argv[1], 0)
want = int(sys.argv[2]) if len(sys.argv) > 2 else 0
half = float(sys.argv[3]) if len(sys.argv) > 3 else 40.0
scale = float(sys.argv[4]) if len(sys.argv) > 4 else 12.0

n = 0
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for s in line["spans"]:
                if any(ord(c) == code for c in s["text"]):
                    if n < want:
                        n += 1
                        continue
                    b = fitz.Rect(s["bbox"])
                    r = fitz.Rect(b.x0 - half, b.y0 - 7, b.x1 + half, b.y1 + 7)
                    r &= doc[pno].rect
                    name = OUT / f"w{code:04X}_{want:03d}_p{pno+1}.png"
                    name.write_bytes(doc[pno].get_pixmap(
                        matrix=fitz.Matrix(scale, scale), clip=r).tobytes("png"))
                    # textual neighbours
                    same = [x["text"] for x in line["spans"]]
                    print(f"U+{code:04X} #{want}: p{pno+1}  line={''.join(same)!r}")
                    print(name)
                    sys.exit(0)
print("not found")
