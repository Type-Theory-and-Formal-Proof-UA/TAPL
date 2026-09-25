#import "/templates/preamble.typ": *

#chap("", "Розв’язки до вибраних вправ")

#solution("16.3.4")[Обробка типів `Ref` прямолінійна. Ми просто додаємо один пункт до
алгоритмів перетину та об’єднання:

#disp($ S or T = cases(
  dots.h,
  op("Ref")(T_1) quad "якщо " S = op("Ref")(S_1) " і " T = op("Ref")(T_1) " і " S_1 <: T_1 " і " T_1 <: S_1,
  dots.h,
) $)

#disp($ S and T = cases(
  dots.h,
  op("Ref")(T_1) quad "якщо " S = op("Ref")(S_1) " і " T = op("Ref")(T_1) " і " S_1 <: T_1 " і " T_1 <: S_1,
  dots.h,
) $)

Коли ж ми уточнюємо `Ref` конструкторами `Source` і `Sink`, ми натрапляємо на велику
трудність: відношення підтипів більше не має об’єднань (чи перетинів)! Наприклад, типи
$op("Ref"){a:"Nat",b:"Bool"}$ і $op("Ref"){a:"Nat"}$ є підтипами і $op("Source"){a:"Nat"}$,
і $op("Sink"){a:"Nat",b:"Bool"}$, але в цих типів немає спільної нижньої межі.

Є різні способи зарадити цій трудності. Мабуть, найпростіший — додати до системи або
`Source`, або `Sink`, але не обидва. Для багатьох прикладних царин цього досить. Наприклад,
для уточненої реалізації класів у §18.12 нам потрібен лише `Source`. У мові з паралелізмом
і типами каналів (§15.5), з другого боку, ми могли б віддати перевагу самому лише `Sink`,
оскільки це дасть нам змогу означити процес-сервер і передавати лише «здатність надсилати»
на його каналі доступу (здатність приймати потрібна тільки самому процессові-серверу).

З самими лише типами `Source` алгоритм об’єднання лишається повним, якщо уточнити його
так (нам також потрібен пункт для `Ref` згори; аналогічні пункти додаються й до алгоритму
перетину):

#disp($ S or T = cases(
  dots.h,
  op("Source")(J_1) quad "якщо " S = op("Ref")(S_1) " і " T = op("Ref")(T_1) " і " S_1 or T_1 = J_1,
  op("Source")(J_1) quad "якщо " S = op("Source")(S_1) " і " T = op("Source")(T_1) " і " S_1 or T_1 = J_1,
  dots.h,
  op("Source")(J_1) quad "якщо " S = op("Ref")(S_1) " і " T = op("Source")(T_1) " і " S_1 or T_1 = J_1,
  op("Source")(J_1) quad "якщо " S = op("Source")(S_1) " і " T = op("Ref")(T_1) " і " S_1 or T_1 = J_1,
  dots.h,
) $)

Інший розв’язок (його запропонували Hennessy and Riely, 1998) — уточнити конструктор
типу `Ref` так, щоб він брав не один аргумент, а два: елементи $op("Ref") S T$ — це комірки
посилань, які можна вживати, щоб зберігати елементи типу $S$ і вичитувати елементи типу
$T$. Новий `Ref` є контраваріантним за першим параметром і коваріантним за другим. Тепер
$op("Sink") S$ можна означити як скорочення для $op("Ref") S "Top"$, а $op("Source") T$ —
як $op("Ref") bot T$.]

#solution("16.4.1")[Так:

#rule([$Gamma tack t_1 : T_1$ #h(1.5em) $T_1 = bot$ #h(1.5em) $Gamma tack t_2 : T_2$ #h(1.5em) $Gamma tack t_3 : T_3$ #h(1.5em) $T_2 or T_3 = T$], "TA-If", [$Gamma tack op("if") t_1 op("then") t_2 op("else") t_3 : T$])

Альтернативне правило

#rule([$Gamma tack t_1 : T_1$ #h(1.5em) $T_1 = bot$ #h(1.5em) $Gamma tack t_2 : T_2$ #h(1.5em) $Gamma tack t_3 : T_3$], "TA-If", [$Gamma tack op("if") t_1 op("then") t_2 op("else") t_3 : bot$])

привабливе й було б безпечним (оскільки $bot$ порожній, обчислення $t_1$ ніколи не може
дати звичайного результату), але це правило приписало б деяким термам типи, яких не можна
приписати за декларативними правилами типізації; вибір його зламав би теорему 16.2.4.]

#solution("17.3.1")[Розв’язок вимагає лише переписати алгоритми з вправи 16.3.2.]

#code[
  #raw("let rec join tyS tyT =")
  #raw("  match (tyS,tyT) with")
  #raw("    (TyArr(tyS1,tyS2),TyArr(tyT1,tyT2)) →")
  #raw("       (try TyArr(meet tyS1 tyT1, join tyS2 tyT2)")
  #raw("        with Not_found → TyTop)")
  #raw("  | (TyBool,TyBool) →")
  #raw("       TyBool")
  #raw("  | (TyRecord(fS), TyRecord(fT)) →")
  #raw("       let labelsS = List.map (fun (li,_) → li) fS in")
  #raw("       let labelsT = List.map (fun (li,_) → li) fT in")
  #raw("       let commonLabels =")
  #raw("         List.find_all (fun l → List.mem l labelsT) labelsS in")
  #raw("       let commonFields =")
  #raw("         List.map (fun li →")
  #raw("           let tySi = List.assoc li fS in")
  #raw("           let tyTi = List.assoc li fT in")
  #raw("           (li, join tySi tyTi))")
  #raw("           commonLabels in")
  #raw("       TyRecord(commonFields)")
  #raw("  | _ →")
  #raw("       TyTop")
  #raw("and meet tyS tyT =")
  #raw("  match (tyS,tyT) with")
  #raw("    (TyArr(tyS1,tyS2),TyArr(tyT1,tyT2)) →")
  #raw("       TyArr(join tyS1 tyT1, meet tyS2 tyT2)")
  #raw("  | (TyBool,TyBool) →")
  #raw("       TyBool")
  #raw("  | (TyRecord(fS), TyRecord(fT)) →")
  #raw("       let labelsS = List.map (fun (li,_) → li) fS in")
  #raw("       let labelsT = List.map (fun (li,_) → li) fT in")
  #raw("       let allLabels =")
  #raw("         List.append")
  #raw("           labelsS")
  #raw("           (List.find_all")
  #raw("              (fun l → not (List.mem l labelsS)) labelsT) in")
  #raw("       let allFields =")
  #raw("         List.map (fun li →")
  #raw("           if List.mem li allLabels then")
  #raw("             let tySi = List.assoc li fS in")
  #raw("             let tyTi = List.assoc li fT in")
  #raw("             (li, meet tySi tyTi)")
  #raw("           else if List.mem li labelsS then")
  #raw("             (li, List.assoc li fS)")
  #raw("           else")
  #raw("             (li, List.assoc li fT))")
  #raw("           allLabels in")
  #raw("       TyRecord(allFields)")
  #raw("  | _ →")
  #raw("       raise Not_found")
  #raw("let rec typeof ctx t =")
  #raw("  match t with")
  #raw("    ...")
  #raw("  | TmTrue(fi) →")
  #raw("       TyBool")
  #raw("  | TmFalse(fi) →")
  #raw("       TyBool")
  #raw("  | TmIf(fi,t1,t2,t3) →")
  #raw("       if subtype (typeof ctx t1) TyBool then")
  #raw("         join (typeof ctx t2) (typeof ctx t3)")
  #raw("       else error fi \"guard of conditional not a boolean\"")
]

#solution("17.3.2")[Див. реалізацію `rcssubbot`.]

#solution("18.6.1")[]

#code[
  #raw("DecCounter = {get:Unit→Nat, inc:Unit→Unit, reset:Unit→Unit,")
  #raw("              dec:Unit→Unit};")
  #raw("decCounterClass =")
  #raw("  λr:CounterRep.")
  #raw("    let super = resetCounterClass r in")
  #raw("    {get=  super.get,")
  #raw("     inc=  super.inc,")
  #raw("     reset= super.reset,")
  #raw("     dec=  λ_:Unit. r.x:=pred(!(r.x))};")
]

#solution("18.7.1")[]

#code[
  #raw("BackupCounter2 = {get:Unit→Nat, inc:Unit→Unit,")
  #raw("                  reset:Unit→Unit, backup: Unit→Unit,")
  #raw("                  reset2:Unit→Unit, backup2: Unit→Unit};")
  #raw("BackupCounterRep2 = {x: Ref Nat, b: Ref Nat, b2: Ref Nat};")
  #raw("backupCounterClass2 =")
  #raw("  λr:BackupCounterRep2.")
  #raw("    let super = backupCounterClass r in")
  #raw("    {get = super.get, inc = super.inc,")
  #raw("     reset = super.reset, backup = super.backup,")
  #raw("     reset2 = λ_:Unit. r.x:=!(r.b2),")
  #raw("     backup2 = λ_:Unit. r.b2:=!(r.x)};")
]

#solution("18.11.1")[]

#code[
  #raw("instrCounterClass =")
  #raw("  λr:InstrCounterRep.")
  #raw("    λself: Unit→InstrCounter.")
  #raw("      λ_:Unit.")
  #raw("        let super = setCounterClass r self unit in")
  #raw("        {get = λ_:Unit. (r.a:=succ(!(r.a)); super.get unit),")
  #raw("         set = λi:Nat. (r.a:=succ(!(r.a)); super.set i),")
  #raw("         inc = super.inc,")
  #raw("         accesses = λ_:Unit. !(r.a)};")
  #raw("ResetInstrCounter = {get:Unit→Nat, set:Nat→Unit,")
  #raw("                     inc:Unit→Unit, accesses:Unit→Nat,")
  #raw("                     reset:Unit→Unit};")
  #raw("resetInstrCounterClass =")
  #raw("  λr:InstrCounterRep.")
  #raw("    λself: Unit→ResetInstrCounter.")
  #raw("      λ_:Unit.")
  #raw("        let super = instrCounterClass r self unit in")
  #raw("        {get = super.get,")
  #raw("         set = super.set,")
  #raw("         inc = super.inc,")
  #raw("         accesses = super.accesses,")
  #raw("         reset = λ_:Unit. r.x:=0};")
  #raw("BackupInstrCounter = {get:Unit→Nat, set:Nat→Unit,")
  #raw("                      inc:Unit→Unit, accesses:Unit→Nat,")
  #raw("                      backup:Unit→Unit, reset:Unit→Unit};")
  #raw("BackupInstrCounterRep = {x: Ref Nat, a: Ref Nat, b: Ref Nat};")
  #raw("backupInstrCounterClass =")
  #raw("  λr:BackupInstrCounterRep.")
  #raw("    λself: Unit→BackupInstrCounter.")
  #raw("      λ_:Unit.")
  #raw("        let super = resetInstrCounterClass r self unit in")
  #raw("        {get = super.get,")
  #raw("         set = super.set,")
  #raw("         inc = super.inc,")
  #raw("         accesses = super.accesses,")
  #raw("         reset = λ_:Unit. r.x:=!(r.b),")
  #raw("         backup = λ_:Unit. r.b:=!(r.x)};")
  #raw("newBackupInstrCounter =")
  #raw("  λ_:Unit. let r = {x=ref 1, a=ref 0, b=ref 0} in")
  #raw("            fix (backupInstrCounterClass r) unit;")
]

#solution("18.13.1")[Один зі способів перевірки тотожності — вжити комірки посилань. Ми
розширюємо внутрішнє подання наших об’єктів змінною примірника `id` типу

#code[
  #raw("Ref Nat")
  #raw("IdCounterRep = {x: Ref Nat, id: Ref (Ref Nat)};")
]

і методом `id`, який просто повертає поле `id`:

#code[
  #raw("IdCounter = {get:Unit→Nat, inc:Unit→Unit, id:Unit→(Ref Nat)};")
  #raw("idCounterClass =")
  #raw("  λr:IdCounterRep.")
  #raw("    {get = λ_:Unit. !(r.x),")
  #raw("     inc = λ_:Unit. r.x:=succ(!(r.x)),")
  #raw("     id= λ_:Unit. !(r.id)};")
]

Тепер функція `sameObject` бере два об’єкти з методами `id` і перевіряє, чи ті самі
посилання повертають ці методи `id`.

#code[
  #raw("sameObject =")
  #raw("  λa:{id:Unit→(Ref Nat)}. λb:{id:Unit→(Ref Nat)}.")
  #raw("    ((b.id unit) := 1;")
  #raw("     (a.id unit) := 0;")
  #raw("     iszero (!(b.id unit)));")
]

Хитрість тут — у вживанні утворення псевдонімів, щоб перевірити, чи дві комірки посилань
ті самі: ми впевнюємося, що друга ненульова, присвоюємо нуль першій і перевіряємо другу,
чи не стала вона нулем.]

#solution("19.4.1")[Оскільки кожне оголошення класу мусить містити пункт `extends`, і
оскільки ці пункти не можуть бути циклічними, ланцюг пунктів `extends` від кожного класу
мусить зрештою закінчитися на `Object`.]

#solution("19.4.2")[Одне очевидне вдосконалення — об’єднати три правила типізації для
приведення в одне

#rule([$Gamma tack t_0 : D$], "T-Cast", [$Gamma tack (C)t_0 : C$])

і відмовитися від поняття безглуздих приведень. Інше — вилучити конструктори, бо вони
однаково нічого не роблять.]

#solution("19.4.6")[

1. Формулювання інтерфейсів для FJ — рутинна справа.
2. Припустімо, ми оголошуємо такі інтерфейси:

   #code[
     #raw("interface A {}")
     #raw("interface B {}")
     #raw("interface C extends A,B {}")
     #raw("interface D extends A,B {}")
   ]

   Тоді $C$ і $D$ мають спільні верхні межі і $A$, і $B$, але не мають найменшої верхньої
   межі.
3. Замість стандартного алгоритмічного правила для умовних виразів,

   #rule([$Gamma tack t_1 : "boolean"$ #h(1.2em) $Gamma tack t_2 : E_2$ #h(1.2em) $Gamma tack t_3 : E_3$], "", [$Gamma tack t_1 " ? " t_2 " : " t_3 : E_2 or E_3$])

   Java вживає такі обмежені правила:

   #rule([$Gamma tack t_1 : "boolean"$ #h(1.2em) $Gamma tack t_2 : E_2$ #h(1.2em) $Gamma tack t_3 : E_3$ #h(1.2em) $Gamma tack E_2 <: E_3$], "", [$Gamma tack t_1 " ? " t_2 " : " t_3 : E_3$])

   #rule([$Gamma tack t_1 : "boolean"$ #h(1.2em) $Gamma tack t_2 : E_2$ #h(1.2em) $Gamma tack t_3 : E_3$ #h(1.2em) $Gamma tack E_3 <: E_2$], "", [$Gamma tack t_1 " ? " t_2 " : " t_3 : E_2$])

   Вони інтуїтивно коректні, але погано взаємодіють із дрібнокроковим стилем операційної
   семантики, ужитим для FJ, — властивість збереження типу насправді хибна! (Легко
   побудувати приклад, що це показує.)]

#solution("19.4.7")[Як не дивно, обробляти `super` важче, ніж обробляти `self`, бо нам
потрібен якийсь спосіб пам’ятати, з якого класу походить «тіло методу, що його зараз
виконують». Є принаймні два способи цього досягти:

1. Анотувати терми деякою вказівкою на те, де слід шукати посилання `super`.
2. Додати крок попереднього опрацювання, на якому всю таблицю класів переписують,
   перетворюючи посилання на `super` на посилання на `this` зі «спотвореними» іменами,
   що вказують, із якого класу вони походять.]

#solution("19.5.1")[Перш ніж подати головне доведення, ми розробимо кілька потрібних лем.
Як завжди, ключова з них (A.14) пов’язує типізацію та підстановку.

#lem("A.13")[Якщо $op("mtype")(m, D) = C -> C_0$, то $op("mtype")(m, C) = C -> C_0$ для
всіх $C <: D$.#h(0.4em)$square$]

*Доведення.* Прямолінійна індукція за виведенням $C <: D$. Зауважмо, що, чи означено $m$
в $op("CT")(C)$, чи ні, $op("mtype")(m, C)$ має дорівнювати $op("mtype")(m, E)$, де
$op("CT")(C) = op("class") C op("extends") E { dots }$.#h(0.4em)$square$

#lem("A.14")[#strong[Підстановка термів зберігає типізацію]: якщо $Gamma, x : B tack t : D$ і $Gamma tack s : A$, де $A <: B$, то
$Gamma tack [x |-> s]t : C$ для деякого $C <: D$.#h(0.4em)$square$]

*Доведення.* Індукцією за виведенням $Gamma, x : B tack t : D$. Інтуїція точнісінько
така сама, як для лямбда-числення з підтипуванням; подробиці, звісно, трохи різняться.
Найцікавіші випадки — два останні.

#subsec([Випадок T-Var: $t = x$, $x : D in Gamma$])

Якщо $x in.not x$, то результат тривіальний, бо $[x |-> s]x = x$. З другого боку, якщо
$x = x_i$ і $D = B_i$, то, оскільки $[x |-> s]x = s_i$, вибір $C = A_i$ завершує випадок.

#subsec([Випадок T-Field: $t = t_0 "." f_i$, $Gamma, x : B tack t_0 : D_0$, $op("fields")(D_0) = C f$, $D = C_i$])

За індукційною гіпотезою існує деякий $C_0$ такий, що
$Gamma tack [x |-> s]t_0 : C_0$ і $C_0 <: D_0$. Легко перевірити, що
$op("fields")(C_0) = (op("fields")(D_0), D g)$ для деякого $D g$. Отже, за T-Field,
$Gamma tack ([x |-> s]t_0) \".\" f_i : C_i$.

#subsec([Випадок T-Invk: $t = t_0 "." m(t)$, $Gamma, x : B tack t_0 : D_0$, $op("mtype")(m, D_0) = E -> D$, $Gamma, x : B tack t : D$, $D <: E$])

За індукційною гіпотезою існують деякі $C_0$ і $C$ такі, що:
$Gamma tack [x |-> s]t_0 : C_0$, $C_0 <: D_0$,
$Gamma tack [x |-> s]t : C$, $C <: D$. За лемою A.13,
$op("mtype")(m, C_0) = E -> D$. До того ж, $C <: E$ за транзитивністю $<:$. Отже, за
T-Invk, $Gamma tack [x |-> s]t_0 \".\" m([x |-> s]t) : D$.

#subsec([Випадок T-New: $t = op("new") D(t)$, $op("fields")(D) = D f$, $Gamma, x : B tack t : C$, $C <: D$])

За індукційною гіпотезою, $Gamma tack [x |-> s]t : E$ для деякого $E$ з $E <: C$.
За транзитивністю $<:$ маємо $E <: D$. Отже, за T-New,
$Gamma tack op("new") D([x |-> s]t) : D$.

#subsec([Випадок T-UCast: $t = (D)t_0$, $Gamma, x : B tack t_0 : C$, $C <: D$])

За індукційною гіпотезою існує деякий $E$ такий, що $Gamma tack [x |-> s]t_0 : E$ і
$E <: C$. За транзитивністю $<:$ маємо $E <: D$, що за T-UCast дає
$Gamma tack (D)([x |-> s]t_0) : D$.

#subsec([Випадок T-DCast: $t = (D)t_0$, $Gamma, x : B tack t_0 : C$, $D <: C$, $D eq.not C$])

За індукційною гіпотезою існує деякий $E$ такий, що $Gamma tack [x |-> s]t_0 : E$ і
$E <: C$. Якщо $E <: D$ або $D <: E$, то $Gamma tack (D)([x |-> s]t_0) : D$ за T-UCast
або T-DCast, відповідно. З другого боку, якщо і $D ̸<: E$, і $E ̸<: D$, то
$Gamma tack (D)([x |-> s]t_0) : D$ (із безглуздим попередженням) за T-SCast.

#subsec([Випадок T-SCast: $t = (D)t_0$, $Gamma, x : B tack t_0 : C$, $D ̸<: C$, $C ̸<: D$])

За індукційною гіпотезою існує деякий $E$ такий, що $Gamma tack [x |-> s]t_0 : E$ і
$E <: C$. Це означає, що $E ̸<: D$. (Щоб це побачити, зауважмо, що кожен клас у FJ має
лише один надклас. З цього випливає, що коли і $E <: C$, і $E <: D$, то або $C <: D$,
або $D <: C$.) Отже, $Gamma tack (D)([x |-> s]t_0) : D$ (із безглуздим попередженням), за
T-SCast.#h(0.4em)$square$

#lem("A.15")[#strong[Послаблення]: якщо $Gamma tack t : C$, то $Gamma, x : D tack t : C$.#h(0.4em)$square$]

*Доведення.* Прямолінійна індукція.#h(0.4em)$square$

#lem("A.16")[Якщо $op("mtype")(m, C_0) = D -> D$ і $op("mbody")(m, C_0) = (x, t)$, то
для деяких $D_0$ і деякого $C <: D$ маємо $C_0 <: D_0$ і
$x : D, op("this") : D_0 tack t : C$.#h(0.4em)$square$]

*Доведення.* Індукцією за виведенням $op("mbody")(m, C_0)$. Базовий випадок (де $m$
означено в $C_0$) простий, бо $m$ означено в $op("CT")(C_0)$, а правильна побудова
таблиці класів означає, що ми мусили вивести
$x : D, op("this") : C_0 tack t : C$ за T-Method. Крок індукції теж прямолінійний.#h(0.4em)$square$

Тепер ми готові подати доведення теореми про безпечність типів.

*Доведення теореми 19.5.1.* Індукцією за виведенням $t arrow.r.long.long t$, з розбором
випадків за останнім правилом. Зверніть увагу, як породжуються безглузді попередження в
підвипадку T-DCast, другому з кінця.

#subsec([Випадок E-ProjNew: $t = op("new") C_0(v) "." f_i$, $t' = v_i$, $op("fields")(C_0) = D f$])

З форми $t$ ми бачимо, що останнє правило у виведенні $Gamma tack t : C$ мусить бути
T-Field, з посилкою $Gamma tack op("new") C_0(v) : D_0$ для деякого $D_0$, і що
$C = D_i$. Так само останнє правило у виведенні $Gamma tack op("new") C_0(v) : D_0$
мусить бути T-New, з посилками $Gamma tack v : C$ і $C <: D$, і з $D_0 = C_0$. Зокрема,
$Gamma tack v_i : C_i$, що завершує випадок, бо $C_i <: D_i$.

#subsec([Випадок E-InvkNew: $t = (op("new") C_0(v)) "." m(u)$, $t' = [u / x, op("new") C_0(v) / op("this")]t_0$, $op("mbody")(m, C_0) = (x, t_0)$])

Останні правила у виведенні $Gamma tack t : C$ мусять бути T-Invk і T-New, з посилками
$Gamma tack op("new") C_0(v) : C_0$, $Gamma tack u : C$, $C <: D$ і
$op("mtype")(m, C_0) = D -> C$. За лемою A.16 маємо
$x : D, op("this") : D_0 tack t_0 : B$ для деяких $D_0$ і $B$, де $C_0 <: D_0$ і
$B <: C$. За лемою A.15, $Gamma, x : D, op("this") : D_0 tack t_0 : B$. Тоді, за лемою
A.14, $Gamma tack [x |-> u, op("this") |-> op("new") C_0(v)]t_0 : E$ для деякого
$E <: B$. За транзитивністю $<:$ дістаємо $E <: C$. Вибір $C' = E$ завершує випадок.

#subsec([Випадок E-CastNew: $t = (D)(op("new") C_0(v))$, $C_0 <: D$, $t' = op("new") C_0(v)$])

Доведення $Gamma tack (D)(op("new") C_0(v)) : C$ мусить закінчуватися T-UCast, бо
закінчення на T-SCast або T-DCast суперечило б припущенню $C_0 <: D$. Посилки T-UCast
дають нам $Gamma tack op("new") C_0(v) : C_0$ і $D = C$, що завершує випадок.

Випадки для правил конгруентності прості. Покажемо лише один:

#subsec([Випадок RC-Cast: $t = (D)t_0$, $t' = (D)t_0'$, $t_0 arrow.r.long.long t_0'$])

Є три підвипадки відповідно до останнього вжитого правила типізації.

#subsubsec([Підвипадок T-UCast: $Gamma tack t_0 : C_0$, $C_0 <: D$, $D = C$])

За індукційною гіпотезою, $Gamma tack t_0' : C_0'$ для деякого $C_0' <: C_0$. За
транзитивністю $<:$, $C_0' <: C$. Отже, за T-UCast,
$Gamma tack (C)t_0' : C$ (без додаткового безглуздого попередження).

#subsubsec([Підвипадок T-DCast: $Gamma tack t_0 : C_0$, $D <: C_0$, $D = C$])

За індукційною гіпотезою, $Gamma tack t_0' : C_0'$ для деякого $C_0' <: C_0$. Якщо
$C_0' <: C$ або $C <: C_0'$, то $Gamma tack (C)t_0' : C$ за T-UCast або T-DCast (без
жодного додаткового безглуздого попередження). З другого боку, якщо і $C_0' ̸<: C$, і
$C ̸<: C_0'$, то $Gamma tack (C)t_0' : C$ із безглуздим попередженням, за T-SCast.

#subsubsec([Підвипадок T-SCast: $Gamma tack t_0 : C_0$, $D ̸<: C_0$, $C_0 ̸<: D$, $D = C$])

За індукційною гіпотезою, $Gamma tack t_0' : C_0'$ для деякого $C_0' <: C_0$. Тоді
також виконуються і $C_0' ̸<: C$, і $C ̸<: C_0'$. Отже,
$Gamma tack (C)t_0' : C$ із безглуздим попередженням.#h(0.4em)$square$]

#solution("20.1.1")[]

#code[
  #raw("Tree = µX. <leaf:Unit, node:{Nat,X,X}>;")
  #raw("leaf = <leaf=unit> as Tree;")
  #raw("▶ leaf : Tree")
]

#code[
  #raw("node = λn:Nat. λt1:Tree. λt2:Tree. <node={n,t1,t2}> as Tree;")
  #raw("▶ node : Nat → Tree → Tree → Tree")
  #raw("isleaf = λl:Tree. case l of <leaf=u> ⇒ true | <node=p> ⇒ false;")
  #raw("▶ isleaf : Tree → Bool")
  #raw("label = λl:Tree. case l of <leaf=u> ⇒ 0 | <node=p> ⇒ p.1;")
  #raw("▶ label : Tree → Nat")
  #raw("left = λl:Tree. case l of <leaf=u> ⇒ leaf | <node=p> ⇒ p.2;")
  #raw("▶ left : Tree → Tree")
  #raw("right = λl:Tree. case l of <leaf=u> ⇒ leaf | <node=p> ⇒ p.3;")
  #raw("▶ right : Tree → Tree")
  #raw("append = fix (λf:NatList→NatList→NatList.")
  #raw("              λl1:NatList. λl2:NatList.")
  #raw("                if isnil l1 then l2 else")
  #raw("                cons (hd l1) (f (tl l1) l2));")
  #raw("▶ append : NatList → NatList → NatList")
  #raw("preorder = fix (λf:Tree→NatList. λt:Tree.")
  #raw("                if isleaf t then nil else")
  #raw("                cons (label t)")
  #raw("                     (append (f (left t)) (f (right t))));")
  #raw("▶ preorder : Tree → NatList")
  #raw("t1 = node 1 leaf leaf;")
  #raw("t2 = node 2 leaf leaf;")
  #raw("t3 = node 3 t1 t2;")
  #raw("t4 = node 4 t3 t3;")
  #raw("l = preorder t4;")
  #raw("hd l;")
  #raw("▶ 4 : Nat")
  #raw("hd (tl l);")
  #raw("▶ 3 : Nat")
  #raw("hd (tl (tl l));")
  #raw("▶ 1 : Nat")
]

#solution("20.1.2")[]

#code[
  #raw("fib = fix (λf: Nat→Nat→Stream. λm:Nat. λn:Nat. λ_:Unit.")
  #raw("                 {n, f n (plus m n)}) 0 1;")
  #raw("▶ fib : Stream")
]

#solution("20.1.3")[]

#code[
  #raw("Counter = µC. {get:Nat, inc:Unit→C, dec:Unit→C,")
  #raw("             reset:Unit→C, backup:Unit→C};")
  #raw("c = let create =")
  #raw("      fix (λcr: {x:Nat,b:Nat}→Counter. λs: {x:Nat,b:Nat}.")
  #raw("            {get= s.x,")
  #raw("             inc= λ_:Unit. cr {x=succ(s.x),b=s.b},")
  #raw("             dec= λ_:Unit. cr {x=pred(s.x),b=s.b},")
  #raw("             backup = λ_:Unit. cr {x=s.x,b=s.x},")
  #raw("             reset= λ_:Unit. cr {x=s.b,b=s.b}})")
  #raw("    in create {x=0,b=0};")
  #raw("▶ c : Counter")
]

#solution("20.1.4")[]

#code[
  #raw("D = µX. <nat:Nat, bool:Bool, fn:X→X>;")
  #raw("lam = λf:D→D. <fn=f> as D;")
  #raw("ap = λf:D. λa:D.")
  #raw("       case f of")
  #raw("         <nat=n> ⇒ divergeD unit")
  #raw("       | <bool=b> ⇒ divergeD unit")
  #raw("       | <fn=f> ⇒ f a;")
  #raw("ifd = λb:D. λt:D. λe:D.")
  #raw("        case b of")
  #raw("          <nat=n> ⇒ divergeD unit")
  #raw("        | <bool=b> ⇒(if b then t else e)")
  #raw("        | <fn=f> ⇒ divergeD unit;")
  #raw("tru = <bool=true> as D;")
  #raw("fls = <bool=false> as D;")
  #raw("ifd fls one zro;")
  #raw("▶<nat=0> as D : D")
  #raw("ifd fls one fls;")
  #raw("▶<bool=false> as D : D")
]

Читачів, яких непокоїть той факт, що в цій системі ми можемо закодувати некоректно
типізовані терми, має заспокоїти те, що ми зробили, — а зробили ми структуру даних для
подання об’єктної мови негіпованих термів у метамові просто типізованого лямбда-числення
з рекурсивними типами. Те, що ми можемо це зробити, не дивніше за факт (який ми вживали
в усіх розділах про реалізацію по всій книзі), що терми різних гіпованих і негіпованих
лямбда-числень можна подати як структури даних у ML.

#solution("20.1.5")[]

#code[
  #raw("lam = λf:D→D. <fn=f> as D;")
  #raw("ap = λf:D. λa:D. case f of")
  #raw("         <nat=n> ⇒ divergeD unit")
  #raw("       | <fn=f> ⇒ f a")
  #raw("       | <rcd=r> ⇒ divergeD unit;")
  #raw("rcd = λfields:Nat→D. <rcd=fields> as D;")
  #raw("prj = λf:D. λn:Nat. case f of")
  #raw("         <nat=n> ⇒ divergeD unit")
  #raw("       | <fn=f> ⇒ divergeD unit")
  #raw("       | <rcd=r> ⇒ r n;")
  #raw("myrcd = rcd (λn:Nat. if iszero 0 then zro")
  #raw("                  else if iszero (pred n) then one")
  #raw("                  else divergeD unit);")
]

#solution("20.2.1")[Ось деякі з цікавіших прикладів в ізо-рекурсивній формі:]

#code[
  #raw("Hungry = µA. Nat → A;")
  #raw("f = fix (λf: Nat→Hungry. λn:Nat. fold [Hungry] f);")
  #raw("ff = fold [Hungry] f;")
  #raw("ff1 = (unfold [Hungry] ff) 0;")
  #raw("ff2 = (unfold [Hungry] ff1) 2;")
  #raw("fixT =")
  #raw("  λf:T→T.")
  #raw("    (λx:(µA.A→T). f ((unfold [µA.A→T] x) x))")
  #raw("    (fold [µA.A→T] (λx:(µA.A→T). f ((unfold [µA.A→T] x) x)));")
  #raw("D = µX. X→X;")
  #raw("lam = λf:D→D. fold [D] f;")
  #raw("ap = λf:D. λa:D. (unfold [D] f) a;")
  #raw("Counter = µC. {get:Nat, inc:Unit→C};")
  #raw("c = let create = fix (λcr: {x:Nat}→Counter. λs: {x:Nat}.")
  #raw("                       fold [Counter]")
  #raw("                         {get = s.x,")
  #raw("                          inc = λ_:Unit. cr {x=succ(s.x)}})")
  #raw("    in create {x=0};")
  #raw("c1 = (unfold [Counter] c).inc unit;")
  #raw("(unfold [Counter] c1).get;")
]

#solution("21.1.7")[]

#disp($ E_2(emptyset) = {a} quad quad E_2({a, b}) = {a, c} $)
#disp($ E_2({a}) = {a} quad quad E_2({a, c}) = {a, b} $)
#disp($ E_2({b}) = {a} quad quad E_2({b, c}) = {a, b} $)
#disp($ E_2({c}) = {a, b} quad quad E_2({a, b, c}) = {a, b, c} $)

Множини, замкнені щодо $E_2$, — це ${a}$ і ${a, b, c}$. Множини, узгоджені з $E_2$, — це
$emptyset$, ${a}$ і ${a, b, c}$. Найменша нерухома точка $E_2$ — це ${a}$. Найбільша
нерухома точка — ${a, b, c}$.

#solution("21.1.9")[Щоб довести принцип звичайної індукції за натуральними числами,
продовжуємо так. Означмо твірну функцію $F in P(N) -> P(N)$ як
$F(X) = {0} union {i + 1 divides i in X}$.

Тепер припустімо, що ми маємо предикат (тобто множину чисел) $P$ такий, що $P(0)$ і що
$P(i)$ тягне $P(i+1)$. Тоді з означення $F$ легко бачити, що $X subset.eq P$ тягне
$F(X) subset.eq P$, тобто $P$ замкнена щодо $F$. За принципом індукції, $mu F subset.eq P$.
Але $mu F$ — це вся множина натуральних чисел (справді, це можна взяти за означення
множини натуральних чисел), тож $P(n)$ виконується для всіх $n in N$.

Для лексикографічної індукції означмо $F in P(N times N) -> P(N times N)$ як

#disp($ F(X) = {(m, n) divides forall (m', n') < (m, n), (m', n') in X} $)

Тепер припустімо, що ми маємо предикат (тобто множину пар чисел) $P$ такий, що

#disp($ forall (m', n') < (m, n), P(m', n') $)

а саме: щоразу, коли $P(m', n')$ для всіх $(m', n') < (m, n)$, ми також маємо $P(m, n)$.
Як і раніше, з означення $F$ легко бачити, що $X subset.eq P$ тягне $F(X) subset.eq P$,
тобто
$P$ замкнена щодо $F$. За принципом індукції, $mu F subset.eq P$. Щоб завершити, ми
мусимо перевірити, що $mu F$ справді є множиною всіх пар чисел (це єдине тонке місце
аргументу). Це можна обґрунтувати у два кроки. По-перше, зауважмо, що $N times N$
замкнена щодо $F$ (це негайно випливає з означення $F$). По-друге, покажімо, що жодна
власна підмножина $N times N$ не є замкненою щодо $F$, — тобто $N times N$ є найменшою
замкненою щодо $F$ множиною. Щоб це побачити, припустімо, що існує менша замкнена щодо
$F$ множина $Y$, і нехай $(m, n)$ — найменша пара, що не належить $Y$; з означення $F$
ми бачимо, що $F(Y) not subset.eq Y$, тобто $Y$ не замкнена, — суперечність.]

#solution("21.2.2")[Означмо дерево як часткову функцію $T in {1, 2} ⇀ {arrow.r, times, "Top"}$,
що задовольняє такі обмеження:

- $T(bullet)$ означена;
- якщо $T(pi, sigma)$ означена, то $T(pi)$ означена.

Зауважмо, що входження символів $arrow.r$, $times$, `Top` у вузлах дерева зовсім не
обмежені — наприклад, вузол із `Top` може мати нетривіальних нащадків тощо. Як і в §21.2,
ми перевантажуємо символи $arrow.r$, $times$ і `Top`, щоб вони були також операторами над
деревами.

Множину всіх дерев беремо за універсум $U$. Твірна функція $F$ будується за звичною
граматикою типів:

#disp($ F(X) = {top} union {T_1 times T_2 divides T_1, T_2 in X} union {T_1 -> T_2 divides T_1, T_2 in X} $)

З означень $T$ і $U$ видно, що $T subset.eq U$, тож порівнювати множини в рівняннях, які
нас цікавлять, — $T = nu F$ і $T_f = mu F$ — має сенс. Лишається перевірити, чи ці
рівняння істинні.

$T subset.eq nu F$ випливає за принципом коіндукції з того, що $T$ узгоджена з $F$. Щоб
дістати $nu F subset.eq T$, нам треба перевірити для будь-якого $T in nu F$ дві останні
умови з означення 21.2.1. Це можна зробити індукцією за довжиною $pi$.

$mu F subset.eq T_f$ випливає за принципом індукції з того, що $T_f$ замкнена щодо $F$.
Щоб дістати $T_f subset.eq mu F$, ми стверджуємо, індукцією за розміром $T$, що
$T in T_f$ тягне $T in mu F$. (Розмір $T in T_f$ можна означити як довжину найдовшої
послідовності $pi in {1, 2}^*$ такої, що $T(pi)$ означена.)]

#solution("21.3.3")[Пара $(top, top times top)$ не належить $nu S$. Щоб це побачити,
просто зауважмо з означення $S$, що ця пара не належить $S(X)$ для жодного $X$. Тож
немає жодної узгодженої з $S$ множини, яка містить цю пару, і зокрема $nu S$ (яка
узгоджена з $S$) її не містить.]

#solution("21.3.4")[Як приклад пари типів дерев, пов’язаних $nu S$, але не $mu S$, можна
взяти пару $(T, T)$ для будь-якого нескінченного типу $T$. Розгляньмо множину пар
$R = {(T(pi), T(pi)) divides pi in {1, 2}^*}$. Огляд означення $S$ легко дає
$R subset.eq S(R)$, а застосування принципу коіндукції дає $R subset.eq nu S$. Тоді
$(T, T) in nu S$, бо $(T, T) in R$. З другого боку, $(T, T) in.not mu S$, бо $mu S$
пов’язує лише скінченні типи, — це можна встановити, узявши за $R$ множину всіх пар
скінченних типів і діставши $mu S subset.eq R$ за принципом індукції.

Немає таких пар $(S, T)$ скінченних типів, які пов’язані $nu S_f$, але не $mu S_f$, бо ці
дві нерухомі точки збігаються. Це випливає з того, що для будь-яких $S, T in T_f$ з
$(S, T) in nu S_f$ випливає $(S, T) in mu S_f$. (Оскільки $T$ — скінченне дерево, останнє
твердження, своєю чергою, можна дістати індукцією за $T$. Треба розглянути випадки, коли
$T$ — це `Top`, $T_1 times T_2$ або $T_1 -> T_2$, оглянути означення $S_f$ і вжити
рівностей $S_f(nu S_f) = nu S_f$ і $S_f(mu S_f) = mu S_f$.)]

#solution("21.3.8")[Почнімо з означення відношення тотожності на типах дерев:
$I = {(T, T) divides T in T}$. Якщо ми зможемо показати, що $I$ узгоджена з $S$, то
принцип коіндукції скаже нам, що $I subset.eq nu S$, — тобто $nu S$ рефлексивна. Щоб
показати узгодженість $I$ з $S$, розгляньмо елемент $(T, T) in I$ і продовжмо розбором
випадків за формою $T$. Спершу припустімо, що $T = top$. Тоді $(T, T) = (top, top)$, що
за означенням належить $S(I)$. Припустімо далі, що $T = T_1 times T_2$. Тоді, оскільки
$(T_1, T_1), (T_2, T_2) in I$, означення $S$ дає $(T_1 times T_2, T_1 times T_2) in S(I)$.
Так само для $T = T_1 -> T_2$.]

#solution("21.4.2")[За принципом коіндукції достатньо показати, що
$U_("TR") times U_("TR")$ узгоджена з $F$, тобто
$U_("TR") times U_("TR") subset.eq F(U_("TR") times U_("TR"))$. Припустімо
$(x, y) in U_("TR") times U_("TR")$. Візьмімо будь-який $z in U_("TR")$. Тоді
$(x, z), (z, y) in U_("TR") times U_("TR")$, а отже, за означенням $F$, також
$(x, y) in F(U_("TR") times U_("TR"))$.]

#solution("21.5.2")[Щоб перевірити оборотність, ми просто оглядаємо означення $S_f$ і $S$
та переконуємося, що кожна множина $G(S, T)$ містить щонайбільше один елемент.

В означеннях $S_f$ і $S$ кожен пункт явно задає форму елемента, який можна підперти, і
вміст його множини підтримки, тож виписати функцію підтримки $S_m$ у $S_f$ і $S$ легко.
(Порівняйте з функцією підтримки для означення 21.8.4.)]

#solution("21.5.4")[]

#code[
  #raw("i a b c b d e f g g")
  #raw("h a d e b c f g")
]

#solution("21.5.6")[Ні, з $x in nu F \\ mu F$ не мусить випливати цикл у графі підтримки:
він може вести також до нескінченного ланцюга. Наприклад, розгляньмо
$F in P(N) -> P(N)$, означену як $F(X) = {0} union {n divides n + 1 in X}$. Тоді
$mu F = {0}$ і $nu F = N$. Крім того, для будь-якого $n in nu F \\ mu F$, тобто для
будь-якого $n > 0$, $op("support")(n) = {n + 1}$, що творить нескінченний ланцюг.]

#solution("21.5.13")[Спершу розгляньмо часткову правильність. Доведення для кожної
частини ведеться індукцією за рекурсивною структурою прогону алгоритму:

1. З означення `lfp` легко бачити, що є два випадки, коли `lfp(X)` може повернути `true`.
   Якщо `lfp(X) = true` тому, що $X = emptyset$, то $X subset.eq mu F$ тривіально. З
   другого боку, якщо `lfp(X) = true` тому, що `lfp(support(X)) = true`, то за
   індукційною гіпотезою $op("support")(X) subset.eq mu F$, звідки лема 21.5.8 дає
   $X subset.eq mu F$.
2. Якщо `lfp(X) = false` тому, що $op("support")(X) arrow.t$, то $X not subset.eq mu F$ за
   лемою 21.5.8. Інакше `lfp(X) = false` тому, що `lfp(support(X)) = false`, і за
   індукційною гіпотезою $op("support")(X) not subset.eq mu F$. За лемою 21.5.8,
   $X not subset.eq mu F$.

Далі ми хочемо схарактеризувати ті твірні функції $F$, для яких `lfp` гарантовано
завершується на всіх скінченних входах. Для цього стане в пригоді трохи нової
термінології. Для твірної функції зі скінченним станом $F in P(U) -> P(U)$ часткова
функція $op("height")_F ⇀ N$ (або просто `height`)#footnote[Зауважмо, що цей
спосіб формулювання означення `height` легко переформулювати як найменшу нерухому точку
монотонної функції на відношеннях, що подають часткові функції.] — це найменша часткова
функція, що задовольняє таку умову:

#disp($ op("height")(x) = cases(
  0 quad quad "якщо " op("support")(x) = emptyset,
  0 quad quad "якщо " op("support")(x) arrow.t,
  1 + op("max"){op("height")(y) divides y in op("support")(x)} quad "якщо " op("support")(x) eq.not emptyset,
) $)

(Зауважмо, що $op("height")(x)$ не означена, якщо $x$ або сам бере участь у циклі
досяжності, або залежить від елемента з циклу.) Кажемо, що твірна функція $F$ має
скінченну висоту, якщо $op("height")_F in U ⇀ N$ — тотальна функція. Легко
перевірити, що коли $y in op("support")(x)$ і означено і $op("height")(x)$, і
$op("height")(y)$, то $op("height")(y) < op("height")(x)$.

Тепер, якщо $F$ має скінченний стан і скінченну висоту, то `lfp(X)` завершується для
будь-якої скінченної вхідної множини $X subset.eq U$. Щоб це побачити, зауважмо, що,
оскільки $F$ має скінченний стан, для кожного рекурсивного виклику `lfp(Y)`, що походить
від початкового виклику `lfp(X)`, множина $Y$ скінченна. Оскільки $F$ має скінченну
висоту, $h(Y) = op("max"){op("height")(y) divides y in Y}$ правильно означена. Оскільки
$h(Y)$ спадає з кожним рекурсивним викликом і завжди невід’ємна, вона править за міру
завершуваності для `lfp`.]

#solution("21.8.5")[Означення $S_d$ таке саме, як означення $S_m$, крім того, що останній
пункт не містить умов $T eq.not mu X. T_1$ і $T eq.not top$. Щоб побачити, що $S_d$ не
оборотна, зауважмо, що множина $G(mu X. top, mu Y. top)$ містить дві твірні множини,
${(top, mu Y. top)}$ і ${(mu X. top, top)}$ (порівняйте вміст цієї множини для функції
$S_m$).

Оскільки всі пункти $S_d$ і $S_m$ однакові, крім останнього, а останній пункт $S_m$ є
обмеженням останнього пункту $S_d$, включення $nu S_m subset.eq nu S_d$ очевидне. Інше
включення, $nu S_d subset.eq nu S_m$, можна довести, вживши принцип коіндукції разом із
такою лемою, яка встановлює, що $nu S_d$ узгоджена з $S_m$.

#lem("A.17")[Для будь-яких двох $mu$-типів $S$, $T$, якщо $(S, T) in nu S_d$, то
$(S, T) in S_m(nu S_d)$.#h(0.4em)$square$]

*Начерк доведення.* Лексикографічною індукцією за $(n, k)$, де
$k = "µ-height"(S)$ і $n = "µ-height"(T)$. Ця індукція підтверджує неформальну ідею, що
будь-яке виведення $(S, T) in nu S_d$ можна перетворити на інше виведення того самого
факту, яке до того ж виявляється виведенням $(S, T) in nu S_m$. Обмеження в правилі
лівого $mu$-згортання диктують, що перетворене виведення має таку властивість: кожна
послідовність застосувань правил $mu$-згортання починається з послідовності лівих
$mu$-згортань, за якими йде послідовність правих $mu$-згортань.#h(0.4em)$square$]

#solution("21.9.2")[]

#figure([], rules([
  $ S ⊑ T_1 quad quad S ⊑ T_2 $
  $ T ⊑ T quad quad S ⊑ T_1 times T_2 quad quad S ⊑ T_1 times T_2 $
  $ S ⊑ T_1 quad quad S ⊑ T_2 quad quad S ⊑[X |-> mu X. T] T $
  $ S ⊑ T_1 -> T_2 quad quad S ⊑ T_1 -> T_2 quad quad S ⊑ mu X. T $
]))

(Зауважмо, як цікавий факт, що твірна функція $op("TD")$ відрізняється від твірних
функцій, які ми розглядали в цьому розділі: вона не оборотна. Наприклад,
$B ⊑ A times B -> B times C$ підперта двома множинами ${B ⊑ A times B}$ і
${B ⊑ B times C}$, жодна з яких не є підмножиною іншої.)

#solution("21.9.7")[Усі правила для `BU` такі самі, як правила для $op("TD")$, наведені в
розв’язку вправи 21.9.2, крім правила для типів, які починаються зі зв’язувача $mu$:

#figure([], rules([
  $ S ⪯ T $
  $ [X |-> mu X. T]S ⪯ mu X. T $
]))]

#solution("21.11.1")[Їх багато. Тривіальний приклад — $mu X. T$ і $[X |-> mu X. T]T$ для
майже будь-якого $T$. Цікавіший — $mu X. "Nat" times ("Nat" times X)$ і
$mu X. "Nat" times X$.]

#solution("22.3.9")[Ось головні алгоритмічні правила породження обмежень:

#figure([], rules([
  #rule([$Gamma(x) = T$], "CT-Var", [$Gamma tack_F x : T divides_F emptyset$])
  #rule([$Gamma, x:T_1 tack_F t_2 : T_2 divides_F C$ #h(1.2em) $x in.not op("dom")(Gamma)$], "CT-Abs",
        [$Gamma tack_F lambda x:T_1 . t_2 : T_1 -> T_2 divides_F C$])
  #rule([$Gamma tack_F t_1 : T_1 divides_F C_1$ #h(1.2em) $Gamma tack_(F') t_2 : T_2 divides_F C_2$ #h(1.2em) $F' = X, F''$], "CT-App",
        [$Gamma tack_F t_1 t_2 : X divides_F C_1 union C_2 union {T_1 = T_2 -> X}$])
]))

Решта правил подібні. Еквівалентність початкових правил і алгоритмічного подання можна
сформулювати так:

1. (Коректність) Якщо $Gamma tack_F t : T divides_(F') C$ і змінні, згадані в $Gamma$ і
   $t$, не з’являються в $F$, то $Gamma tack t : T divides_(F' \\ F) C$.
2. (Повнота) Якщо $Gamma tack t : T divides_X C$, то існує така перестановка $F$ імен у
   $X$, що $Gamma tack_F t : T divides_emptyset C$.

Обидві частини доводять прямолінійною індукцією за виведеннями. Для випадку застосування
в частині 1 стане в пригоді така лема:

Якщо змінні типів, згадані в $Gamma$ і $t$, не з’являються в $F$, і якщо
$Gamma tack_F t : T divides_(F') C$, то змінні типів, згадані в $T$ і $C$, не з’являються
в $F' \\ F$.

Для відповідного випадку в частині 2 вживають таку лему:

Якщо $Gamma tack_F t : T divides_F C$, то $Gamma tack_(F,G) t : T divides_(F,G) C$, де
$G$ — будь-яка послідовність свіжих імен змінних.]
