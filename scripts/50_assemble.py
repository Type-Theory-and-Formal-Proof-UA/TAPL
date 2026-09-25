#!/usr/bin/env python3
"""Assemble book/<unit>.typ include files and the full book, then compile.

  book/<unit>.typ   includes out/<part>/uk.typ in manifest order
  book/tapl-uk.typ  includes every unit, in book order
  build/tapl-uk.pdf the rendered book (only if every part exists)

A unit whose parts are not all translated is reported as incomplete and is left
out of the full book rather than silently producing a half chapter.
"""
import json, pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MAN = json.loads((ROOT / "manifest.json").read_text())
BOOK = ROOT / "book"
BUILD = ROOT / "build"

# the order units appear in the book
ORDER = ["front"] + [f"ch{i:02d}" for i in range(1, 33)] + \
        ["appA", "appB", "refs", "index"]


def main():
    BOOK.mkdir(exist_ok=True)
    BUILD.mkdir(exist_ok=True)
    byunit = {}
    for pid, m in MAN.items():
        byunit.setdefault(m["unit"], []).append((m.get("part", 1), pid))
    for u in byunit:
        byunit[u].sort()

    done, missing = [], []
    for uid in ORDER:
        if uid not in byunit:
            continue
        parts = byunit[uid]
        have = [(n, p) for n, p in parts
                if (ROOT / MAN[p]["output"]).exists()]
        if len(have) == len(parts):
            done.append(uid)
        else:
            missing.append((uid, len(have), len(parts)))
        body = ["// Згенеровано scripts/50_assemble.py — не редагувати вручну."]
        for _n, pid in parts:
            if (ROOT / MAN[pid]["output"]).exists():
                body.append(f'#include "/out/{pid}/uk.typ"')
        (BOOK / f"{uid}.typ").write_text("\n".join(body) + "\n", encoding="utf-8")

    full = ["// Згенеровано scripts/50_assemble.py — не редагувати вручну.",
            "// Типи та мови програмування — український переклад."]
    for uid in done:
        full.append(f'#include "/book/{uid}.typ"')
    (BOOK / "tapl-uk.typ").write_text("\n".join(full) + "\n", encoding="utf-8")

    print(f"частин у manifest: {len(MAN)}, готово одиниць: {len(done)}/{len(ORDER)}")
    for uid, h, n in missing:
        print(f"  неповна: {uid} ({h}/{n} частин)")
    if missing:
        print("\nповна книга не збирається, доки є неповні одиниці.")
        return 0
    r = subprocess.run(["typst", "compile", "--root", ".", "book/tapl-uk.typ",
                        "build/tapl-uk.pdf"], cwd=ROOT, capture_output=True, text=True)
    if r.returncode != 0:
        print("typst:", r.stderr.strip()[:600])
        return 1
    print("build/tapl-uk.pdf")
    return 0


if __name__ == "__main__":
    sys.exit(main())
