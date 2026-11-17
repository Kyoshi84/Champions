class_name KKarta
extends RefCounted
## Klocki karty postaci wzorowanej na papierowej karcie WFRP: sekcje z postrzępionym nagłówkiem, pola formularza
## z linią do wpisywania, tabela cech z ramkami komórek. Kolory - te same co w całych Koszarach (Gk).

const LINIA := Color(0.42, 0.31, 0.14, 0.75)

## Sekcja karty: [panel, zawartość]. Nagłówek to szkarłatny pas z poszarpanymi końcami, jak na papierowej karcie.
static func sekcja(tytul: String, odstep: int = 4) -> Array:
	var p := PanelContainer.new()
	var st := Gk.sb(Color(Gk.PANEL.r, Gk.PANEL.g, Gk.PANEL.b, 0.94), Gk.ZLOTO_C, 1, 0.0, 2)
	st.content_margin_bottom = 8
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 5
	p.add_theme_stylebox_override("panel", st)
	var v := Gk.vb(0)
	p.add_child(v)
	v.add_child(naglowek(tytul))
	var m := MarginContainer.new()
	for k in ["left", "right"]:
		m.add_theme_constant_override("margin_" + k, 10)
	m.add_theme_constant_override("margin_top", 4)
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(m)
	var tresc := Gk.vb(odstep)
	m.add_child(tresc)
	return [p, tresc]

static func naglowek(tytul: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 30)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var napis := tytul.to_upper()
	c.draw.connect(func():
		var w := c.size.x
		var h := c.size.y
		if w < 60.0:
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(napis)
		# pas z poszarpanymi krawędziami: prostokąt + nieregularne ząbki (same trójkąty - zawsze poprawne wielokąty)
		var kol := Color(0.40, 0.05, 0.04)
		c.draw_rect(Rect2(7, 4, w - 14, h - 8), kol)
		var x := 7.0
		while x < w - 9.0:
			var d := rng.randf_range(8.0, 18.0)
			var x2 := minf(x + d, w - 7.0)
			c.draw_colored_polygon(PackedVector2Array([Vector2(x, 4), Vector2((x + x2) * 0.5, 4.0 - rng.randf_range(1.0, 3.5)), Vector2(x2, 4)]), kol)
			c.draw_colored_polygon(PackedVector2Array([Vector2(x, h - 4), Vector2(x2, h - 4), Vector2((x + x2) * 0.5, h - 4.0 + rng.randf_range(1.0, 3.5))]), kol)
			x = x2
		for i in 3:          # zęby na końcach
			var y0 := 4.0 + (h - 8.0) * float(i) / 3.0
			var y1 := 4.0 + (h - 8.0) * float(i + 1) / 3.0
			c.draw_colored_polygon(PackedVector2Array([Vector2(7, y0), Vector2(7, y1), Vector2(rng.randf_range(0.0, 3.0), (y0 + y1) * 0.5)]), kol)
			c.draw_colored_polygon(PackedVector2Array([Vector2(w - 7, y0), Vector2(w - rng.randf_range(0.0, 3.0), (y0 + y1) * 0.5), Vector2(w - 7, y1)]), kol)
		c.draw_line(Vector2(7, 4), Vector2(w - 7, 4), Color(0.70, 0.15, 0.10), 1.0)
		c.draw_line(Vector2(8, h - 1), Vector2(w - 8, h - 1), Color(0, 0, 0, 0.6), 1.0)
		var f := Gk.f_tytul()
		var fs := 19
		var sz := f.get_string_size(napis, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var poz := Vector2((w - sz) * 0.5, h * 0.5 + fs * 0.34)
		c.draw_string_outline(f, poz, napis, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.05, 0.01, 0.01))
		c.draw_string(f, poz, napis, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Gk.ZLOTO_J)
		# romby po bokach napisu
		for s in [-1.0, 1.0]:
			var r := Vector2(w * 0.5 + s * (sz * 0.5 + 14.0), h * 0.5)
			c.draw_colored_polygon(PackedVector2Array([r + Vector2(0, -4), r + Vector2(4, 0), r + Vector2(0, 4), r + Vector2(-4, 0)]), Gk.ZLOTO))
	return c

## Pole formularza: „ETYKIETA:” i wartość na linii, jak rubryka do wpisania.
static func pole(etykieta: String, wartosc: String, kolor: Color = Gk.TEKST, rozmiar: int = 16) -> Control:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0)
	st.border_color = LINIA
	st.border_width_bottom = 1
	st.content_margin_top = 1
	st.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := Gk.hb(6)
	p.add_child(h)
	var e := Gk.gruby(etykieta.to_upper() + ":", 12, Gk.PRZYG)
	e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(e)
	var w := Gk.tekst(wartosc, rozmiar, kolor, false)
	w.clip_text = true
	w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	w.tooltip_text = wartosc
	w.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(w)
	return p

## Dwa pola obok siebie (jak „Wiek / Płeć” na karcie).
static func dwa_pola(a: Control, b: Control) -> HBoxContainer:
	var h := Gk.hb(14)
	h.add_child(a)
	h.add_child(b)
	return h

## Komórka tabeli z ramką.
static func komorka(t: String, kolor: Color = Gk.TEKST, rozmiar: int = 15, gruba: bool = false, tlo: Color = Color(0, 0, 0, 0.35), podpowiedz: String = "") -> Control:
	var p := PanelContainer.new()
	var st := Gk.sb(tlo, LINIA, 1, 0.0, 0)
	st.content_margin_left = 3
	st.content_margin_right = 3
	st.content_margin_top = 1
	st.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := Gk.gruby(t, rozmiar, kolor) if gruba else Gk.tekst(t, rozmiar, kolor, false)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	if podpowiedz != "":
		p.tooltip_text = podpowiedz
	return p

## Tabela profilu: kolumny = cechy, wiersze = Początkowa / Rozwinięcie / Obecna.
## kolumny: [[skrót, opis, wartość_start, wartość_obecna, format, wyzej_lepiej]]
static func tabela_profilu(tytul: String, kolumny: Array) -> GridContainer:
	var g := GridContainer.new()
	g.columns = kolumny.size() + 1
	g.add_theme_constant_override("h_separation", 0)
	g.add_theme_constant_override("v_separation", 0)
	var szer_et := 92.0
	var naglowek_k := komorka(tytul.to_upper(), Gk.ZLOTO, 12, true, Color(0.30, 0.04, 0.03, 0.9))
	naglowek_k.custom_minimum_size = Vector2(szer_et, 0)
	naglowek_k.size_flags_horizontal = Control.SIZE_FILL
	g.add_child(naglowek_k)
	for k in kolumny:
		g.add_child(komorka(str(k[0]), Gk.ZLOTO_J, 14, true, Color(0.30, 0.04, 0.03, 0.9), str(k[1])))
	for wiersz in ["Początkowa", "Rozwinięcie", "Obecna"]:
		var e := komorka(wiersz, Gk.PRZYG, 13, false, Color(0, 0, 0, 0.5))
		e.custom_minimum_size = Vector2(szer_et, 0)
		e.size_flags_horizontal = Control.SIZE_FILL
		g.add_child(e)
		for k in kolumny:
			var start := float(k[2])
			var obecna := float(k[3])
			var fmt := str(k[4])
			match wiersz:
				"Początkowa":
					g.add_child(komorka(fmt % start, Gk.TEKST, 15))
				"Rozwinięcie":
					var d := obecna - start
					var zero := absf(d) < 0.05
					var lepiej := (d > 0.0) == bool(k[5])
					g.add_child(komorka("" if zero else (("+" if d > 0.0 else "") + fmt % d), Gk.ZIELEN if lepiej else Gk.SZKARLAT_J, 14))
				_:
					g.add_child(komorka(fmt % obecna, Gk.ZLOTO_J, 16, true, Color(0.12, 0.07, 0.04, 0.8)))
	return g
