class_name KFormacja
extends RefCounted
## 6. Formacja drużyny: ławka po lewej, szyk 2x5 pośrodku (przeciąganie albo dotknięcia), buffy pozycyjne po prawej.

static func buduj(k: BarracksScene, c: Control, p: Dictionary) -> void:
	var sel := str(p.get("sel", ""))
	if sel != "" and not Game.ma(sel):
		sel = ""
	var units := _jednostki()
	var sel_pole := Game.pole_bohatera(sel) if sel != "" else -1
	var sel_unit: CUnit = null
	for u in units:
		if u.id == sel:
			sel_unit = u
	var h: HBoxContainer = k.pelny(Gk.hb(14), c)

	# ---- ławka: wszyscy bohaterowie
	var lewa := Gk.rama(12.0)
	lewa.custom_minimum_size = Vector2(300, 0)
	var lv := Gk.vb(8)
	lewa.add_child(lv)
	lv.add_child(Gk.naglowek("Bohaterowie", 20))
	var lista := Gk.vb(8)
	lv.add_child(Gk.przewijany(lista))
	for id in Data.hero_ids():
		if not Game.ma(id):
			continue
		var karta := Gk.karta(func():
			p["sel"] = "" if sel == id else id
			k.odswiez(), sel == id, 6.0)
		karta[1].name = "lawka_" + str(id)
		karta[1].set_drag_forwarding(func(_poz): return _ciagnij(id, karta[1]), Callable(), Callable())
		var rh := Gk.hb(10)
		rh.add_child(Gk.portret(id, Vector2(52, 52), Gk.stan_bohatera(id)))
		var rv := Gk.vb(0)
		rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var n := Gk.gruby(str(Data.hero(id)["imie"]), 17, Gk.ZLOTO_J)
		n.clip_text = true
		rv.add_child(n)
		rv.add_child(Gk.tekst("poz. %d  ·  %s" % [Game.poziom(id), KW.miejsce(id)], 14, Gk.ZLOTO if Game.pole_bohatera(id) != -1 else Gk.PRZYG, false))
		rh.add_child(rv)
		Gk.do_karty(karta, rh)
		lista.add_child(karta[0])
	h.add_child(lewa)

	# ---- szyk
	var srodek := Gk.rama(12.0)
	srodek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sv := Gk.vb(8)
	srodek.add_child(sv)
	sv.add_child(Gk.naglowek("Szyk  —  %d z %d miejsc" % [Game.w_formacji().size(), Game.miejsca()], 20))
	var nag := Gk.hb(10)
	for t in ["TYLNY RZĄD", "PRZEDNI RZĄD  →  wrogowie"]:
		var l := Gk.gruby(t, 14, Gk.PRZYG)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nag.add_child(l)
	sv.add_child(nag)
	var siatka := GridContainer.new()
	siatka.columns = 2
	siatka.add_theme_constant_override("h_separation", 10)
	siatka.add_theme_constant_override("v_separation", 8)
	siatka.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sv.add_child(siatka)
	for tor in Formation.RZAD:
		for pole in [Formation.RZAD + tor, tor]:        # tylny rząd po lewej, przedni po prawej
			var id := str(Game.state["formacja"][pole])
			var w_aurze := false
			if sel_unit != null and pole != sel_pole:
				for s in sel_unit.skills_of("aura"):
					if Formation.w_zasiegu(sel_pole, pole, str(s.get("zasieg", ""))):
						w_aurze = true
			var karta := Gk.karta(func(): _dotknij(k, p, pole), pole == sel_pole and sel_pole != -1, 6.0)
			var pan: PanelContainer = karta[0]
			pan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pan.size_flags_vertical = Control.SIZE_EXPAND_FILL
			pan.custom_minimum_size = Vector2(0, 66)
			if w_aurze:
				var st: StyleBoxFlat = pan.get_theme_stylebox("panel").duplicate()
				st.border_color = Gk.ZIELEN
				st.bg_color = Color(0.08, 0.14, 0.07, 0.95)
				pan.add_theme_stylebox_override("panel", st)
			karta[1].name = "pole_%d" % pole
			karta[1].set_drag_forwarding(
				func(_poz): return _ciagnij(id, karta[1]) if id != "" else null,
				func(_poz, d): return d is Dictionary and d.has("bohater"),
				func(_poz, d): _upusc(k, p, str(d["bohater"]), pole))
			var rh := Gk.hb(10)
			if id != "" and Game.ma(id):
				rh.add_child(Gk.portret(id, Vector2(54, 54), Gk.stan_bohatera(id)))
				var rv := Gk.vb(2)
				rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				rv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				var n := Gk.gruby("%s  ·  poz. %d" % [str(Data.hero(id)["imie"]), Game.poziom(id)], 16, Gk.PRZYG if Game.polegly(id) else Gk.ZLOTO_J)
				n.clip_text = true
				rv.add_child(n)
				var pasek := Gk.pasek_hp(id, 15.0)
				rv.add_child(pasek)
				k.zywe.append(func(): pasek.queue_redraw())
				rh.add_child(rv)
			else:
				var pusty := Gk.tekst("wolne pole" + ("  ·  w zasięgu aury" if w_aurze else ""), 16, Gk.ZIELEN if w_aurze else Color(0.45, 0.4, 0.35), false)
				pusty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				pusty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				rh.add_child(pusty)
			Gk.do_karty(karta, rh)
			siatka.add_child(pan)
	h.add_child(srodek)

	# ---- buffy i podpowiedzi
	var prawa := Gk.rama(12.0)
	prawa.custom_minimum_size = Vector2(320, 0)
	var pv := Gk.vb(8)
	prawa.add_child(Gk.przewijany(pv))
	if sel == "":
		pv.add_child(Gk.naglowek("Jak ustawiać", 20))
		pv.add_child(Gk.tekst("Przeciągnij bohatera z listy na pole albo dotknij bohatera, a potem pola.\n\nDotknięcie zajętego pola zamienia bohaterów miejscami. Dotknięcie własnego pola zdejmuje bohatera z szyku.\n\nWalczący wręcz dosięgają wroga tylko z przedniego rzędu. Strzelcy i magowie są bezpieczniejsi z tyłu.", 16, Gk.TEKST))
	else:
		pv.add_child(Gk.naglowek(str(Data.hero(sel)["imie"]), 20))
		if sel_unit == null:
			pv.add_child(Gk.tekst("W rezerwie. Dotknij pola w szyku, żeby go wstawić.", 16, Gk.TEKST))
		else:
			pv.add_child(Gk.gruby("Otrzymuje:", 16, Gk.ZLOTO))
			if sel_unit.aury_zrodla.is_empty():
				pv.add_child(Gk.tekst("Żadnych buffów pozycyjnych.", 16, Gk.PRZYG))
			for z in sel_unit.aury_zrodla:
				var ef: Array = []
				for e in z["efekty"]:
					ef.append(Formation.nazwa_efektu(e, float(z["efekty"][e])))
				pv.add_child(Gk.tekst("%s\nod: %s (%s)" % [", ".join(ef), z["od"], z["nazwa"]], 16, Gk.ZIELEN))
			var daje := sel_unit.skills_of("aura")
			pv.add_child(Gk.gruby("Daje:", 16, Gk.ZLOTO))
			if daje.is_empty():
				pv.add_child(Gk.tekst("Nie ma jeszcze żadnej aury.", 16, Gk.PRZYG))
			for s in daje:
				var ef2: Array = []
				for e in s.get("efekty", {}):
					ef2.append(Formation.nazwa_efektu(e, float(s["efekty"][e])))
				pv.add_child(Gk.tekst("%s: %s\nzasięg: %s" % [str(s.get("nazwa", "")), ", ".join(ef2), Formation.nazwa_zasiegu(str(s.get("zasieg", "")))], 16, Gk.TEKST))
			pv.add_child(Gk.tekst("Zielone pola są w zasięgu jego aury.", 14, Gk.PRZYG))
			var zd := Gk.przycisk("Zdejmij z szyku", func():
				Game.zdejmij(sel)
				k.odswiez(), false, 0.0, 46.0)
			zd.name = "btn_zdejmij_z_szyku"
			pv.add_child(zd)
		if Game.polegly(sel):
			pv.add_child(Gk.tekst("Leży w lazarecie — nie wyruszy na misję, dopóki nie wróci.", 16, Gk.SZKARLAT_J))
	h.add_child(prawa)

static func _jednostki() -> Array:
	var out: Array = []
	for pole in Formation.POLA:
		var id := str(Game.state["formacja"][pole])
		if id != "" and Game.ma(id):
			out.append(Progression.bohater(id, Game.poziom(id), Game.spec(id), Game.ekwipunek(id), pole))
	Formation.przelicz_aury(out)
	return out

static func _ciagnij(id: String, zrodlo: Control):
	zrodlo.set_drag_preview(Gk.tytul(str(Data.hero(id).get("imie", id)), 22))
	return {"bohater": id}

static func _brak_miejsc() -> String:
	return "Brak wolnych miejsc w drużynie (%d). Ukończ przygodę, żeby odblokować kolejne." % Game.miejsca()

static func _dotknij(k: BarracksScene, p: Dictionary, pole: int) -> void:
	var sel := str(p.get("sel", ""))
	var kto := str(Game.state["formacja"][pole])
	var info := ""
	if sel == "" or not Game.ma(sel):
		p["sel"] = kto
	elif kto == sel:
		Game.zdejmij(sel)
	elif not Game.ustaw(sel, pole):
		info = _brak_miejsc()
	k.odswiez(info)

static func _upusc(k: BarracksScene, p: Dictionary, id: String, pole: int) -> void:
	p["sel"] = id
	k.odswiez("" if Game.ustaw(id, pole) else _brak_miejsc())
