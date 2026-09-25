#!/usr/bin/env python3
"""Define the translation units from the PDF's own outline.

The outline (doc.get_toc()) lists every part, chapter and appendix with its
PHYSICAL page number, which is authoritative. Deriving boundaries from printed
folio numbers is not: front matter uses roman numerals, so the physical/printed
offset shifts and an off-by-one silently truncates a chapter's opening page.

Unit ids:  front, ch01..ch32, appA, appB, refs, index
"""
import fitz, pathlib, json, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
N = doc.page_count
toc = doc.get_toc()

# outline entries that start a chapter, an appendix or a back-matter section
CHAP = re.compile(r"^(\d{1,2})\s+(\S.*)$")
APPS = re.compile(r"^([AB])\s+(\S.*)$")
BACK = {"References": "refs", "Index": "index"}

starts = []
for lvl, title, pg in toc:
    t = title.strip()
    if t == "Contents":
        continue
    if t == "Preface":
        starts.append((pg, "front", t))
        continue
    m = CHAP.match(t)
    if m:
        starts.append((pg, f"ch{int(m.group(1)):02d}", m.group(2).strip()))
        continue
    m = APPS.match(t)
    if m:
        starts.append((pg, f"app{m.group(1)}", m.group(2).strip()))
        continue
    if t in BACK:
        starts.append((pg, BACK[t], t))
        continue
    if t == "Appendices":
        continue
    # part titles: "I Untyped Systems" etc. - keep as a boundary marker only
    starts.append((pg, None, t))

starts.sort()
units = {}
for i, (pg, uid, title) in enumerate(starts):
    if uid is None:
        continue
    nxt = N
    for pg2, uid2, _t2 in starts[i + 1:]:
        if pg2 > pg:
            nxt = pg2 - 1
            break
    units[uid] = {"first": pg, "last": nxt, "title": title}

# the Index runs to the end of the file
units["index"]["last"] = N

for uid, u in units.items():
    w = 0
    for p in range(u["first"] - 1, u["last"]):
        w += len(doc[p].get_text().split())
    u["pages"] = u["last"] - u["first"] + 1
    u["words"] = w

(ROOT / "src" / "units.json").write_text(json.dumps(units, indent=1, ensure_ascii=False))
tw = sum(u["words"] for u in units.values())
print(f"{len(units)} units, {tw:,} words, {N} pages\n")
print(f"{'unit':7s} {'pg':>5s} {'to':>5s} {'pages':>6s} {'words':>7s}  title")
for uid in sorted(units, key=lambda k: units[k]["first"]):
    u = units[uid]
    print(f"{uid:7s} {u['first']:5d} {u['last']:5d} {u['pages']:6d} {u['words']:7d}  {u['title']}")
