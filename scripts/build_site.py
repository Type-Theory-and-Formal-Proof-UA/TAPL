"""Build the site published by GitHub Pages: site/tapl-uk.pdf and site/index.html.

Includes every unit whose parts are all translated, in book order. Units that
are only partly translated are left out until their last part lands.
"""
import json, pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MAN = json.loads((ROOT / "manifest.json").read_text())
BOOK = ROOT / "book"
SITE = ROOT / "site"

ORDER = ["front"] + [f"ch{i:02d}" for i in range(1, 33)] + \
        ["appA", "appB", "refs", "index"]

INDEX = """<!doctype html>
<html lang="uk">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Типи та мови програмування — український переклад</title>
<style>
  body {{ font: 18px/1.6 system-ui, sans-serif; max-width: 40rem; margin: 3rem auto; padding: 0 1rem; }}
  a.btn {{ display: inline-block; padding: .6rem 1.2rem; background: #1a5fb4; color: #fff;
          border-radius: .4rem; text-decoration: none; }}
  small {{ color: #666; }}
</style>
</head>
<body>
<h1>Типи та мови програмування</h1>
<p>Український переклад книги Бенджаміна Пірса <em>Types and Programming Languages</em>.
Переклад триває; у збірці лише повністю перекладені розділи.</p>
<p>Перекладено розділів: {done}. Очікують: {todo}.</p>
<p><a class="btn" href="tapl-uk.pdf">Завантажити PDF</a></p>
<p><small>Зібрано {stamp}.</small></p>
</body>
</html>
"""


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
        (BOOK / f"{uid}.typ").write_text(
            "".join(f'#include "/out/{pid}/uk.typ"\n' for pid in have), encoding="utf-8")
        done.append(uid)

    # `#set`/`#show` rules do not leak out of an imported module, so the page,
    # text and paragraph setup from the preamble is applied here, at the top level.
    pre = (ROOT / "templates" / "preamble.typ").read_text(encoding="utf-8")
    setup = pre[pre.index("#set page("):pre.index("// --- змінні стану")]
    head = '#let currentchapter = state("chapter", "")\n' + setup + "\n"
    (BOOK / "tapl-uk.typ").write_text(
        head + "".join(f'#include "/book/{uid}.typ"\n' for uid in done), encoding="utf-8")

    r = subprocess.run(["typst", "compile", "--root", ".", "--font-path", "fonts",
                        "--ignore-system-fonts", "book/tapl-uk.typ",
                        "site/tapl-uk.pdf"], cwd=ROOT, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stderr.strip()[:2000])
        return 1

    import datetime
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    (SITE / "index.html").write_text(
        INDEX.format(done=len(done), todo=len(todo), stamp=stamp), encoding="utf-8")
    print(f"units in book: {len(done)}; still pending: {len(todo)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
