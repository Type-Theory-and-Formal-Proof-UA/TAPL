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

// --- структурні заголовки ---------------------------------------------------
// Глава: #chap("3", "Негіповані арифметичні вирази")
#let chap(num, title) = {
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
    #strong[#head].#h(0.35em) #it
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
#let code(body) = block(
  width: 100%, inset: 7pt, radius: 2pt, fill: luma(97),
  stroke: (paint: luma(75), thickness: 0.4pt),
  breakable: false,
)[
  #set text(font: ("DejaVu Sans Mono", "Menlo", "Courier New"), size: 9pt)
  #set par(justify: false, first-line-indent: 0em, leading: 0.58em)
  #body
]

// Дошка для правил виведення, боксів синтаксису й таблиць: текст усередині
// зберігає розбиття на рядки (саме так воно надруковано в книзі).
#let rules(body, scale: 0.94) = block(
  width: 100%, inset: 7pt, radius: 0pt,
  stroke: (paint: luma(60), thickness: 0.5pt),
)[
  #set text(size: 10.5pt * scale)
  #set par(justify: false, first-line-indent: 0em, leading: 0.60em)
  #set block(spacing: 0.45em)
  #body
]
// Правило виведення у два стовпці: посилки над рискою, висновок під нею.
// Посилки й висновок — це ВМІСТ (content), тож і математика ($…$), і звичайний
// текст («t1 — числове значення») передаються однаково.
#let rule(premises, name, conclusion) = block(breakable: false)[
  #grid(columns: 2, column-gutter: 1.2em, align: (center + horizon, right + horizon),
    premises, text(size: 8.5pt, fill: luma(70))[#name])
  #v(-0.35em)
  #line(length: 100%, stroke: 0.5pt)
  #v(-0.15em)
  #align(center)[#conclusion]
]
#let figure(caption, body) = block(width: 100%, breakable: false)[
  #body
  #v(0.25em)
  #align(center)[#text(size: 9.5pt)[#caption]] 
]
#let tbl(caption, body) = block(width: 100%, breakable: false)[
  #body
  #v(0.25em)
  #align(center)[#text(size: 9.5pt)[#caption]]
]

// Нумерована виключна формула: #eqn($...$, "3.1") — номер у правому полі.
#let eqn(body, num) = block(width: 100%, breakable: false)[
  #place(right + horizon, text(size: 9.5pt)[(#num)])
  #align(center)[$#body$]
  #v(-0.35em)
]

// Нумерований список із довільним стилем нумерації: #numbered("(i)", [...], [...])
#let numbered(numbering, ..items) = enum(numbering: numbering, ..items.pos())

// --- дрібні позначки --------------------------------------------------------
#let todo = text(fill: rgb("#b00"), weight: "bold")[TODO]
#let ukr(s) = text(lang: "uk")[#s]
