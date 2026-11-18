class_name KBohater
extends RefCounted
## 3. Karta postaci - wzorowana na papierowej karcie WFRP, rozłożona na ekran komputera w trzech kolumnach.
## Strona I:  Postać, Szczegóły osobiste, Profil postaci | logo, Wyposażenie (punkty trafienia jak „Armour Points”) |
##            Służba, Doświadczenie, Walka, Podsumowanie zdolności.
## Strona II: Historia i Rola w drużynie | ta sama środkowa kolumna | Umiejętności i talenty, Specjalizacja.
## Trening, ekwipunek i formacja to osobne ekrany - karta tylko do nich prowadzi.

## Sloty wyposażenia rozstawione wokół postaci jak lokacje trafień na karcie (z rzutami k100 dla klimatu).
const LEWE := [["helm", "01–15"], ["bron", "16–35"], ["rekawice", "81–90"]]
const PRAWE := [["zbroja", "56–80"], ["dodatek", "36–55"], ["amulet", "91–00"]]
const RODZAJ_ATAKU := {"wrecz": "Wręcz", "dystans": "Dystansowy", "magia": "Magiczny"}

static func buduj(k: BarracksScene, c: Control, p: Dictionary) -> void:
	var id := str(p.get("id", ""))
	if not Game.ma(id):
		k.pelny(Gk.tekst("Tego bohatera nie ma w Gwardii.", 20), c)
		return
	var strona := int(p.get("strona", 1))
	var kolumny := Gk.hb(12)
	kolumny.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var przew := Gk.przewijany(kolumny)
	k.pelny(przew, c)
	var lewa := Gk.vb(6)
	var srodek := Gk.vb(6)
	var prawa := Gk.vb(6)
	for kol in [[lewa, 1.0, 340.0], [srodek, 1.08, 360.0], [prawa, 1.0, 340.0]]:
		var v: VBoxContainer = kol[0]
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.size_flags_stretch_ratio = kol[1]
		v.custom_minimum_size = Vector2(kol[2], 0)
		kolumny.add_child(v)
	if strona == 2:
		_historia(lewa, id)
		_talenty(prawa, id)
	else:
		_postac(lewa, id)
		_sluzba(k, prawa, id)
	_srodek(k, srodek, p, id)
	var b := Gk.przycisk("Strona I: profil" if strona == 2 else "Strona II: historia i talenty", func():
		p["strona"] = 1 if strona == 2 else 2
		k.odswiez(), false, 0.0, 40.0, "wstecz" if strona == 2 else "ksiega")
	b.name = "btn_strona"
	prawa.add_child(b)

# ---------------------------------------------------------------- lewa kolumna, strona I
static func _postac(v: VBoxContainer, id: String) -> void:
	var def := Data.hero(id)
	var kd: Dictionary = def.get("karta", {})
	var s1 := KKarta.sekcja("Postać")
	s1[1].add_child(KKarta.pole("Imię", str(def.get("imie", id)), Gk.ZLOTO_J, 18))
	s1[1].add_child(KKarta.pole("Rasa", str(kd.get("rasa", "—"))))
	s1[1].add_child(KKarta.pole("Obecna profesja", str(def.get("tytul", def.get("profesja", "")))))
	s1[1].add_child(KKarta.pole("Poprzednia profesja", str(kd.get("profesja_poprzednia", "—"))))
	v.add_child(s1[0])

	var s2 := KKarta.sekcja("Szczegóły osobiste")
	s2[1].add_child(KKarta.dwa_pola(KKarta.pole("Wiek", str(kd.get("wiek", "—"))), KKarta.pole("Płeć", str(kd.get("plec", "—")))))
	s2[1].add_child(KKarta.dwa_pola(KKarta.pole("Oczy", str(kd.get("oczy", "—"))), KKarta.pole("Waga", str(kd.get("waga", "—")))))
	s2[1].add_child(KKarta.dwa_pola(KKarta.pole("Włosy", str(kd.get("wlosy", "—"))), KKarta.pole("Wzrost", str(kd.get("wzrost", "—")))))
	s2[1].add_child(KKarta.dwa_pola(KKarta.pole("Znak gwiezdny", str(kd.get("znak", "—"))), KKarta.pole("Rodzeństwo", str(kd.get("rodzenstwo", "—")))))
	s2[1].add_child(KKarta.pole("Miejsce urodzenia", str(kd.get("urodzony", "—"))))
	s2[1].add_child(KKarta.pole("Znaki szczególne", str(kd.get("znaki", "—"))))
	v.add_child(s2[0])

	var s3 := KKarta.sekcja("Profil postaci", 6)
	s3[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	var start := Progression.zbuduj(def, 1, "", {})
	var akt := Game.zestaw(id)
	var c0: Dictionary = start["cechy"]
	var c1: Dictionary = akt["cechy"]
	var glowne: Array = []
	for kc in ["WW", "US", "K", "Odp", "Zr", "Int", "SW", "Op", "CP", "Ogd"]:
		glowne.append([KW.cecha(kc), str(KW.CECHY_OPIS[kc]), roundf(float(c0.get(kc, 0))), roundf(float(c1.get(kc, 0))), "%d", true])
	s3[1].add_child(KKarta.tabela_profilu("Główne", glowne))
	var typ := str(def.get("atak", {}).get("typ", "wrecz"))
	var czas := float(def.get("atak", {}).get("czas", 5.0))
	var dodatkowe := [
		["Żyw", "Żywotność", float(c0.get("Zyw", 0)), float(c1.get("Zyw", 0)), "%.1f", true],
		["HP", "Punkty życia = Żyw × 10", roundf(Wfrp.max_hp(c0)), roundf(Wfrp.max_hp(c1)), "%d", true],
		["S", "Siła = K / 10, dodawana do obrażeń", Wfrp.sila(c0), Wfrp.sila(c1), "%.1f", true],
		["Sz", "Szybkość: cykl ataku = czas broni × 4 / Sz", roundf(float(c0.get("Sz", 4))), roundf(float(c1.get("Sz", 4))), "%d", true],
		["A", "Ataki: ciosów w jednym cyklu", float(Wfrp.ataki(c0)), float(Wfrp.ataki(c1)), "%d", true],
		["Panc.", "Pancerz = Wt + zbroja; zatrzymuje ten procent obrażeń fizycznych",
			roundf(Wfrp.redukcja(Wfrp.pancerz(c0, float(start["pancerz"]))) * 100.0), roundf(Wfrp.redukcja(Wfrp.pancerz(c1, float(akt["pancerz"]))) * 100.0), "%d%%", true],
		["Kryt.", "Szansa krytyka (%s/3)" % Wfrp.cecha_krytyka(typ), roundf(Wfrp.szansa_krytyka(typ, c0) * 100.0), roundf(Wfrp.szansa_krytyka(typ, c1) * 100.0), "%d%%", true],
		["×Kryt", "Siła krytyka = 1,5 + Zr/100", Wfrp.sila_krytyka(c0), Wfrp.sila_krytyka(c1), "%.2f", true],
		["Cykl", "Sekundy między cyklami ataku (mniej = szybciej)", Wfrp.czas_ataku(czas, c0), Wfrp.czas_ataku(float(akt["atak"].get("czas", czas)), c1), "%.1f", false]]
	s3[1].add_child(KKarta.tabela_profilu("Dodatkowe", dodatkowe))
	v.add_child(s3[0])

# ---------------------------------------------------------------- prawa kolumna, strona I
static func _sluzba(k: BarracksScene, v: VBoxContainer, id: String) -> void:
	var def := Data.hero(id)
	var z := Game.zestaw(id)
	var s1 := KKarta.sekcja("Służba")
	var kamp := "—"
	for kp in Data.campaigns():
		kamp = str(kp.get("nazwa", "—"))
		var reszta := kamp.split(": ", false, 1)
		if reszta.size() == 2:
			kamp = reszta[1]
		break
	s1[1].add_child(KKarta.dwa_pola(KKarta.pole("Kampania", kamp), KKarta.pole("Rok", "2522 KI")))
	s1[1].add_child(KKarta.pole("Rola", ", ".join(def.get("role", []))))
	var szyk := Gk.hb(8)
	szyk.add_child(KKarta.pole("Miejsce w szyku", KW.miejsce(id), Gk.ZLOTO if Game.pole_bohatera(id) != -1 else Gk.PRZYG))
	var bf := Gk.przycisk("Formacja", func(): k.idz("formacja", {"sel": id}), false, 128.0, 30.0)
	bf.name = "btn_formacja"
	bf.add_theme_font_size_override("font_size", 15)
	szyk.add_child(bf)
	s1[1].add_child(szyk)
	# zdrowie w jednym wierszu: pasek, krótki status, leczenie za korony (gdy potrzebne)
	var zdr := Gk.hb(8)
	var pasek := Gk.pasek_hp(id, 18.0)
	pasek.custom_minimum_size = Vector2(120, 18)
	pasek.size_flags_horizontal = Control.SIZE_FILL
	pasek.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	zdr.add_child(pasek)
	var st := Gk.tekst(_status(id), 14, KW.kolor_zdrowia(id), false)
	st.clip_text = true
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zdr.add_child(st)
	s1[1].add_child(zdr)
	var lecz: Button = null
	if Game.polegly(id) or Game.ranny(id):
		lecz = Gk.przycisk("", func():
			if Game.ulecz(id):
				Audio.play("coin")
				k.odswiez("%s wraca do pełni sił." % str(def.get("imie", id))), false, 128.0, 28.0, "krzyz")
		lecz.name = "btn_ulecz"
		lecz.add_theme_font_size_override("font_size", 14)
		lecz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		zdr.add_child(lecz)
	var odswiez := func():
		pasek.queue_redraw()
		st.text = _status(id)
		if lecz != null:
			lecz.text = "%s · %d" % ["Postaw" if Game.polegly(id) else "Lecz", Game.koszt_leczenia(id)]
			lecz.tooltip_text = "%s za %d koron" % ["Postaw na nogi" if Game.polegly(id) else "Opatrz rany", Game.koszt_leczenia(id)]
			lecz.disabled = not Game.moze_uleczyc(id)
	odswiez.call()
	k.zywe.append(odswiez)
	v.add_child(s1[0])

	var s2 := KKarta.sekcja("Doświadczenie")
	var poz := Game.poziom(id)
	var maks := Progression.max_poziom()
	var wydane := 0
	for i in range(1, poz):
		wydane += Progression.koszt_poziomu(i)
	s2[1].add_child(KKarta.dwa_pola(KKarta.pole("Poziom", "%d / %d" % [poz, maks], Gk.ZLOTO_J), KKarta.pole("Wydano", "%d koron" % wydane)))
	var tr := Gk.hb(8)
	var moze := Game.moze_awansowac(id) or Progression.moze_wybrac_spec(def, poz, Game.spec(id))
	tr.add_child(KKarta.pole("Następny trening", "poziom maksymalny" if poz >= maks else "%d koron" % Game.koszt_awansu(id),
		Gk.ZIELEN if Game.moze_awansowac(id) else Gk.TEKST))
	var bt := Gk.przycisk("Trening", func(): k.idz("rozwoj", {"id": id}), moze, 128.0, 30.0, "awans")
	bt.name = "btn_rozwoj"
	bt.add_theme_font_size_override("font_size", 15)
	tr.add_child(bt)
	s2[1].add_child(tr)
	v.add_child(s2[0])

	var s3 := KKarta.sekcja("Walka")
	var atak: Dictionary = z["atak"]
	var rodzaj := str(atak.get("typ", "wrecz"))
	s3[1].add_child(KKarta.dwa_pola(KKarta.pole("Atak", str(atak.get("nazwa", ""))), KKarta.pole("Rodzaj", str(RODZAJ_ATAKU.get(rodzaj, rodzaj)))))
	var mn := 1.0
	for s in z["wszystkie"]:
		if s["odblokowana"] and str(s.get("typ", "")) == "atak_mnoznik":
			mn *= float(s.get("mnoznik", 1.0))
	var obr := Wfrp.obrazenia(rodzaj, float(atak.get("bron", 1.0)), z["cechy"], {}, 0.0, mn)
	var ile := Wfrp.ataki(z["cechy"])
	s3[1].add_child(KKarta.dwa_pola(KKarta.pole("Cykl co", "%.1f s%s" % [Wfrp.czas_ataku(float(atak.get("czas", 5.0)), z["cechy"]), "  ×%d ciosy" % ile if ile > 1 else ""]),
		KKarta.pole("Obrażenia", "%d  (kryt. %d)" % [roundi(obr), roundi(obr * Wfrp.sila_krytyka(z["cechy"]))], Gk.ZLOTO_J)))
	s3[1].add_child(KKarta.pole("Krytyk", "%d%% szans (z %s), ×%.2f (ze Zr)" % [roundi(Wfrp.szansa_krytyka(rodzaj, z["cechy"]) * 100.0), Wfrp.cecha_krytyka(rodzaj), Wfrp.sila_krytyka(z["cechy"])]))
	s3[1].add_child(KKarta.pole("Zasięg", "tylko z przedniego rzędu" if rodzaj == "wrecz" else ("każdy wróg; omija pancerz, chroni SW" if rodzaj == "magia" else "każdy wróg na polu")))
	v.add_child(s3[0])

	var s4 := KKarta.sekcja("Podsumowanie zdolności")
	s4[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 2)
	for n in ["ZDOLNOŚĆ", "RODZAJ", "POZ."]:
		g.add_child(Gk.gruby(n, 12, Gk.PRZYG))
	for s in z["wszystkie"]:
		var odb: bool = s["odblokowana"]
		var n := Gk.tekst(str(s.get("nazwa", "")), 15, Gk.ZLOTO_J if odb else Gk.PRZYG, false)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = str(s.get("opis", ""))
		n.mouse_filter = Control.MOUSE_FILTER_PASS
		g.add_child(n)
		g.add_child(Gk.tekst(KW.typ_umiejetnosci(s).split(" · ")[0], 14, Gk.TEKST if odb else Gk.PRZYG, false))
		g.add_child(Gk.tekst(str(int(s.get("prog", 1))) if not odb else "✓", 14, Gk.ZIELEN if odb else Gk.PRZYG, false))
	var gal := Progression.galaz(def, Game.spec(id))
	var sp: Dictionary = def.get("specjalizacja", {})
	if not sp.is_empty():
		g.add_child(Gk.tekst("Specjalizacja: " + (str(gal["nazwa"]) if not gal.is_empty() else "do wyboru"), 15, Gk.ZIELEN if not gal.is_empty() else Gk.PRZYG, false))
		g.add_child(Gk.tekst("Ścieżka", 14, Gk.TEKST, false))
		g.add_child(Gk.tekst("✓" if not gal.is_empty() else str(int(sp.get("prog", 10))), 14, Gk.ZIELEN if not gal.is_empty() else Gk.PRZYG, false))
	var sc := Gk.przewijany(g)
	sc.custom_minimum_size = Vector2(0, 66)
	s4[1].add_child(sc)
	s4[1].size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(s4[0])

static func _status(id: String) -> String:
	if Game.polegly(id):
		return "Lazaret · " + Gk.czas(Game.czas_do_zdrowia(id))
	if Game.ranny(id):
		return "Ranny · " + Gk.czas(Game.czas_do_zdrowia(id))
	return "Zdrowy"

# ---------------------------------------------------------------- środek: logo i wyposażenie na sylwetce
static func _srodek(k: BarracksScene, v: VBoxContainer, p: Dictionary, id: String) -> void:
	var tab := Gk.rama(4.0, 0.9)
	var logo := LogoCC.nowe(100.0)
	logo.custom_minimum_size = Vector2(320, 100)
	tab.add_child(logo)
	v.add_child(tab)

	var s := KKarta.sekcja("Wyposażenie")
	s[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	s[1].size_flags_vertical = Control.SIZE_EXPAND_FILL
	var h := Gk.hb(6)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s[1].add_child(h)
	h.add_child(_sloty(k, id, LEWE))
	var fig := Gk.portret(id, Vector2(150, 300), Gk.stan_bohatera(id), true)
	fig.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fig.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(fig)
	h.add_child(_sloty(k, id, PRAWE))
	var dol := Gk.hb(8)
	var moi: Array = []
	for hid in Data.hero_ids():
		if Game.ma(hid):
			moi.append(hid)
	var i := moi.find(id)
	var poprz: String = moi[(i - 1 + moi.size()) % moi.size()]
	var nast: String = moi[(i + 1) % moi.size()]
	var bp := Gk.przycisk("", func():
		p["id"] = poprz
		k.odswiez(), false, 52.0, 40.0, "wstecz")
	bp.name = "btn_poprzedni"
	bp.disabled = moi.size() < 2
	dol.add_child(bp)
	var be := Gk.przycisk("Ekwipunek  (%d/%d)" % [Game.ekwipunek(id).size(), Data.items.get("sloty", []).size()],
		func(): k.idz("ekwipunek", {"id": id}), false, 0.0, 40.0, "sakwa")
	be.name = "btn_ekwipunek"
	be.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dol.add_child(be)
	var bn := Gk.przycisk("", func():
		p["id"] = nast
		k.odswiez(), false, 52.0, 40.0, "dalej")
	bn.name = "btn_nastepny"
	bn.disabled = moi.size() < 2
	dol.add_child(bn)
	s[1].add_child(dol)
	v.add_child(s[0])

static func _sloty(k: BarracksScene, id: String, lista: Array) -> VBoxContainer:
	var v := Gk.vb(8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.custom_minimum_size = Vector2(118, 0)
	var nazwy: Dictionary = Data.items.get("nazwy_slotow", {})
	var ekw := Game.ekwipunek(id)
	for wpis in lista:
		var slot := str(wpis[0])
		var it := Data.item(str(ekw.get(slot, "")))
		var kol: Color = Gk.RZADKOSC.get(str(it.get("rzadkosc", "")), Gk.ZLOTO_C)
		var karta := Gk.karta(func(): k.idz("ekwipunek", {"id": id, "slot": slot}), false, 6.0)
		karta[1].name = "karta_slot_" + slot
		karta[1].tooltip_text = KW.opis_cech(it) if not it.is_empty() else "Pusty slot - dotknij, żeby coś założyć"
		var w := Gk.vb(2)
		var g := Gk.hb(4)
		var n := Gk.gruby(str(nazwy.get(slot, slot)).split(" /")[0].to_upper(), 12, Gk.ZLOTO)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(n)
		g.add_child(Gk.tekst(str(wpis[1]), 11, Gk.PRZYG, false))
		w.add_child(g)
		var r := Gk.hb(4)
		r.add_child(Ikona.nowa(slot, 26.0, kol if not it.is_empty() else Color(0.35, 0.3, 0.26)))
		var nz := Gk.tekst(str(it.get("nazwa", "— pusty —")), 13, kol if not it.is_empty() else Gk.PRZYG)
		nz.custom_minimum_size = Vector2(76, 0)
		r.add_child(nz)
		w.add_child(r)
		var pp := float(it.get("cechy", {}).get("pancerz", 0.0))
		if pp > 0.0:
			w.add_child(Gk.tekst("PP +%s" % KW._liczba(pp), 12, Gk.TEKST, false))
		Gk.do_karty(karta, w)
		v.add_child(karta[0])
	return v

# ---------------------------------------------------------------- strona II
static func _historia(v: VBoxContainer, id: String) -> void:
	var def := Data.hero(id)
	var s1 := KKarta.sekcja("Historia", 8)
	s1[1].add_child(Gk.pergamin(str(def.get("fabula", def.get("opis", "")))))
	v.add_child(s1[0])
	var s2 := KKarta.sekcja("Rola w drużynie", 6)
	var role := Gk.hb(6)
	for r in def.get("role", []):
		role.add_child(Gk.odznaka(str(r)))
	s2[1].add_child(role)
	s2[1].add_child(Gk.tekst(str(def.get("opis", "")), 16))
	v.add_child(s2[0])
	var kd: Dictionary = def.get("karta", {})
	var s3 := KKarta.sekcja("Pochodzenie", 4)
	s3[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	s3[1].add_child(KKarta.pole("Miejsce urodzenia", str(kd.get("urodzony", "—"))))
	s3[1].add_child(KKarta.pole("Znak gwiezdny", str(kd.get("znak", "—"))))
	s3[1].add_child(KKarta.pole("Znaki szczególne", str(kd.get("znaki", "—"))))
	v.add_child(s3[0])

static func _talenty(v: VBoxContainer, id: String) -> void:
	var def := Data.hero(id)
	var z := Game.zestaw(id)
	var s1 := KKarta.sekcja("Umiejętności i talenty", 8)
	s1[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lista := Gk.vb(8)
	for s in z["wszystkie"]:
		var odb: bool = s["odblokowana"]
		var w := Gk.vb(1)
		var g := Gk.hb(6)
		var n := Gk.gruby(str(s.get("nazwa", "")), 16, Gk.ZLOTO_J if odb else Gk.PRZYG)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		g.add_child(n)
		g.add_child(Gk.odznaka(KW.typ_umiejetnosci(s).split(" · ")[0], Gk.ZLOTO if odb else Gk.PRZYG))
		g.add_child(Gk.odznaka("✓" if odb else "poz. %d" % int(s.get("prog", 1)), Gk.ZIELEN if odb else Gk.PRZYG))
		w.add_child(g)
		w.add_child(Gk.tekst(str(s.get("opis", "")), 14, Gk.TEKST if odb else Gk.PRZYG))
		lista.add_child(w)
	var sc := Gk.przewijany(lista)
	sc.custom_minimum_size = Vector2(0, 200)
	s1[1].add_child(sc)
	s1[1].size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(s1[0])
	var sp: Dictionary = def.get("specjalizacja", {})
	if sp.is_empty():
		return
	var s2 := KKarta.sekcja("Specjalizacja", 6)
	var wyb := Game.spec(id)
	for g in sp.get("galezie", []):
		var gid := str(g["id"])
		var h := Gk.hb(6)
		var n := Gk.gruby(str(g["nazwa"]), 15, Gk.ZIELEN if wyb == gid else (Gk.PRZYG if wyb != "" else Gk.ZLOTO_J))
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		h.add_child(Gk.odznaka("Wybrana" if wyb == gid else ("Zamknięta" if wyb != "" else "Od poz. %d" % int(sp.get("prog", 10))),
			Gk.ZIELEN if wyb == gid else Gk.PRZYG))
		s2[1].add_child(h)
		s2[1].add_child(Gk.tekst(str(g.get("opis", "")), 14, Gk.TEKST if wyb in ["", gid] else Gk.PRZYG))
	v.add_child(s2[0])
