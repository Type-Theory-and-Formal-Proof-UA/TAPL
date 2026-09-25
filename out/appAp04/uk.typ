#import "/templates/preamble.typ": *

#chap("", "Розв’язки до вибраних вправ")

#solution("22.3.10")[Якщо подати множини обмежень як списки пар типів, алгоритм породження
обмежень — це безпосереднє переписування правил виведення, наведених у розв’язку
вправи 22.3.9.

#code[
  #raw("let rec recon ctx nextuvar t = match t with")
  #raw("  TmVar(fi,i,_) →")
  #raw("    let tyT = getTypeFromContext fi ctx i in")
  #raw("    (tyT, nextuvar, [])")
  #raw("  | TmAbs(fi, x, tyT1, t2) →")
  #raw("    let ctx’ = addbinding ctx x (VarBind(tyT1)) in")
  #raw("    let (tyT2,nextuvar2,constr2) = recon ctx’ nextuvar t2 in")
  #raw("    (TyArr(tyT1, tyT2), nextuvar2, constr2)")
  #raw("  | TmApp(fi,t1,t2) →")
  #raw("    let (tyT1,nextuvar1,constr1) = recon ctx nextuvar t1 in")
  #raw("    let (tyT2,nextuvar2,constr2) = recon ctx nextuvar1 t2 in")
  #raw("    let NextUVar(tyX,nextuvar’) = nextuvar2() in")
  #raw("    let newconstr = [(tyT1,TyArr(tyT2,TyId(tyX)))] in")
  #raw("    ((TyId(tyX)), nextuvar’,")
  #raw("     List.concat [newconstr; constr1; constr2])")
  #raw("  | TmZero(fi) → (TyNat, nextuvar, [])")
  #raw("  | TmSucc(fi,t1) →")
  #raw("    let (tyT1,nextuvar1,constr1) = recon ctx nextuvar t1 in")
  #raw("    (TyNat, nextuvar1, (tyT1,TyNat)::constr1)")
  #raw("  | TmPred(fi,t1) →")
  #raw("    let (tyT1,nextuvar1,constr1) = recon ctx nextuvar t1 in")
  #raw("    (TyNat, nextuvar1, (tyT1,TyNat)::constr1)")
  #raw("  | TmIsZero(fi,t1) →")
  #raw("    let (tyT1,nextuvar1,constr1) = recon ctx nextuvar t1 in")
  #raw("    (TyBool, nextuvar1, (tyT1,TyNat)::constr1)")
  #raw("  | TmTrue(fi) → (TyBool, nextuvar, [])")
  #raw("  | TmFalse(fi) → (TyBool, nextuvar, [])")
  #raw("  | TmIf(fi,t1,t2,t3) →")
  #raw("    let (tyT1,nextuvar1,constr1) = recon ctx nextuvar t1 in")
  #raw("    let (tyT2,nextuvar2,constr2) = recon ctx nextuvar1 t2 in")
  #raw("    let (tyT3,nextuvar3,constr3) = recon ctx nextuvar2 t3 in")
  #raw("    let newconstr = [(tyT1,TyBool); (tyT2,tyT3)] in")
  #raw("    (tyT3, nextuvar3,")
  #raw("     List.concat [newconstr; constr1; constr2; constr3])")
]]

#solution("22.3.11")[Правило породження обмежень для виразів `fix` можна безпосередньо
вивести з правила типізації T-Fix на рисунку 11-12.

#figure([], rules([
  #rule([$Gamma tack t_1 : T_1 divides_(X_1) C_1$ #h(1.5em) $X$ не згадується в $X_1$, $Gamma$
         або $t_1$],
        "CT-Fix",
        [$Gamma tack op("fix") t_1 : X divides_(X_1 union {X}) C_1 {T_1 = X -> X}$])
]))

Це правило реконструює тип $t_1$ (називаючи його $T_1$), переконується, що $T_1$ має форму
$X -> X$ для деякого свіжого $X$, і видає $X$ як тип $op("fix") t_1$.

Правило породження обмежень для виразів `letrec` своєю чергою можна вивести з цього,
разом з означенням `letrec` як похідної форми.]

#solution("22.4.3")[

#figure([], rules([
  $ {X = "Nat", Y = X -> X} quad quad [X |-> "Nat", Y |-> "Nat" -> "Nat"] $
  $ {"Nat" -> "Nat" = X -> Y} quad quad [X |-> "Nat", Y |-> "Nat"] $
  $ {X -> Y = Y -> Z, Z = U -> W} quad quad [X |-> U -> W, Y |-> U -> W, Z |-> U -> W] $
  $ {"Nat" = "Nat" -> Y} quad quad "Не уніфікується" $
  $ {Y = "Nat" -> Y} quad quad "Не уніфікується" $
  $ {} quad quad [] $
]))]

#solution("22.4.6")[Основна структура даних, потрібна для цієї вправи, — подання підстановок.
Є багато альтернатив; проста з них — ужити тип `constr` із вправи 22.3.10: підстановка — це
просто множина обмежень, усі ліві частини якої є змінними уніфікації. Якщо означити функцію
`substinty`, яка виконує підстановку типу за однією змінною типу

#code[
  #raw("let substinty tyX tyT tyS =")
  #raw("  let rec f tyS = match tyS with")
  #raw("    TyArr(tyS1,tyS2) → TyArr(f tyS1, f tyS2)")
  #raw("  | TyNat → TyNat")
  #raw("  | TyBool → TyBool")
  #raw("  | TyId(s) → if s=tyX then tyT else TyId(s)")
  #raw("  in f tyS")
]

то застосування цілої підстановки до типу можна означити так:

#code[
  #raw("let applysubst constr tyT =")
  #raw("  List.fold_left")
  #raw("    (fun tyS (TyId(tyX),tyC2) → substinty tyX tyC2 tyS)")
  #raw("    tyT (List.rev constr)")
]

Функція уніфікації також має вміти застосовувати підстановку до всіх типів у деякій
множині обмежень:

#code[
  #raw("let substinconstr tyX tyT constr =")
  #raw("  List.map")
  #raw("    (fun (tyS1,tyS2) →")
  #raw("       (substinty tyX tyT tyS1, substinty tyX tyT tyS2))")
  #raw("    constr")
]

Так само ключовою є «перевірка на входження», яка виявляє циклічні залежності:

#code[
  #raw("let occursin tyX tyT =")
  #raw("  let rec o tyT = match tyT with")
  #raw("    TyArr(tyT1,tyT2) → o tyT1 || o tyT2")
  #raw("  | TyNat → false")
  #raw("  | TyBool → false")
  #raw("  | TyId(s) → (s=tyX)")
  #raw("  in o tyT")
]

Тепер функція уніфікації — це безпосереднє переписування псевдокоду з рисунка 22-2. Як
звичайно, вона бере позицію у файлі та рядок як додаткові аргументи, які вживають для
друку повідомлень про помилки, коли уніфікація зазнає невдачі.

#code[
  #raw("let unify fi ctx msg constr =")
  #raw("  let rec u constr = match constr with")
  #raw("    [] → []")
  #raw("  | (tyS,TyId(tyX)) :: rest →")
  #raw("      if tyS = TyId(tyX) then u rest")
  #raw("      else if occursin tyX tyS then")
  #raw("        error fi (msg ^ \": circular constraints\")")
  #raw("      else")
  #raw("        List.append (u (substinconstr tyX tyS rest))")
  #raw("                    [(TyId(tyX),tyS)]")
  #raw("  | (TyId(tyX),tyT) :: rest →")
  #raw("      if tyT = TyId(tyX) then u rest")
  #raw("      else if occursin tyX tyT then")
  #raw("        error fi (msg ^ \": circular constraints\")")
  #raw("      else")
  #raw("        List.append (u (substinconstr tyX tyT rest))")
  #raw("                    [(TyId(tyX),tyT)]")
  #raw("  | (TyNat,TyNat) :: rest → u rest")
  #raw("  | (TyBool,TyBool) :: rest → u rest")
  #raw("  | (TyArr(tyS1,tyS2),TyArr(tyT1,tyT2)) :: rest →")
  #raw("      u ((tyS1,tyT1) :: (tyS2,tyT2) :: rest)")
  #raw("  | (tyS,tyT)::rest →")
  #raw("      error fi \"Unsolvable constraints\"")
  #raw("  in")
  #raw("      u constr")
]

Ця педагогічна версія уніфікатора не надто старається друкувати корисні повідомлення про
помилки. На практиці «пояснення» помилок типів може бути однією з найважчих частин
розробки промислового компілятора для мови з реконструкцією типів. Див. Wand (1986).]

#solution("22.5.6")[Розширити алгоритм реконструкції типів на записи не прямолінійно, хоч
це й можливо. Головна трудність у тому, що неясно, які обмеження слід породжувати для
проєкції запису. Наївна перша спроба була б такою:

#figure([], rules([
  #rule([$Gamma tack t : T divides_X C$], "",
        [$Gamma tack t "." l_i : X divides_(X union {X}) C union {T = {l_i : X}}$])
]))

але це незадовільно, бо це правило, по суті, каже, що поле $l_i$ можна спроєктувати лише
із запису, який містить тільки поле $l_i$ і жодного іншого.

Елегантний розв’язок запропонував Wand (1987), а далі його розвинули Wand (1988, 1989b),
Remy (1989, 1990) та інші. Ми вводимо новий різновид змінної, який зветься #emph[змінною
рядка] і набуває значень не з типів, а з «рядків» міток полів і пов’язаних з ними типів.
Уживаючи змінні рядків, правило породження обмежень для проєкції поля можна записати так:

#figure([], rules([
  #rule([$Gamma tack t_0 : T divides_X C$], "CT-Proj",
        [$Gamma tack t_0 "." l_i : X divides_(X union {X, sigma, rho}) C union {T = {rho}, rho = l_i : X ⊕ sigma}$])
]))

де $sigma$ і $rho$ — змінні рядків, а оператор $⊕$ з’єднує два рядки (за припущення, що
їхні поля не перетинаються). Тобто терм $t "." l_i$ має тип $X$, якщо $t$ має тип запису
з полями $rho$, де $rho$ містить поле $l_i : X$ і деякі інші поля $sigma$.

Обмеження, породжені цим уточненим алгоритмом, складніші за прості множини рівностей між
типами зі змінними уніфікації з початкового алгоритму реконструкції, оскільки нові
множини обмежень залучають також асоціативний і комутативний оператор $⊕$. Щоб знаходити
розв’язки таких множин обмежень, потрібна проста форма рівнянь уніфікації.]

#solution("23.4.3")[Ось стандартний розв’язок із допоміжною функцією `append`

#code[
  #raw("append = λX. (fix (λapp:(List X) → (List X) → (List X).")
  #raw("                 λl1:List X. λl2:List X.")
  #raw("                   if isnil [X] l1 then l2")
  #raw("                   else cons [X] (head [X] l1)")
  #raw("                                (app (tail [X] l1) l2)));")
  #raw("▶ append : ∀X. List X → List X → List X")
  #raw("reverse =")
  #raw("  λX.")
  #raw("   (fix (λrev:(List X) → (List X).")
  #raw("          λl: (List X).")
  #raw("           if isnil [X] l")
  #raw("           then nil [X]")
  #raw("           else append [X] (rev (tail [X] l))")
  #raw("                           (cons [X] (head [X] l) (nil [X]))));")
  #raw("▶ reverse : ∀X. List X → List X")
]]

#solution("23.4.5")[

#code[
  #raw("and = λb:CBool. λc:CBool.")
  #raw("        λX. λt:X. λf:X. b [X] (c [X] t f) f;")
]]

#solution("23.4.6")[

#code[#raw("iszro = λn:CNat. n [Bool] (λb:Bool. false) true;")]]

#solution("23.4.8")[

#code[
  #raw("pairNat = λn1:CNat. λn2:CNat.")
  #raw("            λX. λf:CNat→CNat→X. f n1 n2;")
  #raw("fstNat = λp:PairNat. p [CNat] (λn1:CNat. λn2:CNat. n1);")
  #raw("sndNat = λp:PairNat. p [CNat] (λn1:CNat. λn2:CNat. n2);")
]]

#solution("23.4.9")[

#code[
  #raw("zz = pairNat c0 c0;")
  #raw("f = λp:PairNat. pairNat (sndNat p) (cplus c1 (sndNat p));")
  #raw("prd = λm:CNat. fstNat (m [PairNat] f zz);")
]]

#solution("23.4.10")[

#code[
  #raw("vpred = λn:CNat. λX. λs:X→X.")
  #raw("              λz:X.")
  #raw("                (n [(X→X)→X]")
  #raw("                   (λp:(X→X)→X. λq:(X→X). q (p s))")
  #raw("                   (λx:X→X. z))")
  #raw("                  (λx:X. x);")
  #raw("▶ vpred : CNat → CNat")
]

Я вдячний Michael Levin за те, що він звернув мою увагу на цей приклад.]

#solution("23.4.11")[

#code[
  #raw("head = λX. λdefault:X. λl:List X.")
  #raw("         l [X] (λhd:X. λtl:X. hd) default;")
]]

#solution("23.4.12")[Функція вставляння — найхитріша частина цієї вправи. Цей розв’язок
працює так: заданий список $l$ застосовують до функції, яка будує два нові списки — один,
тотожний початковому, а другий із включеним $e$. Для кожного елемента $op("hd")$ списку $l$
(рухаючись справа наліво) цій функції передають $op("hd")$ і пару списків, уже побудованих
для елементів праворуч від $op("hd")$. Нову пару списків будують, порівнюючи $e$ з
$op("hd")$: якщо $e$ менший або рівний, то він належить на початок другого результівного
списку; тому другий результівний список ми будуємо, додаючи $e$ на початок першого
переданого нам списку (того, який ще не містить $e$). З другого боку, якщо $e$ більший за
$op("hd")$, то він належить кудись у середину другого списку, і ми будуємо новий другий
список, просто долучаючи $op("hd")$ до вже побудованого другого списку, який нам передали.

#code[
  #raw("insert =")
  #raw("  λX. λleq:X→X→Bool. λl:List X. λe:X.")
  #raw("    let res =")
  #raw("      l [Pair (List X) (List X)]")
  #raw("        (λhd:X. λacc: Pair (List X) (List X).")
  #raw("           let rest = fst [List X] [List X] acc in")
  #raw("           let newrest = cons [X] hd rest in")
  #raw("           let restwithe = snd [List X] [List X] acc in")
  #raw("           let newrestwithe =")
  #raw("             if leq e hd")
  #raw("             then cons [X] e (cons [X] hd rest)")
  #raw("             else cons [X] hd restwithe in")
  #raw("           pair [List X] [List X] newrest newrestwithe)")
  #raw("        (pair [List X] [List X] (nil [X]) (cons [X] e (nil [X])))")
  #raw("    in snd [List X] [List X] res;")
  #raw("▶ insert : ∀X. (X→X→Bool) → List X → X → List X")
]

Далі нам потрібна функція порівняння чисел. Оскільки ми вживаємо примітивні числа, для її
написання потрібен `fix`. (Ми могли б узагалі обійтися без `fix`, уживши тут `CNat` замість
`Nat`.)

#code[
  #raw("leqnat =")
  #raw("  fix (λf:Nat→Nat→Bool. λm:Nat. λn:Nat.")
  #raw("        if iszero m then true")
  #raw("        else if iszero n then false")
  #raw("        else f (pred m) (pred n));")
  #raw("▶ leqnat : Nat → Nat → Bool")
]

Нарешті, ми будуємо функцію сортування, вставляючи кожен елемент списку по черзі в новий
список:

#code[
  #raw("sort = λX. λleq:X→X→Bool. λl:List X.")
  #raw("         l [List X]")
  #raw("           (λhd:X. λrest:List X. insert [X] leq rest hd)")
  #raw("           (nil [X]);")
  #raw("▶ sort : ∀X. (X→X→Bool) → List X → List X")
]

Щоб перевірити, що `sort` працює правильно, ми будуємо невпорядкований список,

#code[
  #raw("l = cons [Nat] 9")
  #raw("      (cons [Nat] 2 (cons [Nat] 6 (cons [Nat] 4 (nil [Nat]))));")
]

сортуємо його,

#code[#raw("l = sort [Nat] leqnat l;")]

і вичитуємо вміст:

#code[
  #raw("nth =")
  #raw("  λX. λdefault:X.")
  #raw("    fix (λf:(List X)→Nat→X. λl:List X. λn:Nat.")
  #raw("          if iszero n")
  #raw("          then head [X] default l")
  #raw("          else f (tail [X] l) (pred n));")
  #raw("▶ nth : ∀X. X → List X → Nat → X")
  #raw("nth [Nat] 0 l 0;")
  #raw("▶ 2 : Nat")
  #raw("nth [Nat] 0 l 1;")
  #raw("▶ 4 : Nat")
  #raw("nth [Nat] 0 l 2;")
  #raw("▶ 6 : Nat")
  #raw("nth [Nat] 0 l 3;")
  #raw("▶ 9 : Nat")
  #raw("nth [Nat] 0 l 4;")
  #raw("▶ 0 : Nat")
]

Демонстрація того, що коректно типізований алгоритм сортування можна реалізувати в System F,
була віртуозним досягненням Reynolds (1985). Його алгоритм трохи відрізнявся від наведеного
тут.]

#solution("23.5.1")[Структура доведення майже точнісінько така сама, як для 9.3.9
(див. стор. 107). Для правила застосування типу E-TappTabs нам потрібна одна додаткова лема
про підстановку, паралельна лемі 9.3.8 (див. стор. 106).

#disp($ "Якщо " Gamma, X, Delta tack t : T, " то " Gamma, [X |-> S]Delta tack [X |-> S]t : [X |-> S]T. $)

Додатковий контекст $Delta$ тут потрібен, щоб дістати достатньо сильну індукційну гіпотезу;
якщо його опустити, випадок T-Abs зазнає невдачі.]

#solution("23.5.2")[Знову ж таки, структура цього доведення дуже подібна до доведення
поступу для $lambda arrow.r$, теорема 9.3.5. Лему про канонічні форми (9.3.4) розширюють
одним додатковим випадком

#disp($ "Якщо " v " — значення типу " forall X. T_12, " то " v = lambda X. t_12. $)

який уживають у випадку застосування типу основного доведення.]

#solution("23.6.3")[Усі частини — це відносно прямолінійні індуктивні та/або обчислювальні
аргументи, крім останньої, де потрібно трохи більше прозірливості, щоб побачити, як скласти
все докупи й дістати суперечність. Pawel Urzyczyn підказав структуру цього аргументу.

(1) Прямолінійна індукція за $t$ з уживанням леми про обернення для відношення типізації.

(2) Ми показуємо, індукцією за кількістю зовнішніх абстракцій типу та застосувань, що

#figure([], rules([
  $ "Якщо " t " має форму " lambda Y. (r [B]) " для деяких " Y, B " і " r " (де " r $
  $ "не обов’язково викрито), і якщо " op("erase")(t) = m " і " Gamma tack t : T, " то існує" $
  $ "деякий тип " s " форми " s = lambda X. (u [A]) ", причому " op("erase")(s) = m $ 
  $ "і " Gamma tack s : T ", де до того ж " u " викрито." $
]))

У базовому випадку зовнішніх абстракцій типу чи застосувань немає — тобто сам $r$ викрито,
і ми закінчили.

В індукційному випадку зовнішній конструктор $r$ — це або абстракція типу, або застосування
типу. Якщо це застосування типу, скажімо $r_1 [R]$, то ми додаємо $R$ до послідовності $B$ і
застосовуємо індукційну гіпотезу. Якщо це абстракція типу, скажімо $lambda Z. r_1$, то
треба розглянути два підвипадки:

(a) Якщо послідовність застосувань $B$ порожня, то ми можемо додати $Z$ до послідовності
абстракцій $Y$ і застосувати індукційну гіпотезу.

(b) Якщо $B$ непорожня, то ми можемо записати $t$ як

#disp($ t = lambda Y. ((lambda Z. r_1) [B_0] [B']) $)

де $B = B_0 B'$. Але цей терм містить редекс R-Beta2; зведення цього редекса лишає нам терм

#disp($ t' = lambda Y. ([B_0 |-> Z]r_1 [B']) $)

де $[B_0 |-> Z]r_1$ містить строго менше зовнішніх абстракцій типу та застосувань, ніж $r$.
До того ж теорема про збереження суб’єкта каже нам, що $t'$ має той самий тип, що й $t$.
Бажаний результат тепер випливає, якщо застосувати індукційну гіпотезу.

(3) Негайно з леми про обернення.

(4) Прямолінійне обчислення з частин (1), (3) і (2) [двічі].

(5) Негайно з частини (2) і леми про обернення.

(6) Індукцією за розміром $T_1$. У базовому випадку, де $T_1$ — змінна, ця змінна мусить
походити з $X_1 X_2$, бо інакше ми мали б

#disp($ [X_1 X_2 |-> A](forall Y. T_1) = forall Y. W = forall Z. (forall Y. W) -> ([X_1 |-> B]T_2), $)

а це не може бути так (ліворуч немає стрілок, а праворуч є щонайменше одна). Решта
випадків випливають безпосередньо з індукційної гіпотези.

(7) Припустімо, задля суперечності, що `omega` типізується. Тоді, за частинами (1) і (3),
існує деякий викритий терм $o = s u$, де

#figure([], rules([
  $ op("erase")(s) = lambda x. x x quad quad op("erase")(u) = lambda y. y y $
  $ Gamma tack s : U -> V quad quad quad quad Gamma tack u : U. $
]))

За частиною (2) існують терми $s' = lambda R. (s_0 [E])$ і $u' = lambda V. (u_0 [F])$, де
$s_0$ і $u_0$ викрито, а також

#figure([], rules([
  $ op("erase")(s_0) = lambda x. x x quad quad op("erase")(u_0) = lambda y. y y $
  $ Gamma tack s' : U -> V quad quad quad quad Gamma tack u' : U. $
]))

Оскільки $s'$ має стрілковий тип, $R$ мусить бути порожнім. Так само, оскільки $s_0$ і $u_0$
викрито, вони обидва мусять починатися з абстракцій, тож $E$ і $F$ теж порожні, і ми маємо

#figure([], rules([
  $ o' = s' u' $
  $ = s_0 (lambda V. u_0) $
  $ = (lambda x : T_x . w) (lambda V. lambda y : T_y . v), $
]))

де $op("erase")(w) = x x$ і $op("erase")(v) = y y$. За лемою про обернення, $U = T_x$, і

#figure([], rules([
  $ Gamma, x : T_x tack w : W quad quad quad quad Gamma, V, y : T_y tack v : P. $
]))

Застосовуючи частину (4) до першого з них, отримуємо або

(a) $T_x = forall X. X_i$, або

(b) $T_x = forall X_1 X_2 . T_1 -> T_2$, і для деяких $A$ і $B$

#disp($ [X_1 X_2 |-> A]T_1 = [X_1 |-> B](forall Z. T_1 -> T_2). $)

За частиною (5) $T_x$ мусить мати другу форму, тож, за частиною (6), найлівіший листок $T_1$
— це $X_i in X_1 X_2$.

Тепер, застосовуючи частину (4) до типізації $Gamma, V, y : T_y tack v : P$, маємо або

(a) $T_y = forall Y. Y_i$, або

(b) $T_y = forall Y_1 Y_2 . S_1 -> S_2$, і для деяких $C$ і $D$

#disp($ [Y_1 Y_2 |-> C]S_1 = [Y_1 |-> D](forall Z'. S_1 -> S_2). $)

У першому випадку ми негайно маємо, що найлівіший листок $T_y$ — це $Y_i in Y$. У другому
випадку ми можемо скористатися (6), щоб побачити, що знову найлівіший листок $T_y$ — це
$Y_i in Y_1 Y_2$.

Але з форми $o'$ і леми про обернення ми маємо

#figure([], rules([
  $ forall V. T_y -> V = T_x $
  $ = forall X_1 X_2 . T_1 -> T_2, $
]))

тож, зокрема, $T_y = T_1$. Іншими словами, найлівіший листок $T_1$ той самий, що й у $T_y$.
Підсумовуючи, ми маємо $T_x = forall X_1 X_2 . (forall Y. S) -> T_2$, причому і
$op("leftmost-leaf")(S) = X_i in X_1 X_2$, і $op("leftmost-leaf")(S) = Y_i in Y$. Оскільки
змінні $X_1 X_2$ і $Y$ зв’язані в різних місцях, ми дістали суперечність: наше початкове
припущення, що `omega` типізується, мусить бути хибним.]

#solution("23.7.1")[

#code[
  #raw("let r = λX. ref (λx:X. x) in")
  #raw("(r[Nat] := (λx:Nat. succ x);")
  #raw(" (!(r[Bool])) true);")
]]

#solution("24.1.1")[Пакет `p6` надає константу `a` і функцію `f`, але єдина операція, яку
дозволяють типи цих компонентів, — це застосувати `f` до `a` якусь кількість разів і тоді
відкинути результат. Пакет `p7` дозволяє нам уживати `f`, щоб утворювати значення типу $X$,
але з цими значеннями ми нічого не можемо зробити. У `p8` обидва компоненти можна вживати,
але тепер нічого не приховано — ми могли б узагалі відмовитися від екзистенційного
пакування.]

#solution("24.2.1")[

#code[
  #raw("stackADT =")
  #raw("  {*List Nat,")
  #raw("   {new = nil [Nat],")
  #raw("    push = λn:Nat. λs:List Nat. cons [Nat] n s,")
  #raw("    top = λs:List Nat. head [Nat] s,")
  #raw("    pop = λs:List Nat. tail [Nat] s,")
  #raw("    isempty = isnil [Nat]}}")
  #raw("as {∃Stack, {new: Stack, push: Nat→Stack→Stack, top: Stack→Nat,")
  #raw("              pop: Stack→Stack, isempty: Stack→Bool}};")
  #raw("▶ stackADT : {∃Stack,")
  #raw("               {new:Stack,push:Nat→Stack→Stack,top:Stack→Nat,")
  #raw("                pop:Stack→Stack,isempty:Stack→Bool}}")
  #raw("let {Stack,stack} = stackADT in")
  #raw("stack.top (stack.push 5 (stack.push 3 stack.new));")
  #raw("▶ 5 : Nat")
]]

#solution("24.2.2")[

#code[
  #raw("counterADT =")
  #raw("  {*Ref Nat,")
  #raw("   {new = λ_:Unit. ref 1,")
  #raw("    get = λr:Ref Nat. !r,")
  #raw("    inc = λr:Ref Nat. r := succ(!r)}}")
  #raw("  as {∃Counter,")
  #raw("      {new: Unit→Counter, get: Counter→Nat, inc: Counter→Unit}};")
  #raw("▶ counterADT : {∃Counter,")
  #raw("                {new:Unit→Counter,get:Counter→Nat,")
  #raw("                 inc:Counter→Unit}}")
]]

#solution("24.2.3")[

#code[
  #raw("FlipFlop = {∃X, {state:X, methods: {read: X→Bool, toggle: X→X,")
  #raw("                                    reset: X→X}}};")
  #raw("f = {*Counter,")
  #raw("     {state = zeroCounter,")
  #raw("      methods = {read = λs:Counter. iseven (sendget s),")
  #raw("                 toggle = λs:Counter. sendinc s,")
  #raw("                 reset = λs:Counter. zeroCounter}}}")
  #raw("  as FlipFlop;")
  #raw("▶ f : FlipFlop")
]]

#solution("24.2.4")[

#code[
  #raw("c = {*Ref Nat,")
  #raw("     {state = ref 5,")
  #raw("      methods = {get = λx:Ref Nat. !x,")
  #raw("                 inc = λx:Ref Nat. (x := succ(!x); x)}}}")
  #raw("  as Counter;")
]]

#solution("24.2.5")[Цей тип дозволив би нам реалізувати об’єкти-множини з методами об’єднання,
але він заважав би нам їх уживати. Щоб викликати метод об’єднання такого об’єкта, треба
передати йому два значення того самого типу подання $X$. Але вони не можуть походити з двох
різних об’єктів-множин, бо, щоб дістати обидва стани, нам довелося б розкрити кожен об’єкт,
а це зв’язало б дві різні змінні типу; стан другої множини не можна було б передати операції
об’єднання першої. (Це не просто впертість перевіряча типів: легко бачити, що передавати
конкретне подання однієї множини операції об’єднання іншої було б некоректно, оскільки
подання другої множини може взагалі кажучи бути довільно відмінним від першої.) Отже, ця
версія типу `NatSet` дозволяє нам лише об’єднувати множину саму з собою!]

#solution("24.3.2")[Щонайменше нам треба показати, що правила типізації та обчислення для
екзистенційних типів зберігаються за цього перекладу — тобто що, якщо позначити $[[—]]$
функцію, яка виконує всі ці переклади, то $Gamma tack t : T$ тягне за собою
$[[Gamma]] tack [[t]] : [[T]]$, і $t arrow.r.long^* t'$ тягне за собою
$[[t]] arrow.r.long^* [[t']]$. Ці властивості легко перевірити. Ми могли б також
сподіватися виявити, що обернені твердження істинні — тобто що некоректно типізований терм
у мові з екзистенційними типами завжди відображається перекладом у некоректно типізований
терм, а застряглий терм — у застряглий; ці властивості, на жаль, не виконуються: наприклад,
переклад відображає некоректно типізований (і застряглий) терм
$({*"Nat", 0} "as" {exists X. X}) ["Bool"]$ у коректно типізований (і не застряглий).]

#solution("24.3.3")[Я не знаю жодного місця, де це було б виписано. Здається, це мусило б
бути можливо, але перетворення не буде локальним синтаксичним цукром — його треба буде
застосувати до всієї програми відразу.]

#solution("25.2.1")[Зсув типу $T$ на $d$ позицій вище межі $c$, який записують
$arrow.t_c^d (T)$, означують так:

#disp($ arrow.t_c^d (k) = cases(
  k quad quad quad "якщо " k < c,
  k + d quad quad "якщо " k >= c,
) $)

#disp($ arrow.t_c^d (T_1 -> T_2) = arrow.t_c^d (T_1) -> arrow.t_c^d (T_2) \
 arrow.t_c^d (forall. T_1) = forall. arrow.t_(c+1)^d (t_1) \
 arrow.t_c^d ({exists, T_1}) = {exists, arrow.t_(c+1)^d (T_1)} $)

Запис $arrow.t_0^d (T)$ означає зсув на $d$ позицій усіх змінних у типі $T$, тобто
$arrow.t^d (T)$.]

#solution("25.4.1")[Він звільняє місце для змінної типу $X$. Результат підстановки $v_12$
в $t_2$ має бути коректно визначеним за областю дії в контексті форми $Gamma, X$, тоді як
початковий $v_12$ означено відносно самого лише $Gamma$.]

#solution("26.2.3")[Одне місце, де потрібне повне правило F<:, — це кодування об’єктів у
Abadi, Cardelli і Viswanathan (1996), описане також у Abadi і Cardelli (1996).]

#solution("26.3.4")[

#code[
  #raw("spluszz = λn:SZero. λm:SZero.")
  #raw("            λX. λS<:X. λZ<:X. λs:X→S. λz:Z.")
  #raw("              n [X] [S] [Z] s (m [X] [S] [Z] s z);")
  #raw("spluspn = λn:SPos. λm:SNat.")
  #raw("            λX. λS<:X. λZ<:X. λs:X→S. λz:Z.")
  #raw("              n [X] [S] [X] s (m [X] [S] [Z] s z);")
  #raw("▶ spluspn : SPos → SNat → SPos")
]]

#solution("26.3.5")[

#code[
  #raw("SBool = ∀X. ∀T<:X. ∀F<:X. T→F→X;")
  #raw("STrue = ∀X. ∀T<:X. ∀F<:X. T→F→T;")
  #raw("SFalse = ∀X. ∀T<:X. ∀F<:X. T→F→F;")
  #raw("tru = λX. λT<:X. λF<:X. λt:T. λf:F. t;")
  #raw("▶ tru : STrue")
  #raw("fls = λX. λT<:X. λF<:X. λt:T. λf:F. f;")
  #raw("▶ fls : SFalse")
  #raw("notft = λb:SFalse. λX. λT<:X. λF<:X. λt:T. λf:F. b[X][F][T] f t;")
  #raw("▶ notft : SFalse → STrue")
  #raw("nottf = λb:STrue. λX. λT<:X. λF<:X. λt:T. λf:F. b[X][F][T] f t;")
  #raw("▶ nottf : STrue → SFalse")
]]

#solution("26.4.3")[У випадках абстракції та абстракції типу в частинах (1) і (2), а також
у випадку квантифікатора в (3) і (4).]

#solution("26.4.5")[Частина (1) ведеться індукцією за виведеннями підтипування. Усі
випадки або негайні (S-Refl, S-Top), або є прямолінійними застосуваннями індукційної
гіпотези (S-Trans, S-Arrow, S-All), крім S-TVar, який цікавіший. Припустімо, останнє правило
у виведенні $Gamma, X <: Q, Delta tack S <: T$ — це примірник S-TVar, тобто $S$ — деяка
змінна $Y$, а $T$ — верхня межа $Y$ в контексті. Треба розглянути дві можливості. Якщо $X$ і
$Y$ — різні змінні, то припущення $Y <: T$ також можна знайти в контексті
$Gamma, X <: P, Delta$, і результат негайний. З другого боку, якщо $X = Y$, то $T = Q$; щоб
завершити аргумент, нам треба показати, що $Gamma, X <: P, Delta tack X <: Q$. За S-TVar ми
маємо $Gamma, X <: P, Delta tack X <: P$. До того ж, за припущенням, $Gamma tack P <: Q$,
тож за послабленням (лема 26.4.2) $Gamma, X <: P, Delta tack P <: Q$. Склеївши ці два нові
виведення разом із S-Trans, дістаємо бажаний результат.

Частина (2) — рутинна індукція за виведеннями типізації, яка вживає частину (1) для
посилки підтипування у випадку застосування типу.]

#solution("26.4.11")[Усі доведення — прямолінійна індукція за виведеннями підтипування. Ми
показуємо лише перше, ведучи його розбором випадків за останнім правилом у виведенні.
Випадки S-Refl і S-Top негайні. S-TVar трапитися не може (ліва частина висновку S-TVar може
бути лише змінною, а не стрілкою); так само не може трапитися S-All. Якщо останнє правило —
примірник S-Arrow, то підвиведення і є бажаними результатами. Нарешті, припустімо, що
останнє правило — примірник S-Trans, тобто що ми маємо $Gamma tack S_1 -> S_2 <: U$ і
$Gamma tack U <: T$ для деякого $U$. За індукційною гіпотезою або $U$ — це `Top` (і тоді
$T$ теж `Top` за частиною (4) вправи, і ми закінчили), або $U$ має форму $U_1 -> U_2$, де
$Gamma tack U_1 <: S_1$ і $Gamma tack S_2 <: U_2$. У другому випадку ми застосовуємо
індукційну гіпотезу знову до другого підвиведення початкового S-Trans і дізнаємося, що або
$T = "Top"$ (і ми закінчили), або $T$ має форму $T_1 -> T_2$, де $Gamma tack T_1 <: U_1$ і
$Gamma tack U_2 <: T_2$. Два вживання транзитивності кажуть нам, що $Gamma tack T_1 <: S_1$
і $Gamma tack S_2 <: T_2$, звідки бажаний результат випливає за S-Arrow.]

#solution("26.5.1")[

#figure([], rules([
  #rule([$Gamma tack S_1 <: T_1$ #h(1.5em) $Gamma, X <: S_1 tack S_2 <: T_2$], "S-Some",
        [$Gamma tack {exists X <: S_1, S_2} <: {exists X <: T_1, T_2}$])
]))
]

#solution("26.5.2")[Без підтипування їх лише чотири:

#code[
  #raw("{*Nat, {a=5,b=7}} as {∃X, {a:Nat,b:Nat}};")
  #raw("{*Nat, {a=5,b=7}} as {∃X, {a:X,b:Nat}};")
  #raw("{*Nat, {a=5,b=7}} as {∃X, {a:Nat,b:X}};")
  #raw("{*Nat, {a=5,b=7}} as {∃X, {a:X,b:X}};")
]

Із підтипуванням і обмеженою квантифікацією їх досить багато більше — наприклад:

#code[
  #raw("{*Nat, {a=5,b=7}} as {∃X, {a:Nat}};")
  #raw("{*Nat, {a=5,b=7}} as {∃X, {b:X}};")
  #raw("{*Nat, {a=5,b=7}} as {∃X, {a:Top,b:X}};")
  #raw("{*Nat, {a=5,b=7}} as {∃X, Top};")
  #raw("{*Nat, {a=5,b=7}} as {∃X<:Nat, {a:X,b:X}};")
  #raw("{*Nat, {a=5,b=7}} as {∃X<:Nat, {a:Top,b:X}};")
]]

#solution("26.5.3")[Один спосіб зробити це — вкласти ADT лічильника зі скиданням усередину
ADT лічильника:

#code[
  #raw("counterADT =")
  #raw("  {*Nat,")
  #raw("   {new = 1, get = λi:Nat. i, inc = λi:Nat. succ(i),")
  #raw("    rcADT =")
  #raw("      {*Nat,")
  #raw("       {new = 1, get = λi:Nat. i, inc = λi:Nat. succ(i),")
  #raw("        reset = λi:Nat. 1}}")
  #raw("      as {∃ResetCounter<:Nat,")
  #raw("           {new: ResetCounter, get: ResetCounter→Nat,")
  #raw("            inc: ResetCounter→ResetCounter,")
  #raw("            reset: ResetCounter→ResetCounter}} }}")
  #raw("  as {∃Counter,")
  #raw("      {new: Counter, get: Counter→Nat, inc: Counter→Counter,")
  #raw("       rcADT:")
  #raw("       {∃ResetCounter<:Counter,")
  #raw("        {new: ResetCounter, get: ResetCounter→Nat,")
  #raw("         inc: ResetCounter→ResetCounter,")
  #raw("         reset: ResetCounter→ResetCounter}}}};")
  #raw("▶ counterADT : {∃Counter,")
  #raw("                {new:Counter,get:Counter→Nat,inc:Counter→Counter,")
  #raw("                 rcADT:{∃ResetCounter<:Counter,")
  #raw("                       {new:ResetCounter,get:ResetCounter→Nat,")
  #raw("                        inc:ResetCounter→ResetCounter,")
  #raw("                        reset:ResetCounter→ResetCounter}}}}")
]

Коли ці пакети розкрито, результат той, що контекст, у якому перевіряють решту програми,
міститиме зв’язування змінних типу форми `Counter<:Top`, `counter:{...}`,
`ResetCounter<:Counter`, `resetCounter:{...}`:

#code[
  #raw("let {Counter,counter} = counterADT in")
  #raw("let {ResetCounter,resetCounter} = counter.rcADT in")
  #raw("counter.get")
  #raw("  (counter.inc")
  #raw("     (resetCounter.reset (resetCounter.inc resetCounter.new)));")
  #raw("▶ 2 : Nat")
]]

#solution("26.5.4")[Усе, що нам треба зробити, — це додати межі в очевидних місцях до
кодування з §24.3. На рівні типів ми дістаємо:

#disp($ {exists X <: S, T} =^"def" forall Y. (forall X <: S. T -> Y) -> Y. $)

Зміни на рівні термів випливають із цього безпосередньо.]

#solution("27.1")[Ось один спосіб:

#code[
  #raw("setCounterClass =")
  #raw("  λM<:SetCounter. λR<:CounterRep.")
  #raw("  λself: Ref(R→M).")
  #raw("    λr: R.")
  #raw("       {get = λ_:Unit. !(r.x),")
  #raw("        set = λi:Nat. r.x:=i,")
  #raw("        inc = λ_:Unit. (!self r).set (succ((!self r).get unit))};")
  #raw("▶ setCounterClass : ∀M<:SetCounter.")
  #raw("                        ∀R<:CounterRep.")
  #raw("                          (Ref (R→M)) → R → SetCounter")
  #raw("instrCounterClass =")
  #raw("  λM<:InstrCounter.")
  #raw("  λR<:InstrCounterRep.")
  #raw("  λself: Ref(R→M).")
  #raw("    λr: R.")
  #raw("      let super = setCounterClass [M] [R] self in")
  #raw("         {get = (super r).get,")
  #raw("          set = λi:Nat. (r.a:=succ(!(r.a)); (super r).set i),")
  #raw("          inc = (super r).inc,")
  #raw("          accesses = λ_:Unit. !(r.a)};")
  #raw("▶ instrCounterClass : ∀M<:InstrCounter.")
  #raw("                         ∀R<:InstrCounterRep.")
  #raw("                           (Ref (R→M)) → R → InstrCounter")
  #raw("newInstrCounter =")
  #raw("  let m = ref (λr:InstrCounterRep. error as InstrCounter) in")
  #raw("  let m’ =")
  #raw("    instrCounterClass [InstrCounter] [InstrCounterRep] m in")
  #raw("  (m := m’;")
  #raw("   λ_:Unit. let r = {x=ref 1, a=ref 0} in m’ r);")
  #raw("▶ newInstrCounter : Unit → InstrCounter")
]]

#solution("28.2.3")[У випадку T-TAbs ми додаємо тривіальне вживання S-Refl, щоб дати
додаткову посилку для S-All. У випадку T-TApp лема про обернення для підтипування (для
повного F<:) каже нам, що $N_1 = forall X <: N_11 . N_12$, де $Gamma tack T_11 <: N_11$ і
$Gamma, X <: T_11 tack N_12 <: T_12$. Уживаючи транзитивність, ми бачимо, що
$Gamma tack T_2 <: T_11$, що виправдовує вживання TA-TApp, щоб дістати
$Gamma tack ▶ t_1 [T_2] : [X |-> T_2]N_12$. Ми завершуємо, як і раніше, уживаючи збереження
підтипування за підстановки (лема 26.4.8), щоб дістати
$Gamma tack [X |-> T_2]N_12 <: [X |-> T_2]T_12 = T$.]

#solution("28.5.1")[Теорема 28.3.5 (зокрема, випадок для S-All) не виконується для
повного F<:.]

#solution("28.5.6")[Зауважмо, по-перше, що обмеженим і необмеженим квантифікаторам не слід
дозволяти змішуватися: має бути правило підтипування для порівняння двох обмежених
квантифікаторів і окреме для двох необмежених, але жодного правила для порівняння
обмеженого квантифікатора з необмеженим. Інакше ми повернулися б рівно туди, звідки
почали!

Для частин (1) і (2) див. подробиці в Katiyar і Sankar (1992). Для частини (3) відповідь
«ні»: додавання типів записів із підтипуванням за шириною до обмеженої системи знову робить
її нерозв’язною. Проблема в тому, що порожній тип запису — це свого роду максимальний тип
(серед типів записів), і його можна вжити, щоб спричинити розходження в перевірячі
підтипів, скориставшись видозміненою версією прикладу Ghelli. Якщо
$T = forall X <: {}. not {a : forall Y <: X. not Y}$, то вхід
$X_0 <: {a : T} tack X_0 <: {a : forall X_1 <: X_0 . not X_1}$ спричинить розходження
перевіряча підтипів.

Martin Hofmann допоміг мені опрацювати цей приклад. Те саме спостереження зробили Katiyar і
Sankar (1992).]

#solution("28.6.3")[

1. Я нараховую 9 спільних підтипів:

#disp($ forall X <: Y' -> Z'. Y -> Z' quad quad forall X <: Y' -> Z'. "Top" -> Z' quad quad forall X <: Y' -> Z'. X \
 forall X <: Y' -> "Top". Y -> Z' quad quad forall X <: Y' -> "Top". "Top" -> Z' quad quad forall X <: Y' -> "Top". X \
 forall X <: "Top". Y -> Z' quad quad forall X <: "Top". "Top" -> Z' quad quad forall X <: "Top". X. $)

2. І $forall X <: Y' -> Z'. Y -> Z'$, і $forall X <: Y' -> Z'. X$ є нижніми межами для $S$ і
   $T$, але ці два типи не мають спільного надтипу, який теж був би підтипом $S$ і $T$.

3. Розгляньмо $S -> "Top"$ і $T -> "Top"$. (Або $forall X <: Y' -> Z'. Y -> Z'$ і
   $forall X <: Y' -> Z'. X$.)]

#solution("28.7.1")[Функції $R_(X, Gamma)$ і $L_(X, Gamma)$, які відображають типи
відповідно на їхній найменший вільний від $X$ надтип і їхній найбільший вільний від $X$
підтип, означено на рисунку A-2. (Щоб не захаращувати, ми опускаємо індекси $X$ і $Gamma$.)
Ці два означення мають різні побічні умови, бо щоразу, коли з’являється $L$, треба
перевірити, чи воно означене (записують $L(T) eq.not op("fail")$), тоді як $R$ завжди
означене, завдяки наявності типу `Top`. Правильність цих означень доведено в Ghelli і
Pierce (1998).]

// The book sets Figure A-2 as TWO columns side by side — R definitions on the
// left, L on the right, each with its own side conditions — and the source
// extract interleaved the two columns into unreadable fragments, so the
// transcription omitted the whole board (the caption line survived as a bare
// sentence, which the caption check could not see: it only counted `#figure`
// calls whose caption starts "Рисунок"). Structure read off printed page 560.
#tbl([Рисунок A-2: Найменший вільний від $X$ надтип і найбільший вільний від $X$ підтип заданого типу], [
  #grid(
    columns: (1fr, 1fr), column-gutter: 1.4em,
    align: (center, center),
    $ R(forall Y <: S. T) = cases(
      forall Y <: S. R(T) &"якщо " X eq.not op("FV")(S),
      "Top" &"якщо " X in op("FV")(S),
    ) $,
    $ L(forall Y <: S. T) = cases(
      forall Y <: S. L(T) &"якщо " L(T) eq.not op("fail") " і " X eq.not op("FV")(S),
      op("fail") &"інакше",
    ) $,
    $ R({exists Y <: S. T}) = cases(
      {exists Y <: S. R(T)} &"якщо " X eq.not op("FV")(S),
      "Top" &"якщо " X in op("FV")(S),
    ) $,
    $ L({exists Y <: S. T}) = cases(
      {exists Y <: S. L(T)} &"якщо " L(T) eq.not op("fail") " і " X eq.not op("FV")(S),
      op("fail") &"інакше",
    ) $,
    $ R(S -> T) = cases(
      L(S) -> R(T) &"якщо " L(S) eq.not op("fail"),
      "Top" &"якщо " L(S) = op("fail"),
    ) $,
    $ L(S -> T) = cases(
      R(S) -> L(T) &"якщо " L(T) eq.not op("fail"),
      op("fail") &"якщо " L(T) = op("fail"),
    ) $,
    $ R(X) = T quad "де " X <: T in Gamma $,
    $ L(X) = op("fail") $,
    $ R(Y) = Y quad "коли " Y eq.not X $,
    $ L(Y) = Y quad "коли " Y eq.not X $,
    $ R("Top") = "Top" $,
    $ L("Top") = "Top" $,
  )
])

#solution("28.7.2")[Один легкий спосіб показати нерозв’язність повних обмежених
екзистенційних типів (належить Ghelli і Pierce, 1998) — дати переклад $[[—]]$ із задач
підтипування в повному F<: у задачі підтипування в системі лише з екзистенційними типами,
такий що $Gamma tack S <: T$ вивідне в F<: тоді й лише тоді, коли
$[[Gamma tack S <: T]]$ вивідне в системі з екзистенційними типами. Це кодування можна
означити на типах так:

#figure([], rules([
  $ [[X]] = X quad quad quad quad quad [[op("Top")]] = "Top" $
  $ [[forall X <: T_1 . T_2]] = not {exists X <: T_1, not [[T_2]]} quad quad [[T_1 -> T_2]] = [[T_1]] -> [[T_2]] $
]))

де $not S = forall X <: S. X$. Ми поширюємо його на контексти, беручи
$[[X_1 <: T_1, , dots, X_n <: T_n]] = X_1 <: [[T_1]], dots, X_n <: [[T_n]]$, і на
твердження про підтипування, беручи $[[Gamma tack S <: T]] = [[Gamma]] tack [[S]] <: [[T]]$.]

#solution("29.1.1")[$forall X. X -> X$ — це власний тип, з елементами на кшталт
$lambda X. lambda x : X. x$. Ці терми — поліморфні функції, які, будучи конкретизовані
типом $T$, дають функцію з $T$ в $T$. На противагу цьому, $lambda X. X -> X$ — це оператор
типу — функція, яка, будучи застосована до типу $T$, дає власний тип $T -> T$ функцій з $T$ в $T$.

Іншими словами, $forall X. X -> X$ — це тип, чиї елементи є термовими функціями з типів у
терми; конкретизація однієї з них (застосуванням її до типу, що записують $t [T]$) дає
елемент стрілкового типу $T -> T$. З другого боку, $lambda X. X -> X$ сама є функцією (з
типів у типи); конкретизація її типом $T$ (що записують $(lambda X. X -> X) T$) дає сам тип
$T -> T$, а не один з його елементів.

Наприклад, якщо `fn` має тип $forall X. X -> X$, а $op("Op") = lambda X. X -> X$, то
$op("fn") [T] : T -> T = op("Op") T$.]

#solution("29.1.2")[$"Nat" -> "Nat"$ — це (власний) тип функцій, а не функція на рівні
типів.]

#solution("30.3")[Лему 30.3.1 уживають у випадках T-Abs, T-TApp і T-Eq. Лему 30.3.2
уживають у випадку T-Var.]

#solution("30.3.8")[Індукцією за сумарними розмірами заданих виведень, із розбором
випадків за останніми правилами обох. Якщо котресь із виведень закінчується QR-Refl, то
інше виведення і є бажаним результатом. Якщо котресь із виведень закінчується QR-Abs,
QR-Arrow або QR-All, то, за формою правил, обидва виведення мусять закінчуватися тим самим
правилом, і результат випливає з прямолінійного вживання індукційної гіпотези. Якщо обидва
виведення закінчуються QR-App, то результат знову випливає з прямолінійного вживання
індукційної гіпотези. Решта випадків цікавіші.

Якщо обидва виведення закінчуються QR-AppAbs, то ми маємо

#disp($ S = (lambda X :: K_11 . S_12) S_2 quad quad quad T = [X |-> T_2]T_12 quad quad quad U = [X |-> U_2]U_12, $)

причому

#disp($ S_12 ⇛ T_12 quad quad S_2 ⇛ T_2 quad quad quad S_12 ⇛ U_12 quad quad S_2 ⇛ U_2. $)

За індукційною гіпотезою існують $V_12$ і $V_2$ такі, що

#disp($ T_12 ⇛ V_12 quad quad T_2 ⇛ V_2 quad quad quad U_12 ⇛ V_12 quad quad U_2 ⇛ V_2. $)

Застосувавши лему 30.3.7 двічі, ми отримуємо $[X |-> T_2]T_12 ⇛ [X |-> V_2]V_12$ і
$[X |-> U_2]U_12 ⇛ [X |-> V_2]V_12$ — тобто $T ⇛ V$ і $U ⇛ V$.

Нарешті, припустімо, що одне виведення (скажімо, перше) закінчується QR-App, а друге —
QR-AppAbs. У цьому випадку ми маємо

#disp($ S = (lambda X :: K_11 . S_12) S_2 quad quad quad T = (lambda X :: K_11 . T_12') T_2' quad quad quad U = [X |-> U_2]U_12, $)

де знову $S_12 ⇛ T_12$, $S_2 ⇛ T_2$, $S_12 ⇛ U_12$ і $S_2 ⇛ U_2$. Знову, за індукційною
гіпотезою, існують $V_12$ і $V_2$ такі, що $T_12 ⇛ V_12$, $T_2 ⇛ V_2$, $U_12 ⇛ V_12$ і
$U_2 ⇛ V_2$. Застосувавши правило QR-AppAbs до першого й другого з них, а лему 30.3.7 — до
третього й четвертого, ми дістаємо $T ⇛ V$ і $U ⇛ V$.#h(0.4em)$star.filled$]

#solution("30.3.10")[Спершу зауважмо, що ми можемо переорганізувати будь-яке виведення
$S ⇚⇛ T$ так, щоб ні симетрія, ні транзитивність не вживалися в підвиведенні примірника
правила симетрії, — тобто ми можемо дійти від $S$ до $T$ послідовністю кроків, склеєних
докупи за допомогою QR-Trans, де кожен крок складається з однокрокового зведення, за яким
необов’язково йде один примірник симетрії. Цю послідовність можна унаочнити так:

#code[
  #raw("··  T")
  #raw("··")
  #raw("S")
  #raw("·")
]

(стрілки, спрямовані справа наліво, — це зведення, що закінчуються симетрією, тоді як
стрілки зліва направо — це несиметризовані зведення). Тепер ми неодноразово вживаємо лему
30.3.8, додаючи маленькі ромби внизу цієї картини, аж доки не дійдемо спільного звідного
для $S$ і $T$.

#code[
  #raw("T")
  #raw("···")
  #raw("S")
  #raw("···")
  #raw("··")
  #raw("·")
]

Той самий аргумент можна подати й у стандартній індуктивній формі, не вдаючись до картинок,
але це, найпевніше, лише утруднить його розуміння, не зробивши його анітрохи
переконливішим.#h(0.4em)$star.filled$]

#solution("30.3.17")[Якщо ми додамо перше чудернацьке правило, властивість поступу
порушиться; із збереженням, проте, усе гаразд. Якщо ми додамо друге правило, порушаться і
поступ, і збереження.]

#solution("30.3.20")[Порівняйте свій розв’язок із вихідними текстами перевіряча `fomega`.]

#solution("30.5.1")[Замість сім’ї типів `FloatList n` ми тепер маємо параметричну сім’ю
типів `List T n` з такими операціями:

#figure([], rules([
  $ op("nil") : forall X. op("FloatList") X 0 $
  $ op("cons") : forall X. Pi n : "Nat". X -> op("FloatList") X (op("succ") n) $
  $ op("hd") : forall X. Pi n : "Nat". op("List") X (op("succ") n) -> X $
  $ op("tl") : forall X. Pi n : "Nat". op("List") X (op("succ") n) -> op("List") X n $
]))]

#solution("31.2.1")[

#figure([], rules([
  #rule([], "", [$Gamma tack A <: op("Id") B quad quad quad quad "Так"$])
  #rule([], "", [$Gamma tack op("Id") A <: B quad quad quad quad "Так"$])
  #rule([], "", [$Gamma tack lambda X. X <: lambda X. "Top" quad quad quad quad "Так"$])
  #rule([], "", [$Gamma tack lambda X. forall Y <: X. Y <: lambda X. forall Y <: "Top". Y quad quad "Ні"$])
  #rule([], "", [$Gamma tack lambda X. forall Y <: X. Y <: lambda X. forall Y <: X. X quad quad "Так"$])
  #rule([], "", [$Gamma tack op("F") B <: B quad quad quad quad "Так"$])
  #rule([], "", [$Gamma tack B <: op("F") B quad quad quad quad "Ні"$])
  #rule([], "", [$Gamma tack op("F") B <: op("F") B quad quad quad quad "Так"$])
  #rule([], "", [$Gamma tack forall F <: (lambda Y. "Top" -> Y). op("F") A <: forall F <: (lambda Y. "Top" -> Y). "Top" -> B quad "Так"$])
  #rule([], "", [$Gamma tack forall F <: (lambda Y. "Top" -> Y). op("F") A <: forall F <: (lambda Y. "Top" -> Y). op("F") B quad "Ні"$])
  #rule([], "", [$Gamma tack "Top"[*, arrow.r.double, *] <: "Top"[* arrow.r.double * arrow.r.double *] quad quad "Ні"$])
]))]

#solution("32.5.1")[Ключове спостереження — те, що $op("Object") M$ є екзистенційним типом:
`Object` — це скорочення для оператора

#code[#raw("λM::*⇒*. {∃X, {state:X, methods:M X}}")]

Коли ми застосовуємо його до $M$, ми дістаємо редекс, який зводиться до екзистенційного типу

#code[#raw("{∃X, {state:X, methods:M X}}.")]

Зауважте, що в це перетворення не залучено жодного підведення — отже, й жодної втрати
інформації.]

#solution("32.7.2")[Властивість мінімальної типізації не виконується для цього числення в
тому вигляді, як ми його означили. Розгляньмо терм

#code[#raw("{#x={a=5,b=7}}.")]

Йому можна приписати і тип ${hash x : {a : "Nat"}}$, і тип
${hash x : {a : "Nat", b : "Nat"}}$, але ці типи непорівнювані. Один розумний спосіб
зарадити цьому — явно анотувати кожне інваріантне поле в термі-записі його передбачуваним
типом. Це фактично перекладає на програміста відповідальність за вибір між двома
наведеними типами.]

#solution("32.5.2")[

#code[
  #raw("sendget =")
  #raw("  λM<:CounterM. λo:Object M.")
  #raw("    let {X, b} = o in b.methods.get(b.state);")
  #raw("sendreset =")
  #raw("  λM<:ResetCounterM. λo:Object M.")
  #raw("    let {X, b} = o in")
  #raw("      {*X,")
  #raw("       {state = b.methods.reset(b.state),")
  #raw("        methods = b.methods}} as Object M;")
]]

#solution("32.9.1")[

#code[
  #raw("MyCounterM =")
  #raw("  λR. {get: R→Nat, set:R→Nat→R, inc:R→R, accesses:R→Nat,")
  #raw("             backup:R→R, reset:R→R};")
  #raw("MyCounterR = {#x:Nat,#count:Nat,#old:Nat};")
  #raw("myCounterClass =")
  #raw("  λR<:MyCounterR.")
  #raw("  λself: Unit→MyCounterM R.")
  #raw("  λ_:Unit.")
  #raw("     let super = instrCounterClass [R] self unit in")
  #raw("     {get = super.get,")
  #raw("      set = super.set,")
  #raw("      inc = super.inc,")
  #raw("      accesses = super.accesses,")
  #raw("      reset = λs:R. s←x=s.old,")
  #raw("      backup = λs:R. s←old=s.x}")
  #raw("  as MyCounterM R;")
  #raw("mc = {*MyCounterR,")
  #raw("      {state = {#x=0,#count=0,#old=0},")
  #raw("       methods = fix (myCounterClass [MyCounterR]) unit}}")
  #raw("     as Object MyCounterM;")
  #raw("sendget [MyCounterM]")
  #raw("  (sendreset [MyCounterM] (sendinc [MyCounterM] mc));")
]

#figure([], rules([
  #emph[«Мій любий Ватсоне, спробуйте трохи аналізу самі, — мовив він з ноткою нетерплячки.
  Ви знаєте мої методи. Застосуйте їх, і буде повчально порівняти результати.»]
  #align(right)[— A. Conan Doyle, The Sign of the Four (1890)]
]))

#figure([], rules([
  #emph[«Як подати це бездоганно, можна лишити як вправу для читача. Я тут користуюся
  улюбленим прийомом, яким математики оминають слизькі місця викладу.»]
  #align(right)[— W. v. O. Quine (1987)]
]))]
