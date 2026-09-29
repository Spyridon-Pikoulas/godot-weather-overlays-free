extends Node2D
## Toggle the weather on and off, several at once; pick a sheet set; pan with the arrow keys and
## the weather keeps to the world. Left alone, it runs through the weathers by itself.

const Backdrop := preload("res://addons/weather_overlays/demo/backdrop.gd")
const IDLE := 3.0
const PRESETS := [["rain_heavy", "fog"], ["snow_heavy"], ["leaves"], ["fireflies", "fog"], ["rain_storm"],
	["petals", "sparkles"], ["blizzard"], ["embers", "ash"], ["sandstorm"], ["bubbles"], ["cloud_shadows"],
	["dust"], ["rain_light"], ["snow_light", "fog"], ["fog_thick"]]
const PAN_SPEED := 320.0

var on: Dictionary = {}   # effect name -> WeatherOverlay
var buttons: Dictionary = {}
var backdrop: Node2D
var idle := IDLE
var preset := 0
var pan := 0.0
var presets: Array = []


func _ready() -> void:
	backdrop = Backdrop.new()
	add_child(backdrop)
	var have := WeatherOverlay.effects()
	for p: Array in PRESETS:   # the sampler has only some of them
		if p.all(func(n: String) -> bool: return n in have):
			presets.append(p)
	for n in have:
		if [n] not in presets:
			presets.append([n])
	var ui := CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	var bar := VBoxContainer.new()
	bar.position = Vector2(16, 12)
	bar.size.x = 1248
	ui.add_child(bar)
	var row := HFlowContainer.new()
	bar.add_child(row)
	for n in have:
		var b := Button.new()
		b.text = n
		b.toggle_mode = true
		b.toggled.connect(func(pressed: bool) -> void:
			idle = IDLE * 3
			toggle(n, pressed))
		row.add_child(b)
		buttons[n] = b
	var first: Dictionary = WeatherOverlay.info(have[0])
	var sets := ["256", "128", "pixel"].filter(func(s: String) -> bool:  # the web build leaves 256 out
		return ResourceLoader.exists(WeatherOverlay.sheets_dir.path_join(s).path_join(first.file)))
	WeatherOverlay.default_set = sets[0]
	var set_row := HBoxContainer.new()
	var group := ButtonGroup.new()
	for s: String in sets:
		var b := Button.new()
		b.text = s
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = s == sets[0]
		b.pressed.connect(func() -> void:
			idle = IDLE * 3
			use_set(s))
		set_row.add_child(b)
	var hint := Label.new()
	hint.text = "   Arrow keys pan: the weather keeps to the world."
	hint.add_theme_color_override("font_color", Color(0.8, 0.83, 0.95))
	set_row.add_child(hint)
	bar.add_child(set_row)
	show_preset(presets[0])


func toggle(n: String, pressed: bool) -> void:
	if pressed and n not in on:
		on[n] = WeatherOverlay.add(self, n, "", 10 + on.size())
		on[n].scroll.x = pan
		backdrop.kind = Backdrop.for_effect(WeatherOverlay.info(n))
		backdrop.queue_redraw()
	elif not pressed and n in on:
		on[n].stop(0.6)
		on.erase(n)
		if on.is_empty() or not on.keys().any(func(k: String) -> bool:
				return Backdrop.for_effect(WeatherOverlay.info(k)) == backdrop.kind):
			backdrop.kind = "land" if on.is_empty() else Backdrop.for_effect(WeatherOverlay.info(on.keys()[-1]))
			backdrop.queue_redraw()
	buttons[n].set_pressed_no_signal(pressed)


func show_preset(names: Array) -> void:
	for n: String in on.keys():
		if n not in names:
			toggle(n, false)
	for n: String in names:
		toggle(n, true)


func use_set(s: String) -> void:
	WeatherOverlay.default_set = s
	var names := on.keys()
	for n: String in names:
		on[n].setup(n, s)


func _process(delta: float) -> void:
	var dir := Input.get_axis(&"ui_left", &"ui_right")
	if dir != 0.0:
		idle = IDLE * 3
		pan += dir * PAN_SPEED * delta
		backdrop.pan = pan
		for fx: WeatherOverlay in on.values():
			fx.scroll.x = pan
	idle -= delta
	if idle > 0.0:
		return
	idle = 4.0
	preset = (preset + 1) % presets.size()
	show_preset(presets[preset])
