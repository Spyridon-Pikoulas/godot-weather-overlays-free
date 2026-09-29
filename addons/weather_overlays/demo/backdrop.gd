extends Node2D
## A flat scene for the weather to fall over, drawn into `rect`: "land" (hills and pines at
## night), "field" (grass seen from above, for cloud shadows) or "water" (under the sea, for
## bubbles). `pan` slides it sideways; everything repeats every 1280 px. It draws a little past
## `rect` (the moon, trees): put it under a clipping Control to keep it in.

@export_enum("land", "field", "water") var kind := "land"
var rect := Rect2(0, 0, 1280, 720)
var pan := 0.0:
	set(v):
		pan = v
		queue_redraw()


## The backdrop an effect is shown over, from effects.json's "backdrop".
static func for_effect(e: Dictionary) -> String:
	return e.get("backdrop", "land")


func _draw() -> void:
	match kind:
		"field": _field()
		"water": _water()
		_: _land()


func _ridge(base: float, height: float, waves: Array, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 64
	for i in steps + 1:
		var x := rect.position.x + rect.size.x * i / steps
		var u := (x + pan) / 1280.0 * TAU
		var y := 0.0
		for w: Vector2 in waves:   # (cycles per 1280 px, phase)
			y += sin(u * w.x + w.y) / waves.size()
		pts.append(Vector2(x, rect.position.y + rect.size.y * (base - height * y)))
	pts.append(rect.end)
	pts.append(Vector2(rect.position.x, rect.end.y))
	draw_colored_polygon(pts, color)


func _land() -> void:
	var bands := 12
	for i in bands:   # the sky, dark above to the lighter horizon
		var c := Color(0.07, 0.08, 0.16).lerp(Color(0.2, 0.19, 0.32), float(i) / (bands - 1))
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.7 * i / bands), Vector2(rect.size.x, rect.size.y * 0.7 / bands + 1)), c)
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.7), Vector2(rect.size.x, rect.size.y * 0.3)), Color(0.2, 0.19, 0.32))
	var s := rect.size.y / 720.0
	var moon := rect.position + Vector2(fposmod(rect.size.x * 0.78 - pan * 0.1, rect.size.x), rect.size.y * 0.18)
	draw_circle(moon, 70 * s, Color(0.95, 0.92, 0.8, 0.08))
	draw_circle(moon, 34 * s, Color(0.93, 0.9, 0.78))
	_ridge(0.62, 0.1, [Vector2(2, 0.3), Vector2(5, 1.7), Vector2(9, 4.0)], Color(0.15, 0.15, 0.26))
	_ridge(0.74, 0.07, [Vector2(3, 2.1), Vector2(7, 0.4)], Color(0.11, 0.11, 0.19))
	var trees := 22   # pines along the near hills, every 1280 / 22 px of the world
	var gap := 1280.0 / trees
	var first := floori((rect.position.x + pan) / gap) - 1
	for j in range(first, first + ceili(rect.size.x / gap) + 3):
		var n := posmod(j, trees)
		var x := j * gap - pan + sin(n * 7.3) * gap * 0.3
		var u := (x + pan) / 1280.0 * TAU
		var ground := rect.position.y + rect.size.y * (0.74 - 0.07 * (sin(u * 3 + 2.1) + sin(u * 7 + 0.4)) / 2)
		var h := (60.0 + 40.0 * (0.5 + 0.5 * sin(n * 3.1))) * s
		var w := h * 0.36
		for k in 3:
			var top := ground - h * (1.0 - k * 0.28)
			var base := ground - h * (0.45 - k * 0.3)
			draw_colored_polygon(PackedVector2Array([Vector2(x, top), Vector2(x + w * (0.6 + k * 0.2), base),
				Vector2(x - w * (0.6 + k * 0.2), base)]), Color(0.06, 0.07, 0.12))
	_ridge(0.86, 0.02, [Vector2(4, 0.9), Vector2(11, 2.6)], Color(0.08, 0.08, 0.13))
	var windows := [Vector2(0.3, 0.83), Vector2(0.62, 0.845)]   # two lit cottages
	for wpos: Vector2 in windows:
		var p := rect.position + Vector2(fposmod(wpos.x * rect.size.x - pan, rect.size.x), wpos.y * rect.size.y)
		draw_rect(Rect2(p - Vector2(30, 24) * s, Vector2(60, 34) * s), Color(0.05, 0.05, 0.09))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-36, -24) * s, p + Vector2(0, -50) * s,
			p + Vector2(36, -24) * s]), Color(0.05, 0.05, 0.09))
		draw_rect(Rect2(p + Vector2(-16, -14) * s, Vector2(10, 10) * s), Color(1.0, 0.78, 0.4))
		draw_rect(Rect2(p + Vector2(8, -14) * s, Vector2(10, 10) * s), Color(1.0, 0.78, 0.4))


func _field() -> void:
	draw_rect(rect, Color8(96, 140, 72))
	var s := rect.size.y / 720.0
	var path := PackedVector2Array()
	for i in 33:
		var y := rect.position.y + rect.size.y * i / 32.0
		path.append(Vector2(rect.position.x + rect.size.x * 0.4 + sin(y / rect.size.y * 5.0 + pan / 300.0) * 60 * s, y))
	draw_polyline(path, Color(0.62, 0.52, 0.36), 34 * s)
	for j in 16:   # trees seen from above
		var p := rect.position + Vector2(fposmod(j * 523.0 - pan, 1280.0) / 1280.0 * rect.size.x,
			fposmod(j * 311.0, 720.0) / 720.0 * rect.size.y)
		draw_circle(p + Vector2(6, 8) * s, 30 * s, Color(0.2, 0.32, 0.16))
		draw_circle(p, 28 * s, Color(0.24, 0.42, 0.2))
		draw_circle(p - Vector2(8, 8) * s, 14 * s, Color(0.32, 0.52, 0.26))
	for j in 40:
		var p := rect.position + Vector2(fposmod(j * 197.0 - pan, 1280.0) / 1280.0 * rect.size.x,
			fposmod(j * 431.0, 720.0) / 720.0 * rect.size.y)
		draw_circle(p, 5 * s, Color(0.44, 0.62, 0.32))


func _water() -> void:
	var bands := 14
	for i in bands:
		var c := Color(0.12, 0.34, 0.46).lerp(Color8(20, 60, 90), float(i) / (bands - 1))
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * i / bands), Vector2(rect.size.x, rect.size.y / bands + 1)), c)
	var s := rect.size.y / 720.0
	for j in 9:   # light from above
		var x := rect.position.x + fposmod(j * 157.0 - pan * 0.3, 1280.0) / 1280.0 * rect.size.x
		draw_colored_polygon(PackedVector2Array([Vector2(x, rect.position.y), Vector2(x + 40 * s, rect.position.y),
			Vector2(x + 120 * s, rect.position.y + rect.size.y * 0.7), Vector2(x + 60 * s, rect.position.y + rect.size.y * 0.7)]),
			Color(0.6, 0.85, 1.0, 0.05))
	for j in 14:   # weed
		var x := rect.position.x + fposmod(j * 97.0 - pan, 1280.0) / 1280.0 * rect.size.x
		var h := (120.0 + 90.0 * (0.5 + 0.5 * sin(j * 2.3))) * s
		var pts := PackedVector2Array()
		for k in 9:
			pts.append(Vector2(x + sin(k * 0.8 + j) * 10 * s, rect.end.y - h * k / 8.0))
		draw_polyline(pts, Color(0.1, 0.3, 0.22), 8 * s)
	_ridge(0.9, 0.02, [Vector2(3, 0.5), Vector2(8, 2.0)], Color(0.55, 0.5, 0.36))
