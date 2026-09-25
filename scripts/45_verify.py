#!/usr/bin/env python3
"""Verify a translated part against its source slice.

Checks (each one is a real failure mode seen in the sibling ATTаPL project):
  1. the EXACT statement numbers and kinds in the source appear, in the same
     printed order, with the right environment;
  2. every figure block and caption survived;
  3. no ASCII apostrophe inside a Ukrainian word (the target requires U+2019);
  4. no leftover TODO;
  5. no long run of untranslated English prose;
  6. the file compiles with typst.

EXEMPTION for the back matter: the bibliography and the index are legitimately
English — STYLE.md §1 keeps author names, paper titles and publication venues in
the original, so `refs*`/`index` are exempt from check 5 (there is nothing to
translate there but the connective words). The exemption is keyed on the manifest
title, not on a per-file flag, so a chapter cannot accidentally acquire it.

Usage: python3 scripts/45_verify.py [part ...]      (default: all)
"""
import json, pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MAN = json.loads((ROOT / "manifest.json").read_text())
SCRATCH = pathlib.Path("/Users/ihor/.hermes/cache/scratch")

KIND2ENV = {
    "Definition": "defn", "Definitions": "defn", "Theorem": "thm",
    "Lemma": "lem", "Corollary": "cor", "Proposition": "prop_",
    "Claim": "claim", "Notation": "notation", "Convention": "convention",
    "Fact": "fact", "Axiom": "axiom", "Example": "example",
    "Remark": "remark", "Exercise": "exr", "Principle": "principle",
    "Note": "note_", "Solution": "solution", "Answer": "solution",
}
ENV2KIND = {}
for _k, _v in KIND2ENV.items():
    ENV2KIND.setdefault(_v, _k)

# Some kinds share one environment ('Definition' and 'Definitions' both map to
# `defn`), so the reverse map can hold only one spelling. Compare on the
# singular form of the source kind word instead of on the raw word.
_KINDS_SING = {k.rstrip("s") for k in KIND2ENV}

# environment call: #env("1.2.3")  — the number is positional and explicit
CALL = re.compile(r"#([a-z_0-9]+)\(\s*\"([0-9]+(?:\.[0-9]+)*)\"")
# only the statement environments carry a number; #chap("4", …) must not count
STMT_ENVS = tuple(KIND2ENV.values())

EN_STOP = re.compile(
    r"\b(the|this|that|which|with|from|such|then|when|where|there|their|"
    r"however|therefore|suppose|assume|proof|holds|implies|since|because)\b",
    re.I)


def source_items(part):
    src = (ROOT / MAN[part]["source"]).read_text()
    items = []
    for m in re.finditer(r"<<<STMT ([0-9.]+)>>>\n([^\n]*)", src):
        w = re.match(r"^([A-Za-z]+)", m.group(2).strip())
        kind = w.group(1) if w else "?"
        items.append((m.group(1), kind.rstrip("s") if kind.rstrip("s") in _KINDS_SING else kind))
    secs = re.findall(r"(?m)^## (\d+(?:\.\d+)?)", src)
    # A caption, not a cross-reference: the book prints "Figure 21-1: Sample tree
    # types." and refers to it in running text as "Figure 21-1 illustrates...".
    # Requiring the colon separates the two, and the leading `\s*\[?` is needed
    # because the cleaner only sometimes brackets the caption and usually indents
    # it — without it the caption count silently read 0 for ch21p01/ch21p02 (and
    # undercounted 15 parts in all), so the caption check below ran on a short
    # list and could not report the captions it never saw.
    caps = re.findall(r"(?m)^\s*\[?(?:Figure|Table)\s+([A-Z]?\d*[-.]\d+)\s*:", src)
    return {
        "items": items,
        # A figure is identified by its CAPTION, not by a figure-body block: the
        # cleaner emits those for display formulas too (they share the math font
        # families), and a display formula carries no caption. Counting blocks
        # therefore reported dozens of phantom "missing figures" on the
        # formula-dense chapters.
        "figs": len(caps),
        "caps": caps,
        "blocks": src.count("<<<FIGURE-BODY>>>"),
        "secs": secs,
        "subsecs": len(re.findall(r"(?m)^### ", src))
                    + len(re.findall(r"(?m)^#### ", src)),
    }


def actual(part):
    uk = ROOT / MAN[part]["output"]
    if not uk.exists():
        return None
    t = uk.read_text()
    got = [(num, ENV2KIND.get(env, "?" + env)) for env, num in CALL.findall(t)
           if env in STMT_ENVS]
    # singularize both sides so 'Definition' and 'Definitions' compare equal
    got = [(n, k.rstrip("s") if k.rstrip("s") in _KINDS_SING else k) for n, k in got]
    return {"text": t, "items": got,
            # count figures the same way the source does: by caption
            "figs": len(re.findall(r"#(?:figure|tbl)\("
                                   r"\[(?:Рисунок|Таблиця) [A-Z]?\d*[-.]\d+", t)),
            "blocks": len(re.findall(r"#(?:figure|tbl)\(", t))
                      + len(re.findall(r"#code\[", t)),
            "caps": re.findall(r"#(?:figure|tbl)\(\[(?:Рисунок|Таблиця) ([A-Z]?\d*[-.]\d+)", t),
            "secs": re.findall(r"#sec\(\"(\d+(?:\.\d+)?)\"", t),
            "subsecs": len(re.findall(r"#sub(?:sub)?sec\(", t))}


def check(part):
    exp, act = source_items(part), actual(part)
    problems, notes = [], []
    if act is None:
        return [f"файл {MAN[part]['output']} відсутній"], [], {}
    t = act["text"]

    # 1. statement numbers and kinds, in printed order
    if exp["items"] != act["items"]:
        e, a = exp["items"], act["items"]
        if len(e) != len(a):
            problems.append(f"тверджень: у джерелі {len(e)}, у перекладі {len(a)}")
        for i, (x, y) in enumerate(zip(e, a)):
            if x != y:
                problems.append(f"твердження #{i + 1}: джерело {x}, переклад {y}")
                break
    # 2. figures: every source caption reproduced; block count reported as a note
    #    only, since display formulas legitimately produce extra blocks.
    if act["blocks"] < exp["blocks"] and act["blocks"] < exp["figs"]:
        problems.append(f"блоків рисунків: у джерелі {exp['blocks']}, "
                        f"у перекладі {act['blocks']}")
    # 2b. figure/table captions: each printed number must reappear translated
    missing = [c for c in exp["caps"] if c not in act["caps"]]
    if missing:
        problems.append(f"немає підписів до рисунків/таблиць: {missing}")
    # 2c. sections: every source section number must be emitted as #sec
    miss_sec = [s for s in exp["secs"] if s not in act["secs"]]
    if miss_sec:
        problems.append(f"немає розділів: {miss_sec}")
    extra_sec = [s for s in act["secs"] if s not in exp["secs"]]
    if extra_sec:
        problems.append(f"зайві розділи: {extra_sec}")
    # 2d. sub-heads: a dropped #subsec/#subsubsec silently loses structure
    if exp["subsecs"] and act["subsecs"] < exp["subsecs"]:
        problems.append(f"підрозділів: у джерелі {exp['subsecs']}, "
                        f"у перекладі {act['subsecs']}")
    # 3. apostrophe
    bad = re.findall(r"[А-Яа-яЇїІіЄєҐґ]'[А-Яа-яЇїІіЄєҐґ]", t)
    if bad:
        problems.append(f"апостроф ' замість ’: {len(bad)} місць, напр. {bad[:5]}")
    # 4. TODO
    if "TODO" in t:
        problems.append("лишився маркер TODO")
    # 5. untranslated prose (English stopwords are absent from Ukrainian)
    #    Strip everything that legitimately stays English first: OCaml/source
    #    listings, inference-rule names, Typst symbol names, and math. Without
    #    this the check fires 44 times on chapter 3 purely from `with`/`then`/
    #    `from` inside code and rule names, drowning the real signal.
    probe = re.sub(r"#raw\(\"[^\"]*\"\)", " ", t)
    probe = re.sub(r"#rule\(\[[^\]]*\],\s*\"[^\"]*\"", " ", probe)
    probe = re.sub(r"\$[^$]*\$", " ", probe)
    probe = re.sub(r"#(?:code|rules|figure|tbl)\[[^\]]*\]", " ", probe)
    hits = EN_STOP.findall(probe)
    if len(hits) > 25 and MAN[part].get("title") not in ("References", "Index"):
        problems.append(f"схоже на неперекладений англійський текст: {len(hits)} збігів")
    # 6. compile
    pdf = SCRATCH / f"{part}.pdf"
    r = subprocess.run(["typst", "compile", "--root", ".", MAN[part]["output"],
                        str(pdf)], cwd=ROOT, capture_output=True, text=True)
    if r.returncode != 0:
        problems.append("typst: " + r.stderr.strip().split("\n")[0][:200])
    else:
        # 7. literal macro leaks in the RENDER. `#sec`/`#subsec`/`#chap`/`#exr`
        #    splice their argument into a heading with `#title`; when that
        #    argument is passed as a *string* instead of content, math in it is
        #    printed verbatim — `F$lt:$` and `$T = \"Top\"$` reached the page in
        #    five parts before scripts/49_fix_headings.py converted them. A `$`
        #    surviving into the rendered text is always this bug (real math is
        #    typeset and extracts as the glyphs, never as a dollar sign), so it is
        #    a hard failure rather than a note. Checking the render, not the
        #    source, is what makes it catch string-argument misuse anywhere.
        rendered = subprocess.run(["pdftotext", str(pdf), "-"],
                                  capture_output=True, text=True).stdout
        if "$" in rendered:
            leaks = [ln.strip()[:70] for ln in rendered.split("\n") if "$" in ln]
            problems.append(f"у рендері видно літеральний '$': {len(leaks)} рядків, "
                            f"напр. {leaks[0]!r}")
    return problems, notes, {"words": len(t.split()), "compiled": r.returncode == 0,
                             "stmts": len(exp["items"]), "figs": exp["figs"]}


def main():
    parts = sys.argv[1:] or list(MAN)
    results, bad = [], 0
    for p in parts:
        if p not in MAN:
            print(f"{p}: немає в manifest.json")
            bad += 1
            continue
        probs, notes, info = check(p)
        if probs:
            bad += 1
        print(f"{'OK  ' if not probs else 'FAIL'} {p:10s} "
              f"{info.get('words', 0):6d} слів  {info.get('stmts', 0):4d} тверджень  "
              f"{info.get('figs', 0):4d} рисунків  compiled={info.get('compiled')}")
        for x in probs:
            print(f"       ! {x}")
        for x in notes:
            print(f"       ~ {x}")
        results.append({"part": p, "status": "ok" if not probs else "fail",
                        "problems": probs, "notes": notes, "info": info})
    (ROOT / "verify.json").write_text(json.dumps(results, indent=1, ensure_ascii=False))
    print(f"\n{len(parts) - bad}/{len(parts)} частин без проблем")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())