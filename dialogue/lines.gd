class_name Lines
extends RefCounted

## Všechny hlášky ve hře na jednom místě. Nové hlášky stačí připsat do seznamu.
## Zástupné texty: {android} = jméno androida v 5. pádě (např. „Pumpíku“),
## {amount} = počet kreditů.

## Loď zdraví androida, když přistane. Zazní jen někdy.
const GREETINGS := [
	"Ahoj, {android}!",
	"Nazdar, {android}! Jak se vede?",
	"{android}! Rád tě zase vidím.",
	"Čau, {android}, zase já!",
	"Zdravím, {android}!",
	"Ahoj, {android}, chyběl jsi mi!",
]

## Loď chce plnou nádrž.
const ORDER_FULL := [
	"Plnou nádrž galaxínu, prosím.",
	"Do plna, prosím!",
	"Jednou plnou, díky.",
	"Galaxín až po okraj!",
	"Natankuj mi to do plna.",
]

## Loď chce galaxín jen za určitou částku.
const ORDER_AMOUNT := [
	"Galaxín za {amount} kr, prosím.",
	"Chci galaxínu za {amount} kreditů.",
	"Za {amount} kr, víc nemám.",
	"Jen za {amount}, jsem švorc.",
	"Dej mi galaxín za {amount} kr.",
]

## Loď ve frontě ztrácí trpělivost.
const IMPATIENT := [
	"Bude to ještě dlouho?",
	"No tak, {android}, pohni!",
	"Mám tu čekat navěky?",
	"Fronta jak na úřadě...",
	"Čas jsou kredity!",
	"Haló, jsem tu taky!",
]

## Loď ve frontě kouká na zábavní systém (místo stížnosti, když ho stanice má).
const TV_COMMENTS := [
	"Hele, reklama na galaxín!",
	"Tenhle seriál znám!",
	"Aspoň že tu běží telka.",
	"Pusťte tam zprávy!",
	"Ještě chvilku, je to napínavé.",
]

## Texty, které běží na obrazovce zábavního systému.
const BILLBOARD := [
	"Galaxín - palivo budoucnosti!",
	"Plná nádrž, plná pohoda.",
	"Tankuj chytře, tankuj galaxín.",
	"Nejrychlejší hadice v galaxii!",
	"Dnes v 8: Pirátské hvězdy, 3. díl",
]

## Loď to přestalo bavit a odlétá bez placení.
const ANGRY_LEAVE := [
	"Tak to ne! Letím jinam.",
	"Příště ke konkurenci!",
	"Hrozná obsluha!",
	"Na tuhle pumpu už nikdy!",
	"Tady se načekám do smrti!",
	"Ztráta času!",
]

## Spokojená loď po zaplacení. Zazní jen někdy.
const HAPPY_LEAVE := [
	"Díky, {android}!",
	"Díky, zase příště!",
	"Galaxín jak má být!",
	"Měj se, {android}!",
	"Ať se daří!",
	"Jede to jak po másle!",
]

## Loď nechává dýško.
const TIP := [
	"Tady máš dýško, {android}!",
	"Drobné si nech, {android}.",
	"To je za rychlou obsluhu!",
	"Něco navíc pro tebe, {android}.",
	"Kup si nový šroubek!",
]

## Android děkuje za dýško.
const ANDROID_TIP_THANKS := [
	"Jé, děkuju!",
	"To nemusíte!",
	"Díky, šťastný let!",
	"Moje obvody se tetelí!",
]

## Loď dostala nekvalitní galaxín a stanice platí pokutu.
const QUALITY_COMPLAINT := [
	"Tohle je břečka! Hlásím vás!",
	"Fuj, to není galaxín!",
	"Inspekce o tom uslyší!",
	"Motor mi kašle. Pokuta!",
]

## Pumpíkovi došel galaxín v zásobníku.
const ANDROID_EMPTY := [
	"Došel galaxín!",
	"Zásobník je prázdný, šéfe!",
	"Objednej cisternu!",
]

## Cisterna dorazila včas a plná.
const TANKER_ARRIVAL := [
	"Galaxín je tu!",
	"Dovoz galaxínu, podepiš to tady.",
	"Čerstvá várka galaxínu!",
]

## Cisterna dorazila se zpožděním.
const TANKER_LATE := [
	"Promiň, zácpa u Saturnu.",
	"Pozdě, ale přece!",
	"Navigace mě poslala oklikou.",
]

## Cisterna přivezla méně, než se objednalo.
const TANKER_SHORT := [
	"Víc nebylo, šéfe.",
	"Trochu jsem to cestou upil...",
	"Zbytek vrátím v kreditech.",
]

## Cisterna odlétá, protože útočí piráti.
const TANKER_SCARED := [
	"Piráti? Tak to teda ne!",
	"Za tohle mi neplatí!",
	"Zbytek vrátím v kreditech, mizím!",
]

## Vesmírný vetešník přiletěl, když hráči došel galaxín i kredity.
const JUNK_DEALER_OFFER := [
	"Došel ti galaxín i kredity? Takový žal. Jedno vylepšení odkoupím za půlku ceny, férovka.",
	"Čuchám prázdný zásobník až z Jupiteru. Vyber si, s čím se rozloučíš. Dám ti za to půlku.",
	"Nikdo ti teď nepomůže, jen já. Jedno vylepšení za půlku ceny a jsme kamarádi.",
]

## Vetešník přiletěl, ale hráč už nemá co prodat.
const JUNK_DEALER_HANDOUT := [
	"Tady už není co vzít, i krysy odletěly. Tak tady máš něco ode mě, ať se mi klidně spí.",
	"Tolik bídy jsem neviděl ani na Marsu. Na, vezmi si to, než si to rozmyslím.",
]

## Loď odlétá, protože na stanici došel galaxín.
const SHIP_NO_FUEL := [
	"Čerpací stanice bez galaxínu? Sbohem!",
	"Prázdná pumpa, to je mi obsluha.",
	"Tady nic neteče, letím jinam.",
	"Až budete mít galaxín, ozvěte se!",
]

## Android začíná tankovat. Zazní jen někdy.
const ANDROID_REPLY := [
	"Hned to bude!",
	"Rozumím!",
	"Galaxín teče!",
	"Už nesu hadici.",
	"S radostí!",
]

## Android po vylepšení.
const ANDROID_UPGRADE := [
	"Juchů, nové obvody!",
	"Cítím se jako nový!",
	"Teď to půjde rychleji!",
	"Upgrade nainstalován.",
]

## Nákladní loď s velkou nádrží objednává.
const FREIGHTER_ORDER := [
	"Velkou nádrž, prosím. Opravdu velkou.",
	"Do plna. Bude to chvíli trvat.",
	"Plnou, vezu náklad přes půl galaxie.",
]

## Turisté po přistání (pak hodně utratí v obchodě).
const TOURISTS := [
	"Kde tu máte suvenýry?",
	"Fotka s androidem! Jé, ten je roztomilý!",
	"Tohle je ta slavná pumpa z průvodce?",
	"Všichni vystupovat, máme dvacet minut nákupů!",
]

## Loď utíká z fronty, protože útočí piráti.
const SHIP_SCARED := [
	"Piráti! Mizím!",
	"Tady natankuju jindy!",
	"Nic jsem neviděl, už letím!",
	"Galaxín za život nestojí!",
]

## Pirát dorazil ke stanici a začíná útok.
const PIRATE_ARRIVAL := [
	"Kasu sem, pumpaři!",
	"Tohle je přepadení!",
	"Kredity, nebo to tu rozstřílím!",
	"Hezká stanička. Škoda by jí bylo.",
]

## Pirát se posmívá při krádeži.
const PIRATE_TAUNT := [
	"Díky za příspěvek!",
	"Tohle si beru jako dýško.",
	"Galaxín si nech, chceme prachy!",
	"Ještě kousek a jdem.",
]

## Android se staví pirátovi.
const ANDROID_FIGHT := [
	"Takhle ne, kamaráde!",
	"Pistole nabitá galaxínem!",
	"Ze stanice ruce pryč!",
	"Ochranka je v práci!",
]

## Android je po boji poškozený.
const ANDROID_DAMAGED := [
	"Au, jiskří mi to v kloubech...",
	"Potřebuju servis.",
	"Bzučáku, pomoc!",
	"Chvilku netankuju, jsem na kusy.",
]

## Android je zase opravený.
const ANDROID_REPAIRED := [
	"Zase jako nový!",
	"Díky, Bzučáku!",
	"Zpátky k hadici!",
]


## Vybere náhodnou hlášku a doplní do ní hodnoty, např. {"android": "Pumpíku"}.
static func pick(lines: Array, values := {}) -> String:
	return String(lines.pick_random()).format(values)
