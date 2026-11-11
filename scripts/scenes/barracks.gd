class_name BarracksScene
extends Control
## Koszary - główny hub: bohaterowie, formacja (przeciąganie lub dotknięcia), rozwój, ekwipunek, wybór przygody.
## Cały ekran buduje się od nowa po każdej zmianie stanu (prosto i bez rozjazdów między danymi a widokiem).

var main: Node
var sel: String = ""                 # wybrany bohater
var adv_sel: String = ""
var diff_sel: String = "normal"
var komunikat: String = ""

const RZADKOSC := {"common": "#b8b0a0", "uncommon": "#6fbf5a", "rare": "#5a9be0", "epic": "#b56ae0", "legendary": "#e8a83a"}

func _ready() -> void:
	theme = UiKit.theme()
	UiKit.full_rect(self)
	Audio.play_track("koszary")
	if sel == "" and not Game.state["bohaterowie"].is_empty():
		sel = str(Game.w_formacji()[0]) if not Game.w_formacji().is_empty() else str(Game.state["bohaterowie"].keys()[0])
	for id in Data.adventure_ids():
		if Game.dostepna(id, "normal"):
			adv_sel = id
	_buduj()

func _buduj() -> void:
	for c in get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	UiKit.full_rect(bg)
	add_child(bg)
	_gora()
	_lista_bohaterow()
	_formacja()
	_przygody()
	_bohater()

func _panel(r: Rect2, tytul: String) -> VBoxContainer:
	var p := PanelContainer.new()
	p.position = r.position
	p.size = r.size
	p.custom_minimum_size = r.size
	add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	p.add_child(vb)
	if tytul != "":
		vb.add_child(UiKit.label(tytul, 20, UiKit.GOLD, false))
	return vb

func _maly(t: String, cb: Callable, w: float = 0.0, h: float = 40.0, fs: int = 17) -> Button:
	var b := UiKit.button(t, cb, w, h)
	b.add_theme_font_size_override("font_size", fs)
	b.clip_text = true
	return b

func _tekst(t: String, fs: int = 16, kol: Color = UiKit.TEXT) -> Label:
	var l := UiKit.label(t, fs, kol, false)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

# ---------------------------------------------------------------- pasek górny
func _gora() -> void:
	var t := UiKit.outlined(UiKit.label("Koszary Szkarłatnej Gwardii", 30, UiKit.RED, false))
	t.position = Vector2(16, 8)
	add_child(t)
	var w := UiKit.label("Korony: %d     Klejnoty: %d     Favor: +%d%% koron" % [int(Game.state["korony"]), int(Game.state["klejnoty"]),
		roundi(float(Game.state["favor"]) * 100.0)], 22, UiKit.GOLD, false)
	w.position = Vector2(500, 14)
	add_child(w)
	var m := _maly("Menu", func(): main.go("menu"), 110.0, 40.0)
	m.position = Vector2(1156, 8)
	add_child(m)

# ---------------------------------------------------------------- lista bohaterów
func _lista_bohaterow() -> void:
	var vb := _panel(Rect2(10, 56, 250, 404), "Bohaterowie")
	for id in Data.hero_ids():
		var def := Data.hero(id)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		vb.add_child(hb)
		hb.add_child(UiKit.icon(str(def.get("portret", "")), 52.0))
		var b: Button
		if Game.ma(id):
			var w_form := "" if Game.pole_bohatera(id) != -1 else "  (rezerwa)"
			b = _maly("%s\npoz. %d%s" % [str(def["imie"]), Game.poziom(id), w_form], func():
				sel = id
				komunikat = ""
				_buduj(), 164.0, 56.0, 16)
			if id == sel:
				b.add_theme_color_override("font_color", UiKit.GOLD)
			b.set_drag_forwarding(func(_p): return _ciagnij(id, b), Callable(), Callable())
		else:
			var o: Dictionary = def.get("odblokowanie", {})
			if str(o.get("typ", "")) == "sklep":
				b = _maly("%s\nkup: %d koron" % [str(def["imie"]), int(o.get("koszt", 0))], func():
					if Game.kup(id):
						Audio.play("coin")
						sel = id
					_buduj(), 164.0, 56.0, 16)
				b.disabled = not Game.moze_kupic(id)
			else:
				b = _maly("%s\n(po prologu)" % str(def["imie"]), func(): pass, 164.0, 56.0, 16)
				b.disabled = true
		hb.add_child(b)
	vb.add_child(_tekst("Przeciągnij bohatera na pole formacji albo wybierz go i dotknij pola.", 14, UiKit.DIM))

func _ciagnij(id: String, zrodlo: Control):
	var l := UiKit.label(str(Data.hero(id).get("imie", id)), 20, UiKit.GOLD)
	zrodlo.set_drag_preview(l)
	return {"bohater": id}

# ---------------------------------------------------------------- formacja
func _jednostki() -> Array:
	var out: Array = []
	for pole in Formation.POLA:
		var id := str(Game.state["formacja"][pole])
		if id != "" and Game.ma(id):
			out.append(Progression.bohater(id, Game.poziom(id), Game.spec(id), Game.ekwipunek(id), pole))
	Formation.przelicz_aury(out)
	return out

func _formacja() -> void:
	var units := _jednostki()
	var vb := _panel(Rect2(270, 56, 420, 404), "Formacja   -   drużyna %d/%d miejsc" % [Game.w_formacji().size(), Game.miejsca()])
	var naglowki := HBoxContainer.new()
	naglowki.add_theme_constant_override("separation", 8)
	vb.add_child(naglowki)
	for n in ["TYLNY RZĄD", "PRZEDNI RZĄD  ->  wrogowie"]:
		var l := UiKit.label(n, 14, UiKit.DIM)
		l.custom_minimum_size = Vector2(192, 0)
		naglowki.add_child(l)
	var sel_pole := Game.pole_bohatera(sel)
	var sel_unit: CUnit = null
	for u in units:
		if u.id == sel:
			sel_unit = u
	for tor in Formation.RZAD:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		vb.add_child(hb)
		for pole in [Formation.RZAD + tor, tor]:      # najpierw tylny rząd (po lewej), potem przedni
			var id := str(Game.state["formacja"][pole])
			var txt := "- wolne -"
			if id != "":
				txt = "%s  (poz. %d)" % [str(Data.hero(id).get("imie", id)), Game.poziom(id)]
			var b := _maly(txt, func(): _dotknij_pola(pole), 192.0, 46.0, 16)
			# podświetlenie: pola, na które działa aura wybranego bohatera
			var w_aurze := false
			if sel_unit != null and pole != sel_pole:
				for s in sel_unit.skills_of("aura"):
					if Formation.w_zasiegu(sel_pole, pole, str(s.get("zasieg", ""))):
						w_aurze = true
			if pole == sel_pole and sel_pole != -1:
				b.add_theme_color_override("font_color", UiKit.GOLD)
			elif w_aurze:
				b.add_theme_color_override("font_color", Color(0.55, 0.9, 0.5))
				b.text = "* " + b.text
			b.set_drag_forwarding(
				func(_p): return _ciagnij(id, b) if id != "" else null,
				func(_p, d): return d is Dictionary and d.has("bohater"),
				func(_p, d): _upusc(str(d["bohater"]), pole))
			hb.add_child(b)
	# buffy wybranego bohatera
	var opis := ""
	if sel_unit != null:
		if sel_unit.aury_zrodla.is_empty():
			opis = "%s nie otrzymuje żadnych buffów pozycyjnych." % sel_unit.nazwa
		else:
			opis = "%s otrzymuje:" % sel_unit.nazwa
			for z in sel_unit.aury_zrodla:
				var ef: Array = []
				for k in z["efekty"]:
					ef.append(Formation.nazwa_efektu(k, float(z["efekty"][k])))
				opis += "\n  %s od: %s (%s; zasięg: %s)" % [", ".join(ef), z["od"], z["nazwa"], Formation.nazwa_zasiegu(str(z["zasieg"]))]
		opis += "\n* = pola objęte jego aurą"
	elif sel != "":
		opis = "%s jest w rezerwie. Dotknij pola, żeby wstawić go do formacji." % str(Data.hero(sel).get("imie", sel))
	if komunikat != "":
		opis = komunikat + "\n" + opis
	vb.add_child(_tekst(opis, 14, UiKit.TEXT))

func _dotknij_pola(pole: int) -> void:
	komunikat = ""
	var kto := str(Game.state["formacja"][pole])
	if sel == "" or not Game.ma(sel):
		sel = kto
	elif kto == sel:
		Game.zdejmij(sel)
	elif not Game.ustaw(sel, pole):
		komunikat = "Brak wolnych miejsc w drużynie (%d). Ukończ przygodę, żeby odblokować kolejne." % Game.miejsca()
	_buduj()

func _upusc(id: String, pole: int) -> void:
	komunikat = ""
	sel = id
	if not Game.ustaw(id, pole):
		komunikat = "Brak wolnych miejsc w drużynie (%d). Ukończ przygodę, żeby odblokować kolejne." % Game.miejsca()
	_buduj()

# ---------------------------------------------------------------- przygody
func _przygody() -> void:
	var vb := _panel(Rect2(10, 470, 680, 240), "Przygody")
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	for id in Data.adventure_ids():
		var adv := Data.adventure(id)
		var b := _maly(("%s%s" % ["[OK] " if Game.ukonczona(id) else "", str(adv["nazwa"])]), func():
			adv_sel = id
			diff_sel = "normal"
			_buduj(), 212.0, 44.0, 15)
		b.disabled = not Game.dostepna(id, "normal")
		if id == adv_sel:
			b.add_theme_color_override("font_color", UiKit.GOLD)
		hb.add_child(b)
	if adv_sel == "":
		return
	var adv := Data.adventure(adv_sel)
	var plansze: Array = adv.get("plansze", [])
	var boss := ""
	for f in plansze[plansze.size() - 1].get("fale", []):
		for e in f.get("wrogowie", {}):
			if bool(Data.enemy(e).get("boss", false)):
				boss = str(Data.enemy(e).get("nazwa", ""))
	vb.add_child(_tekst("%s\nPlansz: %d.  Boss: %s.  Nagroda: %d koron (pierwsze ukończenie)." % [str(adv.get("opis", "")), plansze.size(), boss,
		roundi(float(adv.get("nagroda_korony", 0)) * float(Data.difficulty(diff_sel).get("zloto", 1.0)))], 15))
	var hb2 := HBoxContainer.new()
	hb2.add_theme_constant_override("separation", 8)
	vb.add_child(hb2)
	for t in Data.adventures.get("kolejnosc_trudnosci", ["normal"]):
		var d := Data.difficulty(t)
		var b := _maly(("[OK] " if Game.ukonczona(adv_sel, t) else "") + str(d.get("nazwa", t)), func():
			diff_sel = t
			_buduj(), 150.0, 42.0, 15)
		b.disabled = not Game.dostepna(adv_sel, t)
		if t == diff_sel:
			b.add_theme_color_override("font_color", UiKit.GOLD)
		hb2.add_child(b)
	var start := UiKit.button("Wyrusz!", func(): main.go("bitwa", {"przygoda": adv_sel, "trudnosc": diff_sel}), 190.0, 46.0)
	start.disabled = Game.w_formacji().is_empty() or not Game.dostepna(adv_sel, diff_sel)
	hb2.add_child(start)
	var najlepszy := ""
	for r in Game.state["ranking"]:
		if str(r["przygoda"]) == str(adv["nazwa"]) and int(r["plansza"]) == plansze.size():
			najlepszy = "Ranking Hardcore - najlepszy czas planszy z bossem: %.1f s (%s)" % [float(r["czas"]), ", ".join(r["sklad"])]
			break
	if najlepszy != "":
		vb.add_child(_tekst(najlepszy, 14, UiKit.DIM))

# ---------------------------------------------------------------- karta bohatera
func _bohater() -> void:
	var p := PanelContainer.new()
	p.position = Vector2(700, 56)
	p.size = Vector2(570, 654)
	p.custom_minimum_size = p.size
	add_child(p)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(530, 0)
	vb.add_theme_constant_override("separation", 6)
	sc.add_child(vb)
	if sel == "" or not Game.ma(sel):
		vb.add_child(_tekst("Wybierz bohatera z listy."))
		return
	var def := Data.hero(sel)
	var poz := Game.poziom(sel)
	var z := Game.zestaw(sel)
	var c: Dictionary = z["cechy"]
	var naglowek := HBoxContainer.new()
	naglowek.add_theme_constant_override("separation", 12)
	vb.add_child(naglowek)
	naglowek.add_child(UiKit.icon(str(def.get("portret", "")), 96.0))
	var nv := VBoxContainer.new()
	naglowek.add_child(nv)
	nv.add_child(UiKit.label("%s   -   poziom %d" % [str(def["imie"]), poz], 24, UiKit.GOLD, false))
	nv.add_child(UiKit.label("%s   |   %s" % [str(def.get("profesja", "")), " / ".join(def.get("role", []))], 16, UiKit.DIM, false))
	var aw := _maly("", func():
		if Game.awansuj(sel):
			Audio.play("levelup")
		_buduj(), 300.0, 40.0)
	if poz >= Progression.max_poziom():
		aw.text = "Poziom maksymalny"
		aw.disabled = true
	else:
		aw.text = "Awansuj na poziom %d  (%d koron)" % [poz + 1, Game.koszt_awansu(sel)]
		aw.disabled = not Game.moze_awansowac(sel)
	nv.add_child(aw)
	vb.add_child(_tekst(str(def.get("opis", "")), 15))
	# cechy WFRP
	var linie := ""
	var kol := ["WW", "US", "K", "Odp", "Zr", "Int", "SW", "Ogd", "Zyw", "Sz"]
	for i in kol.size():
		linie += "%s %d    " % ["Żyw" if kol[i] == "Zyw" else kol[i], roundi(float(c.get(kol[i], 0)))]
		if i == 4:
			linie += "\n"
	var atak: Dictionary = z["atak"]
	var typ := {"wrecz": "wręcz (tylko z pierwszej linii)", "dystans": "dystansowy", "magia": "magiczny (omija pancerz)"}
	linie += "\nHP %d    S %.1f    Wt %.1f    pancerz %.1f" % [roundi(Wfrp.max_hp(c)), Wfrp.sila(c), Wfrp.wytrzymalosc(c), float(z["pancerz"])]
	linie += "\nAtak: %s - %s, co %.1f s" % [str(atak.get("nazwa", "")), str(typ.get(str(atak.get("typ", "")), "")), Wfrp.czas_ataku(float(atak.get("czas", 5.0)), c)]
	vb.add_child(_tekst(linie, 16, UiKit.TEXT))
	# umiejętności
	vb.add_child(UiKit.label("Umiejętności", 18, UiKit.GOLD, false))
	for s in z["wszystkie"]:
		var odb: bool = s["odblokowana"]
		var extra := ""
		if str(s.get("typ", "")) == "ultimate":
			extra = " [ULTIMATE]"
		elif str(s.get("typ", "")) == "aura":
			extra = " [aura: %s]" % Formation.nazwa_zasiegu(str(s.get("zasieg", "")))
		vb.add_child(_tekst("%s %s%s - %s" % ["poz. %d:" % int(s.get("prog", 1)), str(s.get("nazwa", "")), extra, str(s.get("opis", ""))],
			14, UiKit.TEXT if odb else UiKit.DIM))
	# specjalizacja
	var sp: Dictionary = def.get("specjalizacja", {})
	if not sp.is_empty():
		var wybrana := Game.spec(sel)
		vb.add_child(UiKit.label("Specjalizacja (od poziomu %d)" % int(sp.get("prog", 10)), 18, UiKit.GOLD, false))
		for g in sp.get("galezie", []):
			var gid := str(g["id"])
			if wybrana == gid:
				vb.add_child(_tekst("WYBRANA: %s - %s" % [str(g["nazwa"]), str(g["opis"])], 14, Color(0.55, 0.9, 0.5)))
			elif wybrana == "" and Progression.moze_wybrac_spec(def, poz, wybrana):
				var b := _maly("Wybierz: %s" % str(g["nazwa"]), func():
					if Game.wybierz_spec(sel, gid):
						Audio.play("levelup")
					_buduj(), 520.0, 40.0, 15)
				vb.add_child(b)
				vb.add_child(_tekst(str(g["opis"]), 14, UiKit.DIM))
			else:
				vb.add_child(_tekst("%s - %s" % [str(g["nazwa"]), str(g["opis"])], 14, UiKit.DIM))
	# ekwipunek
	vb.add_child(UiKit.label("Ekwipunek (dotknij slotu: załóż kolejny pasujący z magazynu / zdejmij)", 16, UiKit.GOLD, false))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	vb.add_child(grid)
	var ekw := Game.ekwipunek(sel)
	for slot in Data.items.get("sloty", []):
		var it := Data.item(str(ekw.get(slot, "")))
		var nazwa_slotu := str(Data.items.get("nazwy_slotow", {}).get(slot, slot))
		var txt := "%s: -" % nazwa_slotu
		if not it.is_empty():
			var ce: Array = []
			for k in it.get("cechy", {}):
				ce.append("%s +%s" % [k, str(it["cechy"][k])])
			txt = "%s: %s\n%s" % [nazwa_slotu, str(it["nazwa"]), ", ".join(ce)]
		var pasujace := 0
		for m in Game.state["magazyn"]:
			if Game.pasuje(str(m), sel, slot):
				pasujace += 1
		if pasujace > 0:
			txt += "   [w magazynie: %d]" % pasujace
		var b := _maly(txt, func():
			Game.przelacz_przedmiot(sel, slot)
			_buduj(), 258.0, 52.0, 13)
		b.disabled = it.is_empty() and pasujace == 0
		if not it.is_empty():
			b.add_theme_color_override("font_color", Art.col(str(RZADKOSC.get(str(it.get("rzadkosc", "common")), "#ffffff"))))
		grid.add_child(b)
