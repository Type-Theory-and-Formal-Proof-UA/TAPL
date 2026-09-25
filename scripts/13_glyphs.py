#!/usr/bin/env python3
"""Map every mangled glyph: list each control/PUA code point with contexts."""
import fitz, pathlib, collections, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

ctx = collections.defaultdict(list)
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            # reconstruct the line with markers for mangled chars
            for s in line["spans"]:
                t = s["text"]
                if not any(ord(c) < 32 or 0xE000 <= ord(c) <= 0xF8FF for c in t):
                    continue
                marked = "".join(f"<<U+{ord(c):04X}>>" if (ord(c) < 32 or 0xE000 <= ord(c) <= 0xF8FF)
                                 else c for c in t)
                full = " ".join(x["text"] for x in line["spans"])
                full_marked = "".join(
                    f"<<U+{ord(c):04X}>>" if (ord(c) < 32 or 0xE000 <= ord(c) <= 0xF8FF) else c
                    for c in full)
                for c in t:
                    o = ord(c)
                    if o < 32 or 0xE000 <= o <= 0xF8FF:
                        key = (o, s["font"])
                        if len(ctx[key]) < 4:
                            ctx[key].append((pno + 1, full_marked.strip()[:100]))

for (o, f), v in sorted(ctx.items(), key=lambda kv: (kv[0][0], kv[0][1])):
    print(f"U+{o:04X}  {f}")
    for p, c in v:
        print(f"     p{p:4d} {c}")
