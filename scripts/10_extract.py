#!/usr/bin/env python3
"""Extract TAPL with PyMuPDF into per-unit text files with page markers.

Output: src/raw/<unit>.txt, each page preceded by  <<<P <physical> (printed <n>)>>>
Printed page number = physical page - 13 for the Arabic-numbered body (front
matter is roman), verified below against the page's own folio.

Ligatures are normalised (ﬁ→fi) and PUA big-brace glyphs are kept as their own
code points so the cleaner can map them.
"""
import fitz, pathlib, unicodedata, json, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

# unit -> (first physical page, last physical page inclusive), 1-based, from the
# PDF outline (scripts/00_recon.py)
UNITS = [
    ("front", 1, 23),
    ("ch01", 24, 37),
    ("ch02", 38, 43),
    ("partI", 44, 45),
    ("ch03", 46, 67),
    ("ch04", 68, 73),
    ("ch05", 74, 97),
    ("ch06", 98, 105),
    ("ch07", 106, 111),
    ("partII", 112, 113),
    ("ch08", 114, 121),
    ("ch09", 122, 135),
    ("ch10", 136, 139),
    ("ch11", 140, 171),
    ("ch12", 172, 175),
    ("ch13", 176, 193),
    ("ch14", 194, 201),
    ("partIII", 202, 203),
    ("ch15", 204, 231),
    ("ch16", 232, 243),
    ("ch17", 244, 247),
    ("ch18", 248, 269),
    ("ch19", 270, 287),
    ("partIV", 288, 289),
    ("ch20", 290, 303),
    ("ch21", 304, 337),
    ("partV", 338, 339),
    ("ch22", 340, 361),
    ("ch23", 362, 385),
    ("ch24", 386, 403),
    ("ch25", 404, 411),
    ("ch26", 412, 433),
    ("ch27", 434, 439),
    ("ch28", 440, 459),
    ("partVI", 460, 461),
    ("ch29", 462, 471),
    ("ch30", 472, 489),
    ("ch31", 490, 497),
    ("ch32", 498, 513),
    ("appA", 516, 587),
    ("appB", 588, 589),
    ("refs", 590, 627),
    ("index", 628, 646),
]

NORM = {
    "\ufb00": "ff", "\ufb01": "fi", "\ufb02": "fl", "\ufb03": "ffi", "\ufb04": "ffl",
    "\u00ad": "", "\u200b": "", "\u0000": "",
    "\u2018": "\u2019", "\u201B": "\u2019",   # left single quote in words -> right
}

out = ROOT / "src" / "raw"
out.mkdir(parents=True, exist_ok=True)
report = []
for unit, a, b in UNITS:
    buf = []
    for p in range(a - 1, b):
        t = doc[p].get_text()
        for k, v in NORM.items():
            t = t.replace(k, v)
        printed = p - 12          # 1-based physical page p+1 -> printed p+1-13
        buf.append(f"<<<P {p + 1} (printed {printed})>>>\n" + t)
    txt = "\n".join(buf)
    (out / f"{unit}.txt").write_text(txt, encoding="utf-8")
    body = re.sub(r"<<<P[^>]*>>>", " ", txt)
    words = len(re.findall(r"[^\s]+", body))
    report.append((unit, a, b, b - a + 1, words))

print(f"{'unit':8s} {'phys':>10s} {'pages':>6s} {'words':>8s}")
tot = 0
for unit, a, b, n, w in report:
    tot += w
    print(f"{unit:8s} {f'{a}-{b}':>10s} {n:6d} {w:8d}")
print(f"{'TOTAL':8s} {'':>10s} {'':>6s} {tot:8d}")
json.dump({u: {"first": a, "last": b, "pages": n, "words": w} for u, a, b, n, w in report},
          open(ROOT / "src" / "units.json", "w"), indent=2)
