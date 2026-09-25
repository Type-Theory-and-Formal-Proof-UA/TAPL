#!/usr/bin/env python3
"""Clean TAPL into structure-marked text, one file per unit.

This is the ONLY structural extractor; everything downstream (split, verify,
assemble) reads its output.

Markers
    <<<CHAPNUM 3>>>                  chapter / part number
    # Untyped Arithmetic Expressions  chapter or part title
    ## 2.3 Sequences                  section (number joined to its title)
    ### 2.2.1 Formalities             subsection
    #### Case T-App:                  subsubsection
    <<<STMT 3.2.1>>>                  numbered statement; kind+text follows
    [Figure 3-1: Booleans (B)]        figure caption, closing its block
    <<<FIGURE-BODY>>> ... <<<END-FIGURE-BODY>>>   figure content, indented 4
    ^^^ footnote text                 7.33pt page footnote

WHY THIS SHAPE (all three were wrong in the first attempt, verified by dumping
raw spans with scripts/25_probe.py):

  * Rows are grouped by BASELINE ORIGIN (span["origin"][1]), never bbox top.
    In a statement the number (LucidaBright 8.97, x~121), the kind word
    (LucidaBrightSmallcaps 8.97), and the body (LucidaNewMath, Typewriter) all
    share ONE baseline; bbox tops differ per font size and split them apart.
  * A statement is therefore detected on the JOINED row text
    ("2.2.10  Deﬁnition:  Suppose ..."), matching a number in the gutter.
    Do not require the row to be the number alone: it never is.
  * Section head = LucidaBright-Demi at 10.52pt (number x~131, title x~166);
    subsection = LucidaBright-Demi at 9.7pt. Subsubsection heads (e.g.
    "Induction on depth:") are LucidaBright-Italic 8.97 at x~180.
  * Body/prose, footnotes and figure text are ALL LucidaBright 8.97 / 7.33 and
    are told apart by x and size only, not by font.

Mangled glyph codes are resolved PER FONT SUBSET. TAPL's embedded subsets remap
the same visual glyph to different code points per subset, so a code means
different things on different pages. The table is built by
scripts/26_font_table.py from the PDF's own /Differences arrays resolved through
the Adobe Glyph List, and stored in src/font_table.json; the handful of glyph
names AGL cannot resolve are listed with their shapes in EXTRA below.
XYATIP10 / XYBTIP10 / XYDASH10 carry XY-pic picture pieces (/d7, /d23, /d119,
/d127 ...), i.e. no text at all: dropped, counted, never joined to a sentence.
"""
import fitz, pathlib, json, re, sys, collections, importlib.util

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
UNITS = json.load(open(ROOT / "src" / "units.json"))

# ---- glyph resolution ------------------------------------------------------
# glyph names the Adobe Glyph List does not know; shapes read off the page
EXTRA = {
    "trianglerightsld": "\u25b7", "turnstileleft": "\u22a2", "prime": "\u2032",
    "sharp": "\u266f", "subsetsqequal": "\u2ac5", "negationslash": "\u2260",
    "angbracketleft": "\u27e8", "angbracketright": "\u27e9",
    "bracehtipupleft": "\u23cb", "bracehtipupright": "\u23cc",
    "bracehtipdownleft": "\u23cb", "bracehtipdownright": "\u23cc",
}
# per-xref overrides, keyed by the xref strings in src/font_table.json
TABLE = {int(k): {int(c): u for c, u in v.items()}
         for k, v in json.loads((ROOT / "src" / "font_table.json").read_text()).items()}
# the early Arrows subset is 1-based over the SAME order as the late one; both
# now live in the table, so no hand-written map is needed here.

LIG = {"\ufb00": "ff", "\ufb01": "fi", "\ufb02": "fl", "\ufb03": "ffi",
       "\ufb04": "ffl", "\ufb05": "ft", "\ufb06": "st"}

PROSE = "LucidaBright"
HEAD = "LucidaBright-Demi"
TITLE = "LucidaBright-DemiItalic"
ITAL = "LucidaBright-Italic"
CAP = re.compile(r"^(Figure|Table)\s+\d+[-.]\d+\s*:")
NUMROW = re.compile(r"^(\d{1,2}(?:\.\d{1,2}){0,2})\s+(.+)$")
# the kind word a numbered statement opens with, in the book's own spellings
KINDW = re.compile(
    "^(De(?:fi|f\ufb01)ni\\w*|Theorem|Lemma|Corollary|Proposition|Claim|Notation|"
    "Convention|Fact|Axiom|Example|Remark|Exercise|Principle|Note|Figure|Table|"
    "Solution|Answer)\\b")
DROP_STATS = collections.Counter()

# page -> {font base name: xref}, so a code is read with its own subset
SUBSET = {}
for _p in range(doc.page_count):
    _m = {}
    for _f in doc[_p].get_fonts(full=True):
        _m.setdefault(_f[3].lstrip("/"), _f[0])
    SUBSET[_p] = _m


def resolve_glyph(name):
    if name in EXTRA:
        return EXTRA[name]
    if name.startswith("uni") and len(name) >= 7:
        try:
            return chr(int(name[3:7], 16))
        except ValueError:
            return None
    return None


def decode(text, xref, base):
    """Map a span's private/control code points through its own subset table."""
    out = []
    for ch in text:
        o = ord(ch)
        if o < 32 or 0xE000 <= o <= 0xF8FF:
            if o in TABLE.get(xref, {}):
                out.append(TABLE[xref][o])
                continue
            m = re.match(r"^d(\d+)$", "")        # placeholder, see below
            DROP_STATS[(base, f"0x{o:02X}")] += 1
            continue
        out.append(ch)
    s = "".join(out)
    if "(cid:" in s:                             # PyMuPDF's unresolved-glyph form
        s = re.sub(r"\(cid:(\d+)\)", "", s)
    for k, v in LIG.items():
        s = s.replace(k, v)
    return s


def tidylines(s):
    """Rejoin words the PDF hyphenated across a line break."""
    return s


def page_rows(pno):
    """Rows = spans sharing a BASELINE, in reading order.

    Sub- and superscripts are separate spans at 6.56pt sitting on their own
    baselines (about 1.3pt below/above the base). Grouping strictly by baseline
    therefore peels them into fragments of their own, which shreds every stacked
    display formula (the shifting and substitution definitions in chapter 6 came
    out as dozens of empty blocks). Each small script span is instead attached to
    the nearest span on an adjacent baseline that it horizontally follows — that
    is what it modifies — so a formula stays one line.
    """
    raw = []
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for sp in line["spans"]:
                if not sp["text"]:
                    continue
                base = sp["font"]
                xr = SUBSET.get(pno, {}).get(base, -1)
                raw.append({"b": sp["origin"][1], "x": sp["bbox"][0],
                            "x1": sp["bbox"][2], "size": round(sp["size"], 2),
                            "font": base, "t": decode(sp["text"], xr, base),
                            "script": sp["size"] < 7.5})
    raw = [r for r in raw if r["t"]]
    raw.sort(key=lambda r: (round(r["b"], 1), r["x"]))

    # attach every small script span to the base span it decorates
    bases = [r for r in raw if not r["script"]]
    attached = []
    for r in raw:
        if not r["script"]:
            continue
        best, bd = None, None
        for c in bases:
            db = abs(c["b"] - r["b"])
            if db > 3.5 or c["x1"] > r["x"] + 1.5:
                continue
            d = (db, r["x"] - c["x1"])
            if bd is None or d < bd:
                best, bd = c, d
        if best is not None:
            best.setdefault("scripts", []).append(r)
        else:
            attached.append(r)              # stray script: keep it as its own row
    raw = [r for r in bases + attached]
    raw.sort(key=lambda r: (round(r["b"], 1), r["x"]))
    rows, cur = [], []
    for r in raw:
        if cur and abs(cur[0]["b"] - r["b"]) > 1.5:
            rows.append(cur)
            cur = []
        cur.append(r)
    if cur:
        rows.append(cur)
    out = []
    for grp in rows:
        grp.sort(key=lambda r: r["x"])
        spans = []
        for r in grp:
            spans.append((r["font"], r["t"], r["x"], r["x1"]))
            # a script is written directly after its base: no space, no marker
            for s in sorted(r.get("scripts", []), key=lambda s: s["x"]):
                spans.append((s["font"], s["t"], s["x"], s["x1"]))
        out.append({"b": round(min(r["b"] for r in grp), 1),
                    "x": round(min(r["x"] for r in grp), 1),
                    "x1": round(max(r["x1"] for r in grp), 1),
                    "size": max(r["size"] for r in grp),
                    "font": max(grp, key=lambda r: len(r["t"]))["font"],
                    "spans": spans})
    return out


def join(row):
    parts, prev = [], None
    for font, txt, x0, x1 in row["spans"]:
        # A LONG arrow is drawn in TWO pieces: LucidaNewMath-Arrows /arrowext
        # (the shaft extension, mapped to U+27F6) followed by
        # LucidaNewMath-Symbol `→` (the head). Concatenating both emits "⟶→"
        # where the book prints one ⟶ — 374 sites across the book. The pair is
        # one glyph, so when the head arrives directly after its extension the
        # head is dropped. Measured on the book's own index legend: the
        # evaluation line is 1.97pt extension + 7.67pt head = 9.64pt, versus
        # 7.67pt for the plain `→` of "function type" — i.e. the printed glyph
        # really is the long arrow, so the extension must be KEPT and the
        # redundant head dropped, not the other way round.
        # A LONG arrow is drawn in TWO pieces: LucidaNewMath-Arrows (the shaft
        # extension, mapped to the long form U+27F6/U+27F8/U+27F9) followed by
        # LucidaNewMath-Symbol (the head `→`/`⇐`/`⇒`). Concatenating both emits
        # "⟶→" where the book prints one ⟶ — 374 sites, plus the double-arrow
        # twins "⟹⇒"/"⇐⟸" used for proof directions. The pair is one glyph, so
        # when the head arrives directly after its own extension the head is
        # dropped. Measured on the book's own index legend: the evaluation line
        # is 1.97pt extension + 7.67pt head = 9.64pt, versus 7.67pt for the
        # plain `→` of "function type" — i.e. the printed glyph really is the
        # long arrow, so the extension is KEPT and the redundant head dropped.
        # The extension span sometimes carries a leading space (w≈4.2pt), which
        # is real spacing and must survive.
        _EXT_HEAD = {"\u27f6": "\u2192", "\u27f8": "\u21d0", "\u27f9": "\u21d2"}
        if parts and "Arrows" not in font and txt:
            last = parts[-1].rstrip(" ")
            for ext, head in _EXT_HEAD.items():
                if last.endswith(ext) and txt.startswith(head):
                    parts[-1] = parts[-1][: parts[-1].rfind(ext) + 1]
                    txt = txt[1:]
                    break
            if not txt.strip():
                prev = x1
                continue
        if prev is not None:
            nxt = txt[:1]
            tight = nxt in ".,;:!?)]}\u2019\u201d%\u2032\u2033|"
            opens = parts and parts[-1][-1:] in "([{\u201c\u2018"
            if (x0 - prev) > 1.2 and nxt.isalnum() and not opens and parts \
                    and not parts[-1].endswith(" ") and not txt.startswith(" "):
                parts.append(" ")
        parts.append(txt)
        prev = x1
    return "".join(parts).strip()


PROSE_FAMS = ("LucidaBright",)
FIG_FAMS = ("LucidaSans-Typewriter", "LucidaNewMath", "XY")
X_PROSE_MIN, X_PROSE_MAX = 150, 508


def prose_spans(row):
    """Spans that can only belong to running prose: upright serif text at the
    prose column's x. A row's dominant font says nothing (a body line naming a
    term is mostly Typewriter), so classification keys on this instead."""
    return [(f, t, x0, x1) for f, t, x0, x1 in row["spans"]
            if f in PROSE_FAMS and X_PROSE_MIN <= x0 <= X_PROSE_MAX]


def kind_of(row, t):
    f, sz, x, b = row["font"], row["size"], row["x"], row["b"]
    fonts = {s[0] for s in row["spans"]}
    if b < 62 or b > 608:
        return "skip"                            # running head, folio
    if TITLE in fonts:
        return "chapter"
    if "LucidaSans-Demi" in fonts:
        return "chapnum"
    if CAP.match(t) and x <= 95:
        return "cap"                             # caption sits in the wide margin
    heads = [s for s in row["spans"] if s[0] == HEAD]
    if heads:
        hs = max(s[0] and row["size"] for s in heads)
        if row["size"] >= 19:
            return "part"
        if row["size"] >= 10.0:
            return "sec"
        if row["size"] >= 9.5:
            return "sub"
        return "figlbl"
    # unnumbered italic sub-head ("Proof:", "Case T-App:", "Induction on depth:")
    # is a whole italic row ending in a colon, not a figure line at the same x
    if fonts == {ITAL} and 8.7 <= sz <= 9.1 and t.endswith(":") \
            and len(t) < 72 and x < 300:
        return "sub"
    if fonts == {"LucidaBrightSmallcaps"}:
        return "smallcap"
    if sz <= 7.6 and b > 400 and prose_spans(row):
        return "foot"
    if prose_spans(row):
        # a bare digit or operator at figure coordinates (x far from the prose
        # column) is a superscript fragment of a figure, not a paragraph line
        if len(t) <= 3 and not any(c.isalpha() for c in t):
            return "fig"
        return "body"
    return "fig"


def build(unit):
    info = UNITS[unit]
    items = []
    for pno in range(info["first"] - 1, info["last"]):
        rows = page_rows(pno)
        for row in rows:
            t = join(row)
            if not t:
                continue
            k = kind_of(row, t)
            if k == "skip":
                continue
            # a numbered item in the gutter: statement, section or subsection
            if row["x"] <= 152:
                m = NUMROW.match(t)
                if m and KINDW.match(m.group(2)):
                    items.append(("stmt", m.group(1), m.group(2).strip()))
                    continue
                if m and re.fullmatch(r"\d{1,2}\.\d{1,2}", m.group(1)):
                    items.append(("secnum", m.group(1), m.group(2).strip()))
                    continue
                if m and re.fullmatch(r"\d{1,2}\.\d{1,2}\.\d{1,2}", m.group(1)):
                    items.append(("subnum", m.group(1), m.group(2).strip()))
                    continue
                if re.fullmatch(r"\d{1,2}\.\d{1,2}", t):
                    items.append(("secnum", t, ""))
                    continue
            items.append((k, t, ""))

    # a section number and its title are separate rows on the same baseline:
    # fold the title into the numbered row that precedes it
    folded = []
    for i, it in enumerate(items):
        # a numbered gutter row whose title came out as a separate row
        if it[0] in ("secnum", "subnum") and not it[2] \
                and i + 1 < len(items) and items[i + 1][0] in ("sec", "sub", "body"):
            folded.append((it[0], it[1], items[i + 1][1]))
            items[i + 1] = ("used", "", "")
            continue
        if it[0] in ("secnum", "subnum") and not it[2] and i + 1 < len(items) \
                and items[i + 1][0] in ("secnum", "subnum") and items[i + 1][2]:
            folded.append((it[0], it[1], items[i + 1][2]))
            items[i + 1] = ("used", "", "")
            continue
        # a chapter opener whose title is set on two lines: the kicker
        # ("An ML Implementation of Arithmetic") sits above the number line
        # ("4 Expressions"). Both rows carry the TITLE font, so join them and
        # read the chapter number off the leading digits of the second row.
        if it[0] == "chapter" and i + 1 < len(items) \
                and items[i + 1][0] == "chapter":
            m2 = re.match(r"^(\d{1,2})\s+(.*)$", items[i + 1][1])
            if m2:
                folded.append(("chaphead", m2.group(1), it[1] + " " + m2.group(2)))
                items[i + 1] = ("used", "", "")
                continue
        if it[0] == "chapter":
            m2 = re.match(r"^(\d{1,2})\s+(.*)$", it[1])
            if m2:
                folded.append(("chaphead", m2.group(1), m2.group(2)))
                continue
        # a caption split over rows ("Figure 5-1:" then its title) is one block
        if it[0] == "cap" and not re.search(r"\d+[-.]\d+\s*:\s*\S", it[1]) \
                and i + 1 < len(items) and items[i + 1][0] in ("cap", "figlbl", "sub"):
            folded.append(("cap", (it[1] + " " + items[i + 1][1]).strip(), ""))
            items[i + 1] = ("used", "", "")
            continue
        folded.append(it)
    items = [i for i in folded if i[0] != "used"]

    lines, fig_open = [], False

    def closefig():
        nonlocal fig_open
        if fig_open:
            lines.extend(["<<<END-FIGURE-BODY>>>", ""])
            fig_open = False

    for k, t, extra in items:
        if k in ("fig", "figlbl"):
            # a lone prime or digit is a superscript fragment of a nearby text
            # line, not a figure: emitting it as figure content splits the
            # paragraph in two and invents an empty figure block. Only attach it
            # while no real figure is open; inside one, keep every line.
            if k == "fig" and not fig_open and len(t) <= 2 \
                    and not any(c.isalpha() for c in t):
                if lines and lines[-1] != "":
                    lines[-1] = lines[-1] + t
                    continue
            if not fig_open:
                if lines and lines[-1] != "":
                    lines.append("")
                lines.append("<<<FIGURE-BODY>>>")
                fig_open = True
            lines.append("    " + t)
            continue
        closefig()
        if k == "chaphead":
            lines += ["", "<<<CHAPTER " + t + ">>>", "# " + extra, ""]
        elif k == "chapter":
            lines += ["", "# " + t, ""]
        elif k == "part":
            lines += ["", "<<<PART " + t + ">>>", ""]
        elif k == "chapnum":
            lines.append("<<<CHAPNUM " + t + ">>>")
        elif k == "sec":
            lines += ["", "## " + t, ""]
        elif k == "sub":
            lines += ["", "### " + t, ""]
        elif k == "cap":
            lines += ["[" + t + "]", ""]
        elif k == "secnum":
            lines += ["", "## " + t + (" " + extra if extra else ""), ""]
        elif k == "subnum":
            lines += ["", "### " + t + (" " + extra if extra else ""), ""]
        elif k == "stmt":
            lines += ["", "<<<STMT " + t + ">>>"]
            if extra:
                lines.append(extra)
        elif k == "smallcap":
            lines.append(t)
        elif k == "foot":
            lines.append("^^^ " + t)
        else:
            lines.append(t)
    closefig()
    return re.sub(r"\n{3,}", "\n\n", "\n".join(lines)).strip() + "\n"


if __name__ == "__main__":
    want = sys.argv[1:] or sorted(UNITS)
    OUT = ROOT / "src" / "clean"
    OUT.mkdir(parents=True, exist_ok=True)
    print(f"{'unit':8s} {'srcw':>7s} {'clnw':>7s} {'sec':>4s} {'stmt':>5s} "
          f"{'cap':>4s} {'foot':>5s} {'fig':>5s} {'drop':>5s}")
    for unit in want:
        text = build(unit)
        (OUT / f"{unit}.txt").write_text(text, encoding="utf-8")
        print(f"{unit:8s} {UNITS[unit]['words']:7d} {len(re.findall(chr(92)+'S+', text)):7d} "
              f"{len(re.findall(r'(?m)^## ', text)):4d} {text.count('<<<STMT'):5d} "
              f"{text.count('[Figure') + text.count('[Table'):4d} "
              f"{text.count('^^^'):5d} {text.count('<<<FIGURE-BODY>>>'):5d} "
              f"{sum(DROP_STATS.values()):5d}")
    print("\nunresolved code points dropped (recorded):")
    for (b, c), n in DROP_STATS.most_common(40):
        print(f"   {b:26s} {c} {n}")
