#!/usr/bin/env python3
"""For each (code point, font), print the page distribution and sample contexts
spread across the whole book, so a code point that means different things in
different font subsets can be told apart."""
import fitz, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

HITS = collections.defaultdict(list)
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            spans = line["spans"]
            txt = " ".join(x["text"] for x in spans)
            for s in spans:
                for c in s["text"]:
                    o = ord(c)
                    if o < 32 or 0xE000 <= o <= 0xF8FF:
                        marked = "".join(
                            f"[U+{ord(ch):04X}]" if (ord(ch) < 32 or 0xE000 <= ord(ch) <= 0xF8FF) else ch
                            for ch in txt)
                        HITS[(o, s["font"])].append((pno + 1, " ".join(marked.split())))

for (o, f), v in sorted(HITS.items()):
    pages = [p for p, _ in v]
    print(f"\n### U+{o:04X} {f}  n={len(v)}  pages {min(pages)}..{max(pages)}")
    # one sample per page-range bucket
    step = max(1, len(v) // 6)
    for p, t in v[::step][:6]:
        print(f"    p{p:4d} {t[:120]}")
