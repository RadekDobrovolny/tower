class_name Hud
extends CanvasLayer

## Herní HUD: kredity, cíle mise, info panel vybraného objektu (s vylepšeními a stavbami),
## panel galaxínu, pauza a okno mise (úvod mise a shrnutí po jejím splnění).
## Ceny se ukazují s ikonkou mince místo „kr“ (UiIcons.money_bbcode).

const DONE_COLOR := Color(0.5, 0.94, 0.55)
const GAIN_FLASH := Color(1.6, 1.4, 0.9)
const SPEND_FLASH := Color(1.4, 0.6, 0.6)
## Kolikrát za sekundu se zobrazené kredity přiblíží ke skutečným (počítadlo „dojíždí“).
const CREDITS_ROLL_SPEED := 10.0
## Popisek řádku info panelu („Tankování:“) se zobrazí tlumeně, když je krátký.
const INFO_KEY_MAX_LENGTH := 24
const INFO_KEY_COLOR := "#9e99a8"

var _campaign: Campaign
## Objekt, jehož info panel je otevřený, a tlačítka jeho akcí.
var _selected: Node
var _action_buttons: Array[ActionButton] = []
## Texty akcí, pro které jsou tlačítka postavená (když se změní, tlačítka se přestaví).
var _action_labels := PackedStringArray()
var _refresh_pending := false
var _galaxin_panel_ready := false
var _shown_credits := 0.0
var _last_credits := 0
## Řádky cílů: {"icon": TextureRect, "label": RichTextLabel, "value": Label, "bar": ProgressBar, "done": bool}.
var _goal_rows: Array[Dictionary] = []
var _hint_tween: Tween

@onready var _coin_icon: TextureRect = %CoinIcon
@onready var _credits_label: Label = %CreditsLabel
@onready var _served_label: Label = %ServedLabel
@onready var _lost_label: Label = %LostLabel
@onready var _goals_kicker: Label = %GoalsKicker
@onready var _goals_title: Label = %GoalsTitle
@onready var _goals_list: VBoxContainer = %GoalsList
@onready var _info_panel: HudPanel = $Right/InfoPanel
@onready var _info_title: Label = %InfoTitle
@onready var _info_text: RichTextLabel = %InfoText
@onready var _info_actions: VBoxContainer = %InfoActions
@onready var _hint: Label = $HintLabel
@onready var _pirate_alert: Label = $PirateAlert
@onready var _mission_popup: Control = $MissionPopup
@onready var _mission_title: Label = %MissionTitle
@onready var _mission_body: RichTextLabel = %MissionBody
@onready var _mission_button: Button = %MissionButton
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _galaxin_panel: Control = $Left/GalaxinPanel
@onready var _tank_label: Label = %TankLabel
@onready var _tank_bar: ProgressBar = %TankBar
@onready var _price_label: RichTextLabel = %PriceLabel
@onready var _demand_label: Label = %DemandLabel
@onready var _supplier_buttons: HBoxContainer = %SupplierButtons
@onready var _supplier_info: Label = %SupplierInfo
@onready var _order_button: ActionButton = %OrderButton
@onready var _supply_status: Label = %SupplyStatus


func _ready() -> void:
	_coin_icon.pivot_offset = _coin_icon.custom_minimum_size / 2.0
	_order_button.setup(preload("res://assets/ui/icons/tanker.svg"), "")


func _process(delta: float) -> void:
	_roll_credits(delta)
	_update_pirate_alert()
	# Nastavení galaxínu (cena, dodavatel, objednávky) je vidět jen s vybraným zásobníkem.
	_galaxin_panel.visible = _galaxin_panel_ready and _selected == _campaign.station.tank
	if _galaxin_panel.visible:
		_refresh_galaxin_panel()
	if _info_panel.visible:
		_refresh_info_panel()


func setup(campaign: Campaign) -> void:
	_campaign = campaign
	_shown_credits = Game.credits
	_last_credits = Game.credits
	_credits_label.text = Game.format_number(Game.credits)
	Game.credits_changed.connect(_on_credits_changed)
	Game.stats_changed.connect(_request_refresh)
	campaign.station.state_changed.connect(_request_refresh)
	campaign.station.selection_changed.connect(_on_selection_changed)
	%InfoClose.pressed.connect(campaign.station.select.bind(null))
	$PauseButton.pressed.connect(_pause_menu.open)
	_show_hint(Game.start_mission == 0)
	_mission_button.pressed.connect(campaign.continue_game)


## Přestaví cíle a panel galaxínu podle aktuální mise.
func refresh_mission() -> void:
	if _campaign.mission:
		_goals_kicker.text = "Mise %d / %d" % [_campaign.number(), Missions.ALL.size()]
		_goals_title.text = _campaign.mission.title
	else:
		_goals_kicker.text = "Mise Z" if Game.start_mission == Missions.FREE_PLAY_INDEX else "Všechny mise splněné"
		_goals_title.text = "Volná hra"
	for child in _goals_list.get_children():
		child.queue_free()
	_goal_rows.clear()
	for goal in _campaign.get_goals():
		_goal_rows.append(_create_goal_row(goal.done))

	if _campaign.station.galaxin_economy and not _galaxin_panel_ready:
		_setup_galaxin_panel(_campaign.station)
	_request_refresh()


func show_mission_popup(title: String, body: String, button_text: String) -> void:
	_mission_title.text = title
	_mission_body.text = UiIcons.money_bbcode(body, 15)
	_mission_button.text = button_text
	_mission_popup.show()


func hide_mission_popup() -> void:
	_mission_popup.hide()


func _on_credits_changed(credits: int) -> void:
	if credits != _last_credits:
		_pulse_credits(credits > _last_credits)
	_last_credits = credits
	_request_refresh()


## Nápověda dole je jen pro začátek hry od první mise a pomalu pulzuje.
func _show_hint(show_it: bool) -> void:
	_hint.visible = show_it
	if show_it:
		_hint_tween = create_tween().set_loops()
		_hint_tween.tween_property(_hint, "modulate:a", 0.45, 1.6).set_trans(Tween.TRANS_SINE)
		_hint_tween.tween_property(_hint, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_SINE)


## Hráč poprvé na něco klikl, nápověda už není potřeba.
func _dismiss_hint() -> void:
	if _hint_tween:
		_hint_tween.kill()
		_hint_tween = null
	_hint.hide()


## Varování nahoře bliká, dokud nějaký pirát útočí.
func _update_pirate_alert() -> void:
	var attacking := get_tree().get_nodes_in_group("pirates").any(
			func(pirate: Node) -> bool: return pirate.is_attacking())
	_pirate_alert.visible = attacking
	if attacking:
		_pirate_alert.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 150.0)


## Počítadlo kreditů nedoskočí hned, ale rychle „dojede“ ke skutečné hodnotě.
func _roll_credits(delta: float) -> void:
	var target := float(Game.credits)
	if is_equal_approx(_shown_credits, target):
		return
	var step := maxf(absf(target - _shown_credits) * CREDITS_ROLL_SPEED * delta, 1.0)
	_shown_credits = move_toward(_shown_credits, target, step)
	_credits_label.text = Game.format_number(roundi(_shown_credits))


func _pulse_credits(gain: bool) -> void:
	var tween := create_tween().set_parallel()
	_coin_icon.scale = Vector2.ONE * (1.35 if gain else 0.8)
	tween.tween_property(_coin_icon, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_credits_label.modulate = GAIN_FLASH if gain else SPEND_FLASH
	tween.tween_property(_credits_label, "modulate", Color.WHITE, 0.4)


## Překreslí kredity a cíle až na konci snímku, kdy už jsou všechny změny (např. po nákupu) hotové.
func _request_refresh() -> void:
	if not _refresh_pending:
		_refresh_pending = true
		_refresh.call_deferred()


func _refresh() -> void:
	_refresh_pending = false
	_served_label.text = str(Game.ships_served)
	_lost_label.text = str(Game.ships_lost)

	var goals := _campaign.get_goals()
	for i in mini(goals.size(), _goal_rows.size()):
		_update_goal_row(_goal_rows[i], goals[i])


func _create_goal_row(done: bool) -> Dictionary:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 7)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(14, 14)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.pivot_offset = Vector2(7, 7)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var value := Label.new()
	value.theme_type_variation = &"HudDim"
	var bar := ProgressBar.new()
	bar.theme_type_variation = &"HudThinBar"
	bar.custom_minimum_size = Vector2(0, 3)
	bar.max_value = 1.0
	bar.step = 0.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	line.add_child(label)
	line.add_child(value)
	row.add_child(line)
	row.add_child(bar)
	_goals_list.add_child(row)
	return {"icon": icon, "label": label, "value": value, "bar": bar, "done": done}


func _update_goal_row(row: Dictionary, goal: Dictionary) -> void:
	var label: RichTextLabel = row.label
	var text := UiIcons.money_bbcode(goal.label, 13)
	if label.text != text:
		label.text = text
	row.value.text = goal.value
	row.bar.value = goal.progress
	var icon: TextureRect = row.icon
	icon.texture = UiIcons.CHECK if goal.done else UiIcons.GOAL
	label.modulate = DONE_COLOR if goal.done else Color.WHITE
	row.bar.modulate = DONE_COLOR if goal.done else Color.WHITE
	# Čerstvě splněný cíl krátce zabliká a ikonka „cvakne“.
	if goal.done and not row.done:
		icon.scale = Vector2.ONE * 1.8
		var tween := create_tween().set_parallel()
		tween.tween_property(icon, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		label.modulate = Color(2, 2, 2)
		tween.tween_property(label, "modulate", DONE_COLOR, 0.6)
	row.done = goal.done


func _on_selection_changed(object: Node) -> void:
	var changed := object != _selected
	_selected = object
	_info_panel.visible = object != null
	if object:
		_dismiss_hint()
	_rebuild_action_buttons()
	if object:
		_refresh_info_panel()
		if changed:
			_info_panel.play_reveal()


## Akce vybraného objektu, které jdou teď koupit. Co zatím koupit nejde (cena -1), se nezobrazí.
func _available_actions() -> Array[ShopItem]:
	var actions: Array[ShopItem] = []
	if _selected:
		for item: ShopItem in _selected.info_actions():
			if item.cost.call() >= 0:
				actions.append(item)
	return actions


func _rebuild_action_buttons() -> void:
	for button in _action_buttons:
		button.queue_free()
	_action_buttons.clear()
	_action_labels.clear()
	for item in _available_actions():
		_action_labels.append(item.label.call())
		var button := ActionButton.new()
		button.setup(UiIcons.action_icon(item.kind), item.label.call())
		button.pressed.connect(item.buy)
		_info_actions.add_child(button)
		_action_buttons.append(button)


## Info panel ukazuje živé hodnoty (průběh stavby, stav slotu), proto se obnovuje každý snímek.
func _refresh_info_panel() -> void:
	if not is_instance_valid(_selected):
		_on_selection_changed(null)
		return
	_info_title.text = _selected.info_title()
	var text := _info_bbcode(_selected.info_lines())
	if _info_text.text != text:
		_info_text.text = text
	var actions := _available_actions()
	var labels := PackedStringArray()
	for item in actions:
		labels.append(item.label.call())
	if labels != _action_labels:
		_rebuild_action_buttons()
	for i in actions.size():
		var cost: int = actions[i].cost.call()
		var affordable := Game.credits >= cost
		_action_buttons[i].set_label(labels[i])
		_action_buttons[i].set_cost(cost, affordable)
		# Na co hráč zatím nemá, zůstane vidět, ale ztlumené.
		_action_buttons[i].set_enabled(affordable)


## Řádky „Popisek: hodnota“ dostanou tlumený popisek, ceny ikonku mince.
func _info_bbcode(lines: PackedStringArray) -> String:
	var result := PackedStringArray()
	for line in lines:
		var colon := line.find(": ")
		if colon > 0 and colon <= INFO_KEY_MAX_LENGTH and not line.left(colon).contains("."):
			line = "[color=%s]%s[/color]%s" % [INFO_KEY_COLOR, line.left(colon + 1), line.substr(colon + 1)]
		result.append(UiIcons.money_bbcode(line, 13))
	return "\n".join(result)


func _setup_galaxin_panel(station: Station) -> void:
	_galaxin_panel_ready = true
	%PriceDown.pressed.connect(func() -> void: station.set_sell_price(station.sell_price - 1))
	%PriceUp.pressed.connect(func() -> void: station.set_sell_price(station.sell_price + 1))
	var group := ButtonGroup.new()
	for i in Supply.SUPPLIERS.size():
		var button := _create_supplier_button(Supply.SUPPLIERS[i])
		button.button_group = group
		button.button_pressed = i == station.supply.selected
		button.pressed.connect(func() -> void: station.supply.selected = i)
		_supplier_buttons.add_child(button)
	_order_button.pressed.connect(station.supply.order)


## Přepínač dodavatele: jméno a pod ním cena za jednotku s mincí.
func _create_supplier_button(supplier: Dictionary) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 40)
	button.tooltip_text = supplier.name
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 0)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := Label.new()
	name_label.text = supplier.short_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	var price := RichTextLabel.new()
	price.bbcode_enabled = true
	price.fit_content = true
	price.scroll_active = false
	price.autowrap_mode = TextServer.AUTOWRAP_OFF
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.add_theme_font_size_override("normal_font_size", 11)
	price.add_theme_color_override("default_color", Color(1, 0.87, 0.55))
	price.text = "[center]%s[/center]" % UiIcons.money_bbcode("%d kr/j" % supplier.price, 11)
	content.add_child(name_label)
	content.add_child(price)
	button.add_child(content)
	return button


func _refresh_galaxin_panel() -> void:
	var station := _campaign.station
	var tank := station.tank
	var supply := station.supply
	_tank_label.text = "%d / %d j" % [roundi(tank.amount), roundi(tank.capacity())]
	_tank_bar.value = tank.amount / tank.capacity()
	var price := "[center]%s[/center]" % UiIcons.money_bbcode("%d kr/j" % station.sell_price, 13)
	if _price_label.text != price:
		_price_label.text = price
	_demand_label.text = station.demand_text()
	var supplier := supply.selected_supplier()
	_supplier_info.text = supplier.info
	if supply.state != Supply.State.IDLE:
		_order_button.set_label("Cisterna je objednaná")
		_order_button.set_cost(-1)
		_order_button.set_enabled(false)
	elif station.under_attack():
		_order_button.set_label("Piráti útočí")
		_order_button.set_cost(-1)
		_order_button.set_enabled(false)
	elif supply.max_order_units() <= 0:
		_order_button.set_label("Zásobník je plný")
		_order_button.set_cost(-1)
		_order_button.set_enabled(false)
	elif supply.order_units() <= 0:
		_order_button.set_label("Na cisternu nemáš kredity")
		_order_button.set_cost(-1)
		_order_button.set_enabled(false)
	else:
		_order_button.set_label("Objednat %d j" % supply.order_units())
		_order_button.set_cost(supply.order_cost(), supply.can_order())
		_order_button.set_enabled(supply.can_order())
	_supply_status.text = supply.status_text()
