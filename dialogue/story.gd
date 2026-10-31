class_name Story
extends RefCounted

## Příběh: postavy a jejich rozhovory. Rozhovor je seznam replik, replika má `speaker`
## (klíč do SPEAKERS), `mood` (klíč do `portraits`) a `text`. Přehrává je `DialogueBox`.

const PUMPIK := "pumpik"

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
		{"speaker": PUMPIK, "mood": "worried", "text": "Bez obranné věže se jim postavím sám. Když mě rozbijí, nebudu tankovat, dokud mě Bzučák neopraví."},
		{"speaker": PUMPIK, "mood": "neutral", "text": "Na krajích paluby jsou místa pro obranné věže. Radši je postav."},
		{"speaker": PUMPIK, "mood": "happy", "text": "A z pirátských truhel občas vypadne artefakt. Bez skladiště ho jen prodáme, tak si ho přistav k obchodu."},
	],
]

## Stojí druhý slot, takže se otevřela druhá hadice.
const DUAL_HOSE_UNLOCKED := [
	{"speaker": PUMPIK, "mood": "happy", "text": "Šéfiku, druhý slot stojí! Vypadá skvěle."},
	{"speaker": PUMPIK, "mood": "worried", "text": "Jenže mám jen jednu hadici, takže tankuju lodě po jedné a druhá čeká."},
	{"speaker": PUMPIK, "mood": "neutral", "text": "Pořiď mi druhou hadici a zvládnu dvě lodě najednou. Najdeš ji, když na mě klikneš."},
]

const FREE_PLAY_INTRO := [
	{"speaker": PUMPIK, "mood": "happy", "text": "Šéfiku, podívej se na to! Všechno postavené a vylepšené na maximum."},
	{"speaker": PUMPIK, "mood": "neutral", "text": "Žádné cíle, jen provoz a občasní piráti. Hraj, jak dlouho chceš."},
]
