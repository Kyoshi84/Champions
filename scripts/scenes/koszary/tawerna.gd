class_name KTawerna
extends RefCounted
## 9. Tawerna „Złoty Prosiak”: lista bohaterów do zwerbowania -> szczegóły najemnika -> rekrutacja za korony.

static func _do_wynajecia() -> Array:
	var out: Array = []
	for id in Data.hero_ids():
		if not Game.ma(id) and str(Data.hero(id).get("odblokowanie", {}).get("typ", "")) == "sklep":
			out.append(str(id))
	return out

static func buduj(k: BarracksScene, c: Control, _p: Dictionary) -> void:
	var v: VBoxContainer = k.pelny(Gk.vb(12), c)
	v.add_child(Gk.pergamin("Karczmarz „Złotego Prosiaka” zna każdego, kto w Carroburgu szuka zajęcia dla miecza, łuku albo zaklęcia. Postaw kolejkę, połóż korony na stół — a ktoś się przysiądzie."))
	var lista := _do_wynajecia()
	if lista.is_empty():
		var r := Gk.rama(20.0)
		var rv := Gk.vb(10)
		r.add_child(rv)
		rv.add_child(Ikona.nowa("kufel", 64.0, Gk.ZLOTO_C))
		var t := Gk.tytul("Przy stołach pusto", 28)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rv.add_child(t)
		var o := Gk.tekst("Wszyscy, którzy szukali zajęcia, służą już w Gwardii. Nowi najemnicy pojawią się w kolejnych wersjach gry.", 17, Gk.PRZYG)
		o.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rv.add_child(o)
		v.add_child(r)
		return
	v.add_child(Gk.naglowek("Szukają zajęcia  (%d)" % lista.size()))
	var siatka := GridContainer.new()
	siatka.columns = 2
	siatka.add_theme_constant_override("h_separation", 12)
	siatka.add_theme_constant_override("v_separation", 12)
	v.add_child(Gk.przewijany(siatka))
	for id in lista:
		var def := Data.hero(id)
		var koszt := Game.koszt_zakupu(id)
		var stac := int(Game.state["korony"]) >= koszt
		var karta := Gk.karta(func(): k.idz("najemnik", {"id": id}), false, 12.0)
		karta[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		karta[1].name = "najemnik_" + id
		var h := Gk.hb(14)
		h.add_child(Gk.portret(id, Vector2(110, 110)))
		var w := Gk.vb(5)
		w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		w.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		w.add_child(Gk.tytul(str(def.get("imie", id)), 26))
		w.add_child(Gk.tekst(str(def.get("tytul", def.get("profesja", ""))), 16, Gk.SZKARLAT_J, false))
		var role := Gk.hb(6)
		for r in def.get("role", []):
			role.add_child(Gk.odznaka(str(r)))
		w.add_child(role)
		var cena := Gk.hb(10)
		cena.add_child(Gk.waluta("korona", "%d koron" % koszt, Gk.ZLOTO_J if stac else Gk.PRZYG, 18))
		cena.add_child(Gk.tekst("stać cię" if stac else "brakuje %d" % (koszt - int(Game.state["korony"])), 15, Gk.ZIELEN if stac else Gk.SZKARLAT_J, false))
		w.add_child(cena)
		h.add_child(w)
		h.add_child(Ikona.nowa("dalej", 26.0, Gk.ZLOTO_C))
		Gk.do_karty(karta, h)
		siatka.add_child(karta[0])

## Szczegóły najemnika i werbunek.
static func najemnik(k: BarracksScene, c: Control, p: Dictionary) -> void:
	var id := str(p.get("id", ""))
	var def := Data.hero(id)
	if def.is_empty():
		k.pelny(Gk.tekst("Nie ma takiego najemnika.", 20), c)
		return
	var h: HBoxContainer = k.pelny(Gk.hb(14), c)
	var lewa := Gk.rama(12.0)
	lewa.custom_minimum_size = Vector2(300, 0)
	var por := Gk.portret(id, Vector2(270, 360), "", true)
	por.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lewa.add_child(por)
	h.add_child(lewa)

	var prawa := Gk.vb(10)
	prawa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(prawa)
	var karta := Gk.rama(14.0)
	karta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prawa.add_child(karta)
	var v := Gk.vb(10)
	karta.add_child(Gk.przewijany(v))
	var g := Gk.hb(8)
	var t := Gk.tytul(str(def.get("tytul", def.get("profesja", ""))), 24, Gk.SZKARLAT_J)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(t)
	for r in def.get("role", []):
		g.add_child(Gk.odznaka(str(r)))
	v.add_child(g)
	v.add_child(Gk.pergamin(str(def.get("fabula", ""))))
	v.add_child(Gk.naglowek("Co wnosi do drużyny"))
	v.add_child(Gk.tekst(str(def.get("opis", "")), 17))
	v.add_child(Gk.naglowek("Statystyki na poziomie 1"))
	var cechy: Array = []
	for kc in KW.CECHY:
		cechy.append("%s %d" % [KW.cecha(kc), int(def.get("profil", {}).get(kc, 0))])
	v.add_child(Gk.tekst("    ".join(cechy), 17, Gk.ZLOTO_J))
	v.add_child(Gk.naglowek("Umiejętności"))
	for s in def.get("umiejetnosci", []):
		v.add_child(Gk.tekst("Poziom %d  ·  %s — %s" % [int(s.get("prog", 1)), str(s.get("nazwa", "")), str(s.get("opis", ""))], 16, Gk.TEKST))

	var dol := Gk.hb(12)
	var koszt := Game.koszt_zakupu(id)
	var info := Gk.tekst("", 16, Gk.PRZYG)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dol.add_child(info)
	var b := Gk.przycisk("Zwerbuj · %d koron" % koszt, func():
		if Game.kup(id):
			Audio.play("coin")
			k.stos.pop_back()
			k.idz("bohater", {"id": id})
			k.odswiez("%s dołącza do Szkarłatnej Gwardii.%s" % [str(def["imie"]),
				"" if Game.pole_bohatera(id) != -1 else " Czeka w rezerwie — w szyku nie ma wolnego miejsca."]), true, 340.0, 58.0, "korona")
	b.name = "btn_rekrutuj"
	b.add_theme_font_size_override("font_size", 20)
	if Game.ma(id):
		info.text = "Już służy w Gwardii."
		b.disabled = true
	elif not Game.moze_kupic(id):
		info.text = "Brakuje %d koron. Korony zdobywasz w misjach." % maxi(0, koszt - int(Game.state["korony"]))
		info.add_theme_color_override("font_color", Gk.SZKARLAT_J)
		b.disabled = true
	else:
		info.text = "Po werbunku trafi do szyku, jeśli jest wolne miejsce — inaczej do rezerwy."
	dol.add_child(b)
	prawa.add_child(dol)
