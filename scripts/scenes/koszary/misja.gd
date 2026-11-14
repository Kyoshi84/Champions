class_name KMisja
extends RefCounted
## 8. Szczegóły misji: opis, plansze i wrogowie po lewej; wybór trudności z nagrodami, rekord Hardcore i start po prawej.

static func buduj(k: BarracksScene, c: Control, p: Dictionary) -> void:
	var id := str(p.get("id", ""))
	var adv := Data.adventure(id)
	if adv.is_empty():
		k.pelny(Gk.tekst("Nie ma takiej misji.", 20), c)
		return
	var kolejnosc: Array = Data.adventures.get("kolejnosc_trudnosci", ["normal"])
	var tr := str(p.get("trudnosc", ""))
	if tr == "":
		tr = str(kolejnosc[0])
		for t in kolejnosc:          # domyślnie: pierwsza dostępna, jeszcze nieukończona
			if Game.dostepna(id, t) and not Game.ukonczona(id, t):
				tr = str(t)
				break
		p["trudnosc"] = tr
	var plansze: Array = adv.get("plansze", [])
	var h: HBoxContainer = k.pelny(Gk.hb(14), c)

	# ---- opis misji
	var lewa := Gk.rama(14.0)
	lewa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lv := Gk.vb(10)
	lewa.add_child(Gk.przewijany(lv))
	var g := Gk.hb(8)
	g.add_child(KMisje.odznaka_statusu(id))
	g.add_child(Gk.odznaka("Plansze: %d" % plansze.size()))
	lv.add_child(g)
	lv.add_child(Gk.pergamin(str(adv.get("opis", ""))))
	var wym := KMisje.wymaganie(id)
	if wym != "":
		lv.add_child(Gk.tekst(wym, 17, Gk.ZIELEN if Game.dostepna(id, "normal") else Gk.SZKARLAT_J))
	lv.add_child(Gk.naglowek("Plansze"))
	var wrogowie: Array = []
	var boss := ""
	for i in plansze.size():
		var b: Dictionary = plansze[i]
		var cel := "Pokonaj wszystkich"
		match str(b.get("cel", "")):
			"zabij_bossa": cel = "Pokonaj bossa"
			"przetrwaj": cel = "Przetrwaj %d s" % int(b.get("czas", 30))
			"zbierz_lup": cel = "Zbierz łup: %d" % int(b.get("ile", 5))
		var wiersz := Gk.hb(8)
		wiersz.add_child(Gk.gruby("%d." % (i + 1), 17, Gk.SZKARLAT_J if bool(b.get("boss", false)) else Gk.ZLOTO))
		var nazwa := Gk.tekst(str(b.get("opis", "Plansza %d" % (i + 1))), 17, Gk.TEKST)
		wiersz.add_child(nazwa)
		wiersz.add_child(Gk.odznaka(cel, Gk.SZKARLAT_J if bool(b.get("boss", false)) else Gk.PRZYG))
		lv.add_child(wiersz)
		for f in b.get("fale", []):
			for e in f.get("wrogowie", {}):
				var en := str(Data.enemy(e).get("nazwa", e))
				if bool(Data.enemy(e).get("boss", false)):
					boss = en
				elif not wrogowie.has(en):
					wrogowie.append(en)
	lv.add_child(Gk.naglowek("Wrogowie"))
	lv.add_child(Gk.tekst(",  ".join(wrogowie), 17, Gk.TEKST))
	if boss != "":
		lv.add_child(Gk.tekst("Boss: %s" % boss, 18, Gk.SZKARLAT_J))
	h.add_child(lewa)

	# ---- trudność, nagrody, rekord, start
	var prawa := Gk.vb(8)
	prawa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(prawa)
	var lista := Gk.vb(8)
	var przew := Gk.przewijany(lista)
	prawa.add_child(przew)
	lista.add_child(Gk.naglowek("Poziom trudności"))
	for t in kolejnosc:
		lista.add_child(_karta_trudnosci(k, p, id, str(t), tr == str(t)))
	# rekord czasowy Hardcore
	var rek := Gk.rama(10.0)
	var rh := Gk.hb(10)
	rek.add_child(rh)
	rh.add_child(Ikona.nowa("zegar", 30.0, Gk.ZLOTO))
	var r := Game.rekord(id)
	var rt := Gk.tekst("", 16, Gk.TEKST)
	if r.is_empty():
		rt.text = "Rekord Hardcore: brak. Pokonaj bossa na Hardcore, żeby zapisać czas."
		rt.add_theme_color_override("font_color", Gk.PRZYG)
	else:
		var sklad: Array = []
		for hid in r.get("sklad", []):
			sklad.append(str(Data.hero(str(hid)).get("imie", hid)))
		rt.text = "Rekord Hardcore (plansza z bossem): %.1f s  —  %s" % [float(r.get("czas", 0.0)), ", ".join(sklad)]
	rt.name = "rekord"
	rh.add_child(rt)
	lista.add_child(rek)

	var dol := Gk.hb(10)
	var powod := ""
	if not Game.dostepna(id, tr):
		powod = "Ten poziom trudności jest jeszcze zablokowany."
	elif Game.w_formacji().is_empty():
		powod = "Szyk jest pusty — ustaw bohaterów w Formacji."
	elif Game.gotowi() == 0:
		powod = "Cała drużyna leży w lazarecie."
	var info := Gk.tekst(powod if powod != "" else "Wyrusza bohaterów z szyku: %d." % Game.gotowi(), 16, Gk.SZKARLAT_J if powod != "" else Gk.PRZYG)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dol.add_child(info)
	var start := Gk.przycisk("Rozpocznij misję", func(): k.wyrusz(id, str(p.get("trudnosc", "normal"))), true, 320.0, 58.0, "miecze")
	start.name = "btn_start"
	start.add_theme_font_override("font", Gk.f_tytul())
	start.add_theme_font_size_override("font_size", 26)
	start.disabled = powod != ""
	dol.add_child(start)
	prawa.add_child(dol)

static func _karta_trudnosci(k: BarracksScene, p: Dictionary, id: String, t: String, wybrana: bool) -> Control:
	var adv := Data.adventure(id)
	var d := Data.difficulty(t)
	var dostepna := Game.dostepna(id, t)
	var zrobiona := Game.ukonczona(id, t)
	var karta := Gk.karta(func():
		p["trudnosc"] = t
		k.odswiez(), wybrana, 10.0)
	karta[1].name = "trudnosc_" + t
	if not dostepna:
		karta[0].modulate = Color(0.75, 0.73, 0.71)
	var v := Gk.vb(4)
	var g := Gk.hb(8)
	var n := Gk.tytul(str(d.get("nazwa", t)), 24, Gk.ZLOTO_J if dostepna else Gk.PRZYG)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(n)
	if float(d.get("limit_czasu", 0)) > 0.0:
		g.add_child(Gk.odznaka("limit %d s na planszę" % int(d["limit_czasu"]), Gk.SZKARLAT_J))
	if zrobiona:
		g.add_child(Gk.odznaka("Ukończona", Gk.ZIELEN))
	elif dostepna:
		g.add_child(Gk.odznaka("Dostępna", Gk.ZLOTO_J, Color(0.3, 0.06, 0.05, 0.8)))
	else:
		g.add_child(Ikona.nowa("klodka", 20.0, Gk.PRZYG))
		g.add_child(Gk.odznaka("Zablokowana", Gk.PRZYG))
	v.add_child(g)
	v.add_child(Gk.tekst("Wrogowie: życie ×%s,  obrażenia ×%s,  liczebność ×%s" % [KW._liczba(float(d.get("hp", 1))), KW._liczba(float(d.get("obrazenia", 1))),
		KW._liczba(float(d.get("liczba", 1)))], 15, Gk.PRZYG))
	# nagrody
	var baza := float(adv.get("nagroda_korony", 0)) * float(d.get("zloto", 1.0))
	var nag := Gk.hb(14)
	nag.add_child(Gk.waluta("korona", ("%d" % roundi(baza * 0.25) + " (powtórka)") if zrobiona else "%d" % roundi(baza), Gk.ZLOTO_J, 16))
	if int(d.get("klejnoty_za_bossa", 0)) > 0:
		nag.add_child(Gk.waluta("klejnot", "%d" % int(d["klejnoty_za_bossa"]), Color(0.92, 0.36, 0.42), 16))
	nag.add_child(Gk.waluta("skrzynia", "łup z bossa", Gk.ZLOTO, 16))
	if not zrobiona:
		nag.add_child(Gk.gruby("Favor +%d%%" % roundi(float(Data.balance.get("ekonomia", {}).get("favor_za_przygode", 0.05)) * 100.0), 16, Gk.ZLOTO))
	v.add_child(nag)
	if not dostepna:
		var kol: Array = Data.adventures.get("kolejnosc_trudnosci", [])
		var i := kol.find(t)
		var wym := KMisje.wymaganie(id) if not Game.dostepna(id, "normal") else "Odblokowanie: ukończ tę misję na poziomie %s." % KW.nazwa_trudnosci(str(kol[maxi(i - 1, 0)]))
		v.add_child(Gk.tekst(wym, 15, Gk.SZKARLAT_J))
	Gk.do_karty(karta, v)
	return karta[0]
