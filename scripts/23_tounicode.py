#!/usr/bin/env python3
"""Parse each font's ToUnicode CMap: the authoritative code point -> Unicode map.
Where a font lacks ToUnicode, fall back to its builtin encoding array."""
import fitz, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

# fonts of interest and the pages they are used on
targets = {
    "LucidaNewMath-Arrows": [2575, 2686],
    "LucidaNewMath-Extension": [2579, 2704],
    "XYATIP10": [2581, 2696],
    "XYBTIP10": [2580, 2700],
    "XYDASH10": [2584],
    "LucidaNewMath-Symbol": [2574, 2671],
    "LucidaNewMath-Roman": [2578, 2658],
    "LucidaBrightSmallcaps": [2573, 2668],
}


def parse_tounicode(s):
    m = {}
    for a, b, u in re.findall(r"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>", s):
        start, end, uni = int(a, 16), int(b, 16), u
        # uni may be multi-char UTF-16BE
        try:
            ch = bytes.fromhex(uni).decode("utf-16-be")
        except Exception:
            ch = f"<{uni}>"
        for c in range(start, end + 1):
            m[c] = ch
    return m


for fam, xrefs in targets.items():
    for xref in xrefs:
        tu = doc.xref_get_key(xref, "ToUnicode")
        if tu[0] != "xref":
            print(f"\n### {fam} xref {xref}: no ToUnicode (enc array only)")
            enc = doc.xref_get_key(xref, "Encoding")
            print("   Encoding:", enc)
            continue
        _, num = tu
        cmap_xref = int(num.split()[0])
        s = doc.xref_stream(cmap_xref)
        if s is None:
            print(f"### {fam} xref {xref}: stream missing"); continue
        text = s.decode("latin-1")
        m = parse_tounicode(text)
        codes = sorted(c for c in m if c < 32 or c >= 0xE000)
        print(f"\n### {fam} xref {xref}  ToUnicode entries {len(m)}, "
              f"low/private {len(codes)}")
        for c in codes:
            print(f"    0x{c:04X} -> {m[c]!r}  U+{ord(m[c][0]):04X}" if m[c] else f"    0x{c:04X} -> ''")
