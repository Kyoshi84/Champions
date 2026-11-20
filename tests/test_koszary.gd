extends GutTest
## Koszary: nawigacja po wszystkich ekranach i każda akcja wykonywana prawdziwymi przyciskami.

var main: Node
var k: BarracksScene
var _stara_sciezka: String

func before_each():
	_stara_sciezka = Save.save_path
	Save.save_path = "user://test_zapis_koszary.json"
	Save.delete_save()
	Game.czas_testowy = 1000.0
	Game.new_game(false)
	Game.ukoncz_prolog()
	Game.state["korony"] = 1000
	main = load("res://scripts/main.gd").new()
	add_child_autofree(main)
	main.go("koszary")
	await wait_frames(2)
	k = main.current

func after_each():
	Game.czas_testowy = -1.0
	Save.delete_save()
	Save.save_path = _stara_sciezka

func klik(nazwa: String) -> void:
	var b := k.znajdz(nazwa)
	assert_not_null(b, "jest przycisk " + nazwa)
	if b != null:
		assert_false(b.disabled, "przycisk %s jest aktywny" % nazwa)
		b.pressed.emit()
	await wait_frames(2)

func test_hub_prowadzi_do_kazdego_ekranu_i_z_powrotem():
	assert_eq(k.ekran(), "hub")
	for e in ["druzyna", "formacja", "misje", "tawerna", "sklep", "osiagniecia"]:
		await klik("kafel_" + e)
		assert_eq(k.ekran(), e, "kafel otwiera ekran " + e)
		await klik("btn_wroc")
		assert_eq(k.ekran(), "hub", "Wróć wraca do Hubu z " + e)
	await klik("btn_misje")
	assert_eq(k.ekran(), "misje")

func test_sciezka_bohatera_i_powrot_herbem():
	await klik("kafel_druzyna")
	await klik("bohater_ivo")
	assert_eq(k.ekran(), "bohater")
	await klik("btn_rozwoj")
	assert_eq(k.ekran(), "rozwoj")
	await klik("btn_wroc")
	await klik("btn_ekwipunek")
	assert_eq(k.ekran(), "ekwipunek")
	await klik("btn_wroc")
	await klik("btn_nastepny")
	assert_eq(str(k.parametry()["id"]), "borubar", "strzałka przechodzi do następnego bohatera")
	await klik("btn_formacja")
	assert_eq(k.ekran(), "formacja")
	assert_eq(k.stos.size(), 4)
	await klik("btn_hub")
	assert_eq(k.ekran(), "hub", "herb wraca do Hubu z dowolnej głębokości")
	assert_eq(k.stos.size(), 1)

func test_awans_i_specjalizacja():
	k.idz("rozwoj", {"id": "ivo"})
	await wait_frames(2)
	var korony := int(Game.state["korony"])
	await klik("btn_awans")
	assert_eq(Game.poziom("ivo"), 2)
	assert_lt(int(Game.state["korony"]), korony, "awans kosztuje korony")
	Game.state["korony"] = 100000
	Game.state["bohaterowie"]["ivo"]["poziom"] = 10
	k.odswiez()
	await wait_frames(2)
	var galaz := str(Data.hero("ivo")["specjalizacja"]["galezie"][1]["id"])
	await klik("wezel_spec_" + galaz)
	await klik("btn_spec")
	assert_eq(Game.spec("ivo"), galaz, "wybrana specjalizacja zapisana")
	assert_null(k.znajdz("btn_spec"), "po wyborze nie da się wybrać ponownie")
	# węzły drzewka są klikalne i pokazują opis
	var pierwsza := str(Data.hero("ivo")["umiejetnosci"][0]["id"])
	await klik("wezel_" + pierwsza)
	assert_eq(str(k.parametry()["wezel"]), pierwsza)

func test_ekwipunek_zaloz_i_zdejmij():
	Game.state["magazyn"] = ["szyszak", "helm_garnczkowy"]
	k.idz("ekwipunek", {"id": "ivo"})
	await wait_frames(2)
	await klik("slot_helm")
	var stary := str(Game.ekwipunek("ivo").get("helm", ""))
	await klik("btn_zaloz_helm_garnczkowy")
	assert_eq(str(Game.ekwipunek("ivo")["helm"]), "helm_garnczkowy", "założono wskazany przedmiot")
	if stary != "":
		assert_true(Game.state["magazyn"].has(stary), "poprzedni hełm wrócił do magazynu")
	await klik("btn_zdejmij")
	assert_false(Game.ekwipunek("ivo").has("helm"))
	assert_true(Game.state["magazyn"].has("helm_garnczkowy"))

func test_formacja_dotkniecia():
	k.idz("formacja")
	await wait_frames(2)
	await klik("lawka_ivo")
	await klik("pole_0")
	assert_eq(Game.pole_bohatera("ivo"), 0, "dotknięcie pola przestawia wybranego bohatera")
	await klik("pole_0")
	assert_eq(Game.pole_bohatera("ivo"), -1, "dotknięcie własnego pola zdejmuje z szyku")
	await klik("pole_3")
	assert_eq(Game.pole_bohatera("ivo"), 3)
	await klik("btn_zdejmij_z_szyku")
	assert_eq(Game.pole_bohatera("ivo"), -1)

func test_tawerna_rekrutacja():
	await klik("kafel_tawerna")
	await klik("najemnik_modraszka")
	assert_eq(k.ekran(), "najemnik")
	var korony := int(Game.state["korony"])
	await klik("btn_rekrutuj")
	assert_true(Game.ma("modraszka"))
	assert_eq(int(Game.state["korony"]), korony - Game.koszt_zakupu("modraszka"))
	assert_eq(k.ekran(), "bohater", "po werbunku otwiera się ekran nowego bohatera")
	await klik("btn_wroc")
	assert_eq(k.ekran(), "tawerna")
	assert_null(k.znajdz("najemnik_modraszka"), "zwerbowana znika z listy")
	Game.state["korony"] = 0
	await klik("najemnik_ursa")
	assert_true(k.znajdz("btn_rekrutuj").disabled, "bez koron nie da się werbować")

func test_misje_statusy_trudnosc_i_start():
	await klik("kafel_misje")
	await klik("misja_odbicie_hufduhofu")
	assert_true(k.znajdz("btn_start").disabled, "zablokowana misja nie startuje")
	await klik("btn_wroc")
	await klik("misja_piwnice_carroburga")
	assert_eq(str(k.parametry()["trudnosc"]), "normal")
	await klik("trudnosc_hard")
	assert_true(k.znajdz("btn_start").disabled, "Hard zablokowany przed ukończeniem Normal")
	await klik("trudnosc_normal")
	await klik("btn_start")
	assert_true(main.current is BattleScene)
	assert_eq(main.current.adv_id, "piwnice_carroburga")
	assert_eq(main.current.trudnosc, "normal")
	assert_eq(get_tree().root.content_scale_aspect, Window.CONTENT_SCALE_ASPECT_KEEP, "bitwa wraca do proporcji 16:9")

func test_rekord_hardcore_na_ekranie_misji():
	Game.state["postep"]["piwnice_carroburga"] = {"normal": true, "hard": true, "hardcore": true}
	Game.zapisz_ranking("piwnice_carroburga", "hardcore", 5, 41.3, ["ivo", "borubar"])
	k.idz("misja", {"id": "piwnice_carroburga"})
	await wait_frames(2)
	var l: Label = k.find_child("rekord", true, false)
	assert_string_contains(l.text, "41.3")
	assert_string_contains(l.text, "Ivo Eggert")

func test_lazaret_ranni_polegli_i_leczenie():
	var ivo := Progression.bohater("ivo", 1, "", Game.ekwipunek("ivo"), 2)
	var bor := Progression.bohater("borubar", 1, "", Game.ekwipunek("borubar"), 1)
	ivo.hp = ivo.max_hp * 0.5
	bor.alive = false
	bor.hp = 0.0
	Game.zapisz_zdrowie([ivo, bor])
	assert_true(Game.ranny("ivo"))
	assert_true(Game.polegly("borubar"))
	assert_eq(Game.hp_akt("borubar"), 0)
	assert_eq(Game.druzyna(Data.adventure("piwnice_carroburga")).size(), 1, "poległy nie wyrusza na misję")
	assert_almost_eq(Game.druzyna(Data.adventure("piwnice_carroburga"))[0].hp, ivo.max_hp * 0.5, 1.0, "ranny wyrusza z aktualnym HP")
	# zapis i odczyt zachowują zdrowie
	Game.new_game(false)
	assert_true(Game.load_game())
	assert_true(Game.polegly("borubar"))
	# czas leczy
	Game.czas_testowy += 60.0
	assert_almost_eq(Game.hp_proc("ivo"), 0.6, 0.01, "10% na minutę")
	Game.czas_testowy += 200.0
	assert_false(Game.polegly("borubar"), "po czasie lazaretu poległy wraca")
	assert_true(Game.ranny("borubar"))
	# leczenie za korony przyciskiem na ekranie bohatera
	k.idz("bohater", {"id": "borubar"})
	await wait_frames(2)
	var korony := int(Game.state["korony"])
	await klik("btn_ulecz")
	assert_false(Game.ranny("borubar"))
	assert_lt(int(Game.state["korony"]), korony)
	assert_null(k.znajdz("btn_ulecz"), "zdrowy bohater nie ma przycisku leczenia")

func test_osiagniecia_odbior_nagrody():
	await klik("kafel_osiagniecia")
	var klejnoty := int(Game.state["klejnoty"])
	await klik("btn_odbierz_ocalaly")
	assert_eq(int(Game.state["klejnoty"]), klejnoty + 5)
	assert_null(k.znajdz("btn_odbierz_ocalaly"), "nagrody nie da się odebrać drugi raz")
	assert_true(k.znajdz("btn_odbierz_mistrz").disabled, "niezdobyte osiągnięcie nie daje nagrody")
	assert_false(Game.odbierz_osiagniecie("ocalaly"))

func test_stary_zapis_bez_nowych_pol():
	Save.write({"wersja": 1, "prolog_ukonczony": true, "korony": 77, "klejnoty": 3, "favor": 0.05,
		"bohaterowie": {"ivo": {"poziom": 4, "spec": "", "ekwipunek": {}}}, "formacja": ["", "", "ivo"], "magazyn": [], "postep": {}, "ranking": []})
	Game.new_game(false)
	assert_true(Game.load_game())
	assert_eq(Game.poziom("ivo"), 4)
	assert_false(Game.ranny("ivo"))
	assert_eq(Game.hp_akt("ivo"), Game.hp_max("ivo"))
	assert_eq(Game.osiagniecia_do_odebrania(), 1)
	k.hub()
	await wait_frames(2)
	for e in k.EKRANY:
		k.idz(e, {"id": "ivo"} if e in ["bohater", "rozwoj", "ekwipunek"] else {"id": "piwnice_carroburga"} if e == "misja" else {"id": "ursa"} if e == "najemnik" else {})
		await wait_frames(2)
		assert_eq(k.ekran(), e)
		k.hub()

func test_karta_postaci_strony_i_sloty():
	k.idz("bohater", {"id": "ivo"})
	await wait_frames(2)
	assert_not_null(k.find_child("*", true, false), "karta zbudowana")
	var logo := k.find_children("*", "LogoCC", true, false)
	assert_eq(logo.size(), 1, "na karcie jest logo Carroburg Champions")
	await klik("btn_strona")
	assert_eq(int(k.parametry()["strona"]), 2, "strona II: historia i talenty")
	assert_not_null(k.znajdz("btn_ekwipunek"), "środkowa kolumna zostaje na obu stronach")
	await klik("btn_strona")
	assert_eq(int(k.parametry()["strona"]), 1)
	await klik("karta_slot_helm")
	assert_eq(k.ekran(), "ekwipunek", "slot na sylwetce otwiera ekwipunek")
	assert_eq(str(k.parametry()["slot"]), "helm", "od razu na właściwym slocie")
	await klik("btn_wroc")
	await klik("btn_rozwoj")
	assert_eq(k.ekran(), "rozwoj", "przycisk Trening prowadzi do treningu")

func test_sklep_oferta_zawsze_bron_pancerz_wstega():
	var rng := RandomNumberGenerator.new()
	for proba in 30:
		rng.seed = proba
		var o := Sklep.losuj_oferte(rng, Game.state["bohaterowie"].keys())
		var sloty: Array = o.map(func(id): return str(Data.item(str(id))["slot"]))
		for s in ["bron", "zbroja", "wstega"]:
			assert_eq(sloty.count(s), 1, "dostawa %d ma dokładnie jeden przedmiot slotu %s" % [proba, s])
		assert_eq(o.size(), 3 + int(Data.items["sklep"]["dodatkowe"]), "stałe + losowe okazje")
		var bez_powtorzen := {}
		for id in o:
			bez_powtorzen[id] = true
			assert_true(bool(Data.item(str(id)).get("sklep", false)), "tylko towar sklepowy")
			assert_true(Sklep.przydatny(str(id), Game.state["bohaterowie"].keys()), "ktoś z drużyny może to nosić")
		assert_eq(bez_powtorzen.size(), o.size(), "bez powtórzeń")

func test_sklep_towar_ma_plus_jeden_do_cech():
	for id in Sklep.pula(func(_it): return true):
		var it := Data.item(str(id))
		assert_gt(int(it.get("cena", 0)), 0, "%s ma cenę" % id)
		for c in it["cechy"]:
			if c in KW.CECHY:
				assert_eq(int(it["cechy"][c]), 1, "%s: cecha %s +1" % [id, c])

func test_sklep_zakup_i_nowa_dostawa_po_misji():
	await klik("kafel_sklep")
	assert_eq(k.ekran(), "sklep")
	assert_not_null(k.find_child("kupiec", true, false), "kupiec ze zdjęcia na ekranie")
	var oferta: Array = Game.sklep_oferta().duplicate()
	var id := str(oferta[0])
	var korony := int(Game.state["korony"])
	await klik("btn_kup_" + id)
	assert_eq(int(Game.state["korony"]), korony - Game.cena(id), "zakup kosztuje korony")
	assert_true(Game.state["magazyn"].has(id), "przedmiot trafia do magazynu")
	assert_null(k.znajdz("btn_kup_" + id), "kupiona pozycja jest wyprzedana")
	assert_false(Game.kup_przedmiot(id), "drugi raz w tej dostawie się nie da")
	var d := Game.sklep_dostawa()
	Game.sklep_nowa_dostawa()
	assert_eq(Game.sklep_dostawa(), d + 1, "po misji nowa dostawa")
	assert_true(Game.state["sklep"]["kupione"].is_empty(), "nowa dostawa - nic jeszcze nie kupione")
	# kupiony przedmiot da się założyć
	var slot := str(Data.item(id)["slot"])
	for h in Game.state["bohaterowie"]:
		if Game.pasuje(id, h, slot):
			assert_true(Game.zaloz(h, id))
			assert_eq(str(Game.ekwipunek(h)[slot]), id)
			break

func test_sklep_bez_koron_przycisk_nieaktywny():
	Game.state["korony"] = 0
	k.idz("sklep")
	await wait_frames(2)
	var b := k.znajdz("btn_kup_" + str(Game.sklep_oferta()[0]))
	assert_not_null(b)
	assert_true(b.disabled, "nie stać - nie kupisz")
