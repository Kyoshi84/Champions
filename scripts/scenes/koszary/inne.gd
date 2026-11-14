class_name KInne
extends RefCounted
## 10. Sklep (na razie zamknięty) i 11. Osiągnięcia.

static func sklep(k: BarracksScene, c: Control, _p: Dictionary) -> void:
	var srodek := CenterContainer.new()
	k.pelny(srodek, c)
	var r := Gk.rama(28.0)
	r.custom_minimum_size = Vector2(640, 0)
	var v := Gk.vb(12)
	r.add_child(v)
	v.add_child(Ikona.nowa("klodka", 84.0, Gk.ZLOTO_C))
	var t := Gk.tytul("Sklep jest zamknięty", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var o := Gk.tekst("Kupiec z Altdorfu utknął na trakcie — dopóki drogi są pełne Zwierzoludzi, kram stoi pusty.\nSklep zostanie otwarty w jednej z kolejnych wersji gry.", 18, Gk.TEKST)
	o.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(o)
	var kl := Gk.waluta("klejnot", "Twoje klejnoty: %d — poczekają na otwarcie." % int(Game.state["klejnoty"]), Color(0.92, 0.36, 0.42), 18)
	kl.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(kl)
	var b := Gk.przycisk("Wróć do Hubu", k.hub, false, 240.0, 50.0, "wstecz")
	b.name = "btn_sklep_hub"
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)
	srodek.add_child(r)

static func osiagniecia(k: BarracksScene, c: Control, _p: Dictionary) -> void:
	var v: VBoxContainer = k.pelny(Gk.vb(10), c)
	var wszystkie := Data.achievement_list()
	var zdobyte := 0
	for o in wszystkie:
		if Game.osiagniecie_zdobyte(o):
			zdobyte += 1
	var g := Gk.hb(12)
	g.add_child(Gk.gruby("Zdobyte: %d z %d" % [zdobyte, wszystkie.size()], 18, Gk.ZLOTO_J))
	var pp := Gk.pasek_postepu(float(zdobyte) / maxf(wszystkie.size(), 1.0), Gk.ZLOTO, 12.0)
	pp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	g.add_child(pp)
	g.add_child(Gk.tekst("Nagrody w klejnotach odbierasz ręcznie.", 16, Gk.PRZYG, false))
	v.add_child(g)
	var siatka := GridContainer.new()
	siatka.columns = 2
	siatka.add_theme_constant_override("h_separation", 12)
	siatka.add_theme_constant_override("v_separation", 10)
	v.add_child(Gk.przewijany(siatka))
	# najpierw do odebrania, potem w toku, na końcu odebrane
	var kolejnosc: Array = wszystkie.duplicate()
	var waga := func(o: Dictionary) -> int:
		if Game.osiagniecie_odebrane(str(o["id"])):
			return 2
		return 0 if Game.osiagniecie_zdobyte(o) else 1
	var indeks := {}
	for i in wszystkie.size():
		indeks[str(wszystkie[i]["id"])] = i
	kolejnosc.sort_custom(func(a, b):
		var wa: int = waga.call(a)
		var wb: int = waga.call(b)
		return wa < wb if wa != wb else int(indeks[str(a["id"])]) < int(indeks[str(b["id"])]))
	for o in kolejnosc:
		var oid := str(o["id"])
		var post := Game.osiagniecie_postep(o)
		var ma := int(post[0]) >= int(post[1])
		var odebrane := Game.osiagniecie_odebrane(oid)
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Gk.sb(Color(Gk.PANEL_J.r, Gk.PANEL_J.g, Gk.PANEL_J.b, 0.95),
			Gk.ZLOTO if (ma and not odebrane) else Gk.ZLOTO_C, 2, 10.0, 3))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := Gk.hb(12)
		p.add_child(h)
		h.add_child(Ikona.nowa("puchar", 46.0, Gk.ZLOTO_J if ma else Color(0.36, 0.32, 0.28)))
		var w := Gk.vb(3)
		w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		w.add_child(Gk.tytul(str(o.get("nazwa", "")), 22, Gk.ZLOTO_J if ma else Gk.PRZYG))
		w.add_child(Gk.tekst(str(o.get("opis", "")), 16, Gk.TEKST))
		var ph := Gk.hb(8)
		var pas := Gk.pasek_postepu(float(post[0]) / maxf(float(post[1]), 1.0), Gk.ZIELEN if ma else Gk.ZLOTO, 10.0)
		pas.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ph.add_child(pas)
		ph.add_child(Gk.gruby("%d / %d" % [int(post[0]), int(post[1])], 14, Gk.PRZYG))
		w.add_child(ph)
		h.add_child(w)
		var pr := Gk.vb(4)
		pr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var nag := Gk.waluta("klejnot", "+%d" % int(o.get("nagroda_klejnoty", 0)), Color(0.92, 0.36, 0.42), 17)
		nag.alignment = BoxContainer.ALIGNMENT_CENTER
		pr.add_child(nag)
		if odebrane:
			var od := Gk.odznaka("Odebrano", Gk.ZIELEN)
			od.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			pr.add_child(od)
		else:
			var b := Gk.przycisk("Odbierz", func():
				if Game.odbierz_osiagniecie(oid):
					Audio.play("coin")
					k.odswiez("Odebrano nagrodę (%s): klejnoty +%d." % [str(o.get("nazwa", "")), int(o.get("nagroda_klejnoty", 0))]), ma, 120.0, 42.0)
			b.name = "btn_odbierz_" + oid
			b.disabled = not ma
			pr.add_child(b)
		h.add_child(pr)
		siatka.add_child(p)
