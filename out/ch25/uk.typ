#import "/templates/preamble.typ": *

#chap("25", "Реалізація System F мовою ML")

Тепер ми розширимо нашу реалізацію $lambda arrow$ з розділу 10, щоб включити
універсальні та екзистенційні типи з розділів 23 і 24. Оскільки правила, що означують
цю систему, керовані синтаксисом (як і сам $lambda arrow$, але на відміну від числень
із підтипізацією або еквірекурсивними типами), її втілення мовою OCaml досить
прямолінійне. Найцікавіше розширення реалізації $lambda arrow$ — це подання типів,
які можуть містити зв’язування змінних (у кванторах). Для них ми вживаємо техніку
індексів де Брейна, уведену в розділі 6.

#sec("25.1", "Безіменне подання типів")

Ми починаємо з розширення синтаксису типів змінними типів, а також універсальними
та екзистенційними кванторами.

#code[
  #raw("type ty =")
  #raw("    TyVar of int * int")
  #raw("  | TyArr of ty * ty")
  #raw("  | TyAll of string * ty")
  #raw("  | TySome of string * ty")
]

Домовленості тут точно такі самі, як для подання термів у §7.1. Змінні типів
складаються з двох цілих чисел: перше вказує відстань до зв’язувача змінної, а друге,
як перевірку узгодженості, вказує очікуваний загальний розмір контексту. Квантори
анотовано рядковим ім’ям змінної, яку вони зв’язують, — як підказку для функцій друку.

Далі ми розширюємо контексти, щоб вони несли зв’язування для змінних типів на додачу
до змінних термів, додавши новий конструктор до типу `binding`:

#code[
  #raw("type binding =")
  #raw("    NameBind")
  #raw("  | VarBind of ty")
  #raw("  | TyVarBind")
]

Як і в наших попередніх реалізаціях, зв’язувач `NameBind` уживають лише функції
розбору й друку. Конструктор `VarBind` несе тип, як і раніше. Новий конструктор
`TyVarBind` не несе жодного додаткового значення даних, бо (на відміну від змінних
термів) змінні типів у цій системі не анотовано жодними додатковими припущеннями.
У системі з обмеженим квантуванням (розділ 26) або вищими родами (розділ 29) ми
додали б відповідну анотацію до кожного `TyVarBind`.

#sec("25.2", "Зсув і підстановка типів")

Оскільки типи тепер містять змінні, нам треба означити функції зсуву й підстановки
для типів.

#exr("25.2.1", diff: "★")[Користуючись функцією зсуву термів з означення 6.2.1
(сторінка 79) як зразком, випишіть математичне означення аналогічної функції,
яка зсуває змінні в типах.#h(0.4em)$square$]

У §7.2 ми показали зсув і підстановку для термів як дві окремі функції, але зауважили,
що реалізація, доступна на вебсайті книги, насправді вживає узагальнену функцію
«відображення» для виконання обох завдань. Подібну функцію відображення можна вжити,
щоб означити зсув і підстановку для типів. Погляньмо тепер на ці функції відображення.

Основне спостереження — те, що зсув і підстановка мають точно однакову поведінку на
всіх конструкторах, крім змінних. Якщо ми винесемо їхню поведінку на змінних окремо,
то вони стануть ідентичними. Наприклад, ось спеціалізована функція зсуву для типів,
яку ми отримуємо механічним перенесенням розв’язку вправи 25.2.1 мовою OCaml:

#code[
  #raw("let typeShiftAbove d c tyT =")
  #raw("  let rec walk c tyT = match tyT with")
  #raw("      TyVar(x,n) -> if x>=c then TyVar(x+d,n+d) else TyVar(x,n+d)")
  #raw("    | TyArr(tyT1,tyT2) -> TyArr(walk c tyT1,walk c tyT2)")
  #raw("    | TyAll(tyX,tyT2) -> TyAll(tyX,walk (c+1) tyT2)")
  #raw("    | TySome(tyX,tyT2) -> TySome(tyX,walk (c+1) tyT2)")
  #raw("  in walk c tyT")
]

Аргументи цієї функції включають величину $d$, на яку мають бути зсунуті вільні
змінні, відсікання $c$, нижче якого ми не маємо зсувати (щоб не зсувати змінні,
зв’язані кванторами всередині типу), і тип `tyT`, який треба зсунути. Тепер, якщо
ми винесемо пункт `TyVar` із `typeShiftAbove` у новий аргумент `onvar` і відкинемо
аргумент $d$, який згадувався лише в пункті `TyVar`, ми отримаємо узагальнену функцію
відображення

#code[
  #raw("let tymap onvar c tyT =")
  #raw("  let rec walk c tyT = match tyT with")
  #raw("      TyArr(tyT1,tyT2) -> TyArr(walk c tyT1,walk c tyT2)")
  #raw("    | TyVar(x,n) -> onvar c x n")
  #raw("    | TyAll(tyX,tyT2) -> TyAll(tyX,walk (c+1) tyT2)")
  #raw("    | TySome(tyX,tyT2) -> TySome(tyX,walk (c+1) tyT2)")
  #raw("  in walk c tyT")
]

з якої ми можемо відновити функцію зсуву, подавши пункт `TyVar` (як функцію,
абстраговану за $c$, $x$ та $n$) як параметр:

#code[
  #raw("let typeShiftAbove d c tyT =")
  #raw("  tymap")
  #raw("    (fun c x n -> if x>=c then TyVar(x+d,n+d) else TyVar(x,n+d))")
  #raw("    c tyT")
]

Також зручно означити спеціалізовану версію `typeShiftAbove`, яку вживати, коли
початкове відсікання дорівнює 0:

#code[
  #raw("let typeShift d tyT = typeShiftAbove d 0 tyT")
]

Ми можемо також конкретизувати `tymap`, щоб реалізувати операцію підстановки типу
`tyS` замість змінної типу з номером $j$ у типі `tyT`:

#code[
  #raw("let typeSubst tyS j tyT =")
  #raw("  tymap")
  #raw("    (fun j x n -> if x=j then (typeShift j tyS) else (TyVar(x,n)))")
  #raw("    j tyT")
]

Коли ми вживаємо підстановку типів під час перевірки типів і обчислення, ми завжди
будемо підставляти замість 0-ї (найзовнішнішої) змінної, і ми захочемо зсунути
результат так, щоб ця змінна зникла. Допоміжна функція `typeSubstTop` робить це
для нас.

#code[
  #raw("let typeSubstTop tyS tyT =")
  #raw("  typeShift (-1) (typeSubst (typeShift 1 tyS) 0 tyT)")
]

#sec("25.3", "Терми")

На рівні термів робота, яку треба виконати, подібна. Ми починаємо з розширення типу
даних термів із розділу 10 формами введення й усунення для універсальних
та екзистенційних типів.

#code[
  #raw("type term =")
  #raw("    TmVar of info * int * int")
  #raw("  | TmAbs of info * string * ty * term")
  #raw("  | TmApp of info * term * term")
  #raw("  | TmTAbs of info * string * term")
  #raw("  | TmTApp of info * term * ty")
  #raw("  | TmPack of info * ty * term * ty")
  #raw("  | TmUnpack of info * string * string * term * term")
]

Означення зсуву й підстановки для термів подібні до тих, що в розділі 10. Проте
випишімо їх тут через спільну узагальнену функцію відображення, як ми робили
для типів у попередньому підрозділі. Функція відображення виглядає так:

#code[
  #raw("let tmmap onvar ontype c t =")
  #raw("  let rec walk c t = match t with")
  #raw("      TmVar(fi,x,n) -> onvar fi c x n")
  #raw("    | TmAbs(fi,x,tyT1,t2) -> TmAbs(fi,x,ontype c tyT1,walk (c+1) t2)")
  #raw("    | TmApp(fi,t1,t2) -> TmApp(fi,walk c t1,walk c t2)")
  #raw("    | TmTAbs(fi,tyX,t2) -> TmTAbs(fi,tyX,walk (c+1) t2)")
  #raw("    | TmTApp(fi,t1,tyT2) -> TmTApp(fi,walk c t1,ontype c tyT2)")
  #raw("    | TmPack(fi,tyT1,t2,tyT3) ->")
  #raw("        TmPack(fi,ontype c tyT1,walk c t2,ontype c tyT3)")
  #raw("    | TmUnpack(fi,tyX,x,t1,t2) ->")
  #raw("        TmUnpack(fi,tyX,x,walk c t1,walk (c+2) t2)")
  #raw("  in walk c t")
]

Зауважимо, що `tmmap` бере чотири аргументи — на один більше, ніж `tymap`. Щоб
побачити чому, зауважимо, що терми можуть містити два різні види змінних: змінні
термів, а також змінні типів, вбудовані в анотації типів у термах. Тож під час зсуву,
наприклад, є два роди «листків», де нам, можливо, доведеться виконати справжню роботу:
змінні термів і типи. Параметр `ontype` каже відображувачеві термів, що робити, коли
він обробляє конструктор терма, що містить анотацію типу, як у випадку `TmAbs`. Якби
ми мали справу з більшою мовою, таких випадків було б ще кілька.

Зсув термів можна означити, подавши `tmmap` відповідні аргументи.

#code[
  #raw("let termShiftAbove d c t =")
  #raw("  tmmap")
  #raw("    (fun fi c x n -> if x>=c then TmVar(fi,x+d,n+d)")
  #raw("                     else TmVar(fi,x,n+d))")
  #raw("    (typeShiftAbove d)")
  #raw("    c t")
  #raw("let termShift d t = termShiftAbove d 0 t")
]

На змінних термів ми перевіряємо відсікання й будуємо нову змінну, точнісінько як
ми робили в `typeShiftAbove`. Для типів ми викликаємо функцію зсуву типів, означену
в попередньому підрозділі.

Функція підстановки одного терма в інший подібна.

#code[
  #raw("let termSubst j s t =")
  #raw("  tmmap")
  #raw("    (fun fi j x n -> if x=j then termShift j s else TmVar(fi,x,n))")
  #raw("    (fun j tyT -> tyT)")
  #raw("    j t")
]

Зауважимо, що анотації типів не змінюються `termSubst` (типи не можуть містити змінних
термів, тож підстановка терма ніколи на них не впливає).

Нам також потрібна функція підстановки типу в терм — уживана, наприклад, у правилі
обчислення для застосування типів:

#eqn($ (lambda X . t_12) [T_2] arrow.r.long [X |-> T_2] t_12 $, "E-TappTabs")

Її теж можна означити, користуючись відображувачем термів:

#code[
  #raw("let rec tytermSubst tyS j t =")
  #raw("  tmmap (fun fi c x n -> TmVar(fi,x,n))")
  #raw("        (fun j tyT -> typeSubst tyS j tyT) j t")
]

Цього разу функція, яку ми передаємо `tmmap` для роботи зі змінними термів, —
тотожність (вона просто відбудовує початкову змінну терма); коли ми доходимо
до анотації типу, ми виконуємо підстановку на рівні типу над нею.

Нарешті, як ми робили для типів, означмо функції зручності, що пакують базові
функції підстановки для вжитку в `eval` і `typeof`.

#code[
  #raw("let termSubstTop s t =")
  #raw("  termShift (-1) (termSubst 0 (termShift 1 s) t)")
  #raw("let tytermSubstTop tyS t =")
  #raw("  termShift (-1) (tytermSubst (typeShift 1 tyS) 0 t)")
]

#sec("25.4", "Обчислення")

Розширення функції `eval` — це прямолінійні перенесення правил обчислення, уведених
на рисунках 23-1 та 24-1. Важку роботу виконують функції підстановки, означені
в попередньому підрозділі.

#code[
  #raw("let rec eval1 ctx t = match t with")
  #raw("    ...")
  #raw("  | TmTApp(fi,TmTAbs(_,x,t11),tyT2) ->")
  #raw("      tytermSubstTop tyT2 t11")
  #raw("  | TmTApp(fi,t1,tyT2) ->")
  #raw("      let t1' = eval1 ctx t1 in")
  #raw("      TmTApp(fi, t1', tyT2)")
  #raw("  | TmUnpack(fi,_,_,TmPack(_,tyT11,v12,_),t2) when isval ctx v12 ->")
  #raw("      tytermSubstTop tyT11 (termSubstTop (termShift 1 v12) t2)")
  #raw("  | TmUnpack(fi,tyX,x,t1,t2) ->")
  #raw("      let t1' = eval1 ctx t1 in")
  #raw("      TmUnpack(fi,tyX,x,t1',t2)")
  #raw("  | TmPack(fi,tyT1,t2,tyT3) ->")
  #raw("      let t2' = eval1 ctx t2 in")
  #raw("      TmPack(fi,tyT1,t2',tyT3)")
  #raw("    ...")
]

#exr("25.4.1", diff: "★")[Чому в першому випадку `TmUnpack` потрібен
`termShift`?#h(0.4em)$square$]

#sec("25.5", "Типізація")

Нові пункти функції `typeof` теж безпосередньо випливають із правил типізації для
абстракції й застосування типів, а також для пакування й розкриття екзистенційних
типів. Ми наводимо повне означення `typeof`, щоб нові пункти `TmTAbs` і `TmTApp`
можна було порівняти зі старими пунктами для звичайної абстракції та застосування.

#code[
  #raw("let rec typeof ctx t =")
  #raw("  match t with")
  #raw("      TmVar(fi,i,_) -> getTypeFromContext fi ctx i")
  #raw("    | TmAbs(fi,x,tyT1,t2) ->")
  #raw("        let ctx' = addbinding ctx x (VarBind(tyT1)) in")
  #raw("        let tyT2 = typeof ctx' t2 in")
  #raw("        TyArr(tyT1, typeShift (-1) tyT2)")
  #raw("    | TmApp(fi,t1,t2) ->")
  #raw("        let tyT1 = typeof ctx t1 in")
  #raw("        let tyT2 = typeof ctx t2 in")
  #raw("        (match tyT1 with")
  #raw("             TyArr(tyT11,tyT12) ->")
  #raw("               if (=) tyT2 tyT11 then tyT12")
  #raw("               else error fi \"parameter type mismatch\"")
  #raw("           | _ -> error fi \"arrow type expected\")")
  #raw("    | TmTAbs(fi,tyX,t2) ->")
  #raw("        let ctx = addbinding ctx tyX TyVarBind in")
  #raw("        let tyT2 = typeof ctx t2 in")
  #raw("        TyAll(tyX,tyT2)")
  #raw("    | TmTApp(fi,t1,tyT2) ->")
  #raw("        let tyT1 = typeof ctx t1 in")
  #raw("        (match tyT1 with")
  #raw("             TyAll(_,tyT12) -> typeSubstTop tyT2 tyT12")
  #raw("           | _ -> error fi \"universal type expected\")")
  #raw("    | TmPack(fi,tyT1,t2,tyT) ->")
  #raw("        (match tyT with")
  #raw("             TySome(tyY,tyT2) ->")
  #raw("               let tyU = typeof ctx t2 in")
  #raw("               let tyU' = typeSubstTop tyT1 tyT2 in")
  #raw("               if (=) tyU tyU' then tyT")
  #raw("               else error fi \"doesn't match declared type\"")
  #raw("           | _ -> error fi \"existential type expected\")")
  #raw("    | TmUnpack(fi,tyX,x,t1,t2) ->")
  #raw("        let tyT1 = typeof ctx t1 in")
  #raw("        (match tyT1 with")
  #raw("             TySome(tyY,tyT11) ->")
  #raw("               let ctx'  = addbinding ctx tyX TyVarBind in")
  #raw("               let ctx'' = addbinding ctx' x (VarBind tyT11) in")
  #raw("               let tyT2 = typeof ctx'' t2 in")
  #raw("               typeShift (-2) tyT2")
  #raw("           | _ -> error fi \"existential type expected\")")
]

Найцікавіший новий пункт — це пункт для `TmUnpack`. Він передбачає такі кроки.
(1) Ми перевіряємо підвираз $t_1$ і переконуємося, що він має екзистенційний тип
${exists X . T_11}$. (2) Ми розширюємо контекст $Gamma$ зв’язуванням змінної типу $X$
і зв’язуванням змінної терма $x : T_11$ та перевіряємо, що $t_2$ має якийсь тип $T_2$.
(3) Ми зсуваємо індекси вільних змінних у $T_2$ на два вниз, щоб він мав сенс щодо
початкового $Gamma$. (4) Ми повертаємо отриманий тип як тип усього виразу
`let...in...`.

Вочевидь, якщо $X$ трапляється вільно в $T_2$, то зсув на кроці (3) дасть безглуздий
тип з вільними змінними з від’ємними індексами; перевірка типів має зазнати невдачі
на цьому місці. Ми можемо це забезпечити, переозначивши `typeShiftAbove` так, щоб вона
помічала, коли збирається побудувати змінну типу з від’ємним індексом, і сигналізувала
про помилку замість того, щоб повертати нісенітницю.

#code[
  #raw("let typeShiftAbove d c tyT =")
  #raw("  tymap")
  #raw("    (fun c x n -> if x>=c then")
  #raw("                     if x+d<0 then err \"Scoping error!\"")
  #raw("                     else TyVar(x+d,n+d)")
  #raw("                   else TyVar(x,n+d))")
  #raw("    c tyT")
]

Ця перевірка повідомить про помилку області видимості щоразу, коли тип, який ми
обчислюємо для тіла $t_2$ виразу усунення екзистенційного типу
`let {X,x}=t_1 in t_2`, містить зв’язану змінну типу $X$.

#code[
  #raw("let {X,x}=({*Nat,0} as {∃X,X}) in x;")
  #raw("▶ Error: Scoping error!")
]
