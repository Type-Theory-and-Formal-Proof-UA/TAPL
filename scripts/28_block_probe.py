#!/usr/bin/env python3
"""Do display formulas form their own PyMuPDF text BLOCKS, separate from the
surrounding prose paragraphs? If yes, block membership is a clean display signal
and the remaining formula fragmentation can be fixed by grouping on blocks."""
import fitz, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

for pg in [int(a) for a in sys.argv[1:]] or [101]:
    pno = pg - 1
    print(f"\n=========== physical {pg}: text blocks")
    for i, blk in enumerate(doc[pno].get_text("dict")["blocks"]):
        lines = blk.get("lines", [])
        if not lines:
            continue
        txts = []
        for ln in lines:
            s = "".join(sp["text"] for sp in ln["spans"]).strip()
            if s:
                txts.append(s)
        if not txts:
            continue
        r = fitz.Rect(blk["bbox"])
        if r.y0 < 60 or r.y0 > 620:
            continue
        print(f"  block {i:3d} y={r.y0:6.1f}-{r.y1:6.1f} x={r.x0:6.1f} "
              f"lines={len(txts)}")
        for t in txts[:6]:
            print(f"        {t[:70]!r}")
