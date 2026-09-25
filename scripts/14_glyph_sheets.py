#!/usr/bin/env python3
"""Contact sheets for the mangled glyph codes, so the real symbol can be read off.

Font subsets in this PDF encode the same visual glyph as different code points
in different page ranges, so the mapping must be established from pixels, not
from the code point.  For each (code point, font) we crop a box around the span
that holds it, upscale, and tile the crops into one PNG with a label strip.
"""
import fitz, pathlib, collections, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
OUT = ROOT / "raw" / "glyphs"
OUT.mkdir(parents=True, exist_ok=True)

WANT = collections.defaultdict(list)      # (code, font) -> [(page, rect)]
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for s in line["spans"]:
                t = s["text"]
                if not any(ord(c) < 32 or 0xE000 <= ord(c) <= 0xF8FF for c in t):
                    continue
                for idx, c in enumerate(t):
                    o = ord(c)
                    if o < 32 or 0xE000 <= o <= 0xF8FF:
                        WANT[(o, s["font"])].append((pno, fitz.Rect(s["bbox"])))

if __name__ == "__main__":
    only = [int(x, 0) for x in sys.argv[1:]] or None
    for (o, f), hits in sorted(WANT.items(), key=lambda kv: (kv[0][0], kv[0][1])):
        if only and o not in only:
            continue
        print(f"U+{o:04X} {f:26s} {len(hits):4d} occurrences")
