extends Node

## Zvukové efekty. Krátké zvuky hraje `Sfx.play("jméno")`, smyčky se zapínají a vypínají přes
## `Sfx.set_loop("jméno", true)`. Soubory jsou v `assets/sounds/` a vyrábí je `tools/generate_sfx.gd`.
## Hlasitost a ztlumení si hra pamatuje v `user://settings.cfg`.
## Běží i při pauze kvůli tlačítkům, smyčky ale při pauze sám zastaví a po ní zase spustí
## (když je pozastaví engine, na webu se po pauze rozehrají dvakrát). Tlačítka cvakají sama:
## každý nově přidaný `BaseButton` se napojí na `ui_click`.

signal muted_changed

## Krátké zvuky: hlasitost (dB), nejmenší rozestup mezi přehráními (s), aby se stejné zvuky
## nekupily, o kolik se smí náhodně lišit výška tónu a skupina a popisek pro Centrum zvuků.
const SOUNDS := {
	"laser_gold": {"db": -14.0, "gap": 0.06, "pitch": 0.06, "group": "Boj", "label": "Střela Pumpíka a věží"},
	"laser_red": {"db": -16.0, "gap": 0.08, "pitch": 0.05, "group": "Boj", "label": "Střela pirátů"},
	"bolt_hit": {"db": -15.0, "gap": 0.05, "pitch": 0.1, "group": "Boj", "label": "Dopad střely"},
	"explosion": {"db": -4.0, "gap": 0.1, "pitch": 0.05, "group": "Boj", "label": "Výbuch pirátské lodi"},
	"alarm": {"db": -12.0, "gap": 8.0, "pitch": 0.0, "group": "Boj", "label": "Poplach při útoku"},
	"metal_hit": {"db": -10.0, "gap": 0.1, "pitch": 0.06, "group": "Boj", "label": "Zásah do Pumpíka"},
	"break_down": {"db": -10.0, "gap": 0.5, "pitch": 0.0, "group": "Boj", "label": "Pumpík se rozbil"},
	"repaired": {"db": -11.0, "gap": 0.2, "pitch": 0.0, "group": "Boj", "label": "Pumpík je opravený"},
	"theft": {"db": -12.0, "gap": 0.2, "pitch": 0.03, "group": "Boj", "label": "Krádež kreditů"},
	"coin": {"db": -13.0, "gap": 0.05, "pitch": 0.03, "group": "Provoz", "label": "Platba lodi"},
	"fine": {"db": -13.0, "gap": 0.2, "pitch": 0.0, "group": "Provoz", "label": "Pokuta za galaxín"},
	"ship_land": {"db": -21.0, "gap": 0.3, "pitch": 0.08, "group": "Provoz", "label": "Přistání lodi"},
	"ship_takeoff": {"db": -19.0, "gap": 0.4, "pitch": 0.08, "group": "Provoz", "label": "Odlet lodi"},
	"ship_angry": {"db": -19.0, "gap": 0.3, "pitch": 0.06, "group": "Provoz", "label": "Naštvaná loď"},
	"tanker_dock": {"db": -9.0, "gap": 0.2, "pitch": 0.0, "group": "Provoz", "label": "Cisterna zakotvila"},
	"build_done": {"db": -11.0, "gap": 0.1, "pitch": 0.04, "group": "Provoz", "label": "Hotová část stavby"},
	"upgrade_done": {"db": -11.0, "gap": 0.2, "pitch": 0.0, "group": "Provoz", "label": "Dokončená budova"},
	"loot": {"db": -12.0, "gap": 0.1, "pitch": 0.04, "group": "Provoz", "label": "Sebraná kořist"},
	"artifact": {"db": -6.0, "gap": 0.2, "pitch": 0.0, "group": "Provoz", "label": "Nalezený artefakt"},
	"slots": {"db": -15.0, "gap": 0.5, "pitch": 0.0, "group": "Provoz", "label": "Výhra na automatech"},
	"ui_click": {"db": -11.0, "gap": 0.02, "pitch": 0.03, "group": "Rozhraní", "label": "Kliknutí na tlačítko"},
	"ui_select": {"db": -15.0, "gap": 0.04, "pitch": 0.03, "group": "Rozhraní", "label": "Výběr objektu"},
	"ui_buy": {"db": -12.0, "gap": 0.05, "pitch": 0.0, "group": "Rozhraní", "label": "Nákup"},
	"mission_done": {"db": -8.0, "gap": 0.5, "pitch": 0.0, "group": "Rozhraní", "label": "Splněná mise"},
}
## Smyčky: hlasitost (dB), skupina a popisek pro Centrum zvuků.
const LOOPS := {
	"pump": {"db": -25.0, "group": "Smyčky", "label": "Tankování"},
	"weld": {"db": -30.0, "group": "Smyčky", "label": "Svařování Bzučáka"},
	"unload": {"db": -24.0, "group": "Smyčky", "label": "Přečerpávání z cisterny"},
}
const VOICES := 16
const BUS := &"SFX"
const LOOP_FADE_TIME := 0.15
const SILENT_DB := -60.0
const SETTINGS_PATH := "user://settings.cfg"
## Tlačítko s touhle značkou necvaká (v Centru zvuků by se cvaknutí pletlo s ukázkou).
const SILENT_BUTTON := &"silent_click"

## Hlasitost efektů 0–1.
var volume := 1.0:
	set(value):
		volume = clampf(value, 0.0, 1.0)
		_apply_volume()
var muted := false:
	set(value):
		muted = value
		_apply_volume()
		save_settings()
		muted_changed.emit()

var _streams := {}
var _voices: Array[AudioStreamPlayer] = []
## Čas posledního přehrání (ms) podle jména zvuku.
var _last_played := {}
var _loops := {}
var _loops_on := {}
var _loop_fades := {}
var _paused := false
var _preview_voice: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound: String in SOUNDS:
		_streams[sound] = load("res://assets/sounds/%s.wav" % sound)
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = BUS
		add_child(voice)
		_voices.append(voice)
	_preview_voice = AudioStreamPlayer.new()
	_preview_voice.bus = BUS
	add_child(_preview_voice)
	for sound: String in LOOPS:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://assets/sounds/%s_loop.wav" % sound)
		player.bus = BUS
		add_child(player)
		_loops[sound] = player
		_loops_on[sound] = false
	_load_settings()
	get_tree().node_added.connect(_on_node_added)


func _process(_delta: float) -> void:
	if get_tree().paused == _paused:
		return
	_paused = get_tree().paused
	for sound: String in LOOPS:
		if _loops_on[sound]:
			if _paused:
				_loops[sound].stop()
			else:
				_fade_in(sound)


## Zahraje krátký zvuk. `pitch` a `gain_db` ho posunou proti výchozímu nastavení.
func play(sound: String, pitch := 1.0, gain_db := 0.0) -> void:
	var settings: Dictionary = SOUNDS[sound]
	var now := Time.get_ticks_msec()
	if now - _last_played.get(sound, -100000) < settings.gap * 1000.0:
		return
	var voice := _free_voice()
	if voice == null:
		return
	_last_played[sound] = now
	voice.stream = _streams[sound]
	voice.volume_db = settings.db + gain_db
	voice.pitch_scale = pitch * (1.0 + randf_range(-settings.pitch, settings.pitch))
	voice.play()


## Zapne nebo vypne smyčku. Volat se smí každý snímek, měkce se rozjede i doztlumí.
func set_loop(sound: String, active: bool) -> void:
	if _loops_on[sound] == active:
		return
	_loops_on[sound] = active
	if active:
		_fade_in(sound)
	else:
		var player: AudioStreamPlayer = _loops[sound]
		var fade := _new_fade(sound)
		fade.tween_property(player, "volume_db", SILENT_DB, LOOP_FADE_TIME)
		fade.tween_callback(player.stop)


## Zahraje ukázku v Centru zvuků: bez náhodné výšky a bez čekání na rozestup. Předchozí
## ukázka skončí, smyčka hraje až do `stop_preview()`.
func preview(sound: String) -> void:
	stop_preview()
	if LOOPS.has(sound):
		set_loop(sound, true)
		return
	_preview_voice.stream = _streams[sound]
	_preview_voice.volume_db = SOUNDS[sound].db
	_preview_voice.play()


func stop_preview() -> void:
	_preview_voice.stop()
	stop_loops()


func stop_loops() -> void:
	for sound: String in LOOPS:
		set_loop(sound, false)


func save_settings() -> void:
	var settings := ConfigFile.new()
	settings.set_value("audio", "sfx_volume", volume)
	settings.set_value("audio", "muted", muted)
	settings.save(SETTINGS_PATH)


func _load_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		volume = settings.get_value("audio", "sfx_volume", 1.0)
		muted = settings.get_value("audio", "muted", false)
	_apply_volume()


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index(BUS)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus, muted or volume <= 0.0)


func _fade_in(sound: String) -> void:
	if _paused:
		return
	var player: AudioStreamPlayer = _loops[sound]
	var fade := _new_fade(sound)
	if not player.playing:
		player.volume_db = SILENT_DB
		player.play()
	fade.tween_property(player, "volume_db", LOOPS[sound].db, LOOP_FADE_TIME)


## Nové doznívání smyčky nahradí předchozí.
func _new_fade(sound: String) -> Tween:
	if _loop_fades.has(sound):
		_loop_fades[sound].kill()
	_loop_fades[sound] = create_tween()
	return _loop_fades[sound]


func _free_voice() -> AudioStreamPlayer:
	for voice in _voices:
		if not voice.playing:
			return voice
	return null


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta(SILENT_BUTTON):
		node.pressed.connect(play.bind("ui_click"))
