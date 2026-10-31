extends SceneTree

## Vygeneruje zvukové efekty hry do `assets/sounds/` (mono 16bit WAV). Všechno je syntéza kódem,
## žádné nahrávky, takže zvuky nemají cizí licenci. Každý zvuk má vlastní seed, stejný kód dá
## stejný soubor. Smyčky mají v souboru značku smyčky, Godot je importuje jako opakující se.
## Smyčky jsou delší, než by musely: na webu je Godot neopakuje bezešvě, ale po dohrání restartuje.
##
## Spuštění (všechno, nebo jen vyjmenované zvuky):
##   godot --headless --path . -s res://tools/generate_sfx.gd -- [jméno ...]

const BASE_RATE := 32000
## Zvuky s doznívajícími čistými tóny: vyšší frekvence, a v `.import` mají `compress/mode=0`
## (bezztrátově), protože ztrátová komprese je na takových tónech slyšet.
const HIGH_QUALITY := {"tanker_dock": 48000, "artifact": 48000}
const OUT_DIR := "res://assets/sounds/"
const PEAK := 0.89
## Konce zvuků se krátce doztlumí, aby neluply.
const FADE_TIME := 0.004

enum Wave { SINE, TRIANGLE, SOFT_SQUARE, SAW }

var _rate := BASE_RATE


func _initialize() -> void:
	var sounds := {
		"laser_gold": _laser_gold, "laser_red": _laser_red, "bolt_hit": _bolt_hit,
		"explosion": _explosion, "alarm": _alarm, "metal_hit": _metal_hit,
		"break_down": _break_down, "repaired": _repaired, "theft": _theft,
		"coin": _coin, "fine": _fine, "ship_land": _ship_land, "ship_takeoff": _ship_takeoff,
		"ship_angry": _ship_angry, "tanker_dock": _tanker_dock, "build_done": _build_done,
		"upgrade_done": _upgrade_done, "loot": _loot, "artifact": _artifact, "slots": _slots,
		"ui_click": _ui_click, "ui_select": _ui_select, "ui_buy": _ui_buy,
		"mission_done": _mission_done,
	}
	var loops := {
		"pump_loop": _pump_loop, "weld_loop": _weld_loop, "unload_loop": _unload_loop,
	}
	var wanted := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for sound: String in sounds:
		if wanted.is_empty() or wanted.has(sound):
			seed(sound.hash())
			_rate = HIGH_QUALITY.get(sound, BASE_RATE)
			_save(sound, sounds[sound].call(), false)
	for sound: String in loops:
		if wanted.is_empty() or wanted.has(sound):
			seed(sound.hash())
			_rate = BASE_RATE
			_save(sound, loops[sound].call(), true)
	quit()


# --- Boj ---

## Zlatá střela: čistý klesající „ťiu“ jako theremin.
func _laser_gold() -> PackedFloat32Array:
	var out := _sweep(0.2, 2400.0, 380.0, 16.0, Wave.SINE)
	_add(out, _sweep(0.2, 1200.0, 190.0, 20.0, Wave.SOFT_SQUARE), 0.3)
	_add(out, _noise(0.012, 200.0, 6000.0, 6000.0), 0.25)
	return out


## Pirátská střela: špinavější a hlubší, s drsnou modulací.
func _laser_red() -> PackedFloat32Array:
	var out := _sweep(0.26, 1100.0, 130.0, 12.0, Wave.SAW)
	_add(out, _sweep(0.26, 1640.0, 180.0, 14.0, Wave.SAW), 0.5)
	for i in out.size():
		out[i] *= 0.6 + 0.4 * sin(TAU * 90.0 * i / _rate)
	out = _low_pass(out, 3200.0)
	_drive(out, 2.0)
	return out


func _bolt_hit() -> PackedFloat32Array:
	var out := _metal(0.2, [1200.0, 2300.0, 3100.0], [30.0, 40.0, 55.0])
	_add(out, _noise(0.06, 70.0, 5000.0, 1500.0), 0.8)
	return out


func _explosion() -> PackedFloat32Array:
	var out := _noise(1.3, 3.2, 1600.0, 110.0)
	_add(out, _sweep(0.6, 110.0, 32.0, 5.0, Wave.SINE), 1.0)
	_add(out, _crackle(0.6, 80.0, 7.0), 0.5)
	_drive(out, 2.5)
	return out


## Klaxon poplachu: dvě stoupající houknutí.
func _alarm() -> PackedFloat32Array:
	var out := _samples(1.5)
	for start: float in [0.0, 0.72]:
		var whoop := _sweep(0.6, 340.0, 620.0, 0.0, Wave.SAW)
		_add(whoop, _sweep(0.6, 345.0, 630.0, 0.0, Wave.SAW), 0.7)
		_envelope(whoop, 0.03, 0.12)
		_add(out, _low_pass(whoop, 2400.0), 1.0, start)
	return _echo(out, 0.14, 0.3, 3)


func _metal_hit() -> PackedFloat32Array:
	var out := _metal(0.3, [310.0, 745.0, 1240.0, 2130.0], [9.0, 12.0, 18.0, 26.0])
	_add(out, _noise(0.04, 90.0, 3500.0, 1200.0), 1.0)
	return out


## Pumpík se rozbil: motor plynule umírá a nakonec něco měkce žuchne.
func _break_down() -> PackedFloat32Array:
	var out := _samples(1.15)
	var motor := _sweep(1.0, 700.0, 50.0, 1.6, Wave.SAW)
	var phase := 0.0
	for i in motor.size():
		phase += TAU * lerpf(14.0, 4.0, float(i) / motor.size()) / _rate
		motor[i] *= 0.7 + 0.3 * sin(phase)
	_add(out, _soft_low_pass(motor, 1300.0), 1.0)
	_add(out, _metal(0.25, [150.0, 330.0], [14.0, 20.0]), 0.45, 0.88)
	return out


func _repaired() -> PackedFloat32Array:
	var out := _samples(0.65)
	var notes := [523.25, 659.25, 880.0]
	for i in notes.size():
		_add(out, _bell(0.4, notes[i], 9.0, 2.0, 1.5), 1.0, i * 0.09)
	return out


## Krádež: padající řada tónů, peníze ubývají.
func _theft() -> PackedFloat32Array:
	var out := _samples(0.5)
	var notes := [1320.0, 990.0, 740.0, 554.0]
	for i in notes.size():
		var blip := _sweep(0.16, notes[i], notes[i] * 0.85, 22.0, Wave.SAW)
		_add(out, _low_pass(blip, 2600.0), 1.0, i * 0.08)
	return out


# --- Provoz ---

## Dva kovové tóny mince.
func _coin() -> PackedFloat32Array:
	var out := _samples(0.38)
	_add(out, _bell(0.25, 987.77, 16.0, 3.5, 2.0), 0.8)
	_add(out, _bell(0.3, 1318.5, 11.0, 3.5, 2.0), 1.0, 0.07)
	return out


## Pokuta: dva hrubé bzučáky.
func _fine() -> PackedFloat32Array:
	var out := _samples(0.42)
	for start: float in [0.0, 0.22]:
		var buzz := _sweep(0.16, 180.0, 176.0, 0.0, Wave.SAW)
		_add(buzz, _sweep(0.16, 190.0, 186.0, 0.0, Wave.SAW), 1.0)
		_envelope(buzz, 0.005, 0.03)
		_add(out, _low_pass(buzz, 1500.0), 1.0, start)
	return out


## Přistání: motor klesá a utichá, loď měkce dosedne. Jsou to hlavně tóny, šum by v reproduktorech
## šustil, proto zůstává jen jako hluboké dunění.
func _ship_land() -> PackedFloat32Array:
	var out := _engine(0.7, 130.0, 58.0)
	_add(out, _sweep(0.7, 250.0, 88.0, 1.5, Wave.SINE), 0.5)
	_envelope(out, 0.1, 0.22)
	var landing := _samples(0.85)
	_add(landing, out, 1.0)
	_add(landing, _sweep(0.3, 100.0, 44.0, 12.0, Wave.SINE), 1.1, 0.52)
	_add(landing, _metal(0.14, [240.0, 430.0], [34.0, 42.0]), 0.2, 0.52)
	return landing


## Start: hluboký motor se rozběhne, tón stoupá a loď se vzdálí.
func _ship_takeoff() -> PackedFloat32Array:
	var out := _engine(1.3, 55.0, 125.0)
	_add(out, _sweep(1.3, 110.0, 290.0, 0.0, Wave.SINE), 0.45)
	_envelope(out, 0.22, 0.95)
	return out


## Raketový motor: dvě rozladěné pily utlumené filtrem, pod nimi dunění bez vysokých tónů.
func _engine(seconds: float, from: float, to: float) -> PackedFloat32Array:
	var out := _sweep(seconds, from, to, 0.0, Wave.SAW)
	_add(out, _sweep(seconds, from * 1.012, to * 1.012, 0.0, Wave.SAW), 0.8)
	_add(out, _noise(seconds, 0.0, 180.0, 180.0), 0.7)
	return _soft_low_pass(out, 420.0)


## Naštvaná loď odlétá: dvě sestupná zatroubení.
func _ship_angry() -> PackedFloat32Array:
	var out := _samples(0.46)
	var first := _sweep(0.17, 233.0, 220.0, 0.0, Wave.SAW)
	_envelope(first, 0.01, 0.04)
	_add(out, _low_pass(first, 1500.0), 1.0)
	var second := _sweep(0.26, 196.0, 175.0, 0.0, Wave.SAW)
	_envelope(second, 0.01, 0.08)
	_add(out, _low_pass(second, 1300.0), 1.0, 0.2)
	return out


## Cisterna dokovala: těžký kov narazí na kov, zacvaknou zámky, dozní to v doku.
func _tanker_dock() -> PackedFloat32Array:
	var out := _samples(0.7)
	_add(out, _sweep(0.4, 95.0, 42.0, 8.0, Wave.SINE), 1.0)
	var freqs := [196.0, 198.5, 463.0, 471.0, 842.0, 1290.0, 1870.0]
	var decays := [5.0, 5.0, 7.0, 8.0, 11.0, 15.0, 20.0]
	_add(out, _metal(0.7, freqs, decays), 0.9)
	for start: float in [0.14, 0.22]:
		_add(out, _metal(0.05, [2100.0, 3300.0], [90.0, 120.0]), 0.12, start)
	var servo := _sweep(0.3, 190.0, 125.0, 0.0, Wave.TRIANGLE)
	_envelope(servo, 0.03, 0.2)
	_add(out, _soft_low_pass(servo, 900.0), 0.18, 0.3)
	return _reverb(out, 0.9, 0.3)


## Hotová část stavby: klapnutí a čisté cinknutí.
func _build_done() -> PackedFloat32Array:
	var out := _samples(0.5)
	_add(out, _metal(0.2, [350.0, 820.0, 1500.0], [20.0, 24.0, 32.0]), 1.0)
	_add(out, _bell(0.38, 1760.0, 10.0, 2.0, 1.0), 0.55, 0.08)
	return out


## Dokončená budova: stoupající arpeggio.
func _upgrade_done() -> PackedFloat32Array:
	var out := _samples(0.85)
	var notes := [392.0, 523.25, 659.25, 783.99, 1046.5]
	for i in notes.size():
		_add(out, _bell(0.42, notes[i], 8.0, 2.0, 1.2), 1.0, i * 0.075)
	return out


func _loot() -> PackedFloat32Array:
	var out := _samples(0.42)
	_add(out, _sweep(0.14, 500.0, 1500.0, 8.0, Wave.SINE), 1.0)
	_add(out, _bell(0.3, 1318.5, 10.0, 3.0, 1.0), 0.8, 0.1)
	return out


## Artefakt: rozvážný skleněný akord s jemně rozladěnými zvony, měkkým podkresem a třpytem.
func _artifact() -> PackedFloat32Array:
	var out := _samples(1.6)
	var pad := _samples(1.5)
	for freq: float in [220.0, 329.63, 440.0]:
		_add(pad, _sweep(1.5, freq, freq, 1.4, Wave.SINE), 0.3)
	_envelope(pad, 0.14, 0.5)
	_add(out, pad, 1.0)
	var notes := [440.0, 554.37, 659.25, 880.0, 1318.5]
	for i in notes.size():
		_add(out, _bell(1.4, notes[i] * 0.9985, 3.0, 2.0, 0.6), 0.5, i * 0.085)
		_add(out, _bell(1.4, notes[i] * 1.0015, 3.2, 3.0, 0.4), 0.5, i * 0.085)
	var sparkle := [1760.0, 2217.5, 2637.0, 3520.0]
	for i in sparkle.size():
		_add(out, _bell(0.5, sparkle[i], 9.0, 2.0, 0.3), 0.14, 0.45 + i * 0.07)
	return _reverb(out, 1.6, 0.4)


## Výhra na automatech: rychlá řada pípnutí a zvonek.
func _slots() -> PackedFloat32Array:
	var out := _samples(0.72)
	var notes := [659.25, 880.0, 739.99, 987.77, 830.61, 1108.7, 987.77, 1318.5]
	for i in notes.size():
		var blip := _sweep(0.05, notes[i], notes[i], 28.0, Wave.SOFT_SQUARE)
		_add(out, blip, 0.6, i * 0.045)
	_add(out, _bell(0.32, 1760.0, 9.0, 3.5, 1.5), 0.7, 0.38)
	return out


# --- Rozhraní ---

func _ui_click() -> PackedFloat32Array:
	var out := _sweep(0.045, 1500.0, 900.0, 110.0, Wave.TRIANGLE)
	_add(out, _high_pass(_noise(0.012, 300.0, 9000.0, 9000.0), 2000.0), 0.5)
	return out


func _ui_select() -> PackedFloat32Array:
	return _sweep(0.09, 880.0, 1320.0, 34.0, Wave.SINE)


func _ui_buy() -> PackedFloat32Array:
	var out := _samples(0.26)
	_add(out, _sweep(0.1, 783.99, 783.99, 24.0, Wave.TRIANGLE), 1.0)
	_add(out, _bell(0.18, 1174.7, 16.0, 2.0, 1.0), 1.0, 0.07)
	return out


## Splněná mise: fanfára v C dur, nad ní táhlý tón s vibratem jako theremin.
func _mission_done() -> PackedFloat32Array:
	var out := _samples(1.6)
	var notes := [261.63, 329.63, 392.0, 523.25]
	for i in notes.size():
		var note := _sweep(0.9 - i * 0.14, notes[i], notes[i], 2.5, Wave.SAW)
		_envelope(note, 0.012, 0.12)
		_add(out, _low_pass(note, 2200.0), 0.5, i * 0.14)
	var lead := _samples(0.95)
	var phase := 0.0
	for i in lead.size():
		var t := float(i) / _rate
		phase += TAU * 1046.5 * (1.0 + 0.012 * sin(TAU * 6.0 * t) * minf(t * 3.0, 1.0)) / _rate
		lead[i] = sin(phase) * exp(-2.2 * t)
	_envelope(lead, 0.03, 0.2)
	_add(out, lead, 0.45, 0.42)
	return _echo(out, 0.19, 0.3, 3)


# --- Smyčky ---

## Tankování: jen glo glo, galaxín polykaný hadicí.
func _pump_loop() -> PackedFloat32Array:
	return _glugs(6.0, 0.3, 0.42, 170.0, 300.0)


## Svařování: jen krátká elektrická zapraskání.
func _weld_loop() -> PackedFloat32Array:
	var seconds := 6.0
	var zaps := _samples(seconds)
	for i in roundi(seconds * 14.0):
		var freq := randf_range(1100.0, 2400.0)
		_add(zaps, _sweep(0.035, freq, freq * 0.7, 110.0, Wave.SOFT_SQUARE), randf_range(0.2, 0.6), randf() * (seconds - 0.04))
	return _soft_low_pass(zaps, 2600.0)


## Přečerpávání z cisterny: výrazné hluboké glo glo a pod ním tiché tepání čerpadla.
func _unload_loop() -> PackedFloat32Array:
	var seconds := 6.0
	var out := _glugs(seconds, 0.36, 0.5, 105.0, 190.0)
	for i in out.size():
		var t := float(i) / _rate
		var beat := 0.65 + 0.35 * sin(TAU * 1.5 * t)
		out[i] += (sin(TAU * 70.0 * t) * 0.6 + sin(TAU * 140.0 * t) * 0.3) * beat * 0.16
	return out


## Řada polknutí v rozestupech `gap_min` až `gap_max` (s) a výškách `low` až `high` (Hz).
func _glugs(seconds: float, gap_min: float, gap_max: float, low: float, high: float) -> PackedFloat32Array:
	var out := _samples(seconds)
	var at := 0.02
	while at < seconds - 0.25:
		_add(out, _glug(randf_range(low, high)), randf_range(0.75, 1.0), at)
		at += randf_range(gap_min, gap_max)
	return out


## Jedno glo: tón prudce stoupne jako bublina a jeho druhá harmonická mu dá dutý zvuk.
func _glug(freq: float) -> PackedFloat32Array:
	var seconds := 0.2
	var out := _samples(seconds)
	var phase := 0.0
	for i in out.size():
		var u := float(i) / out.size()
		phase += TAU * freq * (1.0 + 1.1 * u * u) / _rate
		out[i] = (sin(phase) + 0.35 * sin(phase * 2.0)) * sin(PI * pow(u, 0.5))
	return out


# --- Stavební kameny ---

func _samples(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(roundi(seconds * _rate))
	return out


## Tón klouzající z `from` na `to` (Hz) s útlumem `decay` (0 = bez útlumu).
func _sweep(seconds: float, from: float, to: float, decay: float, wave: Wave) -> PackedFloat32Array:
	var out := _samples(seconds)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / _rate
		phase += TAU * from * pow(to / from, t / seconds) / _rate
		out[i] = _wave_at(wave, phase) * exp(-decay * t)
	return out


func _wave_at(wave: Wave, phase: float) -> float:
	match wave:
		Wave.TRIANGLE:
			return asin(sin(phase)) * 2.0 / PI
		Wave.SOFT_SQUARE:
			return tanh(sin(phase) * 3.0)
		Wave.SAW:
			# Několik harmonických, aby pila nezněla digitálně ostře.
			var sum := 0.0
			for harmonic in range(1, 7):
				sum += sin(phase * harmonic) / harmonic
			return sum * 0.6
	return sin(phase)


## Zvon: frekvenční modulace, jejíž hloubka s časem klesá.
func _bell(seconds: float, freq: float, decay: float, ratio: float, index: float) -> PackedFloat32Array:
	var out := _samples(seconds)
	for i in out.size():
		var t := float(i) / _rate
		var level := exp(-decay * t)
		out[i] = sin(TAU * freq * t + index * level * sin(TAU * freq * ratio * t)) * level
	return out


## Kovový úder: neharmonické tóny, každý s vlastním útlumem.
func _metal(seconds: float, freqs: Array, decays: Array) -> PackedFloat32Array:
	var out := _samples(seconds)
	for partial in freqs.size():
		for i in out.size():
			var t := float(i) / _rate
			out[i] += sin(TAU * freqs[partial] * t) * exp(-decays[partial] * t) / (partial + 1.0)
	return out


## Šum s dolní propustí, jejíž mez klouže z `from` na `to` (Hz).
func _noise(seconds: float, decay: float, from: float, to: float) -> PackedFloat32Array:
	var out := _samples(seconds)
	var state := 0.0
	for i in out.size():
		var t := float(i) / _rate
		var cutoff := from * pow(to / from, t / seconds)
		state = lerpf(state, randf_range(-1.0, 1.0), 1.0 - exp(-TAU * cutoff / _rate))
		out[i] = state * exp(-decay * t)
	return _balanced(out)


## Náhodné krátké praskance. `density` = kolik jich je za sekundu, `decay` = jak rychle řídnou.
func _crackle(seconds: float, density: float, decay: float) -> PackedFloat32Array:
	var out := _samples(seconds)
	for i in out.size():
		var t := float(i) / _rate
		if randf() < density / _rate * exp(-decay * t):
			var length := randi_range(20, 120)
			for j in mini(length, out.size() - i):
				out[i + j] += randf_range(-1.0, 1.0) * (1.0 - float(j) / length)
	return out


func _low_pass(input: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	var out := input.duplicate()
	var amount := 1.0 - exp(-TAU * cutoff / _rate)
	var state := 0.0
	for i in out.size():
		state += (out[i] - state) * amount
		out[i] = state
	return out


## Strmější dolní propust: tři za sebou. Jedna by nad mezí nechala dost šumu, aby syčel.
func _soft_low_pass(input: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	return _low_pass(_low_pass(_low_pass(input, cutoff), cutoff), cutoff)


func _high_pass(input: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	var low := _low_pass(input, cutoff)
	var out := input.duplicate()
	for i in out.size():
		out[i] -= low[i]
	return out


## Přimíchá `other` do `out` od času `start` (s). Co se nevejde, ořízne.
func _add(out: PackedFloat32Array, other: PackedFloat32Array, gain: float, start := 0.0) -> void:
	var offset := roundi(start * _rate)
	for i in mini(other.size(), out.size() - offset):
		out[offset + i] += other[i] * gain


## Lineární náběh a dozvuk (s).
func _envelope(out: PackedFloat32Array, attack: float, release: float) -> void:
	var attack_samples := maxf(attack * _rate, 1.0)
	var release_samples := maxf(release * _rate, 1.0)
	for i in out.size():
		out[i] *= minf(minf(i / attack_samples, (out.size() - 1 - i) / release_samples), 1.0)


## Měkké zkreslení.
func _drive(out: PackedFloat32Array, amount: float) -> void:
	for i in out.size():
		out[i] = tanh(out[i] * amount)


## Dozvuk prostoru: čtyři zpožděné smyčky s tlumením výšek. `tail` je délka dozvuku (s).
func _reverb(input: PackedFloat32Array, tail: float, wet: float) -> PackedFloat32Array:
	var out := _samples(float(input.size()) / _rate + tail)
	_add(out, input, 1.0)
	for delay: float in [0.0297, 0.0371, 0.0411, 0.0437]:
		var delay_samples := roundi(delay * _rate)
		var feedback := pow(10.0, -3.0 * delay / tail)
		var comb := out.duplicate()
		var low := 0.0
		for i in range(delay_samples, comb.size()):
			low += (comb[i - delay_samples] - low) * 0.5
			comb[i] = (input[i] if i < input.size() else 0.0) + low * feedback
		_add(out, comb, wet * 0.25)
	return out


## Ozvěna: vrátí delší zvuk s `times` opakováními.
func _echo(input: PackedFloat32Array, delay: float, feedback: float, times: int) -> PackedFloat32Array:
	var out := input.duplicate()
	out.resize(input.size() + roundi(delay * times * _rate))
	var gain := 1.0
	for repeat in range(1, times + 1):
		gain *= feedback
		_add(out, input, gain, delay * repeat)
	return out


## Odstraní stejnosměrnou složku a srovná hlasitost.
func _balanced(input: PackedFloat32Array) -> PackedFloat32Array:
	var out := input.duplicate()
	var mean := 0.0
	var peak := 0.0001
	for value in out:
		mean += value
	mean /= maxi(out.size(), 1)
	for i in out.size():
		out[i] -= mean
		peak = maxf(peak, absf(out[i]))
	for i in out.size():
		out[i] /= peak
	return out


func _save(sound: String, input: PackedFloat32Array, looping: bool) -> void:
	var out := _balanced(input)
	var fade_samples := roundi(FADE_TIME * _rate)
	var sum := 0.0
	for i in out.size():
		out[i] *= PEAK
		if not looping:
			out[i] *= minf(minf(float(i) / fade_samples, float(out.size() - 1 - i) / fade_samples), 1.0)
		sum += out[i] * out[i]
	var data := PackedByteArray()
	data.resize(out.size() * 2)
	for i in out.size():
		data.encode_s16(i * 2, roundi(out[i] * 32767.0))
	var file := FileAccess.open(OUT_DIR + sound + ".wav", FileAccess.WRITE)
	var loop_chunk_size := 60 if looping else 0
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + data.size() + (loop_chunk_size + 8 if looping else 0))
	file.store_buffer("WAVEfmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(_rate)
	file.store_32(_rate * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(data.size())
	file.store_buffer(data)
	if looping:
		file.store_buffer("smpl".to_ascii_buffer())
		file.store_32(loop_chunk_size)
		for value: int in [0, 0, 1000000000 / _rate, 60, 0, 0, 0, 1, 0]:
			file.store_32(value)
		for value: int in [0, 0, 0, out.size(), 0, 0]:
			file.store_32(value)
	file.close()
	var rms_db := linear_to_db(sqrt(sum / maxi(out.size(), 1)))
	print("%-14s %5.2f s  RMS %6.1f dB" % [sound, float(out.size()) / _rate, rms_db])
