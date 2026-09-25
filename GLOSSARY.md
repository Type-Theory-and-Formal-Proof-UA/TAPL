# Глосарій (TAPL → українська)

Єдине джерело істини для термінів. Діти-перекладачі читають його, але **не редагують** —
нові терміни вони повертають батьківському агентові у своєму звіті (поле `new_terms`).

Правило: один термін — один відповідник по всій книзі. Якщо терміна немає тут, беріть
найуживаніший український відповідник і **повідомте його**, а не вигадуйте варіант.

Термінологія узгоджена з `GLOSSARY.md` проєкту ATTаPL (`/Users/ihor/atapl/GLOSSARY.md`) —
обидві книги Benjamin C. Pierce, тож терміни мусять збігатися.

## Загальні поняття
| English | Українською |
|---|---|
| type system | система типів |
| typing (n.) | типізація |
| to typecheck / typechecker | перевіряти типи / перевіряч типів |
| type checking | перевірка типів |
| type inference / reconstruction | виведення типів |
| well-typed | коректно типізований |
| ill-typed | некоректно типізований |
| untyped | негіпований |
| typed | гіпований |
| term | терм |
| expression | вираз |
| value | значення |
| variable | змінна |
| binding | зв’язування |
| binder | зв’язувач |
| bound variable / free variable | зв’язана змінна / вільна змінна |
| substitution | підстановка |
| to substitute | підставляти |
| context | контекст |
| judgment | судження |
| derivation | виведення (derivation tree — дерево виведення) |
| inference rule | правило виведення |
| premise / conclusion | посилка / висновок |
| side condition | побічна умова |
| rule schema | схема правила |
| instance (of a rule) | примірник (правила) |
| to instantiate | конкретизувати (примірником) |
| soundness / sound | коректність / коректний |
| completeness / complete | повнота / повний |
| preservation | збереження (типу) |
| progress | поступ |
| type safety | безпечність типів |
| semantics | семантика |
| operational semantics | операційна семантика |
| denotational semantics | денотаційна семантика |
| axiomatic semantics | аксіоматична семантика |
| evaluation | обчислення |
| reduction | зведення (reduction step — крок зведення) |
| to reduce | зводити |
| normal form | нормальна форма |
| normalization | нормалізація |
| confluence | конфлюентність |
| stuck | застрягає (про стан обчислення) |
| small-step / big-step | дрібнокрокова / великокрокова |
| call by name / call by value | виклик за іменем / виклик за значенням |
| congruence | конгруентність |
| lemma | лема |
| theorem | теорема |
| corollary | наслідок |
| proposition | твердження |
| definition | означення |
| remark | зауваження |
| example | приклад |
| exercise | вправа |
| solution | розв’язок |
| proof | доведення |
| induction | індукція |
| by induction on | індукцією за |
| case | випадок |
| hypothesis (IH) | гіпотеза (індукційна гіпотеза) |
| arbitrary | довільний |
| canonical form | канонічна форма |
| abstract syntax | абстрактний синтаксис |
| concrete syntax | конкретний синтаксис |
| parse tree | дерево розбору |
| grammar | граматика |
| metavariable | метазмінна |
| object language / metalanguage | об’єктна мова / метамова |
| metatheory | метатеорія |
| shorthand | скорочення |
| derived form | похідна форма |
| syntactic sugar | синтаксичний цукор |

## Розділи 1–4 — вступ, негіповані системи
| English | Українською |
|---|---|
| formal methods | формальні методи |
| correctness | правильність |
| specification | специфікація |
| checker | перевіряч |
| property | властивість |
| invariant | інваріант |
| inductive definition | індуктивне означення |
| inductive proof | індуктивне доведення |
| rule induction | індукція за правилами |
| least fixed point | найменша нерухома точка |
| reflexive / transitive closure | рефлексивне / транзитивне замикання |
| to range over | набувати значень з |
| set difference | різниця множин |
| powerset | булеан |
| countable | зліченний |
| relation (n-place) | відношення (n-місне) |
| predicate | предикат |
| preorder | передпорядок |
| partial order | частковий порядок |
| well-founded | цілком упорядкований (обґрунтований) |
| decreasing chain | спадний ланцюг |
| sequence | послідовність |
| permutation | перестановка |
| term algebra | алгебра термів |
| evaluation relation | відношення обчислення |
| stuck term | застряглий терм |
| runtime error | помилка часу виконання |
| parser / interpreter | розбірник / інтерпретатор |
| type checker | перевіряч типів |
| unit test | модульний тест |
| to compile | компілювати |

## Розділи 5–7 — лямбда-числення
| English | Українською |
|---|---|
| lambda-calculus | лямбда-числення |
| lambda-abstraction | лямбда-абстракція |
| application | застосування |
| abstraction | абстракція |
| to apply | застосовувати |
| alpha-conversion | альфа-перетворення |
| alpha-equivalence | альфа-еквівалентність |
| beta-reduction | бета-зведення |
| eta-conversion | ета-перетворення |
| capture-avoiding substitution | підстановка без захоплення змінних |
| to capture | захоплювати |
| free / bound occurrences | вільні / зв’язані входження |
| set of free variables (FV) | множина вільних змінних (FV) |
| nameless representation | безіменне подання |
| de Bruijn index | індекс де Брейна |
| de Bruijn level | рівень де Брейна |
| shifting / shift | зсув / зсувати |
| naming context | контекст найменувань |
| combinatory logic | комбінаторна логіка |
| fixpoint combinator | комбінатор нерухомої точки |
| fixed point | нерухома точка |
| Church numeral | число Черча |
| Church encoding | кодування Черча |
| eager / lazy evaluation | енергійне / ледаче обчислення |
| full beta-reduction | повне бета-зведення |
| normal order | нормальний порядок |
| deterministic | детермінований |
| divergence | розходження (обчислення, що не завершується) |
| to diverge | розходитися |

## Розділи 8–12 — прості типи
| English | Українською |
|---|---|
| simply typed lambda-calculus | просто типізоване лямбда-числення |
| type annotation | анотація типу |
| ascription | приписування типу |
| base type | базовий тип |
| function type | функціональний тип |
| arrow type | стрілковий тип |
| typing relation | відношення типізації |
| typing context | контекст типізації |
| typing rule | правило типізації |
| context extension | розширення контексту |
| minimal typing | мінімальна типізація |
| least upper bound (LUB) | найменша верхня межа |
| join | об’єднання (join) |
| meet | перетин (meet) |
| unique type | єдиний тип |
| inversion | обернення (inversion lemma — лема обернення) |
| canonical forms lemma | лема про канонічні форми |
| substitution lemma | лема про підстановку |
| weakening | послаблення |
| strengthening | підсилення |
| permutation lemma | лема про перестановку |
| type preservation | збереження типу |
| subject reduction | збереження суб’єкта |
| evaluation context | контекст обчислення |
| derived typing rule | похідне правило типізації |
| admissible (rule) | допустиме (правило) |
| unit type | одиничний тип |
| sequencing | послідовне виконання |
| let-binding | let-зв’язування |
| record | запис |
| field | поле |
| tuple | кортеж |
| variant | варіант |
| sum type | сума типів |
| option | опція |
| general recursion | загальна рекурсія |
| termination / terminating | завершуваність / той, що завершується |
| totality / total | тотальність / тотальний |
| well-founded induction | індукція за обґрунтованим відношенням |
| strongly normalizing | сильно нормалізовний |
| erasure | стирання |
| sum of sizes | сума розмірів |
| measure | міра |

## Розділи 13–14 — посилання та винятки
| English | Українською |
|---|---|
| reference | посилання |
| store | сховище |
| location | комірка |
| dereference | розіменування |
| to dereference | розіменовувати |
| assignment | присвоєння |
| store typing | типізація сховища |
| memory allocation | виділення пам’яті |
| garbage collection | збирання сміття |
| aliasing | утворення псевдонімів |
| exception | виняток |
| to raise an exception | породжувати виняток |
| handler | обробник |
| to handle | обробляти |
| to propagate | поширювати |
| error | помилка |
| fail / failure | невдача / невдалий |
| unsafe | небезпечний |
| safety | безпечність |

## Розділи 15–19 — підтипування
| English | Українською |
|---|---|
| subtype / subtyping | підтип / підтипування |
| supertype | надтип |
| to be a subtype of | бути підтипом |
| width subtyping | підтипування за шириною |
| depth subtyping | підтипування за глибиною |
| covariant / contravariant / invariant | коваріантний / контраваріантний / інваріантний |
| variance | варіантність |
| subsumption | підведення |
| subtyping relation | відношення підтипування |
| subtype relation | відношення підтипу |
| top type | верхній тип |
| bottom type | нижній тип |
| refinement | уточнення |
| record subtyping | підтипування записів |
| object | об’єкт |
| method | метод |
| message | повідомлення |
| method invocation | виклик методу |
| self | self |
| subclass / superclass | підклас / надклас |
| inheritance | успадкування |
| to override | перекривати |
| interface | інтерфейс |
| class | клас |
| imperative object | імперативний об’єкт |
| method table | таблиця методів |
| Featherweight Java | Featherweight Java |
| cast | приведення |
| encapsulation | інкапсуляція |
| delegation | делегування |
| to expose | викривати |
| exposure | викриття |

## Розділи 20–21 — рекурсивні типи
| English | Українською |
|---|---|
| recursive type | рекурсивний тип |
| iso-recursive / equi-recursive | ізо-рекурсивний / рівно-рекурсивний |
| unfolding | розгортання |
| to fold / to unfold | згортати / розгортати |
| infinite tree | нескінченне дерево |
| type equivalence | еквівалентність типів |
| subtyping for recursive types | підтипування для рекурсивних типів |
| induction on derivations | індукція за деревами виведення |
| Tarski–Knaster | Тарський–Кнастер |
| lattice | ґратка |
| monotone function | монотонна функція |
| greatest / least fixed point | найбільша / найменша нерухома точка |
| gfp / lfp | gfp / lfp |
| approximant | наближення (approximant) |
| to approximate | наближати |
| reachable | досяжний |
| generative | генеративний |
| inductive / coinductive | індуктивний / коіндуктивний |
| principle of coinduction | принцип коіндукції |

## Розділи 22–28 — поліморфізм
| English | Українською |
|---|---|
| polymorphism | поліморфізм |
| polymorphic | поліморфний |
| monomorphic | моноформний |
| universal type | універсальний тип |
| existential type | екзистенційний тип |
| quantifier | квантифікатор |
| to quantify | квантифікувати |
| type variable | змінна типу |
| type abstraction | абстракція типу |
| type application | застосування типу |
| type operator | оператор типу |
| kind | рід (kind) |
| proper type | власний тип |
| impredicative | імпредикативний |
| predicative | предикативний |
| rank | ранг |
| System F | System F |
| parametricity | параметричність |
| polymorphism (parametric / ad-hoc) | поліморфізм (параметричний / спеціальний) |
| type reconstruction / inference | виведення типів |
| unification | уніфікація |
| unifier | уніфікатор |
| to unify | уніфікувати |
| most general unifier | найзагальніший уніфікатор |
| principal type | головний тип |
| constraint | обмеження |
| constraint solving | розв’язування обмежень |
| substitution (of types) | підстановка (типів) |
| algorithm W / M | алгоритм W / M |
| let-polymorphism | let-поліморфізм |
| generalization / to generalize | узагальнення / узагальнювати |
| existential quantification | екзистенційна квантифікація |
| abstract data type (ADT) | абстрактний тип даних (ADT) |
| package | пакет |
| unpacking | розпакування |
| existential type (encoding) | екзистенційний тип (кодування) |
| bounded quantification | обмежена квантифікація |
| bound (of a variable) | межа (змінної) |
| kernel / full variant | ядерний / повний варіант |
| F-sub | F-sub |
| pure F-sub | чистий F-sub |
| decidability / decidable | розв’язність / розв’язний |
| undecidable | нерозв’язний |
| semi-decidable | напіврозв’язний |
| subtype checking | перевірка підтипування |
| promotion | підвищення |
| to promote | підвищувати |
| type parameter | параметр типу |
| row | рядок (row) |

## Розділи 29–32 — системи вищого порядку
| English | Українською |
|---|---|
| higher-order | вищого порядку |
| type constructor | конструктор типу |
| type argument | аргумент типу |
| kinding | обчислення родів |
| kinding relation | відношення родів |
| well-kinded | коректної побудови родів |
| well-formed | правильно побудований |
| operator abstraction | абстракція оператора |
| operator application | застосування оператора |
| higher-order polymorphism | поліморфізм вищого порядку |
| higher-order subtyping | підтипування вищого порядку |
| F-omega (Fω) | F-omega (Fω) |
| lambda-calculus with type operators | лямбда-числення з операторами типів |
| first-class / second-class | повноправний / неповноправний |
| functor | функтор |
| purely functional object | суто функціональний об’єкт |
| existential package | екзистенційний пакет |
| abstraction boundary | межа абстракції |

## Службові слова (часті звороти)
| English | Українською |
|---|---|
| let us write / we write | записуємо / позначаємо |
| it follows that | з цього випливає, що |
| as required | що й треба було довести |
| without loss of generality | без втрати загальності |
| suppose / assume | припустімо |
| hence / thus / therefore | отже |
| moreover / furthermore | до того ж |
| however | проте |
| since / because | оскільки |
| in the case | у випадку |
| it suffices to show | достатньо показати |
| the proof proceeds by induction | доведення ведеться індукцією |
| the remaining cases are similar | решта випадків аналогічні |
| as usual | як звичайно |
| note that | зауважимо, що |
| we say that … is | кажемо, що … є |
| is given by | задається |
| is defined as | означається як |
| such that | такий, що |
| for all / for every | для всіх / для кожного |
| for some | для деякого |
| there exists | існує |
| respectively | відповідно |
| in particular | зокрема |
| on the one hand / on the other hand | з одного боку / з другого боку |
| at most / at least | щонайбільше / щонайменше |
| up to | з точністю до |
| holds (of a property) | виконується |
| to correspond to | відповідає |
| straightforward | безпосередній |
| tedious | громіздкий |
| crucial | ключовий |
| it is easy to see | легко бачити |
| conversely | навпаки |
| otherwise | інакше |
| in other words | іншими словами |
| that is | тобто |
| for instance | наприклад |
| throughout the book | у всій книзі |
| we shall see | ми побачимо |
| left to the reader | залишаємо читачеві |
| at the end of the chapter | наприкінці розділу |
| in the next section | у наступному розділі |
| as we go along | у міру викладу |

## Доповнено під час перекладу

| redex | редекс (редукований вираз) |
| currying | каррінг |
| stuck (term) | застрягає / застряглий |
| dangling reference | висяче посилання |
| case study | тематичне дослідження |
| lexer / token | лексер / лексема |
| strict (evaluation) | строгий |
| variable capture | захоплення змінних |
| heap | купа |
| deallocation | звільнення пам’яті |
| pointer arithmetic | арифметика вказівників |
| shared state | спільний стан |
| side effect | побічний ефект |
| type reconstruction | виведення типів (у TAPL — синонім до type inference; НЕ «відновлення») |
| linker | компонувальник |
| proof checker | перевіряч доведень |
| model checker | перевіряч моделей |
| proof assistant | помічник доведення |
| escape hatch | аварійний люк |
| run-time error | помилка часу виконання |
| one-to-one correspondence | взаємно однозначна відповідність |
| codomain | кодомен |
| total order | тотальний порядок |
| guard (of a conditional) | охорона |
| subderivation | підвиведення |
| termination measure | міра завершуваності |
| natural semantics | природна семантика |
| semantic domain | семантична область |
| domain theory | теорія областей |
| interpretation function | функція інтерпретації |
| abstract machine | абстрактна машина |
| region inference | виведення регіонів |
| translucent types | напівпрозорі типи |
| row variables | змінні рядків |
| extensible records | розширювані записи |
| object calculus | числення об’єктів |
| type environment | середовище типів |
| evaluation environment | середовище обчислення |
| explicit substitution | явна підстановка |
| generation lemma | лема породження |
| typable | типізовний |
| stuck state | застряглий стан |
| subject expansion | розширення суб’єкта |
| go wrong | йти шкереберть |
| wildcard binder | зв’язувач-заповнювач |
| desugaring | розцукровування |
| product type | тип добутку |
| singleton type | одиничний тип |
| Curry-style | стиль Каррі |
| Church-style | стиль Черча |
| introduction rule | правило введення |
| elimination rule | правило усунення |
| inhabited (type) | населений (про тип) |
| provable | довідне |
| degenerate | вироджений |
| fresh name | свіже ім’я |
| pretty printing | гарний друк |
| name clash | колізія імен |
| string hint | підказка (рядкова) |
| principal unifier | головний уніфікатор |
| less specific / more general | менш конкретна / загальніша |
| occur check | перевірка входження |
| unificand | уніфіканд |
| degree (constraint set) | ступінь (множини обмежень) |
| solution (for a context,term) | розв’язок |
| constraint typing | типізація з обмеженнями |
| constraint set | множина обмежень |
| un-annotated abstraction | неанотована абстракція |

## Символи, розпізнані під час перекладу (Typst)

| У книзі | Значення | Typst |
|---|---|---|
| `⊩` (вертикальна риска з ДВОМА горизонтальними — не «7») | forcing / «σ узгоджується з ∆» у Додатку А | `$forces$` |
| `⊢▶` | алгоритмічний turnstile | `$tack ▶$` (літеральний ▶) |
| `⟶` | довга стрілка (зведення) | `$arrow.r.long$` |
| `⟹` | довга подвійна стрілка | `$arrow.r.double.long$` |

Джерельні витяги інколи плутають `⊩` з цифрою `7` — якщо в математиці стоїть `7` там, де
має бути відношення, це завжди `$forces$`.
| overloading | перевантаження |
| multi-method dispatch | диспетчеризація за багатьма методами |
| intensional polymorphism | інтенсіональний поліморфізм |
| genericity / generics | узагальненість / дженерики |
| tag-free garbage collection | збирання сміття без тегів |
| marshaling | маршалювання |
| local type inference | локальне виведення типів |
| greedy type inference | жадібний алгоритм виведення типів |
| abstraction principle | принцип абстракції |
| typability | типізовність |
| universal quantification | універсальна квантифікація |
| nominal type system | номінальна система типів |
| structural type system | структурна система типів |
| spurious subsumption | фальшиве підведення |
| type tag | позначка типу |
| header word | службове слово-заголовок |
| mixin | міксин |
| multi-methods | мультиметоди |
| stupid cast | безглузде приведення |
| upcast | приведення вгору |
| downcast | приведення вниз |
| receiver | одержувач |
| class table | таблиця класів |
| to override a method | перекривати метод |
| field access | доступ до поля |
| object creation | створення об'єкта |
| hole (evaluation context) | дірка (контексту обчислення) |
| sanity conditions | умови здорового глузду |
| instance variable | змінна примірника |
| open recursion through self | відкрита рекурсія через self |
| support (function) | функція опори (support) |
| invertible (generating function) | оборотна (твірна функція) |
| F-supported / F-ground | F-опорний / F-основний |
| subtree / regular tree | піддерево / регулярне дерево |
| raw µ-type | необроблений µ-тип |
| contractive | контрактивний |
| top-down / bottom-up subexpression | підвираз згори вниз / знизу вгору |
| tree automaton / emptiness test | автомат над деревами / перевірка на порожність |
| minimal simulation | мінімальна симуляція |
| partial equivalence relation | відношення часткової еквівалентності |
| µ-folding | µ-згортання |
| mangled names | спотворені імена |
| support set | множина підтримки |
| height (µ-height) | висота (µ-висота) |
| finite-state generating function | твірна функція зі скінченним станом |
| reachability cycle | цикл досяжності |
