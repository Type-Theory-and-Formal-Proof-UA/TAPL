"""Build the site published by GitHub Pages: the HTML edition (one page per
chapter, index.html = contents) and site/tapl-uk.pdf.

Includes every unit whose parts are all translated, in book order. Units that
are only partly translated are left out until their last part lands.
"""
import json, pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MAN = json.loads((ROOT / "manifest.json").read_text())
BOOK = ROOT / "book"
SITE = ROOT / "site"
BUILD = ROOT / "build"

ORDER = ["front"] + [f"ch{i:02d}" for i in range(1, 33)] + \
        ["appA", "appB", "refs", "index"]

def main():
    BOOK.mkdir(exist_ok=True)
    SITE.mkdir(exist_ok=True)
    byunit = {}
    for pid, m in MAN.items():
        byunit.setdefault(m["unit"], []).append((m.get("part", 1), pid))

    done, todo = [], []
    for uid in ORDER:
        parts = sorted(byunit.get(uid, []))
        if not parts:
            continue
        have = [pid for _n, pid in parts if (ROOT / MAN[pid]["output"]).exists()]
        if len(have) < len(parts):
            todo.append(uid)
            continue
        # A unit split into parts repeats its `#chap(...)` heading at the top of
        # every part; keep it only in the first, or the book shows the heading
        # (and the HTML page) once per part.
        lines = []
        for i, pid in enumerate(have):
            if i == 0:
                lines.append(f'#include "/out/{pid}/uk.typ"\n')
                continue
            src = (ROOT / MAN[pid]["output"]).read_text(encoding="utf-8")
            body = "".join(l for l in src.splitlines(keepends=True)
                           if not l.startswith("#chap("))
            (BOOK / f"{pid}.typ").write_text(body, encoding="utf-8")
            lines.append(f'#include "/book/{pid}.typ"\n')
        (BOOK / f"{uid}.typ").write_text("".join(lines), encoding="utf-8")
        done.append(uid)

    # `#set`/`#show` rules do not leak out of an imported module, so the page,
    # text and paragraph setup from the preamble is applied here, at the top level.
    pre = (ROOT / "templates" / "preamble.typ").read_text(encoding="utf-8")
    setup = pre[pre.index("#set page("):pre.index("// --- змінні стану")]
    head = ('#set document(title: "Типи та мови програмування", '
            'author: "Бенджамін К. Пірс")\n'
            '#let currentchapter = state("chapter", "")\n' + setup + "\n"
            # the contents page of the HTML edition (the PDF has no outlined headings)
            '#context if target() == "html" { outline(title: none, depth: 1) }\n')
    (BOOK / "tapl-uk.typ").write_text(
        head + "".join(f'#include "/book/{uid}.typ"\n' for uid in done), encoding="utf-8")

    common = ["--root", ".", "--font-path", "fonts", "--ignore-system-fonts"]
    steps = [
        ["typst", "compile", *common, "book/tapl-uk.typ", "site/tapl-uk.pdf"],
        # HTML export is still experimental in Typst, hence the feature flag.
        ["typst", "compile", "--features", "html", "--format", "html", *common,
         "book/tapl-uk.typ", "build/book.html"],
        # Typst emits one long page; cut it into one page per chapter.
        [sys.executable, "scripts/split_html.py", "build/book.html", "site"],
    ]
    BUILD.mkdir(exist_ok=True)
    for cmd in steps:
        r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
        if r.returncode != 0:
            print(r.stderr.strip()[:2000])
            return 1
    (SITE / ".nojekyll").touch()
    print(f"units in book: {len(done)}; still pending: {len(todo)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
