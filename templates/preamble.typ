// ============================================================================
// Types and Programming Languages — український переклад
// Спільна преамбула. НЕ редагувати в межах перекладу глав: це спільний файл.
// ============================================================================
#set page(
  paper: "a4",
  margin: (x: 22mm, y: 20mm),
  numbering: "1",
  header: context {
    let pg = counter(page).get().first()
    if pg > 1 {
      set text(size: 8.5pt, fill: luma(90))
      grid(columns: (1fr, 1fr), align: (left, right),
        [#currentchapter.get()], [#pg])
    }
  },
)

#set text(
  font: ("STIX Two Text",),
  size: 10.5pt,
  lang: "uk",
  hyphenate: true,
)
#set par(leading: 0.72em, first-line-indent: 1.25em, spacing: 1.05em, justify: true)
#show raw: set text(font: ("DejaVu Sans Mono", "Menlo", "Courier New"), size: 9pt)

// --- змінні стану -----------------------------------------------------------
#let currentchapter = state("chapter", "")

// --- HTML-експорт -------------------------------------------------------------
// HTML-експорт Typst не має рушія верстки: grid, align, place, v, h у ньому
// губляться. Тож усе, що верстається блоками (правила виведення, дошки, рисунки,
// таблиці, формули з номерами), віддається як html.frame — вбудований SVG із
// звичайної верстки. У межах frame `target()` — "paged", тому рекурсії немає.
#let _hf(x) = context if target() == "html" {
  html.elem("div", attrs: (style: "margin: 1.1em 0; overflow-x: auto"),
    html.frame(block(width: 39em, x)))
} else { x }

// --- структурні заголовки ---------------------------------------------------
// Глава: #chap("3", "Негіповані арифметичні вирази")
// У HTML глава — заголовок першого рівня (з нього розрізається сторінка).
#let chap(num, title) = context if target() == "html" {
  currentchapter.update(if num == "" { title } else { num + " " + title })
  heading(level: 1, numbering: none, bookmarked: true)[#if num != "" [#num #h(0.3em)]#title]
} else {
  currentchapter.update(if num == "" { title } else { num + " " + title })
  pagebreak(weak: true)
  v(2em)
  text(size: 22pt, weight: "regular")[
    #if num != "" [#grid(columns: (2.2em, 1fr), column-gutter: 0.6em)[
      #text(size: 30pt, fill: luma(120))[#num]
    ][#title]] else [#title]
  ]
  v(1.2em)
}

// Розділ (section)
#let sec(num, title) = heading(level: 2, outlined: false, bookmarked: true)[#num #title]
// Підрозділ (subsection)
#let subsec(title) = heading(level: 3, outlined: false, bookmarked: false)[#title]
#let subsubsec(title) = heading(level: 4, outlined: false, bookmarked: false)[#title]

// --- середовища тверджень ---------------------------------------------------
// Друкують «Лема 3.2.1.» — номер передається ЯВНО, як в оригіналі:
//     #lem("3.2.1")[Якщо $t$ типізовано, то …]
// Це не лічильник: у книзі номери подекуди йдуть не за порядком друку
// (у розділі 4 вправа 4.2.2 надрукована перед 4.2.1), а явний номер ще й
// дозволяє перевірячу звірити послідовність номерів із джерелом.
#let _stmt(kind, num, it, extra: none) = {
  let head = if extra != none { kind + " " + num + " " + extra }
             else { kind + " " + num }
  block[
    #strong[#head]. #it
  ]
}
#let thm(num, it) = _stmt("Теорема", num, it)
#let lem(num, it) = _stmt("Лема", num, it)
#let cor(num, it) = _stmt("Наслідок", num, it)
#let defn(num, it) = _stmt("Означення", num, it)
#let prop_(num, it) = _stmt("Твердження", num, it)
#let claim(num, it) = _stmt("Твердження", num, it)
#let notation(num, it) = _stmt("Позначення", num, it)
#let convention(num, it) = _stmt("Домовленість", num, it)
#let fact(num, it) = _stmt("Факт", num, it)
#let axiom(num, it) = _stmt("Аксіома", num, it)
#let example(num, it) = _stmt("Приклад", num, it)
#let remark(num, it) = _stmt("Зауваження", num, it)
#let principle(num, it) = _stmt("Принцип", num, it)
#let note_(num, it) = _stmt("Нотатка", num, it)
#let solution(num, it) = _stmt("Розв’язок", num, it)

// Вправа: #exr("3.5.1")[текст]  або #exr("3.5.1", diff: "★★", rec: true)[текст]
#let exr(num, it, diff: none, rec: false) = {
  let bits = ()
  if rec { bits.push("Recommended") }
  if diff != none { bits.push(diff) }
  let extra = if bits.len() > 0 { " [" + bits.join(", ") + "]" } else { none }
  _stmt("Вправа", num, it, extra: extra)
}

// --- блоки правил / фігур ---------------------------------------------------
// Лістинг вихідного коду (OCaml тощо): моноширинно, без вирівнювання.
// Рядки лістингу — або окремі `#raw(...)` без розривів, або з явним `\`.
// Розрив додається лише між двома `#raw` підряд, тож явні розриви не дублюються.
#let _lines(body) = {
  let ch = if body.has("children") { body.children } else { (body,) }
  let out = ()
  let prev-raw = false
  for c in ch {
    if c == [ ] { continue }
    if c.func() == raw {
      if prev-raw { out.push(linebreak()) }
      prev-raw = true
    } else { prev-raw = false }
    out.push(c)
  }
  out.join()
}
#let code(body) = context if target() == "html" {
  html.elem("div", attrs: (style: "white-space: pre; overflow-x: auto; background: #f4f4f4; border: 1px solid #999; padding: .5em .7em; margin: 1em 0; font-family: 'DejaVu Sans Mono', Menlo, monospace; font-size: .85em; line-height: 1.35"), _lines(body))
} else {
  block(
    width: 100%, inset: 7pt, radius: 2pt, fill: luma(97),
    stroke: (paint: luma(75), thickness: 0.4pt),
    breakable: false,
  )[
    #set text(font: ("DejaVu Sans Mono", "Menlo", "Courier New"), size: 9pt)
    #set par(justify: false, first-line-indent: 0em, leading: 0.58em)
    #_lines(body)
  ]
}

// Дошка для правил виведення, боксів синтаксису й таблиць: текст усередині
// зберігає розбиття на рядки (саме так воно надруковано в книзі).
#let rules(body, scale: 0.94) = _hf(block(
  width: 100%, inset: 7pt, radius: 0pt,
  stroke: (paint: luma(60), thickness: 0.5pt),
)[
  #set text(size: 10.5pt * scale)
  #set par(justify: false, first-line-indent: 0em, leading: 0.60em)
  #set block(spacing: 0.45em)
  // Consecutive #raw(...) calls are INLINE and flow together on one line, so a
  // board written as one #raw per line (the book's own line breaks — see
  // STYLE.md §"рисунки") collapses into a single wrapped paragraph. `#code`
  // already re-breaks them through _lines(); `rules` did not, which is why
  // ch13's rule boards and ch14's Figure 14-3 mixed their columns. Run the
  // same helper here so every container that takes raw lines behaves alike,
  // instead of each part patching itself with `#set raw(block: true)`.
  #_lines(body)
])
// Правило виведення у два стовпці: посилки над рискою, висновок під нею.
// Посилки й висновок — це ВМІСТ (content), тож і математика ($…$), і звичайний
// текст («t1 — числове значення») передаються однаково.
#let rule(premises, name, conclusion) = _hf(block(breakable: false)[
  #grid(columns: 2, column-gutter: 1.2em, align: (center + horizon, right + horizon),
    premises, text(size: 8.5pt, fill: luma(70))[#name])
  #v(-0.35em)
  #line(length: 100%, stroke: 0.5pt)
  #v(-0.15em)
  #align(center)[#conclusion]
])
#let figure(caption, body) = _hf(block(width: 100%, breakable: false)[
  #body
  #v(0.25em)
  #align(center)[#text(size: 9.5pt)[#caption]] 
])
#let tbl(caption, body) = _hf(block(width: 100%, breakable: false)[
  #body
  #v(0.25em)
  #align(center)[#text(size: 9.5pt)[#caption]]
])

// Нумерована виключна формула: #eqn($...$, "3.1") — номер у правому полі.
#let eqn(body, num) = _hf(block(width: 100%, breakable: false)[
  #place(right + horizon, text(size: 9.5pt)[(#num)])
  #align(center)[$#body$]
  #v(-0.35em)
])

// Ненумерована виключна формула: #disp($...$) — та сама геометрія, без номера.
// Потрібна там, де джерело друкує формулу на виключку без номера (напр. рівняння
// алгебри підтипів у додатку A): #eqn вимагає номер і без нього не компілюється.
#let disp(body) = _hf(block(width: 100%, breakable: false)[
  #align(center)[$#body$]
  #v(-0.35em)
])

// Запис бібліографії: #bib[текст] — з висячим відступом, як в оригіналі.
// Текст лишається англійською: STYLE.md §1 зберігає імена авторів, назви праць
// і видання як в оригіналі, тож перекладати в бібліографії нічого.
#let bib(it) = block(width: 100%, outset: (left: 1.2em), par(hanging-indent: 1.2em, it))

// Запис покажчика: #idx(0, [термін, 123]) — рівень 0/1/2 задає відступ.
// Покажчик у TAPL — це ключі, а не проза: STYLE.md §1 лишає надруковану форму
// терміна (її шукають за номером сторінки й на неї посилаються), тому текст
// лишається англійською, а рівень вкладеності береться з відступу оригіналу.
#let idx(level, it) = {
  let ind = level * 8pt
  block(width: 100%, inset: (left: ind), par(hanging-indent: 8pt)[#it])
}

// Нумерований список із довільним стилем нумерації: #numbered("(i)", [...], [...])
#let numbered(numbering, ..items) = enum(numbering: numbering, ..items.pos())

// --- дрібні позначки --------------------------------------------------------
#let todo = text(fill: rgb("#b00"), weight: "bold")[TODO]
#let ukr(s) = text(lang: "uk")[#s]
