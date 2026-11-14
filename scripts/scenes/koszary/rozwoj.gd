class_name KRozwoj
extends RefCounted
## 4. Rozwój bohatera: awans poziomu i drzewko umiejętności z rozwidleniem specjalizacji.
## Węzeł drzewka pokazuje tylko nazwę i próg; opis wybranego węzła jest w panelu pod drzewkiem.

static func buduj(k: BarracksScene, c: Control, p: Dictionary) -> void:
	var id := str(p.get("id", ""))
	if not Game.ma(id):
		k.pelny(Gk.tekst("Tego bohatera nie ma w Gwardii.", 20), c)
		return
	var def := Data.hero(id)
	var poz := Game.poziom(id)
	var z := Game.zestaw(id)
	var maks := Progression.max_poziom()
	var v: VBoxContainer = k.pelny(Gk.vb(10), c)

	# ---- poziom i awans
	var gora := Gk.rama(12.0)
	var gh := Gk.hb(14)
	gora.add_child(gh)
	gh.add_child(Gk.portret(id, Vector2(76, 76), Gk.stan_bohatera(id)))
	var gv := Gk.vb(4)
	gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gv.add_child(Gk.tytul("Poziom %d z %d" % [poz, maks], 28))
	gv.add_child(Gk.pasek_postepu(float(poz) / float(maks), Gk.ZLOTO, 12.0))
	var wz: Array = []
	for kc in KW.CECHY:
		if def.get("wzrost", {}).has(kc):
			wz.append("%s +%s" % [KW.cecha(kc), KW._liczba(float(def["wzrost"][kc]))])
	var nast := ""
	for s in z["wszystkie"]:
		if not s["odblokowana"] and (nast == "" ):
			nast = "   Następna umiejętność: %s (poziom %d)." % [str(s.get("nazwa", "")), int(s.get("prog", 1))]
	gv.add_child(Gk.tekst("Każdy poziom: %s.%s" % [",  ".join(wz), nast], 16, Gk.PRZYG))
	gh.add_child(gv)
	var aw := Gk.przycisk("", func():
		if Game.awansuj(id):
			Audio.play("levelup")
			p.erase("wezel")
			k.odswiez(), true, 300.0, 58.0, "awans")
	aw.name = "btn_awans"
	aw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if poz >= maks:
		aw.text = "Poziom maksymalny"
		aw.disabled = true
	else:
		aw.text = "Awansuj · %d koron" % Game.koszt_awansu(id)
		aw.disabled = not Game.moze_awansowac(id)
	gh.add_child(aw)
	v.add_child(gora)

	# ---- drzewko
	var sp: Dictionary = def.get("specjalizacja", {})
	var prog_spec := int(sp.get("prog", 999))
	var wybrana_spec := Game.spec(id)
	var wezly: Array = z["wszystkie"].duplicate()
	wezly.sort_custom(func(a, b): return int(a.get("prog", 1)) < int(b.get("prog", 1)))
	var sel := str(p.get("wezel", ""))
	if sel == "":
		if Progression.moze_wybrac_spec(def, poz, wybrana_spec):
			sel = "spec:" + str(sp["galezie"][0]["id"])
		else:
			for s in wezly:
				if not s["odblokowana"]:
					sel = str(s["id"])
					break
		if sel == "" and not wezly.is_empty():
			sel = str(wezly[wezly.size() - 1]["id"])

	var drz := Gk.rama(12.0)
	var dv := Gk.vb(6)
	drz.add_child(dv)
	dv.add_child(Gk.naglowek("Drzewko umiejętności"))
	var tor := Gk.hb(0)
	tor.alignment = BoxContainer.ALIGNMENT_BEGIN
	var przew := ScrollContainer.new()
	przew.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	przew.custom_minimum_size = Vector2(0, 186)
	przew.add_child(tor)
	dv.add_child(przew)
	var wstawiono_spec := sp.is_empty()
	var pierwszy := true
	for s in wezly:
		if not wstawiono_spec and int(s.get("prog", 1)) > prog_spec:
			_lacznik(tor, poz >= prog_spec, pierwszy)
			_rozwidlenie(k, tor, p, sp, wybrana_spec, poz, sel)
			wstawiono_spec = true
			pierwszy = false
		_lacznik(tor, bool(s["odblokowana"]), pierwszy)
		pierwszy = false
		var sid := str(s["id"])
		var karta := Gk.karta(func():
			p["wezel"] = sid
			k.odswiez(), sel == sid, 8.0)
		karta[0].custom_minimum_size = Vector2(150, 150)
		karta[0].size_flags_vertical = Control.SIZE_SHRINK_CENTER
		karta[1].name = "wezel_" + sid
		var wv := Gk.vb(4)
		wv.alignment = BoxContainer.ALIGNMENT_CENTER
		wv.add_child(_kolo(int(s.get("prog", 1)), bool(s["odblokowana"]), str(s.get("typ", "")) == "ultimate"))
		var n := Gk.gruby(str(s.get("nazwa", "")), 15, Gk.ZLOTO_J if s["odblokowana"] else Gk.PRZYG)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.custom_minimum_size = Vector2(130, 0)
		wv.add_child(n)
		Gk.do_karty(karta, wv)
		tor.add_child(karta[0])
	if not wstawiono_spec:
		_lacznik(tor, poz >= prog_spec, pierwszy)
		_rozwidlenie(k, tor, p, sp, wybrana_spec, poz, sel)
	v.add_child(drz)

	# ---- opis wybranego węzła
	var op := Gk.rama(14.0)
	op.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var ov := Gk.vb(8)
	op.add_child(Gk.przewijany(ov))
	if sel.begins_with("spec:"):
		var gal := Progression.galaz(def, sel.substr(5))
		var gid := str(gal.get("id", ""))
		var oh := Gk.hb(10)
		var t := Gk.tytul("Specjalizacja: %s" % str(gal.get("nazwa", "")), 26)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		oh.add_child(t)
		if wybrana_spec == gid:
			oh.add_child(Gk.odznaka("Wybrana", Gk.ZIELEN))
		elif wybrana_spec != "":
			oh.add_child(Gk.odznaka("Wybrano inną ścieżkę", Gk.PRZYG))
		else:
			oh.add_child(Gk.odznaka("Od poziomu %d" % prog_spec, Gk.ZLOTO if poz >= prog_spec else Gk.PRZYG))
		ov.add_child(oh)
		ov.add_child(Gk.tekst(str(gal.get("opis", "")), 18))
		if wybrana_spec == "":
			ov.add_child(Gk.tekst("Wybór jest ostateczny — druga ścieżka zostanie zamknięta.", 16, Gk.PRZYG))
			var b := Gk.przycisk("Wybierz ścieżkę: %s" % str(gal.get("nazwa", "")), func():
				if Game.wybierz_spec(id, gid):
					Audio.play("levelup")
					k.odswiez("%s obiera ścieżkę: %s." % [str(def["imie"]), str(gal.get("nazwa", ""))]), true, 380.0, 52.0)
			b.name = "btn_spec"
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			b.disabled = not Progression.moze_wybrac_spec(def, poz, wybrana_spec)
			ov.add_child(b)
	else:
		for s in wezly:
			if str(s["id"]) != sel:
				continue
			var oh := Gk.hb(10)
			var t := Gk.tytul(str(s.get("nazwa", "")), 26)
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			oh.add_child(t)
			oh.add_child(Gk.odznaka(KW.typ_umiejetnosci(s)))
			if s["odblokowana"]:
				oh.add_child(Gk.odznaka("Odblokowana", Gk.ZIELEN))
			else:
				oh.add_child(Gk.odznaka("Wymaga poziomu %d" % int(s.get("prog", 1)), Gk.PRZYG))
			ov.add_child(oh)
			ov.add_child(Gk.tekst(str(s.get("opis", "")), 18))
	v.add_child(op)

static func _lacznik(tor: Control, aktywny: bool, pomin: bool) -> void:
	if pomin:
		return
	var l := Control.new()
	l.custom_minimum_size = Vector2(30, 8)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.draw.connect(func():
		var y := l.size.y * 0.5
		l.draw_line(Vector2(0, y), Vector2(l.size.x, y), Gk.ZLOTO if aktywny else Color(0.3, 0.26, 0.22), 3.0)
		l.draw_colored_polygon(PackedVector2Array([Vector2(l.size.x * 0.5 - 5, y), Vector2(l.size.x * 0.5, y - 5), Vector2(l.size.x * 0.5 + 5, y), Vector2(l.size.x * 0.5, y + 5)]),
			Gk.ZLOTO if aktywny else Color(0.3, 0.26, 0.22)))
	tor.add_child(l)

static func _kolo(prog: int, odblokowana: bool, ultimate: bool) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(56, 56)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var s := c.size * 0.5
		var kol := (Gk.SZKARLAT_J if ultimate else Gk.ZLOTO) if odblokowana else Color(0.34, 0.3, 0.26)
		c.draw_circle(s, 26.0, Color(0.04, 0.02, 0.02))
		if odblokowana:
			c.draw_circle(s, 22.0, Color(0.36, 0.07, 0.05) if ultimate else Color(0.26, 0.17, 0.06))
		c.draw_arc(s, 25.0, 0.0, TAU, 40, kol, 3.0, true)
		var t := str(prog)
		var f := Gk.f_tytul()
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		c.draw_string(f, Vector2(s.x - w * 0.5, s.y + 9.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Gk.ZLOTO_J if odblokowana else Gk.PRZYG))
	return c

static func _rozwidlenie(k: BarracksScene, tor: Control, p: Dictionary, sp: Dictionary, wybrana: String, poz: int, sel: String) -> void:
	var v := Gk.vb(8)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for g in sp.get("galezie", []):
		var gid := str(g["id"])
		var karta := Gk.karta(func():
			p["wezel"] = "spec:" + gid
			k.odswiez(), sel == "spec:" + gid, 8.0)
		karta[0].custom_minimum_size = Vector2(250, 70)
		karta[1].name = "wezel_spec_" + gid
		var h := Gk.hb(8)
		var kolor := Gk.ZIELEN if wybrana == gid else (Gk.PRZYG if (wybrana != "" or poz < int(sp.get("prog", 999))) else Gk.ZLOTO_J)
		h.add_child(Ikona.nowa("ptaszek" if wybrana == gid else "gwiazda", 26.0, kolor))
		var w := Gk.vb(0)
		w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		w.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		w.add_child(Gk.tekst("Specjalizacja · poz. %d" % int(sp.get("prog", 10)), 13, Gk.PRZYG, false))
		var n := Gk.gruby(str(g["nazwa"]), 16, kolor)
		n.clip_text = true
		w.add_child(n)
		h.add_child(w)
		Gk.do_karty(karta, h)
		v.add_child(karta[0])
	tor.add_child(v)
