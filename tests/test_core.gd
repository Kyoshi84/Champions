extends GutTest
## Rdzeń mechaniki: zasady WFRP, formacja, progresja, dane.

func test_wfrp_cechy_maja_wplyw():
	var a := {"WW": 40, "US": 40, "K": 40, "Odp": 30, "Zr": 30, "Int": 40, "SW": 30, "Zyw": 10, "Sz": 4}
	var lepszy := a.duplicate()
	lepszy["WW"] = 60
	assert_gt(Wfrp.szansa_trafienia("wrecz", lepszy, a), Wfrp.szansa_trafienia("wrecz", a, a), "WW zwiększa celność wręcz")
	lepszy = a.duplicate(); lepszy["US"] = 60
	assert_gt(Wfrp.szansa_trafienia("dystans", lepszy, a), Wfrp.szansa_trafienia("dystans", a, a), "US zwiększa celność strzału")
	lepszy = a.duplicate(); lepszy["K"] = 60
	assert_gt(Wfrp.obrazenia("wrecz", 5, lepszy, a, 0, 1), Wfrp.obrazenia("wrecz", 5, a, a, 0, 1), "K zwiększa obrażenia")
	lepszy = a.duplicate(); lepszy["Odp"] = 60
	assert_lt(Wfrp.obrazenia("wrecz", 5, a, lepszy, 0, 1), Wfrp.obrazenia("wrecz", 5, a, a, 0, 1), "Odp zmniejsza obrażenia")
	assert_lt(Wfrp.obrazenia("wrecz", 5, a, a, 2, 1), Wfrp.obrazenia("wrecz", 5, a, a, 0, 1), "pancerz zmniejsza obrażenia")
	assert_eq(Wfrp.obrazenia("magia", 5, a, a, 5, 1), Wfrp.obrazenia("magia", 5, a, a, 0, 1), "magia omija pancerz")
	lepszy = a.duplicate(); lepszy["SW"] = 80
	assert_lt(Wfrp.obrazenia("magia", 5, a, lepszy, 0, 1), Wfrp.obrazenia("magia", 5, a, a, 0, 1), "SW chroni przed magią")
	assert_lt(Wfrp.czas_ogluszenia(2.0, lepszy, 0), Wfrp.czas_ogluszenia(2.0, a, 0), "SW skraca ogłuszenie")
	lepszy = a.duplicate(); lepszy["Sz"] = 6
	assert_lt(Wfrp.czas_ataku(5.0, lepszy), Wfrp.czas_ataku(5.0, a), "Sz skraca czas ataku")
	assert_almost_eq(Wfrp.czas_ataku(5.0, a), 5.0, 0.001, "bazowy atak co 5 s")
	lepszy = a.duplicate(); lepszy["Zyw"] = 20
	assert_gt(Wfrp.max_hp(lepszy), Wfrp.max_hp(a), "Żyw daje HP")
	lepszy = a.duplicate(); lepszy["Zr"] = 60
	assert_gt(Wfrp.unik(lepszy), Wfrp.unik(a), "Zr daje unik")
	lepszy = a.duplicate(); lepszy["Int"] = 60
	assert_gt(Wfrp.leczenie(5, lepszy), Wfrp.leczenie(5, a), "Int wzmacnia leczenie")
	lepszy = a.duplicate(); lepszy["Ogd"] = 60
	assert_gt(Wfrp.premia_zlota(lepszy), Wfrp.premia_zlota(a), "Ogd daje złoto")

func test_formacja_zasiegi():
	# pola 0-4 przód, 5-9 tył; 2 i 7 w tym samym torze
	assert_true(Formation.w_zasiegu(2, 1, "sasiednie"))
	assert_true(Formation.w_zasiegu(2, 7, "sasiednie"))
	assert_false(Formation.w_zasiegu(2, 6, "sasiednie"), "skos nie jest sąsiedni")
	assert_false(Formation.w_zasiegu(2, 2, "sasiednie"))
	assert_true(Formation.w_zasiegu(2, 6, "zasieg_2"))
	assert_false(Formation.w_zasiegu(0, 9, "zasieg_2"))
	assert_true(Formation.w_zasiegu(7, 2, "przed_mna"))
	assert_false(Formation.w_zasiegu(2, 7, "przed_mna"))
	assert_true(Formation.w_zasiegu(2, 7, "za_mna"))
	assert_true(Formation.w_zasiegu(0, 3, "rzad_przedni"))
	assert_false(Formation.w_zasiegu(0, 8, "rzad_przedni"))
	assert_true(Formation.w_zasiegu(0, 9, "druzyna"))

func test_aury_zaleza_od_pozycji():
	var ursa := Progression.bohater("ursa", 8, "", {}, 7)
	var ivo := Progression.bohater("ivo", 1, "", {}, 2)
	Formation.przelicz_aury([ursa, ivo])
	assert_almost_eq(float(ivo.aury.get("obrazenia", 0.0)), 0.3, 0.001, "Ivo przed Ursą dostaje Płonący oręż")
	assert_eq(ivo.aury_zrodla.size(), 1)
	ivo = Progression.bohater("ivo", 1, "", {}, 3)
	Formation.przelicz_aury([ursa, ivo])
	assert_eq(float(ivo.aury.get("obrazenia", 0.0)), 0.0, "w innym torze aura nie działa")

func test_progi_umiejetnosci_i_specjalizacja():
	var def := Data.hero("ivo")
	var z1 := Progression.zbuduj(def, 1, "", {})
	assert_eq(z1["umiejetnosci"].size(), 0, "poziom 1: tylko podstawowy atak")
	var z5 := Progression.zbuduj(def, 5, "", {})
	var ids: Array = z5["umiejetnosci"].map(func(s): return s["id"])
	assert_true(ids.has("silniejsze_uderzenie") and ids.has("super_cios"))
	var z8 := Progression.zbuduj(def, 8, "", {})
	var sc: Dictionary = z8["umiejetnosci"].filter(func(s): return s["id"] == "super_cios")[0]
	assert_eq(float(sc["odrzut"]), 130.0, "od poziomu 8 Super Cios odpycha")
	var a := Progression.zbuduj(def, 10, "potezne_uderzenie", {})
	var b := Progression.zbuduj(def, 10, "szybkosc", {})
	assert_gt(float(a["atak"]["bron"]), float(b["atak"]["bron"]), "gałąź A: mocniejszy cios")
	assert_lt(float(b["atak"]["czas"]), float(a["atak"]["czas"]), "gałąź B: szybszy atak")
	var sb: Dictionary = b["umiejetnosci"].filter(func(s): return s["id"] == "super_cios")[0]
	assert_eq(int(sb["n"]), 2, "gałąź B: Super Cios co drugi atak")
	assert_gt(float(Progression.cechy_na_poziomie(def, 10)["WW"]), float(def["profil"]["WW"]), "cechy rosną z poziomem")
	assert_gt(Progression.koszt_poziomu(5), Progression.koszt_poziomu(1))

func test_ekwipunek_zmienia_cechy():
	var def := Data.hero("ivo")
	var bez := Progression.zbuduj(def, 1, "", {})
	var z := Progression.zbuduj(def, 1, "", {"bron": "miecz_dwureczny", "zbroja": "kolczuga", "helm": "szyszak"})
	assert_gt(float(z["atak"]["bron"]), float(bez["atak"]["bron"]))
	assert_gt(float(z["pancerz"]), float(bez["pancerz"]))
	assert_gt(float(z["odp_ogluszenie"]), 0.0)
	assert_gt(float(z["cechy"]["Odp"]), float(bez["cechy"]["Odp"]))

func test_dane_sa_spojne():
	var typy := ["atak_mnoznik", "co_n_atak", "stat", "aura", "leczenie", "status_przy_trafieniu", "prowokacja", "modyfikacja", "ultimate"]
	for id in Data.hero_ids():
		var h := Data.hero(id)
		assert_false(h.is_empty(), "bohater " + id)
		for s in h.get("umiejetnosci", []):
			assert_true(typy.has(str(s.get("typ", ""))), "%s: znany typ umiejętności %s" % [id, s.get("id", "?")])
		for slot in h.get("ekwipunek", {}):
			assert_false(Data.item(h["ekwipunek"][slot]).is_empty(), "%s: przedmiot %s istnieje" % [id, h["ekwipunek"][slot]])
			assert_eq(str(Data.item(h["ekwipunek"][slot]).get("slot", "")), slot)
		for g in h.get("specjalizacja", {}).get("galezie", []):
			for m in g.get("modyfikacje", []):
				if m.has("umiejetnosc"):
					var jest := false
					for s in h.get("umiejetnosci", []):
						if s["id"] == m["umiejetnosc"]:
							jest = true
					assert_true(jest, "%s: specjalizacja wskazuje istniejącą umiejętność %s" % [id, m["umiejetnosc"]])
	for adv_id in Data.adventures.get("przygody", {}):
		var adv := Data.adventure(adv_id)
		var plansze: Array = adv.get("plansze", [])
		assert_eq(plansze.size() % 5, 0, adv_id + ": liczba plansz to wielokrotność 5")
		for i in plansze.size():
			assert_eq(bool(plansze[i].get("boss", false)), (i + 1) % 5 == 0, "%s: boss tylko co piątą planszę (%d)" % [adv_id, i + 1])
			for f in plansze[i].get("fale", []):
				for e in f.get("wrogowie", {}):
					assert_false(Data.enemy(e).is_empty(), "%s: wróg %s istnieje" % [adv_id, e])
		assert_true(Data.art.get("poziomy", {}).has(str(adv.get("poziom_grafiki", ""))), adv_id + ": poziom grafiki opisany")
		assert_true(Data.music.get("tracks", {}).has(str(adv.get("muzyka", ""))), adv_id + ": muzyka istnieje")
	for t in Data.music.get("tracks", {}):
		assert_true(FileAccess.file_exists(str(Data.music["tracks"][t]["file"])), "plik muzyki " + t)
