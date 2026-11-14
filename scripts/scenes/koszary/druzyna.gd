class_name KDruzyna
extends RefCounted
## 2. Lista bohaterów (roster): portret, imię, poziom, HP z paskiem, ranni i polegli. Dotknięcie otwiera bohatera.

static func buduj(k: BarracksScene, c: Control, _p: Dictionary) -> void:
	var v: VBoxContainer = k.pelny(Gk.vb(10), c)
	var gora := Gk.hb(12)
	var opis := Gk.tekst("Bohaterowie w Gwardii: %d.  Miejsca w szyku: %d z %d  (kolejne dwa za każdą pierwszą ukończoną przygodę, najwyżej %d)." % [
		Game.state["bohaterowie"].size(), Game.w_formacji().size(), Game.miejsca(), int(Data.balance.get("progresja", {}).get("miejsca_max", 10))], 17, Gk.TEKST)
	opis.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gora.add_child(opis)
	var f := Gk.przycisk("Formacja", func(): k.idz("formacja"), false, 190.0, 48.0, "formacja")
	f.name = "btn_formacja"
	gora.add_child(f)
	v.add_child(gora)

	var siatka := GridContainer.new()
	siatka.columns = 3 if k.get_viewport_rect().size.x >= 1500.0 else 2
	siatka.add_theme_constant_override("h_separation", 12)
	siatka.add_theme_constant_override("v_separation", 12)
	v.add_child(Gk.przewijany(siatka))
	for id in Data.hero_ids():
		if not Game.ma(id):
			continue
		var karta := KW.karta_bohatera(k, id, func(): k.idz("bohater", {"id": id}))
		karta[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		karta[1].name = "bohater_" + id
		siatka.add_child(karta[0])
	# bohaterowie, których jeszcze nie ma - prowadzą do Tawerny
	for id in Data.hero_ids():
		if Game.ma(id) or str(Data.hero(id).get("odblokowanie", {}).get("typ", "")) != "sklep":
			continue
		var def := Data.hero(id)
		var karta := Gk.karta(func(): k.idz("najemnik", {"id": id}), false, 10.0)
		karta[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		karta[0].modulate = Color(1, 1, 1, 0.72)
		karta[1].name = "wolny_" + id
		var h := Gk.hb(12)
		h.add_child(Gk.portret(id, Vector2(84, 84), "polegly"))
		var w := Gk.vb(4)
		w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		w.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		w.add_child(Gk.tytul(str(def.get("imie", id)), 24, Gk.PRZYG))
		w.add_child(Gk.tekst("Czeka w Tawernie „Złoty Prosiak”", 16, Gk.TEKST, false))
		w.add_child(Gk.waluta("korona", "Werbunek: %d koron" % Game.koszt_zakupu(id), Gk.ZLOTO, 16))
		h.add_child(w)
		h.add_child(Ikona.nowa("kufel", 36.0, Gk.ZLOTO_C))
		Gk.do_karty(karta, h)
		siatka.add_child(karta[0])
