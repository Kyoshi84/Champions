extends GutTest
## Walka: determinizm, prolog (Borubar), strzały gracza, bossowie, pierwsza przygoda.

const DT := 0.1

## Rozgrywa planszę. bot = true: "gracz" strzela w najbliższego wroga na ekranie tak często, jak może.
func rozegraj(heroes: Array, adv: Dictionary, idx: int, bot: bool, seed_: int = 7, limit: float = 600.0, ult: bool = false) -> Combat:
	var c := Combat.new()
	c.setup(heroes, adv, idx, Data.difficulty("normal"), seed_)
	while c.result == "" and c.time < limit:
		c.step(DT)
		if bot:
			var best: CUnit = null
			for e in c.enemies:
				if e.alive and e.x < 1250 and (best == null or e.x < best.x):
					best = e
			if best != null:
				c.strzal_gracza(best.x, best.y - 30)
		if ult:
			for h in c.heroes:
				c.uzyj_ult(h)
	return c

func przejdz_przygode(adv_id: String, heroes: Array, bot: bool, ult: bool = false) -> Array:
	var adv := Data.adventure(adv_id)
	var wyniki: Array = []
	for i in adv["plansze"].size():
		var c := rozegraj(heroes, adv, i, bot, 11 + i, 600.0, ult)
		wyniki.append(c.result)
		if c.result != "wygrana":
			break
		c.odpoczynek()
	return wyniki

func test_determinizm():
	var adv := Data.adventure("piwnice_carroburga")
	var a := rozegraj([Progression.bohater("ivo", 3, "", {}, 2)], adv, 0, false, 5)
	var b := rozegraj([Progression.bohater("ivo", 3, "", {}, 2)], adv, 0, false, 5)
	assert_eq(a.result, b.result)
	assert_almost_eq(a.time, b.time, 0.001, "to samo ziarno = ten sam przebieg")
	assert_almost_eq(a.zloto, b.zloto, 0.001)

func test_prolog_borubar_wygrywa_plansze_1_do_4_ze_strzalami():
	Game.new_game(false)
	var adv := Data.adventure("prolog_wies")
	var heroes := Game.druzyna(adv)
	assert_eq(heroes.size(), 1)
	assert_eq(heroes[0].id, "borubar")
	for i in 4:
		var c := rozegraj(heroes, adv, i, true, 20 + i)
		assert_eq(c.result, "wygrana", "plansza %d prologu do przejścia ze strzałami" % (i + 1))
		gut.p("prolog plansza %d: %.0f s, HP Borubara %.0f/%.0f" % [i + 1, c.time, heroes[0].hp, heroes[0].max_hp])
		c.odpoczynek()

func test_prolog_champion_zawsze_wygrywa():
	var adv := Data.adventure("prolog_wies")
	for seed_ in [1, 2, 3]:
		var heroes := Game.druzyna(adv)
		var c := rozegraj(heroes, adv, 4, true, seed_)
		assert_eq(c.result, "przegrana", "Borubar musi przegrać z Championem (fabuła)")
		assert_between(c.time, 15.0, 90.0, "przegrana nie trwa ani chwilę, ani wieczność")
		gut.p("Champion pokonuje Borubara po %.0f s" % c.time)

func test_borubar_twardy_ale_slaby():
	var bor := Progression.bohater("borubar", 1, "", Data.hero("borubar")["ekwipunek"], 2)
	var ivo := Progression.bohater("ivo", 1, "", Data.hero("ivo")["ekwipunek"], 2)
	assert_gt(bor.max_hp, ivo.max_hp * 1.5, "Borubar ma dużo więcej żywotności")
	assert_gt(Wfrp.czas_ataku(float(bor.atak["czas"]), bor.cechy), Wfrp.czas_ataku(float(ivo.atak["czas"]), ivo.cechy), "bije wolniej")
	var cel: Dictionary = Data.enemy("szczur")["profil"]
	assert_lt(Wfrp.obrazenia("wrecz", float(bor.atak["bron"]), bor.cechy, cel, 0, 1), Wfrp.obrazenia("wrecz", float(ivo.atak["bron"]), ivo.cechy, cel, 0, 1), "i słabiej")

func test_strzal_gracza_rani_i_oglusza():
	var adv := Data.adventure("piwnice_carroburga")
	var c := Combat.new()
	c.setup([Progression.bohater("ivo", 1, "", {}, 2)], adv, 0, Data.difficulty("normal"), 3)
	for i in 60:
		c.step(DT)
	assert_gt(c.enemies.size(), 0)
	var e: CUnit = c.enemies[0]
	var hp := e.hp
	assert_true(c.strzal_gracza(e.x, e.y - 30))
	assert_lt(e.hp, hp)
	assert_true(e.ma_status("ogluszenie"))
	assert_false(c.strzal_gracza(e.x, e.y - 30), "strzał ma odnowienie")

func test_wreczowiec_z_tylu_nie_siega():
	var adv := Data.adventure("piwnice_carroburga")
	var c := Combat.new()
	var ivo := Progression.bohater("ivo", 1, "", {}, 7)
	var bor := Progression.bohater("borubar", 1, "", {}, 2)
	c.setup([bor, ivo], adv, 0, Data.difficulty("normal"), 3)
	for i in 300:
		c.step(DT)
	assert_eq(ivo.licznik_atakow, 0, "Ivo w tylnym rzędzie nie dosięga wrogów walczących z pierwszą linią")
	assert_gt(bor.licznik_atakow, 0)

func test_pierwsza_przygoda_do_przejscia_jednym_bohaterem():
	var heroes := [Progression.bohater("ivo", 1, "", Data.hero("ivo")["ekwipunek"], 2)]
	var w := przejdz_przygode("piwnice_carroburga", heroes, true)
	gut.p("Piwnice, sam Ivo poz. 1 + strzały: " + str(w))
	assert_gte(w.size(), 2, "sam Ivo na poziomie 1 przechodzi przynajmniej pierwszą planszę")
	assert_eq(w[0], "wygrana")

func test_druzyna_przechodzi_pierwsza_przygode():
	var heroes := [
		Progression.bohater("borubar", 4, "", Data.hero("borubar")["ekwipunek"], 2),
		Progression.bohater("ivo", 5, "", Data.hero("ivo")["ekwipunek"], 1),
		Progression.bohater("modraszka", 3, "", Data.hero("modraszka")["ekwipunek"], 7)]
	var w := przejdz_przygode("piwnice_carroburga", heroes, true, true)
	gut.p("Piwnice, drużyna 3 bohaterów: " + str(w))
	assert_eq(w.size(), 5)
	assert_eq(w[4], "wygrana", "rozwinięta drużyna pokonuje Szczurzego Herszta")

func test_boss_wpada_w_furie():
	var adv := Data.adventure("prolog_wies")
	var heroes := Game.druzyna(adv)
	var c := rozegraj(heroes, adv, 4, false, 2, 40.0)
	var furia := 0
	for ev in c.events:
		if ev["typ"] == "furia":
			furia = maxi(furia, int(ev["stopien"]))
	assert_gt(furia, 0, "im dłużej boss żyje, tym groźniejszy")

func test_ultimate_i_zloto():
	var adv := Data.adventure("piwnice_carroburga")
	var ivo := Progression.bohater("ivo", 6, "", {}, 2)
	var c := Combat.new()
	c.setup([ivo], adv, 0, Data.difficulty("normal"), 3, 0.5)
	for i in 80:
		c.step(DT)
	assert_true(c.ult_gotowy(ivo))
	assert_true(c.uzyj_ult(ivo))
	assert_false(c.ult_gotowy(ivo), "ultimate ma odnowienie")
	for e in c.enemies:
		if e.x < 1260:
			assert_true(e.ma_status("ogluszenie"))
	assert_gt(c.mnoznik_zlota, 1.4, "favor podnosi mnożnik złota")

func test_champion_chaosu_odporny_na_magie_ale_do_pokonania():
	var ursa := Progression.bohater("ursa", 10, "", {}, 7)
	var szczur: Dictionary = Data.enemy("szczur")["profil"]
	var champion: Dictionary = Data.enemy("czempion_chaosu")["profil"]
	assert_lt(Wfrp.obrazenia("magia", 4.0, ursa.cechy, champion, 3.0, 1.0), Wfrp.obrazenia("magia", 4.0, ursa.cechy, szczur, 0.0, 1.0),
		"Siła Woli Championa osłabia czary")
	var druzyna := [Progression.bohater("borubar", 10, "mur", Data.hero("borubar")["ekwipunek"], 2),
		Progression.bohater("ivo", 10, "potezne_uderzenie", Data.hero("ivo")["ekwipunek"], 1),
		Progression.bohater("modraszka", 10, "lowczyni", Data.hero("modraszka")["ekwipunek"], 6),
		Progression.bohater("ursa", 10, "piromantka", Data.hero("ursa")["ekwipunek"], 7)]
	assert_eq(rozegraj(druzyna, Data.adventure("odbicie_hufduhofu"), 4, true, 35, 600.0, true).result, "wygrana", "pełna drużyna na poziomie 10 pokonuje Championa")

func test_ataki_zawsze_trafiaja_i_bywaja_krytyczne():
	var c := Combat.new()
	var ivo := Progression.bohater("ivo", 10, "", {}, 2)
	c.setup([ivo], Data.adventure("piwnice_carroburga"), 4, Data.difficulty("normal"), 4)     # plansza z bossem: dużo ciosów
	var trafienia := 0
	var krytyki := 0
	for i in 2000:
		c.step(DT)
		for ev in c.events:
			assert_false(str(ev["typ"]) in ["pudlo", "unik"], "nie ma pudeł ani uników")
			if str(ev["typ"]) == "obrazenia" and int(ev["uid"]) != ivo.uid:
				trafienia += 1
				if bool(ev.get("krytyk", false)):
					krytyki += 1
		c.events.clear()
		if c.result != "":
			break
	assert_gt(trafienia, 10)
	assert_gt(krytyki, 0, "zdarzają się krytyki")
	assert_lt(krytyki, trafienia, "ale nie każdy cios jest krytyczny")

func test_wiele_atakow_w_cyklu():
	var c := Combat.new()
	var bor := Progression.bohater("borubar", 20, "", {}, 2)
	c.setup([bor], Data.adventure("prolog_wies"), 4, Data.difficulty("normal"), 2)
	var ciosy_bossa := 0
	var cykle := 0
	for i in 600:
		c.step(DT)
		for ev in c.events:
			if str(ev["typ"]) == "atak" and int(ev["od"]) != bor.uid:
				cykle += 1
			if str(ev["typ"]) == "obrazenia" and int(ev["uid"]) == bor.uid:
				ciosy_bossa += 1
		c.events.clear()
		if c.result != "":
			break
	assert_gt(cykle, 0)
	assert_gt(ciosy_bossa, cykle * 2, "Champion (A 3) zadaje kilka ciosów w jednym cyklu")

# ---------------------------------------------------------------- ciągły napływ, postęp celu, monety
func test_wrogowie_naplywaja_pojedynczo_bez_przerw():
	var adv := Data.adventure("piwnice_carroburga")
	var c := Combat.new()
	c.setup([Progression.bohater("borubar", 20, "", {}, 1)], adv, 0, Data.difficulty("normal"), 7)
	var lacznie := 0
	for f in adv["plansze"][0]["fale"]:
		for id in f["wrogowie"]:
			lacznie += int(f["wrogowie"][id])
	var czasy: Array = []
	for i in 400:
		c.step(0.1)
		for ev in c.events:
			if str(ev["typ"]) == "spawn":
				czasy.append(c.time)
		c.events.clear()
		if c.result != "":
			break
	assert_eq(czasy.size(), lacznie, "wchodzi tylu wrogów, ilu jest w danych planszy")
	var odstep := float(Data.walka().get("naplyw_odstep", 1.8))
	for i in range(1, czasy.size()):
		var d: float = czasy[i] - czasy[i - 1]
		assert_almost_eq(d, odstep, 0.11, "wrogowie wchodzą pojedynczo w równych odstępach, bez przerw między grupami")

func test_postep_celu_i_monety_z_wrogow():
	var c := Combat.new()
	c.setup([Progression.bohater("ivo", 20, "", {}, 2)], Data.adventure("piwnice_carroburga"), 0, Data.difficulty("normal"), 3)
	assert_almost_eq(c.postep_celu(), 0.0, 0.001)
	var monety := 0
	var poprzedni := 0.0
	for i in 900:
		c.step(0.1)
		for ev in c.events:
			if str(ev["typ"]) == "zloto":
				monety += 1
				assert_true(ev.has("x") and ev.has("y"), "moneta wie, gdzie padł wróg")
		c.events.clear()
		assert_gte(c.postep_celu(), poprzedni - 0.001, "postęp celu nie cofa się")
		poprzedni = c.postep_celu()
		if c.result != "":
			break
	assert_eq(c.result, "wygrana")
	assert_almost_eq(c.postep_celu(), 1.0, 0.001)
	assert_eq(monety, c.zabici, "każdy pokonany wróg upuszcza monety")
