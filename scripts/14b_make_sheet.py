#!/usr/bin/env python3
"""Build a labelled contact sheet of glyph crops.

Usage:  python3 14b_make_sheet.py OUTNAME WxH code1 code2 ...   (codes in hex like 0x07)
        python3 14b_make_sheet.py OUTNAME WxH --page 57 code ...  (a whole page strip)
"""
import fitz, pathlib, collections, sys, math

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

WANT = collections.defaultdict(list)
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for s in line["spans"]:
                t = s["text"]
                for c in t:
                    o = ord(c)
                    if o < 32 or 0xE000 <= o <= 0xF8FF:
                        WANT[(o, s["font"])].append((pno, fitz.Rect(s["bbox"])))


def crop_for(page, rect, pad=14, scale=4):
    r = fitz.Rect(rect.x0 - pad, rect.y0 - pad, rect.x1 + pad, rect.y1 + pad)
    r &= doc[page].rect
    return doc[page].get_pixmap(matrix=fitz.Matrix(scale, scale), clip=r).tobytes("png")


def main():
    out = ROOT / "raw" / "glyphs" / (sys.argv[1] + ".png")
    args = sys.argv[2:]
    per_cell = 3          # crops per code point, side by side
    imgs = []
    for a in args:
        code = int(a, 0)
        for (o, f), hits in sorted(WANT.items()):
            if o != code:
                continue
            pick = hits[:per_cell]
            for pno, rect in pick:
                imgs.append((f"U+{o:04X} {f[:14]} p{pno+1}", crop_for(pno, rect)))
    print("crops:", len(imgs), "->", out)
    # save each crop as its own file; the caller views them individually
    for i, (label, png) in enumerate(imgs):
        p = ROOT / "raw" / "glyphs" / f"{sys.argv[1]}_{i:03d}_{label.replace(' ','_').replace('/','_')}.png"
        p.write_bytes(png)
    for i, (label, _) in enumerate(imgs):
        print(f"  {i:03d} {label}")


if __name__ == "__main__":
    main()
