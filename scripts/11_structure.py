#!/usr/bin/env python3
"""Recover TAPL's heading tree by style and check it against the book's own
Contents page.

Styles in this book:
  LucidaBright-DemiItalic 14.8  -> chapter / part opener title
  LucidaBright-Demi 10.5        -> top section ("1.2  ...")
  LucidaBright-Demi 9.7         -> subsection ("Syntax", ...)
  LucidaBright-Demi 9.0         -> subsubsection
  body                          -> LucidaBright 9.0 / 8.2
Running heads / captions are LucidaBright 8.2 / Smallcaps.
"""
import fitz, pathlib, json, re, collections, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
UNITS = json.load(open(ROOT / "src" / "units.json"))


def span_items(a, b):
    """Every non-empty span in a page range, in reading order."""
    items = []
    for p in range(a - 1, b):
        for blk in doc[p].get_text("dict")["blocks"]:
            for line in blk.get("lines", []):
                for s in line["spans"]:
                    if not s["text"].strip():
                        continue
                    items.append({"page": p + 1, "y": round(s["bbox"][1], 1),
                                  "x": round(s["bbox"][0], 1), "size": round(s["size"], 1),
                                  "font": s["font"], "text": s["text"].strip()})
    items.sort(key=lambda it: (it["page"], it["y"], it["x"]))
    return items


def is_heading(it):
    f, sz = it["font"], it["size"]
    return f.startswith("LucidaBright-Demi") and sz >= 9.0


if __name__ == "__main__":
    want = sys.argv[1:] or list(UNITS)
    for unit in want:
        info = UNITS[unit]
        items = span_items(info["first"], info["last"])
        heads = [it for it in items if is_heading(it)]
        print(f"===== {unit} p{info['first']}-{info['last']}  {info['words']} words, "
              f"{len(heads)} heading spans")
        seen = set()
        for h in heads:
            key = (h["page"], h["y"], h["text"][:30])
            if key in seen:
                continue
            seen.add(key)
            print(f"   p{h['page']:3d} y{h['y']:6.1f} sz{h['size']:5.1f} {h['font']:24s} {h['text'][:78]!r}")
