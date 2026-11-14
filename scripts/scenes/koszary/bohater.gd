class_name KBohater
extends RefCounted
## 3. Szczegółowy ekran bohatera: opis fabularny, statystyki WFRP, skrót specjalizacji i umiejętności.
## Rozwój, ekwipunek i formacja to osobne ekrany - stąd tylko przejścia.

static func buduj(k: BarracksScene, c: Control, p: Dictionary) -> void:
	var id := str(p.get("id", ""))
	if not Game.ma(id):
		k.pelny(Gk.tekst("Tego bohatera nie ma w Gwardii.", 20), c)
		return
	var def := Data.hero(id)
	var z := Game.zestaw(id)
	var cechy: Dictionary = z["cechy"]
	var h: HBoxContainer = k.pelny(Gk.hb(14), c)

	# ---- lewa kolumna: sylwetka, zdrowie, lazaret, sąsiedni bohaterowie
	var lewa := Gk.rama(12.0)
	lewa.custom_minimum_size = Vector2(300, 0)
	var lv := Gk.vb(8)
	lewa.add_child(lv)
	var por := Gk.portret(id, Vector2(270, 300), Gk.stan_bohatera(id), true)
	por.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(por)
	var pasek := Gk.pasek_hp(id, 24.0)
	lv.add_child(pasek)
	var st := Gk.tekst(KW.status_zdrowia(id), 16, KW.kolor_zdrowia(id), false)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(st)
	k.zywe.append(func():
		pasek.queue_redraw()
		st.text = KW.status_zdrowia(id))
	var lecz := KW.przycisk_lazaretu(k, id)
	if lecz != null:
		lv.add_child(lecz)
	var moi: Array = []
	for hid in Data.hero_ids():
		if Game.ma(hid):
			moi.append(hid)
	if moi.size() > 1:
		var nav := Gk.hb(8)
		var i := moi.find(id)
		var poprz: String = moi[(i - 1 + moi.size()) % moi.size()]
		var nast: String = moi[(i + 1) % moi.size()]
		var bp := Gk.przycisk("", func():
			p["id"] = poprz
			k.odswiez(), false, 56.0, 42.0, "wstecz")
		bp.name = "btn_poprzedni"
		nav.add_child(bp)
		var srodek := Gk.tekst("%d / %d" % [i + 1, moi.size()], 16, Gk.PRZYG, false)
		srodek.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		srodek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(srodek)
		var bn := Gk.przycisk("", func():
			p["id"] = nast
			k.odswiez(), false, 56.0, 42.0, "dalej")
		bn.name = "btn_nastepny"
		nav.add_child(bn)
		lv.add_child(nav)
	h.add_child(lewa)

	# ---- prawa kolumna
	var prawa := Gk.vb(10)
	prawa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(prawa)
	var karta := Gk.rama(14.0)
	karta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prawa.add_child(karta)
	var v := Gk.vb(10)
	karta.add_child(Gk.przewijany(v))

	var g := Gk.hb(10)
	var tyt := Gk.tytul(str(def.get("tytul", def.get("profesja", ""))), 24, Gk.SZKARLAT_J)
	tyt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(tyt)
	for r in def.get("role", []):
		g.add_child(Gk.odznaka(str(r)))
	g.add_child(Gk.odznaka("Poziom %d" % Game.poziom(id), Gk.ZLOTO_J, Color(0.3, 0.06, 0.05, 0.8)))
	g.add_child(Gk.odznaka(KW.miejsce(id), Gk.ZLOTO if Game.pole_bohatera(id) != -1 else Gk.PRZYG))
	v.add_child(g)
	v.add_child(Gk.pergamin(str(def.get("fabula", def.get("opis", "")))))

	v.add_child(Gk.naglowek("Statystyki (WFRP)"))
	var siatka := GridContainer.new()
	siatka.columns = 5
	siatka.add_theme_constant_override("h_separation", 8)
	siatka.add_theme_constant_override("v_separation", 8)
	for kc in KW.CECHY:
		siatka.add_child(_komorka(KW.cecha(kc), str(roundi(float(cechy.get(kc, 0)))), str(KW.CECHY_OPIS[kc])))
	v.add_child(siatka)
	var poch := Gk.hb(8)
	poch.add_child(_komorka("HP", str(roundi(Wfrp.max_hp(cechy))), "Punkty życia = Żyw × 10", Gk.SZKARLAT_J))
	poch.add_child(_komorka("S", "%.1f" % Wfrp.sila(cechy), "Siła = K / 10, dodawana do obrażeń", Gk.SZKARLAT_J))
	poch.add_child(_komorka("Wt", "%.1f" % Wfrp.wytrzymalosc(cechy), "Wytrzymałość = Odp / 10, zmniejsza obrażenia", Gk.SZKARLAT_J))
	poch.add_child(_komorka("Pancerz", "%.1f" % float(z["pancerz"]), "Stała redukcja obrażeń fizycznych", Gk.SZKARLAT_J))
	v.add_child(poch)
	var atak: Dictionary = z["atak"]
	var typ := {"wrecz": "wręcz, tylko z pierwszej linii", "dystans": "dystansowy", "magia": "magiczny, omija pancerz"}
	v.add_child(Gk.tekst("Atak: %s  (%s)  —  co %.1f s" % [str(atak.get("nazwa", "")), str(typ.get(str(atak.get("typ", "")), "")),
		Wfrp.czas_ataku(float(atak.get("czas", 5.0)), cechy)], 17, Gk.TEKST))

	v.add_child(Gk.naglowek("Rola w drużynie"))
	v.add_child(Gk.tekst(str(def.get("opis", "")), 17, Gk.TEKST))

	var odbl: Array = []
	for s in z["wszystkie"]:
		if s["odblokowana"]:
			odbl.append(str(s.get("nazwa", "")))
	v.add_child(Gk.naglowek("Umiejętności  (%d z %d)" % [odbl.size(), z["wszystkie"].size()]))
	v.add_child(Gk.tekst(",  ".join(odbl) if not odbl.is_empty() else "Jeszcze żadnej.", 17, Gk.TEKST))
	var sp: Dictionary = def.get("specjalizacja", {})
	if not sp.is_empty():
		v.add_child(Gk.naglowek("Specjalizacja"))
		var gal := Progression.galaz(def, Game.spec(id))
		if not gal.is_empty():
			v.add_child(Gk.tekst("%s — %s" % [str(gal["nazwa"]), str(gal["opis"])], 17, Gk.ZIELEN))
		elif Progression.moze_wybrac_spec(def, Game.poziom(id), Game.spec(id)):
			v.add_child(Gk.tekst("Do wyboru! Otwórz „Rozwój i umiejętności”.", 17, Gk.ZLOTO_J))
		else:
			v.add_child(Gk.tekst("Wybór od poziomu %d." % int(sp.get("prog", 10)), 17, Gk.PRZYG))

	# ---- przejścia do podekranów
	var dol := Gk.hb(10)
	var moze := Game.moze_awansowac(id) or Progression.moze_wybrac_spec(def, Game.poziom(id), Game.spec(id))
	var b1 := Gk.przycisk("Rozwój i umiejętności", func(): k.idz("rozwoj", {"id": id}), moze, 0.0, 54.0, "awans")
	b1.name = "btn_rozwoj"
	var b2 := Gk.przycisk("Ekwipunek  (%d/%d)" % [Game.ekwipunek(id).size(), Data.items.get("sloty", []).size()],
		func(): k.idz("ekwipunek", {"id": id}), false, 0.0, 54.0, "sakwa")
	b2.name = "btn_ekwipunek"
	var b3 := Gk.przycisk("Formacja", func(): k.idz("formacja", {"sel": id}), false, 0.0, 54.0, "formacja")
	b3.name = "btn_formacja"
	for b in [b1, b2, b3]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dol.add_child(b)
	prawa.add_child(dol)

static func _komorka(nazwa: String, wartosc: String, podpowiedz: String, kolor: Color = Gk.ZLOTO) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Gk.sb(Color(0, 0, 0, 0.4), Gk.ZLOTO_C, 1, 6.0, 2))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.tooltip_text = podpowiedz
	var h := Gk.hb(8)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(Gk.gruby(nazwa, 16, kolor))
	h.add_child(Gk.gruby(wartosc, 22, Gk.TEKST))
	p.add_child(h)
	return p
