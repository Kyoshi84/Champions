class_name KArena
extends RefCounted
## 12. Arena: drabinka przeciwników (od dołu najłatwiejszy, wyżej coraz trudniejsi) i szczegóły wybranego szczebla:
## skład drużyny przeciwnika w szyku 2x5, nagrody, rekord, przejście do drużyny areny i start potyczki.

const STATUS := {"pokonany": ["Pokonany", Gk.ZIELEN], "dostepny": ["Dostępny", Gk.ZLOTO_J], "zablokowany": ["Zablokowany", Gk.PRZYG], "wkrotce": ["Wkrótce", Gk.PRZYG]}

static func domyslny() -> String:
	var lista := Data.arena_lista()
	for p in lista:
		if Game.arena_status(str(p["id"])) == "dostepny":
			return str(p["id"])
	return str(lista[0]["id"]) if not lista.is_empty() else ""

static func buduj(k: BarracksScene, c: Control, p: Dictionary) -> void:
	var v: VBoxContainer = k.pelny(Gk.vb(10), c)
	if not Game.arena_odblokowana():
		var r := Gk.rama(12.0)
		var rh := Gk.hb(14)
		r.add_child(rh)
		rh.add_child(Ikona.nowa("klodka", 44.0, Gk.ZLOTO))
		var rv := Gk.vb(4)
		rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rv.add_child(Gk.tytul("Arena jest zamknięta", 24))
		var ile: int = Game.state["bohaterowie"].size()
		rv.add_child(Gk.tekst("Na arenę wychodzi się drużyną dziesięciu. Otworzy się, gdy w Gwardii będzie co najmniej %d bohaterów — teraz jest ich %d." % [Game.arena_wymagani(), ile], 16))
		var pp := Gk.pasek_postepu(float(ile) / float(Game.arena_wymagani()), Gk.ZLOTO, 10.0)
		rv.add_child(pp)
		rh.add_child(rv)
		var bt := Gk.przycisk("Tawerna", func(): k.idz("tawerna"), true, 170.0, 48.0, "kufel")
		bt.name = "btn_do_tawerny"
		bt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rh.add_child(bt)
		v.add_child(r)
	var h := Gk.hb(14)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var sel := str(p.get("sel", ""))
	if Data.arena_przeciwnik(sel).is_empty():
		sel = domyslny()
		p["sel"] = sel

	# ---- drabinka
	var lewa := Gk.rama(12.0)
	lewa.custom_minimum_size = Vector2(340, 0)
	var lv := Gk.vb(8)
	lewa.add_child(lv)
	lv.add_child(Gk.naglowek("Drabinka", 20))
	var lista := Gk.vb(0)
	lista.alignment = BoxContainer.ALIGNMENT_END
	lv.add_child(Gk.przewijany(lista))
	var przeciwnicy := Data.arena_lista()
	for i in range(przeciwnicy.size() - 1, -1, -1):          # od góry najtrudniejszy
		var op: Dictionary = przeciwnicy[i]
		var oid := str(op["id"])
		var st := Game.arena_status(oid)
		if i < przeciwnicy.size() - 1:
			var sz := Control.new()
			sz.custom_minimum_size = Vector2(0, 16)
			var aktywny := st in ["pokonany"]
			sz.draw.connect(func():
				for x in [sz.size.x * 0.3, sz.size.x * 0.7]:
					sz.draw_line(Vector2(x, 0), Vector2(x, sz.size.y), Gk.ZLOTO if aktywny else Color(0.3, 0.26, 0.22), 3.0))
			lista.add_child(sz)
		var karta := Gk.karta(func():
			p["sel"] = oid
			k.odswiez(), sel == oid, 10.0)
		karta[1].name = "szczebel_" + oid
		if st == "wkrotce":
			karta[0].modulate = Color(0.6, 0.58, 0.56)
		var kh := Gk.hb(10)
		var nr := Gk.tytul(str(i + 1), 30, Gk.ZLOTO_J if st != "wkrotce" else Gk.PRZYG)
		nr.custom_minimum_size = Vector2(30, 0)
		nr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kh.add_child(nr)
		var kv := Gk.vb(2)
		kv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var n := Gk.gruby(str(op.get("nazwa", oid)), 17, Gk.PRZYG if st in ["wkrotce", "zablokowany"] else Gk.ZLOTO_J)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		kv.add_child(n)
		var g := Gk.hb(6)
		g.add_child(Gk.odznaka(str(STATUS[st][0]), STATUS[st][1]))
		if not bool(op.get("wkrotce", false)):
			g.add_child(Gk.odznaka("poz. %d" % int(op.get("poziom", 1))))
		kv.add_child(g)
		kh.add_child(kv)
		if st in ["wkrotce", "zablokowany"]:
			kh.add_child(Ikona.nowa("klodka", 22.0, Gk.PRZYG))
		elif st == "pokonany":
			kh.add_child(Ikona.nowa("ptaszek", 22.0, Gk.ZIELEN))
		Gk.do_karty(karta, kh)
		lista.add_child(karta[0])
	h.add_child(lewa)

	# ---- szczegóły szczebla
	var op := Data.arena_przeciwnik(sel)
	var st := Game.arena_status(sel)
	var prawa := Gk.vb(8)
	prawa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(prawa)
	var r2 := Gk.rama(14.0)
	r2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pv := Gk.vb(8)
	r2.add_child(Gk.przewijany(pv))
	prawa.add_child(r2)
	var g2 := Gk.hb(8)
	var t := Gk.tytul(str(op.get("nazwa", "")), 28)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g2.add_child(t)
	g2.add_child(Gk.odznaka(str(STATUS[st][0]), STATUS[st][1]))
	pv.add_child(g2)
	pv.add_child(Gk.pergamin(str(op.get("opis", ""))))
	if st == "wkrotce":
		pv.add_child(Gk.tekst("Ten szczebel jest jeszcze pusty. Kolejni przeciwnicy pojawią się w następnych wersjach gry.", 17, Gk.PRZYG))
	else:
		pv.add_child(Gk.naglowek("Skład przeciwnika", 20))
		pv.add_child(_sklad(op))
		var nag := Gk.hb(16)
		var pierwszy := not Game.arena_pokonany(sel)
		nag.add_child(Gk.gruby("Nagroda:", 16, Gk.ZLOTO))
		var kor := roundi(float(op.get("nagroda_korony", 0)) * (1.0 if pierwszy else float(Data.arena.get("powtorka_mnoznik", 0.25))))
		nag.add_child(Gk.waluta("korona", "%d%s" % [kor, "" if pierwszy else " (powtórka)"], Gk.ZLOTO_J, 16))
		if pierwszy and int(op.get("nagroda_klejnoty", 0)) > 0:
			nag.add_child(Gk.waluta("klejnot", "%d" % int(op["nagroda_klejnoty"]), Color(0.92, 0.36, 0.42), 16))
		pv.add_child(nag)
		var rek: Dictionary = Game.state["arena"]["rekordy"]
		var rt := Gk.tekst("Rekord: %.1f s" % float(rek[sel]) if rek.has(sel) else "Rekord: brak — wygraj, żeby zapisać czas.", 16, Gk.TEKST if rek.has(sel) else Gk.PRZYG, false)
		rt.name = "rekord_areny"
		pv.add_child(rt)
		pv.add_child(Gk.tekst("Na arenie nie strzelasz. Walczą tylko bohaterowie: ich aury, leczenie i czary działają same, Ultimate też odpalają się samoczynnie. Arena nie rani na stałe — nikt nie trafia do lazaretu.", 15, Gk.PRZYG))

	var dol := Gk.hb(10)
	var bd := Gk.przycisk("Drużyna areny  (%d/10)" % Game.w_formacji("arena").size(), func():
		if Game.w_formacji("arena").is_empty():
			Game.arena_auto()
		k.idz("formacja_areny", {"tryb": "arena"}), false, 0.0, 56.0, "formacja")
	bd.name = "btn_druzyna_areny"
	bd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dol.add_child(bd)
	var bw := Gk.przycisk("Do walki", func(): k.main.go("bitwa", {"arena": sel}), true, 260.0, 56.0, "miecze")
	bw.name = "btn_arena_start"
	bw.add_theme_font_override("font", Gk.f_tytul())
	bw.add_theme_font_size_override("font_size", 26)
	bw.disabled = not Game.arena_moze_walczyc(sel)
	if not Game.arena_odblokowana():
		bw.tooltip_text = "Arena jest zamknięta."
	elif Game.w_formacji("arena").is_empty():
		bw.tooltip_text = "Ustaw drużynę areny."
	dol.add_child(bw)
	prawa.add_child(dol)

## Szyk przeciwnika 2x5 widziany od strony gracza: przedni rząd po lewej (bliżej was), tylny po prawej.
static func _sklad(op: Dictionary) -> Control:
	var sklad: Array = op.get("sklad", [])
	var v := Gk.vb(4)
	var nag := Gk.hb(8)
	for tt in ["←  PRZEDNI RZĄD", "TYLNY RZĄD"]:
		var l := Gk.gruby(tt, 13, Gk.PRZYG)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nag.add_child(l)
	v.add_child(nag)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 4)
	for tor in Formation.RZAD:
		for pole in [tor, Formation.RZAD + tor]:
			var id := str(sklad[pole]) if pole < sklad.size() else ""
			g.add_child(_wrog(id, float(op.get("skala_hp", 1.0)), float(op.get("skala_obrazen", 1.0))))
	v.add_child(g)
	return v

static func _wrog(id: String, skala_hp: float, skala_obr: float) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Gk.sb(Color(0, 0, 0, 0.4), Gk.ZLOTO_C, 1, 4.0, 2))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, 44)
	var h := Gk.hb(8)
	p.add_child(h)
	if id == "":
		var l := Gk.tekst("puste pole", 14, Color(0.45, 0.4, 0.35), false)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(l)
		return p
	var def := Data.enemy(id)
	var ob := TextureRect.new()
	ob.custom_minimum_size = Vector2(36, 36)
	ob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ob.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ob.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var kl := Art.frames(str(def.get("grafika", "")), "idle", "west")
	if not kl.is_empty():
		ob.texture = kl[0]
	h.add_child(ob)
	var w := Gk.vb(0)
	w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var n := Gk.gruby(str(def.get("nazwa", id)), 15, Gk.TEKST)
	n.clip_text = true
	w.add_child(n)
	var atak: Dictionary = def.get("atak", {})
	var rodzaj := {"wrecz": "wręcz", "dystans": "dystans", "magia": "magia"}
	w.add_child(Gk.tekst("HP %d  ·  %s  ·  obr. %s" % [roundi(Wfrp.max_hp(def.get("profil", {})) * skala_hp), str(rodzaj.get(str(atak.get("typ", "wrecz")), "")),
		KW._liczba(float(atak.get("bron", 1.0)) * skala_obr)], 13, Gk.PRZYG, false))
	h.add_child(w)
	return p
