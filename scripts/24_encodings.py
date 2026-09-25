#!/usr/bin/env python3
"""Dump each font's /Encoding object (/Differences => glyph names per code) and
the font program's builtin encoding, which resolves the private code points that
ToUnicode leaves out."""
import fitz, pathlib, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

targets = {
    "LucidaNewMath-Arrows": [2575, 2686],
    "LucidaNewMath-Extension": [2579, 2704],
    "XYATIP10": [2581, 2696],
    "XYBTIP10": [2580, 2700],
    "XYDASH10": [2584],
    "LucidaBrightSmallcaps": [2573, 2668],
    "LucidaBright-Demi": [2643, 2663, 2802],
    "LucidaSans-Typewriter": [2571, 2690],
}

for fam, xrefs in targets.items():
    for xref in xrefs:
        enc = doc.xref_get_key(xref, "Encoding")
        print(f"\n=== {fam} xref {xref} Encoding={enc}")
        if enc[0] == "xref":
            num = int(enc[1].split()[0])
            s = doc.xref_object(num)
            print("    ", s[:1500].replace("\n", " "))
        elif enc[0] == "name":
            print("    builtin:", enc[1])
            # builtin encoding lives in the font program; look at /FontDescriptor
        fd = doc.xref_get_key(xref, "FontDescriptor")
        print("    FontDescriptor:", fd)
        base_font = doc.xref_get_key(xref, "BaseFont")
        print("    BaseFont:", base_font)
