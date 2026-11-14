class_name Gk
extends RefCounted
## Zestaw wyglądu Koszar Szkarłatnej Gwardii: czerwień i czerń, złote ramy z ornamentem, czcionki Almendra + Alegreya.
## Wszystkie ekrany Koszar budują się wyłącznie z tych klocków - stąd spójność.

const CZERN := Color(0.045, 0.028, 0.028)
const PANEL := Color(0.085, 0.052, 0.048)
const PANEL_J := Color(0.14, 0.085, 0.075)
const SZKARLAT := Color(0.50, 0.07, 0.06)
const SZKARLAT_J := Color(0.86, 0.20, 0.15)
const ZLOTO := Color(0.83, 0.66, 0.32)
const ZLOTO_J := Color(0.99, 0.87, 0.56)
const ZLOTO_C := Color(0.42, 0.31, 0.14)
const TEKST := Color(0.94, 0.89, 0.78)
const PRZYG := Color(0.66, 0.60, 0.52)
const ZIELEN := Color(0.50, 0.80, 0.42)
const PERGAMIN := Color(0.80, 0.68, 0.47)
const ATRAMENT := Color(0.16, 0.09, 0.05)
const HERB := "res://assets/ui/crest/crest_menu.png"       # oficjalny herb Szkarłatnej Gwardii z Carroburga
const RZADKOSC := {"common": Color(0.78, 0.74, 0.66), "uncommon": Color(0.45, 0.78, 0.38), "rare": Color(0.38, 0.62, 0.92),
	"epic": Color(0.72, 0.44, 0.90), "legendary": Color(0.94, 0.66, 0.22)}
const RZADKOSC_NAZWA := {"common": "pospolity", "uncommon": "niepospolity", "rare": "rzadki", "epic": "epicki", "legendary": "legendarny"}

static var _theme: Theme = null
static var _f_tytul: Font = null
static var _f_tekst: Font = null
static var _f_gruby: Font = null
static var _szary: Shader = null

# ---------------------------------------------------------------- czcionki i motyw
static func f_tytul() -> Font:
	if _f_tytul == null:
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/fonts/Almendra-Regular.ttf")
		var cechy := {}          # bez ligatur - "st" z długim s jest nieczytelne w nazwach
		for znacznik in ["liga", "clig", "dlig", "hlig", "calt"]:
			cechy[TextServerManager.get_primary_interface().name_to_tag(znacznik)] = 0
		fv.opentype_features = cechy
		_f_tytul = fv
	return _f_tytul

static func _alegreya(waga: int) -> Font:
	var fv := FontVariation.new()
	fv.base_font = load("res://assets/fonts/Alegreya.ttf")
	fv.variation_opentype = {"wght": waga}
	return fv

static func f_tekst() -> Font:
	if _f_tekst == null:
		_f_tekst = _alegreya(500)
	return _f_tekst

static func f_gruby() -> Font:
	if _f_gruby == null:
		_f_gruby = _alegreya(800)
	return _f_gruby

static func sb(bg: Color, ramka: Color, grubosc: int = 2, margines: float = 12.0, promien: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = ramka
	s.set_border_width_all(grubosc)
	s.set_corner_radius_all(promien)
	s.set_content_margin_all(margines)
	s.anti_aliasing = false
	return s

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = f_tekst()
	t.default_font_size = 18
	_styl_przyciskow(t, "Button", Color(0.13, 0.08, 0.07), ZLOTO_C, ZLOTO)
	t.set_color("font_color", "Button", TEKST)
	t.set_color("font_hover_color", "Button", ZLOTO_J)
	t.set_color("font_pressed_color", "Button", ZLOTO_J)
	t.set_color("font_focus_color", "Button", TEKST)
	t.set_color("font_disabled_color", "Button", Color(0.46, 0.42, 0.38))
	t.set_font("font", "Button", f_gruby())
	t.set_color("font_color", "Label", TEKST)
	t.set_stylebox("panel", "PanelContainer", styl_panelu())
	# cienkie paski przewijania
	var tor := sb(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0, 0.0, 3)
	tor.content_margin_left = 4
	tor.content_margin_right = 4
	var uchwyt := sb(ZLOTO_C, Color(0, 0, 0, 0), 0, 0.0, 3)
	for typ in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", typ, tor)
		t.set_stylebox("grabber", typ, uchwyt)
		t.set_stylebox("grabber_highlight", typ, sb(ZLOTO, Color(0, 0, 0, 0), 0, 0.0, 3))
		t.set_stylebox("grabber_pressed", typ, sb(ZLOTO_J, Color(0, 0, 0, 0), 0, 0.0, 3))
	_theme = t
	return t

static func _styl_przyciskow(t: Theme, typ: String, tlo: Color, ramka: Color, ramka_j: Color) -> void:
	var st := {
		"normal": sb(tlo, ramka, 2, 10.0),
		"hover": sb(tlo.lightened(0.08), ramka_j, 2, 10.0),
		"pressed": sb(tlo.darkened(0.25), ZLOTO_J, 2, 10.0),
		"focus": sb(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 10.0),
		"disabled": sb(Color(0.09, 0.075, 0.07, 0.85), Color(0.26, 0.22, 0.19), 2, 10.0)}
	for k in st:
		st[k].content_margin_left = 16
		st[k].content_margin_right = 16
		t.set_stylebox(k, typ, st[k])

static func styl_panelu(alpha: float = 0.93, margines: float = 16.0) -> StyleBoxFlat:
	var s := sb(Color(PANEL.r, PANEL.g, PANEL.b, alpha), ZLOTO_C, 2, margines, 2)
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 6
	return s

# ---------------------------------------------------------------- teksty
static func tytul(t: String, rozmiar: int = 28, kolor: Color = ZLOTO_J) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f_tytul())
	l.add_theme_font_size_override("font_size", rozmiar)
	l.add_theme_color_override("font_color", kolor)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.01))
	l.add_theme_constant_override("outline_size", 5)
	return l

static func tekst(t: String, rozmiar: int = 17, kolor: Color = TEKST, zawijaj: bool = true) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", rozmiar)
	l.add_theme_color_override("font_color", kolor)
	if zawijaj:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

static func gruby(t: String, rozmiar: int = 17, kolor: Color = TEKST) -> Label:
	var l := tekst(t, rozmiar, kolor, false)
	l.add_theme_font_override("font", f_gruby())
	return l

## Nagłówek sekcji: tytuł i złota linia z rombem.
static func naglowek(t: String, rozmiar: int = 22) -> Control:
	var h := hb(10)
	h.add_child(tytul(t, rozmiar, ZLOTO))
	var linia := Control.new()
	linia.custom_minimum_size = Vector2(40, 12)
	linia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linia.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linia.draw.connect(func():
		var y := linia.size.y * 0.5
		linia.draw_line(Vector2(10, y), Vector2(linia.size.x, y), ZLOTO_C, 1.0)
		linia.draw_colored_polygon(PackedVector2Array([Vector2(0, y), Vector2(5, y - 5), Vector2(10, y), Vector2(5, y + 5)]), ZLOTO))
	h.add_child(linia)
	return h

static func odznaka(t: String, kolor: Color = ZLOTO, tlo: Color = Color(0, 0, 0, 0.45)) -> PanelContainer:
	var p := PanelContainer.new()
	var s := sb(tlo, kolor, 1, 0.0, 2)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 1
	s.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", s)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(gruby(t, 14, kolor))
	return p

# ---------------------------------------------------------------- układ
static func vb(odstep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", odstep)
	return v

static func hb(odstep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", odstep)
	return h

static func rozpor(min_w: float = 0.0, min_h: float = 0.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(min_w, min_h)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func rozciagnij(c: Control, poziomo: bool = true, pionowo: bool = false, waga: float = 1.0) -> Control:
	if poziomo:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if pionowo:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.size_flags_stretch_ratio = waga
	return c

static func przewijany(zawartosc: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zawartosc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(zawartosc)
	return s

# ---------------------------------------------------------------- ramy
## Panel w złotej ramie z gotyckim ornamentem w narożnikach.
static func rama(margines: float = 16.0, alpha: float = 0.93) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", styl_panelu(alpha, margines))
	p.draw.connect(func(): _ornament(p, ZLOTO))
	return p

static func _ornament(c: Control, kolor: Color) -> void:
	var w := c.size.x
	var h := c.size.y
	if w < 60.0 or h < 40.0:
		return
	var ciemny := Color(kolor.r, kolor.g, kolor.b, 0.35)
	c.draw_rect(Rect2(5, 5, w - 10, h - 10), ciemny, false, 1.0)
	for n in [Vector2(0, 0), Vector2(w, 0), Vector2(0, h), Vector2(w, h)]:
		var kx := 1.0 if n.x == 0.0 else -1.0
		var ky := 1.0 if n.y == 0.0 else -1.0
		var p0: Vector2 = n + Vector2(kx * 5, ky * 5)
		# narożnik: romb i dwa ostrza wzdłuż krawędzi
		c.draw_colored_polygon(PackedVector2Array([p0 + Vector2(0, -6 * ky), p0 + Vector2(6 * kx, 0), p0 + Vector2(0, 6 * ky), p0 + Vector2(-6 * kx, 0)]), kolor)
		c.draw_colored_polygon(PackedVector2Array([p0 + Vector2(8 * kx, -2 * ky), p0 + Vector2(30 * kx, 0), p0 + Vector2(8 * kx, 2 * ky)]), kolor)
		c.draw_colored_polygon(PackedVector2Array([p0 + Vector2(-2 * kx, 8 * ky), p0 + Vector2(0, 30 * ky), p0 + Vector2(2 * kx, 8 * ky)]), kolor)
	# zwornik na środku górnej krawędzi
	var m := Vector2(w * 0.5, 1.0)
	c.draw_colored_polygon(PackedVector2Array([m + Vector2(-9, 0), m + Vector2(0, -5), m + Vector2(9, 0), m + Vector2(0, 7)]), kolor)

## Kartka pergaminu na opisy fabularne.
static func pergamin(t: String, rozmiar: int = 17) -> PanelContainer:
	var p := PanelContainer.new()
	var s := sb(PERGAMIN, Color(0.45, 0.33, 0.17), 2, 14.0, 2)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 4
	p.add_theme_stylebox_override("panel", s)
	var l := tekst(t, rozmiar, ATRAMENT)
	l.add_theme_font_override("font", _kursywa())
	p.add_child(l)
	return p

static var _f_kursywa: Font = null
static func _kursywa() -> Font:
	if _f_kursywa == null:
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/fonts/Alegreya.ttf")
		fv.variation_opentype = {"wght": 600}
		fv.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.12, 1), Vector2.ZERO)
		_f_kursywa = fv
	return _f_kursywa

# ---------------------------------------------------------------- przyciski
static func przycisk(t: String, cb: Callable, glowny: bool = false, min_w: float = 0.0, h: float = 48.0, ikona: String = "") -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(min_w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 18)
	if glowny:
		b.add_theme_stylebox_override("normal", sb(SZKARLAT, ZLOTO, 2, 10.0))
		b.add_theme_stylebox_override("hover", sb(SZKARLAT.lightened(0.12), ZLOTO_J, 2, 10.0))
		b.add_theme_stylebox_override("pressed", sb(SZKARLAT.darkened(0.3), ZLOTO_J, 2, 10.0))
		b.add_theme_color_override("font_color", ZLOTO_J)
	if ikona != "":
		var i := Ikona.nowa(ikona, minf(h - 18.0, 30.0), ZLOTO_J if glowny else ZLOTO)
		i.position = Vector2(12, (h - i.custom_minimum_size.y) * 0.5)
		b.add_child(i)
		for k in ["normal", "hover", "pressed", "disabled"]:
			var s: StyleBoxFlat = (b.get_theme_stylebox(k) if b.has_theme_stylebox_override(k) else theme().get_stylebox(k, "Button")).duplicate()
			s.content_margin_left = 22.0 + i.custom_minimum_size.x
			b.add_theme_stylebox_override(k, s)
	b.pressed.connect(func():
		Audio.play("ui_click")
		cb.call())
	return b

## Klikalna karta o dowolnej zawartości: [panel, przycisk]. Zawartość dodaje się do panelu PRZED przyciskiem
## (użyj Gk.do_karty), przycisk leży na wierzchu i rysuje podświetlenie.
static func karta(cb: Callable, wybrana: bool = false, margines: float = 12.0) -> Array:
	var p := PanelContainer.new()
	var s := sb(Color(PANEL_J.r, PANEL_J.g, PANEL_J.b, 0.95), ZLOTO_J if wybrana else ZLOTO_C, 3 if wybrana else 2, margines, 3)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 4
	if wybrana:
		s.bg_color = Color(0.24, 0.08, 0.06, 0.96)
	p.add_theme_stylebox_override("panel", s)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("disabled", sb(Color(0, 0, 0, 0.45), Color(0, 0, 0, 0), 0, 0.0))
	b.add_theme_stylebox_override("hover", sb(Color(1.0, 0.85, 0.5, 0.07), ZLOTO, 2, 0.0))
	b.add_theme_stylebox_override("pressed", sb(Color(0.9, 0.2, 0.1, 0.18), ZLOTO_J, 2, 0.0))
	b.pressed.connect(func():
		Audio.play("ui_click")
		cb.call())
	p.add_child(b)
	return [p, b]

## Wkłada zawartość do karty pod przycisk-nakładkę.
static func do_karty(k: Array, zawartosc: Control) -> void:
	var p: PanelContainer = k[0]
	p.add_child(zawartosc)
	p.move_child(zawartosc, 0)
	_bierny(zawartosc)

static func _bierny(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_bierny(c)

# ---------------------------------------------------------------- portret, herb, pasek zdrowia
static func tekstura(sciezka: String) -> Texture2D:
	if sciezka != "" and ResourceLoader.exists(sciezka):
		return load(sciezka)
	return null

## Oficjalny herb Gwardii na pergaminowym medalionie w złotej obręczy (rysunek herbu jest czarny, więc potrzebuje jasnego tła).
static func herb(rozmiar: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(rozmiar, rozmiar)
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := tekstura(HERB)
	c.draw.connect(func():
		var s := c.size * 0.5
		var r := minf(c.size.x, c.size.y) * 0.5
		c.draw_circle(s, r, Color(0.02, 0.01, 0.01))
		c.draw_circle(s, r - 1.0, ZLOTO)
		c.draw_circle(s, r - 3.5, SZKARLAT)
		c.draw_circle(s, r - 6.0, ZLOTO_C)
		c.draw_circle(s, r - 7.0, PERGAMIN.lightened(0.12))
		if tex != null:
			var ts := tex.get_size()
			var sk := (r - 8.0) * 1.8 / maxf(ts.x, ts.y)
			c.draw_texture_rect(tex, Rect2(s - ts * sk * 0.5 + Vector2(0, r * 0.03), ts * sk), false))
	return c

## Portret bohatera w złotej ramie. stan: "" | "ranny" (czerwony krzyżyk) | "polegly" (wyszarzony).
## cala = cała sylwetka (ekran szczegółów), inaczej kadr na twarz z danych bohatera.
static func portret(hero_id: String, rozmiar: Vector2, stan: String = "", cala: bool = false) -> Control:
	var def := Data.hero(hero_id)
	var tex := tekstura(str(def.get("portret", "")))
	var c := Control.new()
	c.custom_minimum_size = rozmiar
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.clip_contents = true
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var obraz := Control.new()
	obraz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	obraz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obraz.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if stan == "polegly":
		var m := ShaderMaterial.new()
		m.shader = _shader_szary()
		obraz.material = m
	var kadr: Array = def.get("portret_kadr", [])
	obraz.draw.connect(func():
		var r := Rect2(Vector2.ZERO, obraz.size)
		obraz.draw_rect(r, Color(0.16, 0.07, 0.06))
		obraz.draw_rect(Rect2(0, r.size.y * 0.55, r.size.x, r.size.y * 0.45), Color(0.09, 0.04, 0.04))
		if tex == null:
			return
		var ts := tex.get_size()
		if cala:
			var sk := minf((r.size.x - 12.0) / ts.x, (r.size.y - 12.0) / ts.y)
			var wym := ts * sk
			obraz.draw_texture_rect(tex, Rect2((r.size - wym) * 0.5 + Vector2(0, (r.size.y - wym.y) * 0.5 - 6.0), wym), false)
		else:
			var kx := float(kadr[0]) if kadr.size() >= 3 else 0.0
			var ky := float(kadr[1]) if kadr.size() >= 3 else 0.0
			var kw := (float(kadr[2]) if kadr.size() >= 3 else 1.0) * ts.x
			var kh := kw * r.size.y / maxf(r.size.x, 1.0)
			if kh > ts.y:
				kh = ts.y
				kw = kh * r.size.x / maxf(r.size.y, 1.0)
			var x0 := clampf(kx * ts.x + ((float(kadr[2]) if kadr.size() >= 3 else 1.0) * ts.x - kw) * 0.5, 0.0, ts.x - kw)
			obraz.draw_texture_rect_region(tex, r, Rect2(x0, ky * ts.y, kw, kh)))
	c.add_child(obraz)
	var ramka := Control.new()
	ramka.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ramka.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ramka.draw.connect(func():
		var r := Rect2(Vector2.ZERO, ramka.size)
		if stan == "polegly":
			ramka.draw_rect(r, Color(0, 0, 0, 0.45))
		ramka.draw_rect(r.grow(-1), Color(0.33, 0.33, 0.33) if stan == "polegly" else ZLOTO, false, 2.0)
		ramka.draw_rect(r.grow(-4), Color(0, 0, 0, 0.6), false, 1.0)
		if stan == "ranny":
			var k := clampf(r.size.x * 0.34, 16.0, 30.0)
			var s := Vector2(r.size.x - k * 0.5 - 4.0, k * 0.5 + 4.0)
			ramka.draw_circle(s, k * 0.5, Color(0.05, 0.02, 0.02, 0.9))
			ramka.draw_arc(s, k * 0.5, 0.0, TAU, 24, SZKARLAT_J, 1.5)
			ramka.draw_rect(Rect2(s.x - k * 0.11, s.y - k * 0.32, k * 0.22, k * 0.64), SZKARLAT_J)
			ramka.draw_rect(Rect2(s.x - k * 0.32, s.y - k * 0.11, k * 0.64, k * 0.22), SZKARLAT_J))
	c.add_child(ramka)
	return c

static func _shader_szary() -> Shader:
	if _szary == null:
		_szary = Shader.new()
		_szary.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV) * COLOR;\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114)) * 0.75;\n\tCOLOR = vec4(g, g, g, c.a);\n}\n"
	return _szary

static func stan_bohatera(id: String) -> String:
	if Game.polegly(id):
		return "polegly"
	return "ranny" if Game.ranny(id) else ""

## Pasek zdrowia z liczbami. Wartości czyta przy każdym rysowaniu, więc wystarczy queue_redraw().
static func pasek_hp(id: String, wysokosc: float = 18.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(90, wysokosc)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var r := Rect2(Vector2.ZERO, c.size)
		var martwy := Game.polegly(id)
		var ile := 0.0 if martwy else Game.hp_proc(id)
		c.draw_rect(r, Color(0.03, 0.02, 0.02))
		if ile > 0.0:
			c.draw_rect(Rect2(2, 2, (r.size.x - 4) * ile, r.size.y - 4), Color(0.66, 0.10, 0.08))
			c.draw_rect(Rect2(2, 2, (r.size.x - 4) * ile, (r.size.y - 4) * 0.4), Color(0.86, 0.22, 0.16))
		c.draw_rect(r, Color(0.3, 0.3, 0.3) if martwy else ZLOTO_C, false, 1.0)
		var t := "poległ" if martwy else "%d / %d" % [Game.hp_akt(id), Game.hp_max(id)]
		var fs := int(clampf(wysokosc - 4.0, 11.0, 15.0))
		var f := f_gruby()
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var poz := Vector2((r.size.x - w) * 0.5, r.size.y * 0.5 + fs * 0.34)
		c.draw_string_outline(f, poz, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.9))
		c.draw_string(f, poz, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, TEKST))
	return c

static func pasek_postepu(ile: float, kolor: Color = ZLOTO, wysokosc: float = 10.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(60, wysokosc)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var r := Rect2(Vector2.ZERO, c.size)
		c.draw_rect(r, Color(0.03, 0.02, 0.02))
		c.draw_rect(Rect2(1, 1, (r.size.x - 2) * clampf(ile, 0.0, 1.0), r.size.y - 2), kolor)
		c.draw_rect(r, ZLOTO_C, false, 1.0))
	return c

static func czas(sekundy: float) -> String:
	var s := ceili(maxf(sekundy, 0.0))
	return "%d:%02d" % [s / 60, s % 60]

## Ikona z wartością (korony, klejnoty...).
static func waluta(ikona: String, t: String, kolor: Color = ZLOTO_J, rozmiar: int = 20) -> HBoxContainer:
	var h := hb(6)
	h.add_child(Ikona.nowa(ikona, float(rozmiar) + 4.0, kolor))
	h.add_child(gruby(t, rozmiar, kolor))
	return h
