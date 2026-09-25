#!/usr/bin/env python3
"""Split the cleaned units into translation parts and write manifest.json.

Parts are cut at SECTION boundaries (a "## " line), never inside a statement or
a figure block, so no environment is ever torn in half. A part holds at most
TARGET words unless a single section is longer than that, in which case that
section is split at subsection ("### ") boundaries instead.

  out/<part>/source.txt    the source slice a translator reads
  manifest.json            part -> unit, chapter, sections, words, paths
"""
import json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
UNITS = json.loads((ROOT / "src" / "units.json").read_text())
TARGET = 6000

# chapter number per unit, for #chap(num, title)
def chapnum(uid):
    if uid.startswith("ch") and uid[2:].isdigit():
        return str(int(uid[2:]))
    return ""


def title_of(uid):
    return UNITS[uid]["title"].strip()


def blocks(text):
    """Split into top-level blocks: a '## ' heading starts a new block; so does
    a statement or a chapter head at the top of the file."""
    lines = text.split("\n")
    out, cur = [], []
    for ln in lines:
        is_sec = bool(re.match(r"^## ", ln))
        is_stmt = ln.startswith("<<<STMT")
        if (is_sec or is_stmt) and cur and any(x.strip() for x in cur):
            out.append("\n".join(cur).strip("\n"))
            cur = []
        cur.append(ln)
    if cur:
        out.append("\n".join(cur).strip("\n"))
    return [b for b in out if b.strip()]


def sec_label(b):
    m = re.match(r"^## (\d+(?:\.\d+)?)\s*(.*)", b)
    if m:
        return (m.group(1) + " " + m.group(2)).strip()
    m = re.match(r"^<<<STMT ([0-9.]+)>>>", b)
    if m:
        return "(твердження " + m.group(1) + ")"
    return ""


def split_unit(uid):
    text = (ROOT / "src" / "clean" / f"{uid}.txt").read_text()
    bs = blocks(text)
    # pack blocks into parts
    parts, cur, nw = [], [], 0
    for b in bs:
        w = len(b.split())
        if cur and nw + w > TARGET:
            parts.append(cur)
            cur, nw = [], 0
        if w > TARGET:                       # an oversized single section
            # split it at sub-headings
            sub = re.split(r"(?m)^(?=### )", b)
            if len(sub) < 2:                 # no sub-headings: use paragraphs
                sub = [s + "\n" for s in b.split("\n\n") if s.strip()]
            chunk, cw = [], 0
            for s in sub:
                sw = len(s.split())
                if chunk and cw + sw > TARGET:
                    parts.append(chunk)
                    chunk, cw = [], 0
                chunk.append(s)
                cw += sw
            if chunk:
                if cur:
                    parts.append(cur)
                    cur, nw = [], 0
                parts.append(chunk)
            continue
        cur.append(b)
        nw += w
    if cur:
        parts.append(cur)
    # merge a small trailing chunk back into the previous one: a 300-word part
    # costs a whole agent for nothing, and the section boundary is still a clean
    # cut only if the part is worth translating on its own.
    merged = []
    for p in parts:
        w = sum(len(b.split()) for b in p)
        if merged and w < TARGET // 4:
            pw = sum(len(b.split()) for b in merged[-1])
            if pw + w <= TARGET * 1.25:
                merged[-1] = merged[-1] + p
                continue
        merged.append(p)
    return merged


def main():
    OUT = ROOT / "out"
    OUT.mkdir(exist_ok=True)
    manifest = {}
    for uid in sorted(UNITS, key=lambda u: UNITS[u]["first"]):
        if not (ROOT / "src" / "clean" / f"{uid}.txt").exists():
            continue
        parts = split_unit(uid)
        for i, chunk in enumerate(parts, 1):
            pid = uid if len(parts) == 1 else f"{uid}p{i:02d}"
            body = "\n\n".join(chunk).strip() + "\n"
            d = OUT / pid
            d.mkdir(parents=True, exist_ok=True)
            (d / "source.txt").write_text(body, encoding="utf-8")
            secs = [sec_label(b) for b in chunk if sec_label(b)]
            manifest[pid] = {
                "unit": uid,
                "chapter": chapnum(uid),
                "title": title_of(uid),
                "part": i,
                "parts": len(parts),
                "sections": secs,
                "words": len(body.split()),
                "stmts": body.count("<<<STMT"),
                "source": f"out/{pid}/source.txt",
                "output": f"out/{pid}/uk.typ",
            }
    (ROOT / "manifest.json").write_text(
        json.dumps(manifest, indent=1, ensure_ascii=False))
    tw = sum(m["words"] for m in manifest.values())
    print(f"{len(manifest)} parts, {tw:,} words\n")
    print(f"{'part':10s} {'words':>6s} {'stmts':>6s}  unit    sections")
    for pid, m in manifest.items():
        print(f"{pid:10s} {m['words']:6d} {m['stmts']:6d}  {m['unit']:5s}  "
              f"{len(m['sections'])} sections: {', '.join(m['sections'][:3])}"
              f"{' …' if len(m['sections']) > 3 else ''}")


if __name__ == "__main__":
    main()
