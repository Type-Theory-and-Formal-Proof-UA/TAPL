#!/usr/bin/env python3
"""Can the DRAWN boxes on a page delimit figures?

TAPL draws every rule/figure as a rectangle (vector ops already confirmed present
on 67 pages). If those rectangles reliably enclose a figure's spans, the cleaner
can assign spans to a figure region mechanically instead of relying on font
family — which is what lets figure text leak into the surrounding prose today.

Usage: python3 scripts/29_box_probe.py <physical page> [...]
"""
import fitz, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))


def boxes(page):
    """Rectangle candidates from the page's vector drawings, merged."""
    out = []
    for d in page.get_drawings():
        r = fitz.Rect(d["rect"])
        if r.width < 60 or r.height < 18:
            continue
        out.append(r)
    return out


for pg in [int(a) for a in sys.argv[1:]] or [71]:
    page = doc[pg - 1]
    bs = boxes(page)
    print(f"\n===== physical {pg}: {len(page.get_drawings())} drawings, "
          f"{len(bs)} box candidates")
    for r in bs:
        inside = []
        for blk in page.get_text("dict")["blocks"]:
            for ln in blk.get("lines", []):
                for sp in ln["spans"]:
                    if not sp["text"].strip():
                        continue
                    c = fitz.Rect(sp["bbox"]).tl
                    if r.x0 - 1 <= c.x <= r.x1 + 1 and r.y0 - 1 <= c.y <= r.y1 + 1:
                        inside.append(sp["text"])
        if not inside:
            continue
        txt = " ".join(inside)
        print(f"  box {r.x0:6.1f},{r.y0:6.1f} - {r.x1:6.1f},{r.y1:6.1f} "
              f"spans={len(inside):3d}  {txt[:78]!r}")
