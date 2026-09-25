#!/usr/bin/env python3
"""Print every distinct (code point, font) with its surrounding text, so each
mangled glyph can be identified from context.  Font subsets in this PDF encode
the same visual glyph under different code points in different page ranges, so
a code point alone means nothing - the context decides."""
import fitz, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

CTX = collections.defaultdict(list)
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            spans = line["spans"]
            for si, s in enumerate(spans):
                if not any(ord(c) < 32 or 0xE000 <= ord(c) <= 0xF8FF for c in s["text"]):
                    continue
                full = "".join(
                    f"\u25cbU+{ord(c):04X}\u25cb" if (ord(c) < 32 or 0xE000 <= ord(c) <= 0xF8FF) else c
                    for c in " ".join(x["text"] for x in spans))
                full = " ".join(full.split())
                for c in s["text"]:
                    o = ord(c)
                    if o < 32 or 0xE000 <= o <= 0xF8FF:
                        key = (o, s["font"])
                        if len(CTX[key]) < 9:
                            CTX[key].append((pno + 1, full[:130]))

for (o, f), v in sorted(CTX.items()):
    print(f"\n=== U+{o:04X}  {f}   ({len(v)} samples)")
    for p, c in v:
        print(f"   p{p:4d} {c}")
