#!/usr/bin/env python3
"""Dump the real font inventory and row geometry for chosen physical pages, so
the cleaner's rules are grounded in data instead of guesses."""
import fitz, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

for pg in [int(a) for a in sys.argv[1:]] or [54]:
    pno = pg - 1
    print(f"\n================ physical page {pg}")
    print("fonts:")
    seen = {}
    for f in doc[pno].get_fonts(full=True):
        xref, ext, ftype, base, name, enc = f[0], f[1], f[2], f[3], f[4], f[5]
        seen.setdefault(base, xref)
        print(f"   xref={xref:5d} base={base:34s} enc={enc:6s} ref={name}")
    print("rows (baseline, x, size, font, text):")
    raw = []
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for s in line["spans"]:
                if s["text"].strip():
                    raw.append(s)
    raw.sort(key=lambda s: (round(s["origin"][1], 1), s["bbox"][0]))
    for s in raw:
        t = s["text"]
        t = "".join(ch if ord(ch) >= 32 else f"<{ord(ch):02X}>" for ch in t)
        print(f"   b={s['origin'][1]:7.2f} x={s['bbox'][0]:7.2f} "
              f"sz={s['size']:5.2f} {s['font']:32s} {t!r}")
