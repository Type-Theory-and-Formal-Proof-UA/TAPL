#!/usr/bin/env python3
"""Census of TAPL's numbered statements.

Every numbered statement is a pair of spans on one baseline:
    LucidaBright 9.0, x≈121-131   ->  "3.2.1"
    LucidaBrightSmallcaps 9.0     ->  "Deﬁnition [Terms, inductively]: ..."
plus sometimes a trailing box glyph.  So the kind word is the first word of the
smallcaps span, not of the next line.
"""
import fitz, pathlib, re, collections, json

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
UNITS = json.load(open(ROOT / "src" / "units.json"))

LIG = {"\ufb00": "ff", "\ufb01": "fi", "\ufb02": "fl", "\ufb03": "ffi", "\ufb04": "ffl"}


def norm(s):
    for k, v in LIG.items():
        s = s.replace(k, v)
    return s


NUM = re.compile(r"^(\d{1,2}\.\d{1,2}\.\d{1,2})$")
kinds = collections.Counter()
samples = collections.defaultdict(list)
total = 0

for unit, info in UNITS.items():
    if unit in ("front", "refs", "index"):
        continue
    for pno in range(info["first"] - 1, info["last"]):
        rows = []
        for blk in doc[pno].get_text("dict")["blocks"]:
            for line in blk.get("lines", []):
                for s in line["spans"]:
                    if s["text"].strip():
                        rows.append((round(s["bbox"][1], 1), round(s["bbox"][0], 1),
                                     round(s["size"], 1), s["font"], norm(s["text"].strip())))
        rows.sort()
        for i, (y, x, sz, f, t) in enumerate(rows):
            if not (NUM.match(t) and f == "LucidaBright" and sz == 9.0):
                continue
            if not (110 <= x <= 145):
                continue
            total += 1
            kind, text = "", ""
            # companion span: same baseline (|dy| < 3), x >= 160, smallcaps or body
            for yy, xx, ssz, ff, tt in rows:
                if abs(yy - y) < 3.0 and xx >= 155:
                    text = tt
                    break
            kind = re.split(r"[\s\[]", text)[0] if text else "<none>"
            kinds[kind] += 1
            if len(samples[kind]) < 4:
                samples[kind].append((pno + 1, t, text[:72]))

print(f"total numbered statements: {total}\n")
for k, v in kinds.most_common():
    print(f"{v:5d}  {k!r}")
print()
for k in sorted(samples):
    print("==", k)
    for s in samples[k]:
        print("   ", s)

# also: the trailing box glyph census (end-of-proof / end-of-example)
boxes = collections.Counter()
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for s in line["spans"]:
                t = s["text"].strip()
                for ch in t:
                    if ord(ch) < 32 or 0xE000 <= ord(ch) <= 0xF8FF:
                        boxes[(hex(ord(ch)), s["font"])] += 1
print("\ncontrol/PUA code points:", boxes.most_common(30))
