class_name WeatherOverlay
extends Node2D
## One Weather Overlays sheet played as a looping tile over a rect (the whole screen by default),
## read from sheets/effects.json.
##
##     WeatherOverlay.add(self, "rain_heavy")               # over the screen, in a CanvasLayer of its own
##     var fog := WeatherOverlay.add(self, "fog", "pixel")  # the pixel set, nearest-filtered
##     fog.stop(2.0)                                         # fades out and frees itself
##
## `tile_size` is how many screen pixels one tile spans, whichever set draws it: by default
## effects.json's "tile", else 256 (the soft fogs span 512, and their pixel set is drawn at 128). Set `scroll` to
## the camera's position (times a parallax factor if you like) and the weather stays put in the
## world instead of on the screen.

## Where sheets/ is: found in this folder, or at res://sheets/ as the zip has it. Set it if the
## sheets are elsewhere.
static var sheets_dir := ""
static var default_set := "256"
static var _data: Dictionary = {}
static var _frames: Dictionary = {}

var effect := ""
var sheet_set := ""
## The area covered, in the node's space; empty covers the viewport.
var rect := Rect2()
var tile_size := 0.0
var scroll := Vector2.ZERO
var speed := 1.0
var time := 0.0
var _textures: Array[ImageTexture] = []
var _fps := 12.0
var _fading: Tween


## The effect names in the installed sheets, e.g. "rain_heavy".
static func effects() -> PackedStringArray:
	return PackedStringArray(_effects().keys())


static func info(fx_name: String) -> Dictionary:
	return _effects()[fx_name]


## Adds `fx_name` over the whole screen: a CanvasLayer at `layer` under `parent`, holding the
## overlay, which fades in over `fade` seconds. Returns the overlay.
static func add(parent: Node, fx_name: String, set_name := "", layer := 10, fade := 0.5) -> WeatherOverlay:
	var canvas := CanvasLayer.new()
	canvas.layer = layer
	var fx := WeatherOverlay.new()
	fx.setup(fx_name, set_name)
	canvas.add_child(fx)
	parent.add_child(canvas)
	if fade > 0.0:
		fx.modulate.a = 0.0
		fx.fade_to(1.0, fade)
	return fx


## The effect's frames as textures that repeat, cut once per sheet set and shared.
static func frames_for(fx_name: String, set_name := "") -> Array[ImageTexture]:
	set_name = set_name if set_name else default_set
	var key := set_name + "/" + fx_name
	if key in _frames:
		return _frames[key]
	var e: Dictionary = _effects()[fx_name]
	var sheet: Image = (load(sheets_dir.path_join(set_name).path_join(e.file)) as Texture2D).get_image()
	if sheet.is_compressed():
		sheet.decompress()
	var cell := Vector2i(e.cell[set_name][0], e.cell[set_name][1])
	var cols: int = e.columns
	var out: Array[ImageTexture] = []
	for i in int(e.frames):
		out.append(ImageTexture.create_from_image(sheet.get_region(Rect2i(Vector2i(i % cols, i / cols) * cell, cell))))
	_frames[key] = out
	return out


static func _effects() -> Dictionary:
	if _data.is_empty():
		if sheets_dir.is_empty():
			var here := "res://addons/weather_overlays/sheets/"
			sheets_dir = here if ResourceLoader.exists(here + "effects.json") else "res://sheets/"
		var json: JSON = load(sheets_dir.path_join("effects.json"))
		for e: Dictionary in json.data.effects:
			_data[e.name] = e
	return _data


func setup(fx_name: String, set_name := "") -> void:
	if fx_name not in _effects():
		push_error("WeatherOverlay: no effect %s in %s" % [fx_name, sheets_dir])
		return
	effect = fx_name
	sheet_set = set_name if set_name else default_set
	_textures = frames_for(fx_name, sheet_set)
	_fps = float(_effects()[fx_name].fps)
	if tile_size <= 0.0:
		tile_size = float(_effects()[fx_name].get("tile", 256))
	texture_repeat = TEXTURE_REPEAT_ENABLED
	texture_filter = TEXTURE_FILTER_NEAREST if sheet_set == "pixel" else TEXTURE_FILTER_LINEAR


func frame() -> int:
	return int(time * _fps) % maxi(_textures.size(), 1)


func fade_to(alpha: float, seconds := 1.0) -> void:
	if _fading:
		_fading.kill()
	_fading = create_tween()
	_fading.tween_property(self, "modulate:a", alpha, seconds)


## Fades out over `fade` seconds and frees the overlay, and the CanvasLayer add() made for it.
func stop(fade := 1.0) -> void:
	if not is_inside_tree():
		return
	fade_to(0.0, fade)
	var gone: Node = get_parent() if get_parent() is CanvasLayer and get_parent().get_child_count() == 1 else self
	_fading.finished.connect(gone.queue_free)


func _process(delta: float) -> void:
	time += delta * speed
	queue_redraw()


func _draw() -> void:
	if _textures.is_empty():
		return
	var tex := _textures[frame()]
	var area := rect if rect.has_area() else get_viewport_rect()
	var k := tex.get_width() / tile_size   # texture pixels per screen pixel
	draw_texture_rect_region(tex, area, Rect2((area.position + scroll) * k, area.size * k))
