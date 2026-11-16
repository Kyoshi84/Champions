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

# ---------------------------------------------------------------- cięcie, smuga doskoku
class Ciecie extends Node2D:
	var t := 0.0
	var w_lewo := false
	func _process(delta: float) -> void:
		t += delta
		if t > 0.22:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := clampf(1.0 - t / 0.22, 0.0, 1.0)
		var k := -1.0 if w_lewo else 1.0
		var pts := PackedVector2Array()
		var n := 14
		for i in n + 1:          # sierp: łuk zewnętrzny i wewnętrzny
			var kat := lerpf(-1.25, 1.25, float(i) / n)
			pts.append(Vector2(cos(kat) * 46.0 * k, sin(kat) * 58.0))
		for i in n + 1:
			var kat := lerpf(1.25, -1.25, float(i) / n)
			pts.append(Vector2((cos(kat) * 46.0 - 16.0 * cos(kat * 1.2)) * k, sin(kat) * 58.0))
		draw_colored_polygon(pts, Color(0.92, 0.12, 0.08, a))
		draw_polyline(pts.slice(0, n + 1), Color(1.0, 0.75, 0.6, a), 2.0)

class Smuga extends Node2D:
	var od := Vector2.ZERO
	var do_ := Vector2.ZERO
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		if t > 0.25:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := clampf(1.0 - t / 0.25, 0.0, 1.0) * 0.35
		var n := (do_ - od).orthogonal().normalized() * 14.0
		draw_colored_polygon(PackedVector2Array([od, do_ + n, do_ - n]), Color(1.0, 0.9, 0.7, a))

static func ciecie(parent: Node, pos: Vector2, w_lewo: bool = false) -> void:
	var c := Ciecie.new()
	c.position = pos
	c.w_lewo = w_lewo
	c.z_index = 135
	parent.add_child(c)

static func smuga(parent: Node, od: Vector2, do_: Vector2) -> void:
	var s := Smuga.new()
	s.od = od
	s.do_ = do_
	s.z_index = 2
	parent.add_child(s)

# ---------------------------------------------------------------- krew na ziemi (zostaje do końca planszy)
class Krew extends Node2D:
	const LIMIT := 90
	var plamy: Array = []        # [{p: Vector2, r: float, ziarno: int}]
	func dodaj(p: Vector2, r: float) -> void:
		plamy.append({"p": p, "r": r, "ziarno": randi()})
		if plamy.size() > LIMIT:
			plamy.pop_front()
		queue_redraw()
	func przesun(dx: float) -> void:
		if plamy.is_empty():
			return
		for pl in plamy:
			pl["p"].x -= dx
		plamy = plamy.filter(func(pl): return pl["p"].x > -120.0)
		queue_redraw()
	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		for pl in plamy:
			rng.seed = int(pl["ziarno"])
			var p: Vector2 = pl["p"]
			var r: float = pl["r"]
			var ciemna := Color(0.30, 0.02, 0.02, 0.85)
			var jasna := Color(0.52, 0.05, 0.04, 0.85)
			draw_set_transform(p, 0.0, Vector2(1.0, 0.42))       # spłaszczenie - plama leży na ziemi
			draw_circle(Vector2.ZERO, r, ciemna)
			draw_circle(Vector2(rng.randf_range(-r, r) * 0.3, 0), r * 0.62, jasna)
			for i in rng.randi_range(4, 8):
				var kat := rng.randf() * TAU
				var d := r * rng.randf_range(0.9, 2.1)
				draw_circle(Vector2(cos(kat), sin(kat)) * d, r * rng.randf_range(0.12, 0.34), ciemna)
			# rozbryzg w stronę, z której przyszedł cios (w prawo)
			draw_colored_polygon(PackedVector2Array([Vector2(r * 0.5, -r * 0.4), Vector2(r * rng.randf_range(2.2, 3.4), 0), Vector2(r * 0.5, r * 0.4)]), ciemna)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ---------------------------------------------------------------- moneta: wypada, leży, sama leci do licznika
class Moneta extends Node2D:
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var sz := absf(cos(t * 9.0)) * 0.7 + 0.3            # obrót monety
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(sz, 1.0))
		draw_circle(Vector2.ZERO, 8.0, Color(0.35, 0.22, 0.05))
		draw_circle(Vector2.ZERO, 6.5, Color(0.98, 0.78, 0.25))
		draw_circle(Vector2(-1.5, -1.5), 3.0, Color(1.0, 0.93, 0.6))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Rozsypuje monety wokół 'pos'; po chwili same lecą do 'cel' (licznik koron). 'po_dotarciu' woła się raz na monetę.
static func monety(parent: Node, pos: Vector2, cel: Vector2, ile: int, po_dotarciu: Callable, skala_czasu: float = 1.0) -> void:
	var k := 1.0 / maxf(skala_czasu, 0.1)
	for i in ile:
		var m := Moneta.new()
		m.position = pos + Vector2(0, -30)
		m.z_index = 120
		m.t = randf() * 3.0
		parent.add_child(m)
		var ziemia := pos + Vector2(randf_range(-46, 46), randf_range(-6, 18))
		var tw := m.create_tween()
		tw.tween_property(m, "position", Vector2((m.position.x + ziemia.x) * 0.5, pos.y - 70.0 - randf() * 30.0), 0.16 * k).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(m, "position", ziemia, 0.2 * k).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_interval((0.55 + 0.07 * i) * k)
		tw.tween_property(m, "position", cel, 0.38 * k).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func():
			po_dotarciu.call()
			m.queue_free())

# ---------------------------------------------------------------- krąg pod bohaterem: obrażenia i odnowienie ataku
class Krag extends Node2D:
	var tekst := ""
	var postep := 0.0            # 0..1 - ile odnowienia już minęło
	var aktywny := true
	func ustaw(t: String, p: float, a: bool) -> void:
		if t != tekst or absf(p - postep) > 0.01 or a != aktywny:
			tekst = t
			postep = p
			aktywny = a
			queue_redraw()
	func _draw() -> void:
		var kol := Color(0.86, 0.2, 0.15) if aktywny else Color(0.35, 0.3, 0.28)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 44.0, Color(0.03, 0.02, 0.02, 0.55))
		draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 40, Color(0.9, 0.86, 0.8, 0.75 if aktywny else 0.3), 3.0, true)
		if aktywny and postep > 0.0:
			draw_arc(Vector2.ZERO, 38.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(postep, 0.0, 1.0), 40, kol, 5.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var f := Gk.f_gruby()
		var w := f.get_string_size(tekst, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string_outline(f, Vector2(-w * 0.5, 5), tekst, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.9))
		draw_string(f, Vector2(-w * 0.5, 5), tekst, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.96, 0.92, 0.82) if aktywny else Color(0.6, 0.55, 0.5))
