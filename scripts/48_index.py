#!/usr/bin/env python3
"""Re-extract the TAPL index with its TWO COLUMNS separated.

30_clean.py puts a page's spans into one row list, so on the index — whose every
page is set in two columns — the left and right columns interleave line by line
and the result is unreadable ("∈ alternate notation for type mem- bers, 92 /
⇒ arrow kind, 441"). Structure recovery for a two-column page needs the column
break, which is not a font or a size: it is an x gap that no span straddles.

The gap is found per page, from the spans themselves, so no column width is
hard-coded: histogram the span starts, then take the widest stretch of empty x
that separates two dense clusters. Entry continuation lines (an entry wrapped
onto the next line, printed at a deeper indent) are joined to the entry above
only when the next line starts at the continuation indent.

Usage:  python3 scripts/48_index.py            -> out/index/source.txt
"""
import fitz, pathlib, json, re, collections

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
UNITS = json.load(open(ROOT / "src" / "units.json"))
TABLE = {int(k): {int(c): u for c, u in v.items()}
         for k, v in json.loads((ROOT / "src" / "font_table.json").read_text()).items()}

EXTRA = {"trianglerightsld": "\u25b7", "turnstileleft": "\u22a2", "prime": "\u2032",
         "sharp": "\u266f", "subsetsqequal": "\u2ac5", "negationslash": "\u2260",
         "angbracketleft": "\u27e8", "angbracketright": "\u27e9"}
LIG = {"\ufb00": "ff", "\ufb01": "fi", "\ufb02": "fl", "\ufb03": "ffi",
       "\ufb04": "ffl", "\ufb05": "ft", "\ufb06": "st"}

SUBSET = {}
for _p in range(doc.page_count):
    _m = {}
    for _f in doc[_p].get_fonts(full=True):
        _m.setdefault(_f[3].lstrip("/"), _f[0])
    SUBSET[_p] = _m


def decode(text, xref):
    out = []
    for ch in text:
        o = ord(ch)
        if o < 32 or 0xE000 <= o <= 0xF8FF:
            if o in TABLE.get(xref, {}):
                out.append(TABLE[xref][o])
            continue
        out.append(ch)
    s = "".join(out)
    s = re.sub(r"\(cid:\d+\)", "", s)
    for k, v in LIG.items():
        s = s.replace(k, v)
    return s


def spans_of(pno):
    out = []
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for sp in line["spans"]:
                if not sp["text"]:
                    continue
                base = sp["font"]
                xr = SUBSET.get(pno, {}).get(base, -1)
                raw = decode(sp["text"], xr)
                # The word gap at a font change lives in the RAW span text as a
                # leading/trailing space (" see also"), not in the geometry: the
                # italic run starts at x == the previous bbox's x1, so an x-gap test
                # sees nothing. Stripping it away glued "see alsoderived forms"
                # together throughout the index, so record the edges before stripping.
                out.append({"b": round(sp["origin"][1], 1), "x": sp["bbox"][0],
                            "x1": sp["bbox"][2], "size": round(sp["size"], 2),
                            "t": raw.strip(), "lead": raw[:1] == " ",
                            "trail": raw[-1:] == " "})
    return out


def line_rows(spans):
    rows, cur = [], []
    for s in sorted(spans, key=lambda s: (s["b"], s["x"])):
        if cur and abs(cur[0]["b"] - s["b"]) > 1.6:
            rows.append(cur)
            cur = []
        cur.append(s)
    if cur:
        rows.append(cur)
    return rows


def column_split(spans):
    """The widest empty x-stretch between two clusters of span starts.

    Computed on BODY spans only: the running head and the folio sit in the outer
    margins (x≈63 on the verso, x≈485 on the recto), and that margin gap is far
    wider than the real inter-column gutter, so including them made every verso
    page split at x≈113 — inside the left column — and the two columns then
    interleaved exactly as they had before.
    """
    body = [s for s in spans if s["b"] > 60]
    xs = sorted({round(s["x"]) for s in body})
    best, cut = 0, None
    for a, b in zip(xs, xs[1:]):
        # ignore the small gaps inside a word or an indent step (and any gap
        # narrower than the gutter a two-column index must have)
        if b - a > best and b - a > 18:
            best, cut = b - a, (a + b) / 2
    return cut


def build():
    info = UNITS["index"]
    out, seen_head = [], set()
    for pno in range(info["first"] - 1, info["last"]):
        spans = spans_of(pno)
        if not spans:
            continue
        cut = column_split(spans)
        # drop the running head ("Index" + folio) above the body
        body = [s for s in spans if s["b"] > 60]
        head = [s for s in spans if s["b"] <= 60]
        if head and pno not in seen_head:
            seen_head.add(pno)
        for col in (0, 1):
            if cut is None:
                sel = body if col == 0 else []
            else:
                sel = ([s for s in body if s["x"] < cut] if col == 0
                       else [s for s in body if s["x"] >= cut])
            if not sel:
                continue
            for row in line_rows(sel):
                row.sort(key=lambda s: s["x"])
                t = ""
                prev = None
                for s in row:
                    if not s["t"]:
                        continue
                    if s["lead"] and t and not t.endswith(" "):
                        t += " "
                    elif prev is not None and s["x"] - prev > 1.2 and t \
                            and not t.endswith((" ", "-", "(")) \
                            and s["t"][:1] not in ".,;:!?)]’”“":
                        t += " "
                    t += s["t"]
                    if s["trail"] and not t.endswith(" "):
                        t += " "
                    prev = s["x1"]
                t = t.strip()
                if t:
                    out.append((pno + 1, col, t, round(min(s["x"] for s in row), 1)))
    return out


# An index entry's nesting is its indent, and the indent is a font-independent x:
# main entries start at the column's left edge, sub-entries ~8.1pt in, and
# sub-sub-entries ~8.2pt further. Recovering the level from x (rather than from a
# flat list) is what keeps "booleans, 23–44 / see also Church encodings" a child of
# its parent instead of a sibling of every other entry on the page.
# A wrapped index line is indented exactly like a sub-entry, so indent alone cannot
# tell "wrapped continuation" from "sub-entry". Two shapes are unambiguous, and only
# those are joined:
#   * the previous line ends with a hyphen ("bottom-up subexpressions of a recur-" /
#     "sive type, 304");
#   * this line carries nothing but page numbers ("algorithmic subtyping, 209–213,
#     417–" / "436").
# A first attempt also joined any line starting lowercase, which swallowed every
# legitimate lowercase sub-entry ("Amber, 311" + "rule, 311, 312" became one entry),
# because index entries — main ones included ("alpha-conversion") — start lowercase
# constantly. Content shape, not case, is the discriminator.
PAGENUMS = re.compile(r"^[0-9][0-9,\s.\u2013-]*$")


def join_wrapped(rows):
    """Join a wrapped entry to its continuation, dropping ONLY the line-break hyphen.

    The hyphen removal has to happen at the join, not as a blanket pass over the
    finished text: `(?<=[a-z])-(?=[a-z])` also deletes the real hyphens of
    `user-defined` and `ad-hoc`, which then read `userdefined` and `adhoc`. So the
    join records that it consumed a break hyphen and removes that one character.
    """
    out = []          # (pno, col, text, x, break_hyphen_removed)
    for pno, col, t, x in rows:
        prev = out[-1] if out else None
        if prev is not None:
            # A trailing dash continues the entry. It is a WORD-BREAK hyphen when the
            # continuation starts a word ("bottom-up subexpressions of a recur-" +
            # "sive type") and must be deleted; it is a PAGE RANGE when the
            # continuation is a page number ("algorithmic subtyping, 209–213, 417–" +
            # "436") and must be kept. Dropping it unconditionally printed 417436.
            if prev[2][-1:] in "-–—":
                if PAGENUMS.match(t):
                    out[-1] = (prev[0], prev[1], prev[2] + t, prev[3], prev[4])
                else:
                    out[-1] = (prev[0], prev[1], prev[2][:-1] + t, prev[3], True)
                continue
            if PAGENUMS.match(t):
                out[-1] = (prev[0], prev[1], prev[2] + " " + t, prev[3], prev[4])
                continue
        out.append((pno, col, t, x, False))
    return [(p, c, t, x) for p, c, t, x, _h in out]


def levels(rows):
    """Assign each row an indent level from its x, per page and per column."""
    out = [[p, c, t, x] for p, c, t, x in rows]
    base = {}
    for r in out:
        key = (r[0], r[1])
        base[key] = min(base.get(key, r[3]), r[3])
    for r in out:
        d = r[3] - base[(r[0], r[1])]
        r.append(0 if d < 4 else (1 if d < 12 else 2))
    return [(r[0], r[1], r[2], r[4]) for r in out]


if __name__ == "__main__":
    rows = levels(join_wrapped(build()))
    dst = ROOT / "out" / "index" / "source.txt"
    dst.parent.mkdir(parents=True, exist_ok=True)
    lines = ["  " * lvl + t for _pno, _col, t, lvl in rows]
    dst.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{len(rows)} рядків -> {dst}")
    for _p, c, t, lvl in rows[:20]:
        print(f"  c{c} L{lvl} {t[:74]}")
    print("  ...")
    for _p, c, t, lvl in rows[60:76]:
        print(f"  c{c} L{lvl} {t[:74]}")
