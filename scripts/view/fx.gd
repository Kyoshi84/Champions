class_name Fx
extends RefCounted
## Krótkie efekty wizualne: liczby obrażeń, pocisk z nieba gracza, pociski bohaterów, błyski.

class Bolt extends Node2D:
	var cel := Vector2.ZERO
	var promien := 64.0
	var t := 0.0
	var kolor := Color(1.0, 0.85, 0.35)
	func _process(delta: float) -> void:
		t += delta
		if t > 0.35:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := clampf(1.0 - t / 0.35, 0.0, 1.0)
		var top := Vector2(cel.x + 90.0, cel.y - 520.0)
		var pts := PackedVector2Array([top, top.lerp(cel, 0.35) + Vector2(-18, 0), top.lerp(cel, 0.7) + Vector2(14, 0), cel])
		draw_polyline(pts, Color(kolor.r, kolor.g, kolor.b, a), 5.0)
		draw_polyline(pts, Color(1, 1, 1, a), 2.0)
		draw_arc(cel, promien * (0.4 + t * 1.8), 0, TAU, 28, Color(kolor.r, kolor.g, kolor.b, a * 0.8), 3.0)
		draw_circle(cel, 12.0 * a, Color(1, 1, 0.8, a))

class Ring extends Node2D:
	var promien := 80.0
	var t := 0.0
	var kolor := Color(1, 0.6, 0.2)
	func _process(delta: float) -> void:
		t += delta
		if t > 0.4:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := clampf(1.0 - t / 0.4, 0.0, 1.0)
		draw_arc(Vector2.ZERO, promien * (0.3 + t * 1.75), 0, TAU, 32, Color(kolor.r, kolor.g, kolor.b, a), 4.0)

static func tekst(parent: Node, pos: Vector2, txt: String, kol: Color, size: int = 20) -> void:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", kol)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.01))
	l.add_theme_constant_override("outline_size", 4)
	l.position = pos + Vector2(randf_range(-14, 14) - 10, -10)
	l.z_index = 200
	parent.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 44.0, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)

static func bolt(parent: Node, cel: Vector2, promien: float) -> void:
	var b := Bolt.new()
	b.cel = cel
	b.promien = promien
	b.z_index = 150
	parent.add_child(b)

static func ring(parent: Node, pos: Vector2, promien: float, kol: Color) -> void:
	var r := Ring.new()
	r.position = pos
	r.promien = promien
	r.kolor = kol
	r.z_index = 140
	parent.add_child(r)

static func pocisk(parent: Node, od: Vector2, do_: Vector2, tex_path: String, kol: Color) -> void:
	var t := Art.tex(tex_path)
	var n: Node2D
	if t != null:
		var s := Sprite2D.new()
		s.texture = t
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.rotation = (do_ - od).angle()
		n = s
	else:
		var p := Polygon2D.new()
		p.polygon = PackedVector2Array([Vector2(-6, -3), Vector2(6, 0), Vector2(-6, 3)])
		p.color = kol
		p.rotation = (do_ - od).angle()
		n = p
	n.position = od
	n.z_index = 130
	parent.add_child(n)
	var tw := n.create_tween()
	tw.tween_property(n, "position", do_, 0.22)
	tw.tween_callback(n.queue_free)
