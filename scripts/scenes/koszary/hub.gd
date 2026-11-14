class_name KHub
extends RefCounted
## 1. Główny Hub Koszar: sześć wejść do podekranów, skład w gotowości i skrót do misji. Żadnych szczegółów.

static func buduj(k: BarracksScene, c: Control, _p: Dictionary) -> void:
	var v: VBoxContainer = k.pelny(Gk.vb(12), c)
	var siatka := GridContainer.new()
	siatka.columns = 3
	siatka.add_theme_constant_override("h_separation", 14)
	siatka.add_theme_constant_override("v_separation", 14)
	siatka.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(siatka)

	var ranni := 0
	var polegli := 0
	for id in Game.state["bohaterowie"]:
		if Game.polegly(id):
			polegli += 1
		elif Game.ranny(id):
			ranni += 1
	var druzyna := "Bohaterowie w Gwardii: %d" % Game.state["bohaterowie"].size()
	var uwaga := ""
	if ranni + polegli > 0:
		uwaga = ("Ranni: %d" % ranni if ranni > 0 else "") + ("  ·  " if ranni > 0 and polegli > 0 else "") + ("W lazarecie: %d" % polegli if polegli > 0 else "")
	_kafel(k, siatka, "druzyna", "miecze", "Drużyna", druzyna, uwaga, Gk.SZKARLAT_J)
	_kafel(k, siatka, "formacja", "formacja", "Formacja", "W szyku %d z %d miejsc" % [Game.w_formacji().size(), Game.miejsca()],
		"Wolne miejsce w szyku" if Game.w_formacji().size() < mini(Game.miejsca(), Game.state["bohaterowie"].size()) else "", Gk.ZLOTO_J)

	var ukonczone := 0
	var nastepna := ""
	for id in Data.adventure_ids():
		if Game.ukonczona(id):
			ukonczone += 1
		elif nastepna == "" and Game.dostepna(id, "normal"):
			nastepna = str(Data.adventure(id).get("nazwa", id))
	_kafel(k, siatka, "misje", "zwoj", "Misje", "Ukończone %d z %d" % [ukonczone, Data.adventure_ids().size()],
		"Następna: %s" % nastepna if nastepna != "" else "", Gk.ZLOTO_J)

	var do_wynajecia := 0
	for id in Data.hero_ids():
		if not Game.ma(id) and str(Data.hero(id).get("odblokowanie", {}).get("typ", "")) == "sklep":
			do_wynajecia += 1
	_kafel(k, siatka, "tawerna", "kufel", "Tawerna „Złoty Prosiak”", "Rekrutacja bohaterów",
		"Do zwerbowania: %d" % do_wynajecia if do_wynajecia > 0 else "Wszyscy już w Gwardii", Gk.ZLOTO_J if do_wynajecia > 0 else Gk.PRZYG)
	_kafel(k, siatka, "sklep", "skrzynia", "Sklep", "Zamknięty", "Kupiec jeszcze nie dotarł", Gk.PRZYG, true)
	var do_odebrania := Game.osiagniecia_do_odebrania()
	var zdobyte := 0
	for o in Data.achievement_list():
		if Game.osiagniecie_zdobyte(o):
			zdobyte += 1
	_kafel(k, siatka, "osiagniecia", "puchar", "Osiągnięcia", "Zdobyte %d z %d" % [zdobyte, Data.achievement_list().size()],
		"Nagrody do odebrania: %d" % do_odebrania if do_odebrania > 0 else "", Gk.ZIELEN)

	# skład w gotowości: tylko portret, imię i zdrowie - reszta na ekranie bohatera
	var sklad := Gk.rama(10.0)
	var sv := Gk.vb(6)
	sklad.add_child(sv)
	sv.add_child(Gk.naglowek("Drużyna w szyku  (%d/%d)" % [Game.w_formacji().size(), Game.miejsca()], 20))
	var sh := Gk.hb(10)
	var przew := ScrollContainer.new()
	przew.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	przew.custom_minimum_size = Vector2(0, 84)
	przew.add_child(sh)
	sv.add_child(przew)
	for id in Game.w_formacji():
		var karta := KW.karta_bohatera(k, id, func(): k.idz("bohater", {"id": id}), false, 62.0, true)
		karta[0].custom_minimum_size = Vector2(286, 0)
		karta[1].name = "sklad_" + id
		sh.add_child(karta[0])
	if Game.w_formacji().is_empty():
		sh.add_child(Gk.tekst("Szyk jest pusty. Ustaw bohaterów na ekranie Formacji.", 17, Gk.PRZYG, false))
	v.add_child(sklad)

	var dol := Gk.hb(12)
	var menu := Gk.przycisk("Powrót do głównego menu", func(): k.main.go("menu"), false, 290.0, 54.0, "wstecz")
	menu.name = "btn_menu"
	dol.add_child(menu)
	var info := Gk.tekst("Zarządzaj drużyną i przygotuj się do kolejnej przygody.", 16, Gk.PRZYG, false)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.clip_text = true
	dol.add_child(info)
	var start := Gk.przycisk("Wybierz misję", func(): k.idz("misje"), true, 340.0, 54.0, "miecze")
	start.name = "btn_misje"
	start.add_theme_font_override("font", Gk.f_tytul())
	start.add_theme_font_size_override("font_size", 26)
	dol.add_child(start)
	v.add_child(dol)

static func _kafel(k: BarracksScene, do: Control, ekran: String, ikona: String, tytul: String, opis: String, uwaga: String, kolor_uwagi: Color, zamkniety: bool = false) -> void:
	var karta := Gk.karta(func(): k.idz(ekran), false, 14.0)
	var p: PanelContainer = karta[0]
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.draw.connect(func(): Gk._ornament(p, Gk.ZLOTO_C if zamkniety else Gk.ZLOTO))
	karta[1].name = "kafel_" + ekran
	var h := Gk.hb(16)
	var ik := Ikona.nowa(ikona, 66.0, Gk.PRZYG if zamkniety else Gk.ZLOTO)
	h.add_child(ik)
	var v := Gk.vb(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var t := Gk.tytul(tytul, 28, Gk.PRZYG if zamkniety else Gk.ZLOTO_J)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	v.add_child(Gk.tekst(opis, 17, Gk.TEKST))
	if uwaga != "":
		v.add_child(Gk.tekst(uwaga, 16, kolor_uwagi))
	h.add_child(v)
	if zamkniety:
		h.add_child(Ikona.nowa("klodka", 34.0, Gk.PRZYG))
	Gk.do_karty(karta, h)
	do.add_child(p)
