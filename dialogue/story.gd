class_name Story
extends RefCounted

## Příběh: postavy a jejich rozhovory. Rozhovor je seznam replik, replika má `speaker`
## (klíč do SPEAKERS), `mood` (klíč do `portraits`) a `text`. Přehrává je `DialogueBox`.

const PUMPIK := "pumpik"
const ZORA := "zora"
const GUARD := "guard"
const SIZEL := "sizel"

## Mise 7: hráč Zoru prozradil hlídce.
const REPORT_ZORA := "report"
const HIDE_ZORA := "hide"

const SPEAKERS := {
	PUMPIK: {
		"name": "Pumpík",
		"portraits": {
			"neutral": preload("res://assets/sprites/portraits/pumpik_neutral.png"),
			"happy": preload("res://assets/sprites/portraits/pumpik_happy.png"),
			"worried": preload("res://assets/sprites/portraits/pumpik_worried.png"),
			"angry": preload("res://assets/sprites/portraits/pumpik_angry.png"),
		},
	},
	ZORA: {
		"name": "Zora Zender",
		"portraits": {
			"neutral": preload("res://assets/sprites/portraits/zora_neutral.png"),
			"happy": preload("res://assets/sprites/portraits/zora_happy.png"),
			"worried": preload("res://assets/sprites/portraits/zora_worried.png"),
			"angry": preload("res://assets/sprites/portraits/zora_angry.png"),
		},
	},
	GUARD: {
		"name": "Kobaltový strážce",
		"portraits": {
			"neutral": preload("res://assets/sprites/portraits/guard_neutral.png"),
			"scornful": preload("res://assets/sprites/portraits/guard_scornful.png"),
			"scared": preload("res://assets/sprites/portraits/guard_scared.png"),
			"angry": preload("res://assets/sprites/portraits/guard_angry.png"),
		},
	},
	SIZEL: {
		"name": "Sizel Varn",
		"portraits": {
			"neutral": preload("res://assets/sprites/portraits/sizel_neutral.png"),
			"happy": preload("res://assets/sprites/portraits/sizel_happy.png"),
			"worried": preload("res://assets/sprites/portraits/sizel_worried.png"),
			"angry": preload("res://assets/sprites/portraits/sizel_angry.png"),
		},
	},
}

## Úvody misí ve stejném pořadí jako `Missions.ALL`.
const MISSION_INTROS := [
	[
		{"speaker": PUMPIK, "mood": "happy", "text": "Vítej na stanici, šéfiku! Jsem Pumpík, tvůj android a zatím jediný zaměstnanec."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Jsme na okraji galaxie, máme jeden čerpací slot a prázdnou pokladnu. Vyděláme první peníze a vylepšíš mi tankování, ať stíhám."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Na mě i na budovy můžeš kliknout, ukážu ti, co všechno jde. Cíle najdeš vpravo nahoře."},
	],
	[
		{"speaker": PUMPIK, "mood": "worried", "text": "Šéfiku, lodí přibývá a fronty se prodlužují. Posádky začínají být nervózní."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Klikni na prázdnou parcelu a postav zábavní systém. Autokino pro rakety, u filmu jim čekání uteče."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "A kdyby lodí pořád přibývalo, postav druhý čerpací slot. Parcel máme dost."},
	],
	[
		{"speaker": PUMPIK, "mood": "angry", "text": "Šéfiku, dosavadní dodavatel s námi končí! Od teď si galaxín objednáváš sám."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Zato si sám určuješ cenu. A první várku 300 j máme v zásobníku zdarma."},
		{"speaker": PUMPIK, "mood": "worried", "text": "Jen pozor na levné dodavatele. Za nekvalitní galaxín hrozí pokuty."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "A jeden čerpací slot už nestačí, šéfiku. Postav druhý, ať lodě nečekají."},
	],
	[
		{"speaker": PUMPIK, "mood": "happy", "text": "Stanice se rozrůstá, šéfiku! Posádky by si rády něco koupily, než je natankuju."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Postav jim obchod a rozšiř nabídku."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "K zásobníku na levelu 3 jde přistavět řídící centrum. Vylepší dodávky galaxínu a s automatickým dispečinkem bude cisterny objednávat samo."},
	],
	[
		{"speaker": PUMPIK, "mood": "worried", "text": "Šéfiku, máme problém. Bohatá stanice přitahuje nezvané hosty."},
		{"speaker": PUMPIK, "mood": "angry", "text": "Piráti! Přiletí, střílí a kradou kredity, dokud je nesestřelíme nebo neodletí."},
		{"speaker": PUMPIK, "mood": "worried", "text": "Postavím se jim, šéfiku. Když mě ale rozbijí, nebudu tankovat, dokud mě Bzučák neopraví."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Na krajích paluby jsou místa pro obranné věže. Sám je nezvládnu, radši je postav."},
		{"speaker": PUMPIK, "mood": "happy", "text": "A z pirátských truhel občas vypadne artefakt. Bez skladiště ho jen prodáme, tak si ho přistav k obchodu."},
	],
	[
		{"speaker": PUMPIK, "mood": "happy", "text": "Piráty jsme zahnali, šéfiku! O stanici se začíná mluvit po celé galaxii."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Chce to dotáhnout rozdělanou práci: autokino na level 3 a něco naspořit."},
		{"speaker": PUMPIK, "mood": "worried", "text": "A dávej pozor, kdo k nám přilétá. Prý se tu objevují divné lodě."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Ještě bychom potřebovali druhou věž na druhém kraji paluby, ať piráti nemají kde se schovat."},
	],
	[
		{"speaker": PUMPIK, "mood": "worried", "text": "Šéfiku, Bzučák nestíhá. Na stavby, opravy a kořist je sám a pořád lítá sem a tam."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Pořiď mu rychlejší let i práci. A dodavatel pořád mešká, chtělo by to spolehlivější dodávky."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "A jednu věž bych vylepšil na level 2. Piráti nám nedají pokoj."},
	],
	[
		{"speaker": PUMPIK, "mood": "worried", "text": "Šéfiku, císař uvalil embargo na celou oblast. Galaxis ani Orion sem nesmějí a hlídky zastavují každou loď."},
		{"speaker": PUMPIK, "mood": "worried", "text": "Posádky se bojí létat i tankovat, takže zákazníků bude o polovinu méně."},
		{"speaker": PUMPIK, "mood": "angry", "text": "Zbyl jen černý trh. Sizel Varn nám galaxín doveze, ale chce 6 kr za jednotku a vozí pořád tu samou břečku."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Pořiď v řídícím centru filtry, ať s tím nemáme pokuty. Na level 3 ale nemáme schéma. A rozmysli si prodejní cenu, za 6 kr na galaxínu nic nevyděláme."},
	],
	[
		{"speaker": SIZEL, "mood": "happy", "text": "Šéfe, mám obchod. Embargo jen tak neskončí a kdo sem doletí, nemá kam dál. Někde spát musejí."},
		{"speaker": PUMPIK, "mood": "worried", "text": "Na stanici? Vždyť tu ani není místo, šéfiku."},
		{"speaker": SIZEL, "mood": "happy", "text": "Provizorní motel, plechovko. Pár obytných kapslí, neon a parkoviště pro čtyři lodě. Kredity potečou i bez galaxínu."},
		{"speaker": PUMPIK, "mood": "worried", "text": "Rozšířit plošinu, postavit motel a pod to parkoviště? Šéfiku, to bude práce na celé věky."},
		{"speaker": SIZEL, "mood": "happy", "text": "Plány dodám já, šéfe. Za malou provizi, samozřejmě."},
		{"speaker": PUMPIK, "mood": "angry", "text": "Samozřejmě. Já tankuju, střílím po pirátech a teď mám ještě převlékat postele?"},
	],
]

## Stojí druhý slot, takže se otevřela druhá hadice.
const DUAL_HOSE_UNLOCKED := [
	{"speaker": PUMPIK, "mood": "happy", "text": "Šéfiku, druhý slot stojí! Vypadá skvěle."},
	{"speaker": PUMPIK, "mood": "worried", "text": "Jenže mám jen jednu hadici, takže tankuju lodě po jedné a druhá čeká."},
	{"speaker": PUMPIK, "mood": "neutral", "text": "Pořiď mi druhou hadici a zvládnu dvě lodě najednou. Najdeš ji, když na mě klikneš."},
]

## Mise 6: Zora přistála a chce natankovat.
const ZORA_ARRIVES := [
	{"speaker": ZORA, "mood": "happy", "text": "Ahoj, knírku! Pěkná stanička. Ty tu všechno tankuješ sám?"},
	{"speaker": ZORA, "mood": "neutral", "text": "Plnou nádrž, prosím. A opatrně na lak, tahle kráska je z cirkusu."},
	{"speaker": PUMPIK, "mood": "happy", "text": "Hned to bude, slečno!"},
]

## Mise 6: nádrž je plná a Zora nechce platit. `%s` je cena.
const ZORA_BILL := [
	{"speaker": PUMPIK, "mood": "happy", "text": "Máte plnou, slečno. Bude to %s kreditů."},
	{"speaker": ZORA, "mood": "happy", "text": "Promiň, maličký, musím letět!"},
	{"speaker": PUMPIK, "mood": "angry", "text": "Cože? Hej, počkat! Galaxín není zadarmo!"},
]

## Mise 6: Zora utekla bez placení.
const ZORA_ESCAPED := [
	{"speaker": PUMPIK, "mood": "angry", "text": "Šéfiku, ona ujela bez placení! Trefil jsem ji a raketa se jen otřásla."},
	{"speaker": PUMPIK, "mood": "worried", "text": "Takovou rychlost jsem ještě neviděl. Něco jí ale vypadlo. Bzučák to donese."},
]

## Mise 6: Bzučák přinesl medailon.
const ZORA_MEDALLION := [
	{"speaker": PUMPIK, "mood": "neutral", "text": "Je to starý medailon. Orel s korunou, slunce a půlměsíc. Orla jsem viděl na císařských lodích."},
	{"speaker": PUMPIK, "mood": "worried", "text": "Co s tím dělá cirkusačka? Dám ho do skladiště. Tohle bych neprodával, šéfiku."},
]

## Mise 7: císařská hlídka hledá Zoru. Co odpovědět, vybírá hráč.
const PATROL_ARRIVES := [
	{"speaker": GUARD, "mood": "scornful", "text": "Kobaltová stráž Jeho Veličenstva. Odložte hadice a poslouchejte."},
	{"speaker": PUMPIK, "mood": "worried", "text": "Šéfiku, to je císařská stráž. Tihle netankují, tihle se ptají."},
	{
		"speaker": GUARD, "mood": "neutral",
		"text": "Hledáme ženu jménem Zora Zender. Cirkusová artistka, rychlá červená raketa. Viděli jste ji?",
		"choices": [
			{
				"id": REPORT_ZORA, "text": "Byla tu a ujela bez placení",
				"lines": [
					{"speaker": PUMPIK, "mood": "angry", "text": "Byla tu, pane strážce! Natankovala do plna a ujela bez placení. Letěla jako blesk."},
					{"speaker": GUARD, "mood": "scornful", "text": "Výborně. Říše si pamatuje, kdo jí pomohl. Pokračujte v práci."},
					{"speaker": PUMPIK, "mood": "worried", "text": "Snad jsme udělali dobře, šéfiku. Ale kvůli jedné nádrži by císař stráž neposílal. Co ta holka provedla?"},
				],
			},
			{
				"id": HIDE_ZORA, "text": "Nikoho takového jsme neviděli",
				"lines": [
					{"speaker": PUMPIK, "mood": "neutral", "text": "Nikoho takového jsme neviděli, pane strážce. Létají k nám jen zákazníci a piráti."},
					{"speaker": GUARD, "mood": "angry", "text": "Lhát císařské stráži se nevyplácí. Dobrá. Ještě se vrátíme."},
					{"speaker": PUMPIK, "mood": "worried", "text": "Uf. Dluží nám za nádrž a my ji ještě kryjeme, šéfiku. Co ta holka provedla, že ji hledá císařská stráž?"},
				],
			},
		],
	},
]

## Mise 8: první dodávka od Sizela.
const SIZEL_FIRST_DELIVERY := [
	{"speaker": SIZEL, "mood": "happy", "text": "Sizel Varn, dohazovač všeho, co je zrovna zakázané. Šest za jednotku, šéfe, a nesmlouvám."},
	{"speaker": PUMPIK, "mood": "angry", "text": "Vždyť to bývalo za dva kredity! A je to pořád ta samá břečka!"},
	{"speaker": SIZEL, "mood": "angry", "text": "Bývalo. Teď je embargo a hlídky střílejí bez ptaní. Riziko se platí."},
]

## Mise 8: druhá dodávka, hlídky už jsou Sizelovi v patách.
const SIZEL_SECOND_DELIVERY := [
	{"speaker": SIZEL, "mood": "worried", "text": "Hlídky jsou čím dál blíž, šéfe. Dneska mi prosvištěla střela kolem nádrže."},
	{"speaker": PUMPIK, "mood": "worried", "text": "Tak na sebe dávej pozor. Bez tebe tu nemáme ani kapku."},
]

## Mise 8: třetí cisterna přilétá poškozená a hoří.
const SIZEL_MAYDAY := [
	{"speaker": SIZEL, "mood": "worried", "text": "Tady Sizel! Hlídka mě trefila do trupu, hořím! Nevím, jak dlouho to vydrží!"},
	{"speaker": PUMPIK, "mood": "worried", "text": "Sizeli, hned na plošinu! Bzučák tě opraví! Uvolněte mu místo!"},
]

## Mise 8: Bzučák cisternu opravil, Sizel je náš přítel.
const SIZEL_THANKS := [
	{"speaker": SIZEL, "mood": "worried", "text": "Ještě že jste tady byli. Kdokoli jiný by mě nechal shořet i s cisternou."},
	{"speaker": PUMPIK, "mood": "neutral", "text": "U nás nikdo neshoří. Ani když si účtuje šest za jednotku."},
	{"speaker": SIZEL, "mood": "happy", "text": "Tohle ti nezapomenu, plechovko. Od teď vám to vozím za 4 kr za jednotku."},
	{"speaker": SIZEL, "mood": "happy", "text": "A tady je schéma na filtr level 3. Vyčistí i to, co vozím já."},
	{"speaker": PUMPIK, "mood": "happy", "text": "Šéfiku, máme ho! Filtr level 3 teď jde nainstalovat v řídícím centru."},
]

const FREE_PLAY_INTRO := [
	{"speaker": PUMPIK, "mood": "happy", "text": "Šéfiku, podívej se na to! Všechno postavené a vylepšené na maximum."},
	{"speaker": PUMPIK, "mood": "neutral", "text": "Žádné cíle, jen provoz a občasní piráti. Hraj, jak dlouho chceš."},
]
