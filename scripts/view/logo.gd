class_name LogoCC
extends Control
## Logo „Carroburg Champions”: ciężkie szeryfowe kapitaliki ze złotym, chromowanym wypełnieniem i czarno-szkarłatnym
## konturem; skrajne litery powiększone i ozdobne, napis lekko wygięty w łuk, „CHAMPIONS” na szkarłatnej wstędze.
## Wypełnienie liczy shader: kolor wierzchołka niesie wysokość litery i jej linię bazową, więc gradient pasuje do każdej litery.

const SHADER := """shader_type canvas_item;
varying vec4 vc;
varying float ly;
void vertex() {
	vc = COLOR;
	ly = VERTEX.y;
}
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (vc.r > 0.995 && vc.g < 0.99) {
		float wys = vc.g * 256.0;
		float baza = vc.b * 512.0;
		float t = clamp((baza - ly) / max(wys * 0.70, 1.0), 0.0, 1.0);
		vec3 dol = mix(vec3(0.97, 0.76, 0.32), vec3(0.50, 0.25, 0.07), smoothstep(0.12, 0.47, t));
		vec3 gora = mix(vec3(1.0, 0.86, 0.46), vec3(1.0, 0.98, 0.88), smoothstep(0.52, 0.9, t));
		vec3 g = t < 0.485 ? dol : gora;
		COLOR = vec4(g, tex.a * vc.a);
	} else {
		COLOR = vc * tex;
	}
}
"""
static var _shader: Shader = null
static var _f_glowna: Font = null
static var _f_ozdobna: Font = null

var napis := "CARROBURG"
var podtytul := "CHAMPIONS"

static func nowe(wysokosc: float = 120.0) -> LogoCC:
	var l := LogoCC.new()
	l.custom_minimum_size = Vector2(wysokosc * 3.6, wysokosc)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return l

func _ready() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	material = m

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

static func f_glowna() -> Font:
	if _f_glowna == null:
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/fonts/Cinzel.ttf")
		fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 900}
		_f_glowna = fv
	return _f_glowna

static func f_ozdobna() -> Font:
	if _f_ozdobna == null:
		_f_ozdobna = load("res://assets/fonts/CinzelDecorative-Black.ttf")
	return _f_ozdobna

func _znacznik(rozmiar: float, baza: float) -> Color:
	return Color(1.0, clampf(rozmiar / 256.0, 0.0, 0.985), clampf(baza / 512.0, 0.0, 1.0), 1.0)

## Rysuje napis litera po literze. skrajne > 1 powiększa pierwszą i ostatnią literę; luk = ile px środek jest wyżej.
func _napis(t: String, srodek_x: float, baza: float, rozmiar: float, skrajne: float, luk: float, kontur: float) -> void:
	var znaki: Array = []
	var szer := 0.0
	var odstep := rozmiar * 0.03
	for i in t.length():
		var skr := (i == 0 or i == t.length() - 1) and skrajne > 1.0
		var f: Font = f_ozdobna() if skr else f_glowna()
		var r: float = rozmiar * (skrajne if skr else 1.0)
		var w: float = f.get_char_size(t.unicode_at(i), int(r)).x
		znaki.append([t[i], f, r, w])
		szer += w + odstep
	szer -= odstep
	var x := srodek_x - szer * 0.5
	var poz: Array = []
	for z in znaki:
		var u: float = ((x + float(z[3]) * 0.5) - srodek_x) / maxf(szer * 0.5, 1.0)        # -1..1
		poz.append(Vector2(x, baza - luk * (1.0 - u * u) + (rozmiar * (skrajne - 1.0) * 0.12 if z[2] > rozmiar else 0.0)))
		x += z[3] + odstep
	# cień, czarny kontur, szkarłatny kontur, złote wypełnienie, cienki odblask
	for i in znaki.size():
		var z: Array = znaki[i]
		draw_char_outline(z[1], poz[i] + Vector2(4, 6), z[0], int(z[2]), int(kontur * 1.6), Color(0, 0, 0, 0.55))
	for i in znaki.size():
		var z: Array = znaki[i]
		draw_char_outline(z[1], poz[i], z[0], int(z[2]), int(kontur), Color(0.02, 0.01, 0.01))
	for i in znaki.size():
		var z: Array = znaki[i]
		draw_char_outline(z[1], poz[i], z[0], int(z[2]), int(kontur * 0.5), Color(0.62, 0.08, 0.06))
	for i in znaki.size():
		var z: Array = znaki[i]
		draw_char(z[1], poz[i], z[0], int(z[2]), _znacznik(z[2], poz[i].y))

func _draw() -> void:
	var w := size.x
	var h := size.y
	var r1 := minf(h * 0.50, w / 6.6)
	var baza1 := h * 0.08 + r1 * 1.02
	# wstęga pod „CHAMPIONS”
	var r2 := r1 * 0.42
	var wy := baza1 + r2 * 0.35
	var wh := r2 * 1.45
	var ww := minf(w * 0.62, r2 * 9.6)
	var cx := w * 0.5
	var l := cx - ww * 0.5
	var p := cx + ww * 0.5
	var ogon := wh * 0.9
	var szkarlat := Color(0.52, 0.07, 0.06)
	var ciemny := Color(0.30, 0.03, 0.03)
	# rozwidlone końce wstęgi (ciemniejsze, za wstęgą)
	for s in [-1.0, 1.0]:
		var bx: float = l if s < 0.0 else p
		var pts := PackedVector2Array([
			Vector2(bx - s * wh * 0.2, wy + wh * 0.22), Vector2(bx + s * ogon, wy + wh * 0.22),
			Vector2(bx + s * ogon * 0.62, wy + wh * 0.72), Vector2(bx + s * ogon, wy + wh * 1.22),
			Vector2(bx - s * wh * 0.2, wy + wh * 1.22)])
		draw_colored_polygon(pts, ciemny)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.42, 0.31, 0.14), 2.0)
	var wst := PackedVector2Array([Vector2(l, wy), Vector2(p, wy), Vector2(p, wy + wh), Vector2(l, wy + wh)])
	draw_colored_polygon(wst, szkarlat)
	draw_line(Vector2(l, wy + 3), Vector2(p, wy + 3), Color(0.83, 0.66, 0.32), 2.0)
	draw_line(Vector2(l, wy + wh - 3), Vector2(p, wy + wh - 3), Color(0.83, 0.66, 0.32), 2.0)
	draw_rect(Rect2(l, wy, ww, wh), Color(0.02, 0.01, 0.01), false, 2.0)
	# ćwieki na wstędze
	for s in [-1.0, 1.0]:
		var c := Vector2(cx + s * (ww * 0.5 - wh * 0.42), wy + wh * 0.5)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0)]), Color(0.99, 0.87, 0.56))
	_napis(podtytul, cx, wy + wh * 0.5 + r2 * 0.36, r2, 1.0, 0.0, maxf(5.0, r2 * 0.3))
	_napis(napis, cx, baza1, r1, 1.32, r1 * 0.12, maxf(8.0, r1 * 0.24))
