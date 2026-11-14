class_name KMisje
extends RefCounted
## 7. Lista misji i kampanii: status każdej misji (ukończona / dostępna / zablokowana) i postęp trudności.

static func status(adv_id: String) -> String:
	if Game.ukonczona(adv_id):
		return "ukonczona"
	return "dostepna" if Game.dostepna(adv_id, "normal") else "zablokowana"

static func odznaka_statusu(adv_id: String) -> Control:
	match status(adv_id):
		"ukonczona": return Gk.odznaka("Ukończona", Gk.ZIELEN)
		"dostepna": return Gk.odznaka("Dostępna", Gk.ZLOTO_J, Color(0.3, 0.06, 0.05, 0.8))
	return Gk.odznaka("Zablokowana", Gk.PRZYG)

static func wymaganie(adv_id: String) -> String:
	var wym := str(Data.adventure(adv_id).get("wymaga", ""))
	return "" if wym == "" else "Wymaga ukończenia: %s" % str(Data.adventure(wym).get("nazwa", wym))

static func buduj(k: BarracksScene, c: Control, _p: Dictionary) -> void:
	var v := Gk.vb(12)
	k.pelny(Gk.przewijany(v), c)
	for kamp in Data.campaigns():
		var lista: Array = kamp.get("przygody", [])
		var ukonczone := 0
		for id in lista:
			if Game.ukonczona(id):
				ukonczone += 1
		var r := Gk.rama(14.0)
		var rv := Gk.vb(10)
		r.add_child(rv)
		var g := Gk.hb(12)
		var t := Gk.tytul(str(kamp.get("nazwa", "")), 28)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(t)
		g.add_child(Gk.gruby("Misje: %d z %d" % [ukonczone, lista.size()], 17, Gk.ZLOTO))
		var pp := Gk.pasek_postepu(float(ukonczone) / maxf(lista.size(), 1.0), Gk.ZIELEN, 12.0)
		pp.custom_minimum_size = Vector2(160, 12)
		pp.size_flags_horizontal = Control.SIZE_SHRINK_END
		pp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		g.add_child(pp)
		rv.add_child(g)
		rv.add_child(Gk.tekst(str(kamp.get("opis", "")), 17, Gk.TEKST))
		var rzad := Gk.hb(12)
		rv.add_child(rzad)
		var nr := 0
		for id in lista:
			nr += 1
			rzad.add_child(_karta_misji(k, str(id), nr))
		v.add_child(r)
	v.add_child(Gk.tekst("Kolejne kampanie pojawią się w następnych wersjach gry.", 16, Gk.PRZYG))

static func _karta_misji(k: BarracksScene, id: String, nr: int) -> Control:
	var adv := Data.adventure(id)
	var st := status(id)
	var karta := Gk.karta(func(): k.idz("misja", {"id": id}), false, 12.0)
	var p: PanelContainer = karta[0]
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	karta[1].name = "misja_" + id
	if st == "zablokowana":
		p.modulate = Color(0.78, 0.76, 0.74)
	var v := Gk.vb(6)
	var g := Gk.hb(8)
	g.add_child(Gk.gruby("Misja %d" % nr, 15, Gk.PRZYG))
	g.add_child(Gk.rozpor())
	if st == "zablokowana":
		g.add_child(Ikona.nowa("klodka", 20.0, Gk.PRZYG))
	g.add_child(odznaka_statusu(id))
	v.add_child(g)
	var n := Gk.tytul(str(adv.get("nazwa", id)), 24, Gk.PRZYG if st == "zablokowana" else Gk.ZLOTO_J)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(n)
	# postęp trudności: trzy znaczniki
	var tr := Gk.hb(6)
	for t in Data.adventures.get("kolejnosc_trudnosci", ["normal"]):
		var zrobione := Game.ukonczona(id, t)
		var o := Gk.odznaka(KW.nazwa_trudnosci(t), Gk.ZIELEN if zrobione else (Gk.ZLOTO if Game.dostepna(id, t) else Color(0.4, 0.36, 0.32)))
		tr.add_child(o)
	v.add_child(tr)
	v.add_child(Gk.tekst(str(adv.get("opis", "")), 15, Gk.TEKST if st != "zablokowana" else Gk.PRZYG))
	var boss := ""
	var plansze: Array = adv.get("plansze", [])
	for b in plansze:
		for f in b.get("fale", []):
			for e in f.get("wrogowie", {}):
				if bool(Data.enemy(e).get("boss", false)):
					boss = str(Data.enemy(e).get("nazwa", e))
	v.add_child(Gk.tekst("Plansze: %d   ·   Boss: %s" % [plansze.size(), boss], 15, Gk.SZKARLAT_J))
	if st == "zablokowana":
		v.add_child(Gk.tekst(wymaganie(id), 15, Gk.SZKARLAT_J))
	else:
		v.add_child(Gk.waluta("korona", "Nagroda: %d koron" % int(adv.get("nagroda_korony", 0)), Gk.ZLOTO, 16))
	Gk.do_karty(karta, v)
	return p
