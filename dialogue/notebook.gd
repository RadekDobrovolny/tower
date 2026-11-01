class_name Notebook
extends RefCounted

## Obsah Pumpíkova zápisníku. Popisy píše Pumpík, ceny a čísla se berou přímo z dat hry, takže
## nezastarají. Nové běžné rakety (`Ship.HULLS`) a artefakty se v zápisníku objeví samy.
## Kapitola je seznam záznamů: `title`, `text` a `image` (obrázek, může chybět).

const CHAPTERS := ["Lodě", "Postavy", "Budovy", "Svět"]


static func entries(chapter: String) -> Array[Dictionary]:
	match chapter:
		"Lodě":
			return _ships()
		"Postavy":
			return _characters()
		"Budovy":
			return _buildings()
	return _world()


static func _ships() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for hull: Dictionary in Ship.HULLS:
		result.append({"title": hull.name, "image": hull.texture, "text": "%s\n\n%s" % [hull.about, _hull_facts(hull)]})
	result.append({
		"title": "Velká nákladní loď", "image": Ship.FREIGHTER_TEXTURE,
		"text": "Obr s nádrží dvakrát větší než běžná raketa. Tankuje dlouho, ale vždy do plna.",
	})
	result.append({
		"title": "Turistická loď", "image": Ship.TOURIST_TEXTURE,
		"text": "Plná turistů s plnými peněženkami. V obchodě utratí %d× víc než ostatní, proto létá jen ke stanici s hotovým obchodem. Nádrž má o 30 %% větší." % roundi(Ship.TOURIST_SHOPPING),
	})
	result.append({
		"title": "Zořina raketa", "image": ZoraScene.HULL.texture,
		"text": "Nejrychlejší raketa, jakou jsem kdy viděl, červená se zlatými ozdobami. Stále za ni visí jedna plná nádrž.",
	})
	result.append({
		"title": "Pirátský nájezdník", "image": Pirate.KINDS.raider.texture,
		"text": "Rychlý a drzý. Střílí po mně a pak krade kredity. Životů má %d." % Pirate.KINDS.raider.hp,
	})
	result.append({
		"title": "Pirátská dělová loď", "image": Pirate.KINDS.gunship.texture,
		"text": "Těžká a pomalá, životů má %d. Zato z ní vždy vypadne kořist." % Pirate.KINDS.gunship.hp,
	})
	return result


static func _hull_facts(hull: Dictionary) -> String:
	var facts := PackedStringArray(["Létá od Mise %d." % hull.get("from", 1)])
	if hull.has("patience"):
		facts.append("Trpělivost %d %%." % roundi(hull.patience * 100.0))
	if hull.has("tank"):
		facts.append("Nádrž %d %%." % roundi(hull.tank * 100.0))
	var tip: float = hull.get("tip", 1.0)
	if tip <= 0.0:
		facts.append("Dýško nedává.")
	elif tip < 1.0:
		facts.append("Dýško dává zřídka.")
	elif hull.has("tip_size"):
		facts.append("Dýško dává často a velké.")
	elif tip > 1.0:
		facts.append("Dýško dává často.")
	if hull.get("full_tank", false):
		facts.append("Vždy chce plnou nádrž.")
	if hull.has("motel_pay"):
		facts.append("V motelu platí %d kr." % hull.motel_pay)
	return " ".join(facts)


static func _characters() -> Array[Dictionary]:
	return [
		{
			"title": "Pumpík", "image": Story.SPEAKERS[Story.PUMPIK].portraits.happy,
			"text": "To jsem já! Android, tankovač a ochranka v jednom. Knír je pravý.\n\nVylepšení:\n%s\n%s\n%s\n%s\n- Druhá hadice: %s, tankuju dvě lodě najednou" % [
				_cost_line("Tankování", Android.FUEL_LEVELS.map(_cost_of).slice(1)),
				_cost_line("Jízda", Android.WALK_LEVELS.map(_cost_of).slice(1)),
				_cost_line("Štíty", Android.SHIELD_LEVELS.map(_cost_of).slice(1)),
				_cost_line("Nanoboti", Android.NANOBOT_LEVELS.map(_cost_of).slice(1)),
				_price(Android.DUAL_HOSE_COST),
			],
		},
		{
			"title": "Bzučák", "image": preload("res://assets/sprites/construction/bzucak.png"),
			"text": "Stavební dron. Staví, vylepšuje, opravuje mě a sbírá kořist. Pořád bzučí a nikdy se nezastaví.\n\nVylepšení:\n%s\n%s" % [
				_cost_line("Rychlost letu", ConstructionDrone.SPEED_LEVELS.map(_cost_of).slice(1)),
				_cost_line("Rychlost práce", ConstructionDrone.WORK_LEVELS.map(_cost_of).slice(1)),
			],
		},
		{
			"title": "Zora Zender", "image": Story.SPEAKERS[Story.ZORA].portraits.neutral,
			"text": "Cirkusová artistka s rychlou raketou a ještě rychlejšíma nohama. Natankovala do plna a ujela bez placení. Dluží nám.",
		},
		{
			"title": "Kobaltový strážce", "image": Story.SPEAKERS[Story.GUARD].portraits.neutral,
			"text": "Důstojník císařské stráže ve skleněné přilbě a kobaltové uniformě. Netankuje, jen se ptá. A když se ptá, je lepší stát rovně.",
		},
		{
			"title": "Sizel Varn", "image": Story.SPEAKERS[Story.SIZEL].portraits.neutral,
			"text": "Ještěří dohazovač a překupník. Sežene všechno, co je zrovna zakázané, a vždycky si spočítá přirážku. Vozí nejlevnější galaxín v oblasti, a taky nejhorší.",
		},
		{
			"title": "Vesmírný vetešník",
			"text": "Přiletí, když dojde galaxín i kredity, vždycky ví, kdy je zle. Odkoupí jedno ze tří vylepšení za polovinu ceny. Kdo nemá co prodat, dostane almužnu %s." % _price(JunkDealer.HANDOUT),
		},
	]


static func _buildings() -> Array[Dictionary]:
	var center_lines := PackedStringArray()
	for upgrade: Dictionary in ControlCenter.UPGRADES:
		center_lines.append(_cost_line(upgrade.name, upgrade.costs))
	var product_lines := PackedStringArray()
	for product: Dictionary in Shop.PRODUCTS:
		product_lines.append("- %s: %s" % [product.name, _price(product.cost)])
	return [
		{
			"title": "Čerpací slot", "image": preload("res://assets/sprites/station/landing_pad.png"),
			"text": "Plošina, kde lodě přistávají, a čerpadlo. Každý slot stojí %s a staví se po částech." % _phases_cost(FuelSlot.PHASES),
		},
		{
			"title": "Zásobník", "image": preload("res://assets/sprites/station/tank.png"),
			"text": "Tady je všechen galaxín stanice. Když dojde, lodě odletí a nové nepřiletí.\n\n%s" % _cost_line("Rozšíření", GalaxinTank.LEVELS.map(_cost_of).slice(1)),
		},
		{
			"title": "Zábavní systém", "image": preload("res://assets/sprites/entertainment/drive_in_screen.png"),
			"text": "Autokino pro rakety. U filmu lodím rychleji utíká čekání a nechávají větší dýška. Stojí %s.\n\n%s\n- Výherní automaty: %s" % [
				_phases_cost(EntertainmentSystem.PHASES),
				_cost_line("Vylepšení", EntertainmentSystem.LEVELS.map(_cost_of).slice(1)),
				_price(EntertainmentSystem.SLOTS_COST),
			],
		},
		{
			"title": "Obchod", "image": preload("res://assets/sprites/shop/shop.png"),
			"text": "Posádky si tu při tankování něco koupí. Stojí %s a od začátku prodává nápoje.\n\nDalší zboží:\n%s" % [_phases_cost(Shop.PHASES), "\n".join(product_lines)],
		},
		{
			"title": "Řídící centrum", "image": preload("res://assets/sprites/station/control_center.png"),
			"text": "Serverovna u zásobníku, který musí být aspoň na levelu %d. Stojí %s.\n\n%s" % [Station.CONTROL_CENTER_TANK_LEVEL, _phases_cost(ControlCenter.PHASES), "\n".join(center_lines)],
		},
		{
			"title": "Obranná věž", "image": preload("res://assets/sprites/defense/tower_base.png"),
			"text": "Laserový kanón na kraji paluby, sama míří a střílí. Stojí %s.\n\n%s" % [_phases_cost(DefenseTower.PHASES), _cost_line("Vylepšení", DefenseTower.LEVELS.map(_cost_of).slice(1))],
		},
		{
			"title": "Skladiště", "image": preload("res://assets/sprites/warehouse/warehouse.png"),
			"text": "Přístavba obchodu za %s. Artefakty fungují, jen když jsou v něm, a dají se tu prodat. Má %d míst." % [_phases_cost(Warehouse.PHASES), Warehouse.SLOTS],
		},
		{
			"title": "Rozšíření plošiny", "image": preload("res://assets/sprites/motel/girders.png"),
			"text": "Nová část paluby vpravo se 2 parcelami. Stojí %s." % _phases_cost(PlatformExtension.PHASES),
		},
		{
			"title": "Motel", "image": preload("res://assets/sprites/motel/motel.png"),
			"text": "Obytné kapsle pro posádky, které si potřebují odpočinout. Host nechá loď na parkovišti a každých %d s zaplatí %d kr. Zájezdy tu nebydlí. Stavba stojí %s." % [roundi(Motel.PAY_INTERVAL), Motel.PAY_AMOUNT, _phases_cost(Motel.PHASES)],
		},
		{
			"title": "Parkoviště", "image": preload("res://assets/sprites/motel/parking_bay.png"),
			"text": "%d stání pod plošinou pro lodě hostů motelu. Stojí %s." % [Parking.BAYS.size(), _phases_cost(Parking.PHASES)],
		},
	]


static func _world() -> Array[Dictionary]:
	var supplier_lines := PackedStringArray()
	for supplier: Dictionary in Supply.SUPPLIERS:
		supplier_lines.append("- %s, %d kr/j: %s" % [supplier.name, roundi(supplier.price), supplier.info])
	var result: Array[Dictionary] = [
		{
			"title": "Galaxín",
			"text": "Palivo celé galaxie. Svítí růžově a voní po bouřce. Běžná cena je %d kr/j, nastavit jde od %d do %d kr/j. Čím dražší, tím méně lodí přiletí a tím rychleji jim dochází trpělivost." % [Station.BASE_PRICE, Station.MIN_PRICE, Station.MAX_PRICE],
		},
		{
			"title": "Dodavatelé",
			"text": "Galaxín vozí cisterny. Platí se předem a za to, co nedovezou, vrátí peníze.\n\n%s" % "\n".join(supplier_lines),
		},
		{
			"title": "Trpělivost a dýška",
			"text": "Loď čeká jen tak dlouho, dokud jí nedojde trpělivost, pak odletí. Spokojené lodě občas nechají dýško. Za nekvalitní galaxín hrozí pokuta %s." % _price(Ship.FINE),
		},
		{
			"title": "Piráti",
			"text": "Přiletí, zaženou zákazníky a kradou kredity. Pomůže věž, a když je třeba, postavím se jim sám. Ze sestřelených občas vypadnou trosky nebo truhla.",
		},
		{
			"title": "Artefakty",
			"text": "Poklady z pirátských truhel. Bez skladiště je jen prodáš, ve skladišti zůstanou a některé fungují. Co ve skladišti máš, znovu nevypadne.",
		},
	]
	for artifact: Dictionary in Station.ARTIFACTS:
		result.append({
			"title": artifact.name, "image": artifact.icon,
			"text": "%s\n\n%s\n\nCena: %s" % [artifact.about, artifact.info, _price(artifact.credits)],
		})
	return result


static func _cost_of(level: Dictionary) -> int:
	return level.cost


static func _phases_cost(phases: Array) -> String:
	var total := 0
	for phase: Dictionary in phases:
		total += phase.cost
	return _price(total)


static func _price(value: int) -> String:
	return "%s kr" % Game.format_number(value)


## Řádek s cenami levelů, např. „- Jízda: 500, 1 000 kr“.
static func _cost_line(label: String, costs: Array) -> String:
	var prices := PackedStringArray()
	for cost: int in costs:
		prices.append(Game.format_number(cost))
	return "- %s: %s kr" % [label, ", ".join(prices)]
