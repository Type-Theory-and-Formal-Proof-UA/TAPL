#!/usr/bin/env python3
"""Recover the heading tree of TAPL by font/size style, then diff it against the
book's own printed Contents page (the gate from the skill)."""
import fitz, pathlib, json, re, collections

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

STYLE = collections.Counter()
for p in range(len(doc)):
    for b in doc[p].get_text("dict")["blocks"]:
        for l in b.get("lines", []):
            for s in l["spans"]:
                if s["text"].strip():
                    STYLE[(s["font"], round(s["size"], 1))] += len(s["text"])

print("-- most common (font,size) --")
for k, v in STYLE.most_common(20):
    print(f"   {k[0]:24s} {k[1]:5.1f} {v:8d}")
