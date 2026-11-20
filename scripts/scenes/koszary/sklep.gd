class_name KSklep
extends RefCounted
## 10. Sklep: kram Gottfrieda Siegla. Po lewej kupiec, po prawej bieżąca dostawa -
## zawsze broń, pancerz i wstęga ochronna, plus kilka losowych okazji. Towar zmienia się po każdej misji.

static func buduj(k: BarracksScene, c: Control, _p: Dictionary) -> void:
	var cfg: Dictionary = Data.items.get("sklep", {})
	var kupiec: Dictionary = cfg.get("kupiec", {})
	var oferta := Game.sklep_oferta()
	var h: HBoxContainer = k.pelny(Gk.hb(14), c)

	# ---- kupiec
	var lewa := Gk.rama(12.0)
	lewa.custom_minimum_size = Vector2(350, 0)
	lewa.draw.connect(func(): Gk._ornament(lewa, Gk.ZLOTO))
	var lv := Gk.vb(8)
	lewa.add_child(lv)
	var tex := Gk.tekstura(str(kupiec.get("grafika", "")))
	if tex != null:
		var obraz := TextureRect.new()
		obraz.name = "kupiec"
		obraz.texture = tex
		obraz.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		obraz.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		obraz.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		obraz.size_flags_vertical = Control.SIZE_EXPAND_FILL
		obraz.custom_minimum_size = Vector2(0, 220)
		obraz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lv.add_child(obraz)
	else:
		lv.add_child(Gk.rozciagnij(Ikona.nowa("skrzynia", 120.0, Gk.ZLOTO_C), false, true))
	var imie := Gk.tytul(str(kupiec.get("imie", "Kupiec")), 26)
	imie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(imie)
	var tyt := Gk.tekst(str(kupiec.get("tytul", "")), 15, Gk.SZKARLAT_J, false)
	tyt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(tyt)
	var wszystko_kupione := true
	for id in oferta:
		if not Game.sklep_kupiony(str(id)):
			wszystko_kupione = false
	lv.add_child(Gk.pergamin(str(kupiec.get("wyprzedane" if wszystko_kupione else "powitanie", "")), 15))
	h.add_child(lewa)

	# ---- towar
	var prawa := Gk.rama(14.0)
	prawa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pv := Gk.vb(8)
	prawa.add_child(Gk.przewijany(pv))
	var g := Gk.hb(12)
	var dost := Gk.gruby("Dostawa nr %d" % Game.sklep_dostawa(), 18, Gk.ZLOTO_J)
	dost.name = "sklep_dostawa"
	g.add_child(dost)
	var info := Gk.tekst("Nowy towar po każdej misji. Kupione przedmioty czekają w magazynie — zakładasz je w Ekwipunku bohatera.", 15, Gk.PRZYG)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(info)
	pv.add_child(g)

	var stale: Array = cfg.get("stale", [])
	var na_kramie: Array = []
	var okazje: Array = []
	for id in oferta:
		(na_kramie if stale.has(str(Data.item(str(id)).get("slot", ""))) else okazje).append(str(id))
	pv.add_child(Gk.naglowek("Zawsze na kramie", 20))
	for id in na_kramie:
		pv.add_child(_pozycja(k, id))
	if not okazje.is_empty():
		pv.add_child(Gk.naglowek("Okazje z tej dostawy", 20))
		for id in okazje:
			pv.add_child(_pozycja(k, id))
	h.add_child(prawa)

## Jeden przedmiot na kramie: ikona, nazwa, cechy, dla kogo, cena i przycisk zakupu.
static func _pozycja(k: BarracksScene, item_id: String) -> Control:
	var it := Data.item(item_id)
	var kupiony := Game.sklep_kupiony(item_id)
	var cena := Game.cena(item_id)
	var stac := int(Game.state["korony"]) >= cena
	var kol: Color = Gk.RZADKOSC.get(str(it.get("rzadkosc", "common")), Gk.ZLOTO_C)
	var p := PanelContainer.new()
	p.name = "oferta_" + item_id
	p.add_theme_stylebox_override("panel", Gk.sb(Color(Gk.PANEL_J.r, Gk.PANEL_J.g, Gk.PANEL_J.b, 0.6 if kupiony else 0.95),
		Gk.ZLOTO_C if kupiony else kol.darkened(0.3), 2, 10.0, 3))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := Gk.hb(12)
	p.add_child(h)
	h.add_child(Ikona.nowa(str(it.get("slot", "")), 50.0, Gk.PRZYG if kupiony else kol))
	var v := Gk.vb(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gl := Gk.hb(8)
	var n := Gk.gruby(str(it.get("nazwa", item_id)), 19, Gk.PRZYG if kupiony else kol)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gl.add_child(n)
	gl.add_child(Gk.odznaka(str(Data.items.get("nazwy_slotow", {}).get(str(it.get("slot", "")), "")), Gk.ZLOTO_C if kupiony else Gk.ZLOTO))
	v.add_child(gl)
	v.add_child(Gk.tekst(KW.opis_cech(it), 16, Gk.PRZYG if kupiony else Gk.ZLOTO_J))
	v.add_child(Gk.tekst(_dla_kogo(it) + "  ·  " + str(it.get("opis", "")), 14, Gk.PRZYG))
	h.add_child(v)

	var pr := Gk.vb(4)
	pr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pr.custom_minimum_size = Vector2(150, 0)
	var c := Gk.waluta("korona", str(cena), Gk.PRZYG if (kupiony or not stac) else Gk.ZLOTO_J, 18)
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	pr.add_child(c)
	if kupiony:
		var od := Gk.odznaka("Kupione", Gk.ZIELEN)
		od.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pr.add_child(od)
	else:
		var b := Gk.przycisk("Kup", func():
			if Game.kup_przedmiot(item_id):
				Audio.play("coin")
				k.odswiez("Kupiono: %s. Czeka w magazynie — załóż go w Ekwipunku bohatera." % str(it.get("nazwa", ""))), stac, 150.0, 44.0, "korona")
		b.name = "btn_kup_" + item_id
		b.disabled = not stac
		if not stac:
			b.tooltip_text = "Brakuje %d koron" % (cena - int(Game.state["korony"]))
		pr.add_child(b)
	h.add_child(pr)
	return p

## "Dla wszystkich" albo imiona bohaterów, którzy mogą to nosić (nieobecni w Gwardii - w nawiasie).
static func _dla_kogo(it: Dictionary) -> String:
	var tylko: Array = it.get("tylko", [])
	if tylko.is_empty():
		return "Dla każdego"
	var imiona: Array = []
	for id in tylko:
		var im := str(Data.hero(str(id)).get("imie", id))
		imiona.append(im if Game.ma(str(id)) else "(%s)" % im)
	return "Dla: " + ", ".join(imiona)
