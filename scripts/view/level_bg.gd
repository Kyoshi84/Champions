class_name LevelBg
extends Node2D
## Tło poziomu z warstw (data/levels_art.json). Warstwy 'tyl' są za postaciami, 'przod' przed nimi.
## Brakującą warstwę zastępuje placeholder rysowany kodem. scroll_x przesuwa warstwy zgodnie z ich paralaksą.

const W := 1280.0
const H := 720.0

class Warstwy extends Node2D:
	var bg: LevelBg
	var lista: Array = []
	var front: bool = false
	func _draw() -> void:
		for l in lista:
			bg.rysuj_warstwe(self, l, front)

var cfg: Dictionary = {}
var level_id: String = ""
var scroll_x: float = 0.0
var tyl: Warstwy
var przod: Warstwy
var ma_grafike: bool = false

func setup(id: String) -> void:
	level_id = id
	cfg = Data.art.get("poziomy", {}).get(id, {})
	tyl = Warstwy.new()
	tyl.bg = self
	tyl.lista = cfg.get("tyl", [])
	tyl.z_index = -100
	add_child(tyl)
	przod = Warstwy.new()
	przod.bg = self
	przod.lista = cfg.get("przod", [])
	przod.z_index = 100
	przod.front = true
	add_child(przod)
	for l in tyl.lista:
		if _tex(l) != null:
			ma_grafike = true

func przesun(dx: float) -> void:
	scroll_x += dx
	tyl.queue_redraw()
	przod.queue_redraw()

func _tex(l: Dictionary) -> Texture2D:
	return Art.tex("%s/%s" % [str(cfg.get("folder", "")), str(l.get("plik", ""))])

func rysuj_warstwe(ci: CanvasItem, l: Dictionary, front: bool = false) -> void:
	var p := float(l.get("paralaksa", 0.0))
	var t := _tex(l)
	if t != null:
		if p == 0.0:
			ci.draw_texture(t, Vector2.ZERO)
		else:
			var w := float(t.get_width())
			var x := -fposmod(scroll_x * p, w)
			while x < W:
				ci.draw_texture(t, Vector2(x, 0))
				x += w
		return
	if front and p <= 1.0:
		return      # brak grafiki pierwszego planu = nic nie zasłania postaci
	_placeholder(ci, p)

# ---------------------------------------------------------------- placeholdery
func _c(k: String) -> Color:
	return Art.col(str(cfg.get("placeholder", {}).get(k, "#444444")))

func _placeholder(ci: CanvasItem, p: float) -> void:
	var ph: Dictionary = cfg.get("placeholder", {})
	var hy := float(cfg.get("horyzont_y", 300))
	var wnetrze := str(ph.get("typ", "plener")) == "wnetrze"
	var off := scroll_x * p
	if p == 0.0:
		if wnetrze:
			ci.draw_rect(Rect2(0, 0, W, hy), _c("sciana"))
			for i in 9:
				ci.draw_rect(Rect2(i * 160.0 - 10.0, 0, 20, hy), _c("sciana2"))
			ci.draw_rect(Rect2(0, hy - 14, W, 14), _c("sciana2"))
			if cfg.get("tyl", []).size() == 1:
				_podloga(ci, hy, 0.0)
		else:
			ci.draw_rect(Rect2(0, 0, W, hy * 0.55), _c("niebo"))
			ci.draw_rect(Rect2(0, hy * 0.55, W, hy * 0.45 + 2), _c("niebo2"))
	elif p < 0.3:
		# daleki plan: wzgórza / las
		var x := -fposmod(off, 320.0) - 320.0
		var i := int(floor(off / 320.0))
		while x < W + 320.0:
			var hh := 60.0 + float((i * 37) % 50)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x, hy), Vector2(x + 160, hy - hh), Vector2(x + 320, hy)]), _c("daleko"))
			x += 320.0
			i += 1
	elif p < 1.0:
		# plan środkowy: domy / filary
		var x := -fposmod(off, 300.0) - 300.0
		var i := int(floor(off / 300.0))
		while x < W + 300.0:
			var hh := 110.0 + float((i * 53) % 60)
			if wnetrze:
				ci.draw_rect(Rect2(x + 110, 0, 46, hy), _c("sciana2"))
				ci.draw_rect(Rect2(x + 124, hy * 0.35, 18, 26), _c("akcent"))
			else:
				ci.draw_rect(Rect2(x + 40, hy - hh, 190, hh), _c("domy"))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 24, hy - hh), Vector2(x + 135, hy - hh - 70), Vector2(x + 246, hy - hh)]), _c("dach"))
				ci.draw_rect(Rect2(x + 70, hy - hh + 34, 30, 30), _c("akcent"))
				ci.draw_rect(Rect2(x + 150, hy - 62, 36, 62), _c("daleko"))
			x += 300.0
			i += 1
	elif p == 1.0:
		_podloga(ci, hy, off)
	else:
		# pierwszy plan: kępy / kamienie na dole ekranu
		var x := -fposmod(off, 260.0) - 260.0
		while x < W + 260.0:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x, H), Vector2(x + 30, H - 46), Vector2(x + 60, H - 20), Vector2(x + 90, H - 58), Vector2(x + 130, H)]),
				_c("daleko") if not wnetrze else _c("sciana"))
			x += 260.0

func _podloga(ci: CanvasItem, hy: float, off: float) -> void:
	var a := "podloga" if cfg.get("placeholder", {}).has("podloga") else "ziemia"
	ci.draw_rect(Rect2(0, hy, W, H - hy), _c(a))
	var x := -fposmod(off, 128.0) - 128.0
	while x < W + 128.0:
		ci.draw_rect(Rect2(x, hy, 6, H - hy), _c(a + "2"))
		ci.draw_rect(Rect2(x + 60, hy + 40 + fposmod(x + off, 97.0), 44, 8), _c(a + "2"))
		x += 128.0
	ci.draw_rect(Rect2(0, hy, W, 6), _c(a + "2"))
