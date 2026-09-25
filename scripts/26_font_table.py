#!/usr/bin/env python3
"""Build the authoritative code->Unicode table for every font subset in the PDF.

Two independent sources, in order of trust:
  1. the font object's ToUnicode CMap (what PyMuPDF already applies), and
  2. the font object's /Differences array (code -> glyph name), resolved through
     the Adobe Glyph List via fontTools.agl.toUnicode.

Only the codes that NEITHER source resolves are left, and those are reported
with the glyph name the PDF itself declares, so nothing is guessed.
"""
import fitz, pathlib, json, re, collections

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

try:
    from fontTools.agl import toUnicode as agl_to_unicode
    HAVE_AGL = True
except Exception:
    HAVE_AGL = False


def parse_cmap(s):
    m = {}
    for a, b, u in re.findall(r"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>", s):
        lo, hi = int(a, 16), int(b, 16)
        try:
            ch = bytes.fromhex(u).decode("utf-16-be")
        except Exception:
            continue
        for c in range(lo, hi + 1):
            m[c] = ch
    return m


# glyph names that AGL cannot resolve; shapes read off the rendered page
EXTRA_GLYPHS = {
    "star1": "\u2605", "star2": "\u2605", "star3": "\u2605", "star4": "\u2605",
    "star": "\u2605", "asteriskmath": "\u2217",
    "arrowbarright": "\u21a6", "arrowrightnot": "\u219b", "arrowext": "\u27f6",
    "arrowdblext": "\u27f9", "arrowtripleright": "\u21f6",
    "arrowtripleleft": "\u21f4", "square": "\u25a1",
    "uniondisplay": "\u22c3", "uniontext": "\u22c3",
    "braceleftBigg": "\u23a7", "bracerightBigg": "\u23a9",
    "bracketleftBigg": "\u23a1", "bracketrightBigg": "\u23a4",
    "bracelefttp": "\u23a7", "braceleftmid": "\u23aa", "braceleftbt": "\u23a9",
    "braceleftex": "\u23aa", "bracerighttp": "\u23a8", "bracerightmid": "\u23aa",
    "bracerightbt": "\u23a9", "bracerightex": "\u23aa",
    "bracketlefttp": "\u23a1", "bracketleftex": "\u23a2", "bracketleftbt": "\u23a3",
    "bracketrighttp": "\u23a4", "bracketrightex": "\u23a5", "bracketrightbt": "\u23a6",
    "bar": "|", "bardbl": "\u2016", "bullet": "\u2022",
    "element": "\u2208", "notelement": "\u2209", "subset": "\u2282",
    "union": "\u222a", "intersection": "\u2229",
    "asterisk": "*", "periodcentered": "\u00b7",
}


def glyph_to_unicode(name):
    if HAVE_AGL:
        try:
            u = agl_to_unicode(name)
            if u:
                return u
        except Exception:
            pass
    if name in EXTRA_GLYPHS:
        return EXTRA_GLYPHS[name]
    if name.startswith("uni") and len(name) >= 7:
        try:
            return chr(int(name[3:7], 16))
        except Exception:
            pass
    if name.startswith("u") and 5 <= len(name) <= 7:
        try:
            return chr(int(name[1:], 16))
        except Exception:
            pass
    return None


def parse_differences(xref):
    """Return {code: glyph_name} from the /Encoding /Differences array."""
    enc = doc.xref_get_key(xref, "Encoding")
    if enc[0] != "xref":
        return None, None
    num = int(enc[1].split()[0])
    obj = doc.xref_object(num, compressed=False)
    body = doc.xref_stream(num)
    text = (obj or "") + "\n" + (body.decode("latin-1") if body else "")
    out = {}
    for m in re.finditer(r"(\d+)\s*((?:/[^\s/\[\]]+\s*)+)", text):
        code = int(m.group(1))
        for g in re.findall(r"/([^\s/\[\]]+)", m.group(2)):
            out[code] = g
            code += 1
    return out, text[:200]


# ---- walk every font in the document ---------------------------------------
by_base = collections.defaultdict(set)
fonts = {}          # xref -> dict
for pno in range(doc.page_count):
    for f in doc[pno].get_fonts(full=True):
        xref = f[0]
        if xref in fonts:
            continue
        base = f[3].lstrip("/")
        by_base[base].add(xref)
        tu = doc.xref_get_key(xref, "ToUnicode")
        cmap = {}
        if tu[0] == "xref":
            sx = int(tu[1].split()[0])
            s = doc.xref_stream(sx)
            if s:
                cmap = parse_cmap(s.decode("latin-1"))
        diffs, _ = parse_differences(xref)
        fonts[xref] = {"base": base, "cmap": cmap, "diffs": diffs or {},
                       "enc": doc.xref_get_key(xref, "Encoding")}

print("fonts in document:")
for base in sorted(by_base):
    print(f"  {base:34s} xrefs {sorted(by_base[base])}")

# ---- which codes does PyMuPDF leave unmapped? ------------------------------
print("\n\ncodes NOT resolved by ToUnicode (the actual work set):")
table = {}
unresolved = collections.Counter()
for xref, info in sorted(fonts.items()):
    gaps = {}
    for c, g in sorted(info["diffs"].items()):
        if c < 32 or c >= 0xE000:
            if c in info["cmap"]:
                continue
            u = glyph_to_unicode(g)
            gaps[c] = (g, u)
            if u is None:
                unresolved[(info["base"], g)] += 1
    if gaps:
        table[xref] = {c: u for c, (g, u) in gaps.items() if u}
        print(f"\n  {info['base']} xref {xref}  enc={info['enc'][1] if info['enc'][0]=='name' else 'obj'}")
        for c, (g, u) in sorted(gaps.items()):
            print(f"     0x{c:04X}  /{g:22s} -> {u!r}" if u else
                  f"     0x{c:04X}  /{g:22s} -> UNRESOLVED")

print("\n\nunresolved glyph names (must be handled explicitly):")
for (b, g), n in unresolved.most_common():
    print(f"   {b:26s} /{g}")

out = {str(k): {str(c): v for c, v in t.items()} for k, t in table.items()}
(ROOT / "src" / "font_table.json").write_text(json.dumps(out, indent=1, ensure_ascii=False))
print(f"\nwrote src/font_table.json with {len(table)} xrefs, "
      f"{sum(len(t) for t in table.values())} mapped codes, agl={'yes' if HAVE_AGL else 'no'}")
