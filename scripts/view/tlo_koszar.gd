class_name TloKoszar
extends Control
## Tło ekranów Koszar: obraz z pliku (wypełnia ekran, przyciemniony) albo rysowana kodem nocna sylwetka Carroburga.

var tex: Texture2D = null
var przyciemnienie: float = 0.62

static func dla(ekran: String) -> TloKoszar:
	var t := TloKoszar.new()
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var kandydaci: Array = ["res://assets/ui/koszary/tlo.png"]
	if ekran in ["tawerna", "najemnik"]:
		kandydaci = ["res://assets/ui/koszary/tawerna.png", "res://assets/levels/karczma/tlo.png"]
		t.przyciemnienie = 0.72
	elif ekran in ["misje", "misja"]:
		kandydaci = ["res://assets/ui/koszary/misje.png", "res://assets/levels/hufduhof/wies.png"]
		t.przyciemnienie = 0.7
	for k in kandydaci:
		if ResourceLoader.exists(k):
			t.tex = load(k)
			break
	return t

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	# niebo: od czerni u góry do ciemnego szkarłatu nad horyzontem
	var pasy := 24
	for i in pasy:
		var f := float(i) / float(pasy - 1)
		draw_rect(Rect2(0, h * f * 0.72, w, h * 0.72 / pasy + 1.0), Color(0.03, 0.02, 0.025).lerp(Color(0.30, 0.06, 0.05), f * f))
	draw_rect(Rect2(0, h * 0.72, w, h * 0.28), Color(0.035, 0.02, 0.02))
	if tex != null:
		var ts := tex.get_size()
		var sk := maxf(w / ts.x, h / ts.y)
		var wym := ts * sk
		draw_texture_rect(tex, Rect2((Vector2(w, h) - wym) * 0.5, wym), false)
		draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.012, 0.012, przyciemnienie))
	else:
		_sylwetka(w, h)
	# winieta
	for i in 8:
		var a := 0.07 * float(8 - i) / 8.0
		var g := float(i) * 14.0
		draw_rect(Rect2(0, g, w, 14), Color(0, 0, 0, a))
		draw_rect(Rect2(0, h - g - 14, w, 14), Color(0, 0, 0, a))

func _sylwetka(w: float, h: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1984
	var hor := h * 0.72
	# dalsze miasto
	var x := -20.0
	var dalekie := Color(0.13, 0.045, 0.045)
	while x < w + 40.0:
		var bw := rng.randf_range(26, 70)
		var bh := rng.randf_range(40, 130)
		draw_rect(Rect2(x, hor - bh, bw, bh + 4), dalekie)
		if rng.randf() < 0.45:       # spiczasty dach / wieża
			draw_colored_polygon(PackedVector2Array([Vector2(x, hor - bh), Vector2(x + bw * 0.5, hor - bh - rng.randf_range(18, 60)), Vector2(x + bw, hor - bh)]), dalekie)
		x += bw - 4.0
	# twierdza na pierwszym planie (po prawej) i mur
	var blizsze := Color(0.06, 0.028, 0.03)
	var okno := Color(0.95, 0.62, 0.22, 0.85)
	x = -10.0
	while x < w + 40.0:
		var prawa := x / maxf(w, 1.0)
		var bw2 := rng.randf_range(44, 96)
		var bh2 := rng.randf_range(50, 110) + 190.0 * pow(prawa, 2.2)
		var gora := hor - bh2
		draw_rect(Rect2(x, gora, bw2, bh2 + 6), blizsze)
		var los := rng.randf()
		if los < 0.4:        # blanki
			var zx := x
			while zx < x + bw2 - 6.0:
				draw_rect(Rect2(zx, gora - 9, 8, 10), blizsze)
				zx += 15.0
		elif los < 0.8:      # iglica
			draw_colored_polygon(PackedVector2Array([Vector2(x - 3, gora), Vector2(x + bw2 * 0.5, gora - bw2 * rng.randf_range(0.7, 1.5)), Vector2(x + bw2 + 3, gora)]), blizsze)
		var wy := gora + 16.0
		while wy < hor - 14.0:
			var wx := x + 9.0
			while wx < x + bw2 - 10.0:
				if rng.randf() < 0.16:
					draw_rect(Rect2(wx, wy, 4, 7), okno)
				wx += 13.0
			wy += 22.0
		x += bw2 - 2.0
	# chorągwie Gwardii na murach
	for i in 4:
		var cx := w * (0.58 + 0.11 * i) + rng.randf_range(-12, 12)
		var cy := hor - 60.0 - 190.0 * pow(cx / maxf(w, 1.0), 2.2) - 50.0
		draw_line(Vector2(cx, cy), Vector2(cx, cy + 60), Color(0.3, 0.24, 0.16), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(cx + 1, cy + 2), Vector2(cx + 30, cy + 6), Vector2(cx + 24, cy + 17), Vector2(cx + 31, cy + 28), Vector2(cx + 1, cy + 26)]), Color(0.55, 0.07, 0.06))
	draw_rect(Rect2(0, hor, w, h - hor), Color(0.03, 0.016, 0.016))
