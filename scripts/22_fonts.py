#!/usr/bin/env python3
"""Extract the embedded font programs and look for a ToUnicode CMap, which maps
a subset's private code points to real Unicode - the authoritative answer."""
import fitz, pathlib, re, zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
OUT = ROOT / "raw" / "fonts"
OUT.mkdir(parents=True, exist_ok=True)

seen = {}
for pno in range(doc.page_count):
    for f in doc[pno].get_fonts(full=True):
        xref, ext, typ, base, name, enc, refname = f[:7]
        if xref in seen:
            continue
        info = {"xref": xref, "ext": ext, "type": typ, "base": base, "enc": enc}
        try:
            name2, ext2, typ2, buf = doc.extract_font(xref)
            info["bytes"] = len(buf)
            (OUT / f"{xref}_{re.sub(r'[^A-Za-z0-9]', '_', base)}.{ext or 'bin'}").write_bytes(buf)
        except Exception as e:
            info["bytes"] = f"ERR {e}"
        # ToUnicode presence
        try:
            tu = doc.xref_get_key(xref, "ToUnicode")
            info["ToUnicode"] = tu
        except Exception as e:
            info["ToUnicode"] = f"ERR {e}"
        seen[xref] = info

for xref, i in sorted(seen.items()):
    print(f"xref {xref:5d} {i['base']:28s} {i['type']:22s} enc={i['enc']} "
          f"bytes={i['bytes']} ToUnicode={i['ToUnicode']}")
