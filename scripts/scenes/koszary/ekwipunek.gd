class_name KEkwipunek
extends RefCounted
## 5. Ekwipunek: sześć slotów po lewej, po prawej tylko wybrany slot - założony przedmiot i pasujące z magazynu.

static func buduj(k: BarracksScene, c: Control, p: Dictionary) -> void:
	var id := str(p.get("id", ""))
	if not Game.ma(id):
		k.pelny(Gk.tekst("Tego bohatera nie ma w Gwardii.", 20), c)
		return
	var def := Data.hero(id)
	var sloty: Array = Data.items.get("sloty", [])
	var nazwy: Dictionary = Data.items.get("nazwy_slotow", {})
	var ekw := Game.ekwipunek(id)
	var sel := str(p.get("slot", sloty[0] if not sloty.is_empty() else ""))
	var h: HBoxContainer = k.pelny(Gk.hb(14), c)

	# ---- sloty
	var lewa := Gk.rama(14.0)
	lewa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lv := Gk.vb(10)
	lewa.add_child(lv)
	var gh := Gk.hb(12)
	gh.add_child(Gk.portret(id, Vector2(64, 64), Gk.stan_bohatera(id)))
	var gv := Gk.vb(0)
	gv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gv.add_child(Gk.tytul(str(def["imie"]), 26))
	gv.add_child(Gk.tekst("Założone %d z %d   ·   przedmioty w magazynie: %d" % [ekw.size(), sloty.size(), Game.state["magazyn"].size()], 16, Gk.PRZYG, false))
	gh.add_child(gv)
	lv.add_child(gh)
	var siatka := GridContainer.new()
	siatka.columns = 2
	siatka.add_theme_constant_override("h_separation", 10)
	siatka.add_theme_constant_override("v_separation", 10)
	siatka.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(siatka)
	for slot in sloty:
		var it := Data.item(str(ekw.get(slot, "")))
		var pasujace := _pasujace(id, slot).size()
		var karta := Gk.karta(func():
			p["slot"] = slot
			k.odswiez(), slot == sel, 10.0)
		karta[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		karta[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
		karta[1].name = "slot_" + str(slot)
		var sh := Gk.hb(10)
		var kol: Color = Gk.RZADKOSC.get(str(it.get("rzadkosc", "")), Gk.ZLOTO_C)
		sh.add_child(Ikona.nowa(str(slot), 44.0, kol))
		var sv := Gk.vb(1)
		sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sv.add_child(Gk.tekst(str(nazwy.get(slot, slot)), 14, Gk.PRZYG, false))
		var n := Gk.gruby(str(it.get("nazwa", "— pusty —")), 17, kol if not it.is_empty() else Gk.PRZYG)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sv.add_child(n)
		if not it.is_empty():
			sv.add_child(Gk.tekst(KW.opis_cech(it), 14, Gk.TEKST))
		sh.add_child(sv)
		if pasujace > 0:
			sh.add_child(Gk.odznaka("+%d" % pasujace, Gk.ZIELEN))
		Gk.do_karty(karta, sh)
		siatka.add_child(karta[0])
	h.add_child(lewa)

	# ---- wybrany slot
	var prawa := Gk.rama(14.0)
	prawa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pv := Gk.vb(10)
	prawa.add_child(Gk.przewijany(pv))
	pv.add_child(Gk.naglowek(str(nazwy.get(sel, sel)), 24))
	var obecny := Data.item(str(ekw.get(sel, "")))
	if obecny.is_empty():
		pv.add_child(Gk.tekst("Slot jest pusty.", 17, Gk.PRZYG))
	else:
		var zd := Gk.przycisk("Zdejmij", func():
			if Game.zdejmij_przedmiot(id, sel):
				k.odswiez(), false, 130.0, 44.0)
		zd.name = "btn_zdejmij"
		pv.add_child(_przedmiot(obecny, "Założony", zd))
	pv.add_child(Gk.naglowek("Pasujące w magazynie", 20))
	var lista := _pasujace(id, sel)
	if lista.is_empty():
		pv.add_child(Gk.tekst("Brak pasujących przedmiotów. Łup wypada z bossów na końcu każdej przygody — im wyższa trudność, tym częściej warto wracać.", 17, Gk.PRZYG))
	for item_id in lista:
		var zb := Gk.przycisk("Załóż", func():
			if Game.zaloz(id, item_id):
				Audio.play("ui_click")
				k.odswiez(), true, 130.0, 44.0)
		zb.name = "btn_zaloz_" + str(item_id)
		pv.add_child(_przedmiot(Data.item(item_id), "", zb))
	h.add_child(prawa)

static func _pasujace(hero_id: String, slot: String) -> Array:
	var out: Array = []
	for m in Game.state["magazyn"]:
		if Game.pasuje(str(m), hero_id, slot):
			out.append(str(m))
	return out

static func _przedmiot(it: Dictionary, etykieta: String, akcja: Button) -> Control:
	var p := PanelContainer.new()
	var kol: Color = Gk.RZADKOSC.get(str(it.get("rzadkosc", "common")), Gk.ZLOTO_C)
	p.add_theme_stylebox_override("panel", Gk.sb(Color(0, 0, 0, 0.4), kol.darkened(0.3), 2, 10.0, 2))
	var h := Gk.hb(12)
	p.add_child(h)
	h.add_child(Ikona.nowa(str(it.get("slot", "")), 40.0, kol))
	var v := Gk.vb(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var g := Gk.hb(8)
	var n := Gk.gruby(str(it.get("nazwa", "")), 18, kol)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(n)
	if etykieta != "":
		g.add_child(Gk.odznaka(etykieta, Gk.ZIELEN))
	g.add_child(Gk.odznaka(str(Gk.RZADKOSC_NAZWA.get(str(it.get("rzadkosc", "common")), "")), kol))
	v.add_child(g)
	v.add_child(Gk.tekst(KW.opis_cech(it), 16, Gk.TEKST))
	v.add_child(Gk.tekst(str(it.get("opis", "")), 15, Gk.PRZYG))
	h.add_child(v)
	akcja.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(akcja)
	return p
