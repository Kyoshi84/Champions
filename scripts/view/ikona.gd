class_name Ikona
extends Control
## Proste ikony rysowane kodem (bez plików graficznych): jedna barwa, współrzędne w kwadracie 0..1.

var nazwa: String = ""
var kolor: Color = Color.WHITE

static func nowa(n: String, rozmiar: float = 28.0, k: Color = Color(0.83, 0.66, 0.32)) -> Ikona:
	var i := Ikona.new()
	i.nazwa = n
	i.kolor = k
	i.custom_minimum_size = Vector2(rozmiar, rozmiar)
	i.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	i.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i

func _p(x: float, y: float) -> Vector2:
	var s := minf(size.x, size.y)
	return Vector2((size.x - s) * 0.5 + x * s, (size.y - s) * 0.5 + y * s)

func _w(pts: Array, k: Color = kolor) -> void:
	var a := PackedVector2Array()
	for i in range(0, pts.size(), 2):
		a.append(_p(pts[i], pts[i + 1]))
	draw_colored_polygon(a, k)

func _l(pts: Array, grubosc: float = 0.08, k: Color = kolor) -> void:
	var a := PackedVector2Array()
	for i in range(0, pts.size(), 2):
		a.append(_p(pts[i], pts[i + 1]))
	draw_polyline(a, k, maxf(1.5, grubosc * minf(size.x, size.y)), true)

func _k(x: float, y: float, r: float, k: Color = kolor) -> void:
	draw_circle(_p(x, y), r * minf(size.x, size.y), k)

func _miecz(x0: float, y0: float, x1: float, y1: float) -> void:
	_l([x0, y0, x1, y1], 0.09)
	var d := Vector2(x1 - x0, y1 - y0).normalized()
	var n := Vector2(-d.y, d.x)
	var g := Vector2(x0, y0) + d * 0.22
	_l([g.x - n.x * 0.13, g.y - n.y * 0.13, g.x + n.x * 0.13, g.y + n.y * 0.13], 0.08)

func _draw() -> void:
	var tlo := Color(0.06, 0.035, 0.03)
	match nazwa:
		"miecze":
			_miecz(0.14, 0.86, 0.86, 0.12)
			_miecz(0.86, 0.86, 0.14, 0.12)
		"bron":
			_miecz(0.2, 0.84, 0.82, 0.14)
		"formacja":
			for r in 3:
				for c in 2:
					_k(0.32 + c * 0.36, 0.2 + r * 0.3, 0.11)
		"zwoj":
			_w([0.2, 0.14, 0.8, 0.14, 0.8, 0.86, 0.2, 0.86])
			_k(0.2, 0.2, 0.09)
			_k(0.8, 0.8, 0.09)
			for i in 3:
				_l([0.32, 0.34 + i * 0.16, 0.68, 0.34 + i * 0.16], 0.05, tlo)
		"kufel":
			_w([0.18, 0.28, 0.64, 0.28, 0.64, 0.88, 0.18, 0.88])
			_l([0.64, 0.4, 0.84, 0.44, 0.84, 0.7, 0.64, 0.74], 0.08)
			_k(0.26, 0.24, 0.1)
			_k(0.42, 0.2, 0.12)
			_k(0.57, 0.25, 0.09)
			_l([0.3, 0.44, 0.3, 0.78], 0.05, tlo)
			_l([0.5, 0.44, 0.5, 0.78], 0.05, tlo)
		"skrzynia":
			_w([0.1, 0.42, 0.9, 0.42, 0.9, 0.86, 0.1, 0.86])
			_w([0.1, 0.38, 0.2, 0.18, 0.8, 0.18, 0.9, 0.38])
			_w([0.44, 0.4, 0.56, 0.4, 0.56, 0.6, 0.44, 0.6], tlo)
		"klodka":
			_w([0.2, 0.46, 0.8, 0.46, 0.8, 0.9, 0.2, 0.9])
			draw_arc(_p(0.5, 0.44), 0.2 * minf(size.x, size.y), PI, TAU, 16, kolor, maxf(2.0, 0.09 * minf(size.x, size.y)), true)
			_k(0.5, 0.64, 0.07, tlo)
			_l([0.5, 0.64, 0.5, 0.78], 0.06, tlo)
		"puchar":
			_w([0.26, 0.12, 0.74, 0.12, 0.66, 0.5, 0.56, 0.58, 0.56, 0.74, 0.7, 0.8, 0.7, 0.88, 0.3, 0.88, 0.3, 0.8, 0.44, 0.74, 0.44, 0.58, 0.34, 0.5])
			_l([0.26, 0.2, 0.12, 0.22, 0.14, 0.38, 0.3, 0.42], 0.06)
			_l([0.74, 0.2, 0.88, 0.22, 0.86, 0.38, 0.7, 0.42], 0.06)
		"korona":
			_k(0.5, 0.5, 0.42)
			_k(0.5, 0.5, 0.31, kolor.darkened(0.35))
			_w([0.28, 0.62, 0.26, 0.38, 0.38, 0.5, 0.5, 0.32, 0.62, 0.5, 0.74, 0.38, 0.72, 0.62])
		"klejnot":
			_w([0.5, 0.92, 0.1, 0.4, 0.3, 0.12, 0.7, 0.12, 0.9, 0.4])
			_l([0.1, 0.4, 0.9, 0.4], 0.04, tlo)
			_l([0.3, 0.12, 0.42, 0.4, 0.5, 0.92, 0.58, 0.4, 0.7, 0.12], 0.04, tlo)
		"krzyz":
			_w([0.4, 0.1, 0.6, 0.1, 0.6, 0.4, 0.9, 0.4, 0.9, 0.6, 0.6, 0.6, 0.6, 0.9, 0.4, 0.9, 0.4, 0.6, 0.1, 0.6, 0.1, 0.4, 0.4, 0.4])
		"czaszka":
			_k(0.5, 0.42, 0.34)
			_w([0.32, 0.6, 0.68, 0.6, 0.64, 0.9, 0.36, 0.9])
			_k(0.37, 0.44, 0.09, tlo)
			_k(0.63, 0.44, 0.09, tlo)
			_l([0.44, 0.78, 0.44, 0.9], 0.04, tlo)
			_l([0.56, 0.78, 0.56, 0.9], 0.04, tlo)
		"wstecz":
			_w([0.08, 0.5, 0.46, 0.14, 0.46, 0.38, 0.92, 0.38, 0.92, 0.62, 0.46, 0.62, 0.46, 0.86])
		"dalej":
			_w([0.92, 0.5, 0.54, 0.14, 0.54, 0.38, 0.08, 0.38, 0.08, 0.62, 0.54, 0.62, 0.54, 0.86])
		"awans":
			_w([0.5, 0.06, 0.88, 0.46, 0.64, 0.46, 0.64, 0.74, 0.36, 0.74, 0.36, 0.46, 0.12, 0.46])
			_w([0.36, 0.82, 0.64, 0.82, 0.64, 0.94, 0.36, 0.94])
		"ksiega":
			_w([0.08, 0.2, 0.46, 0.26, 0.46, 0.86, 0.08, 0.8])
			_w([0.92, 0.2, 0.54, 0.26, 0.54, 0.86, 0.92, 0.8])
		"sakwa":
			_w([0.34, 0.3, 0.66, 0.3, 0.88, 0.7, 0.76, 0.9, 0.24, 0.9, 0.12, 0.7])
			_w([0.36, 0.1, 0.5, 0.2, 0.64, 0.1, 0.6, 0.26, 0.4, 0.26])
		"dodatek", "tarcza":
			_w([0.14, 0.12, 0.86, 0.12, 0.86, 0.5, 0.5, 0.94, 0.14, 0.5])
			_l([0.5, 0.2, 0.5, 0.8], 0.05, tlo)
		"helm":
			_w([0.16, 0.9, 0.16, 0.44, 0.3, 0.2, 0.5, 0.1, 0.7, 0.2, 0.84, 0.44, 0.84, 0.9, 0.6, 0.9, 0.6, 0.58, 0.4, 0.58, 0.4, 0.9])
			_l([0.2, 0.5, 0.8, 0.5], 0.05, tlo)
		"zbroja":
			_w([0.3, 0.1, 0.42, 0.2, 0.58, 0.2, 0.7, 0.1, 0.94, 0.28, 0.82, 0.46, 0.74, 0.4, 0.74, 0.9, 0.26, 0.9, 0.26, 0.4, 0.18, 0.46, 0.06, 0.28])
			_l([0.5, 0.26, 0.5, 0.84], 0.04, tlo)
		"rekawice":
			_w([0.26, 0.92, 0.26, 0.42, 0.2, 0.2, 0.32, 0.18, 0.36, 0.34, 0.38, 0.1, 0.5, 0.1, 0.52, 0.32, 0.56, 0.12, 0.68, 0.14, 0.66, 0.36, 0.74, 0.22, 0.84, 0.28, 0.74, 0.56, 0.74, 0.92])
			_l([0.26, 0.74, 0.74, 0.74], 0.05, tlo)
		"amulet":
			draw_arc(_p(0.5, 0.36), 0.3 * minf(size.x, size.y), 0.25, PI - 0.25, 18, kolor, maxf(1.5, 0.05 * minf(size.x, size.y)), true)
			_k(0.5, 0.68, 0.2)
			_k(0.5, 0.68, 0.09, tlo)
		"zegar":
			_k(0.5, 0.5, 0.42)
			_k(0.5, 0.5, 0.33, tlo)
			_l([0.5, 0.26, 0.5, 0.5, 0.68, 0.6], 0.07)
		"ptaszek":
			_l([0.14, 0.52, 0.4, 0.78, 0.86, 0.2], 0.14)
		"gwiazda":
			var a := PackedVector2Array()
			for i in 10:
				var r := 0.44 if i % 2 == 0 else 0.19
				var kat := -PI * 0.5 + float(i) * PI / 5.0
				a.append(_p(0.5 + cos(kat) * r, 0.52 + sin(kat) * r))
			draw_colored_polygon(a, kolor)
		"menu":
			for i in 3:
				_l([0.14, 0.26 + i * 0.24, 0.86, 0.26 + i * 0.24], 0.1)
		_:
			_k(0.5, 0.5, 0.3)
