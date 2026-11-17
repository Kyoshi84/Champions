extends GutTest
## Arena: odblokowanie, drabinka, osobny szyk, walka bez strzału gracza i bez łupu, nagrody i rekord.

var main: Node
var k: BarracksScene
var _stara_sciezka: String
var _wymagani: int

func before_each():
	_stara_sciezka = Save.save_path
	_wymagani = int(Data.arena.get("wymagani_bohaterowie", 10))
	Save.save_path = "user://test_zapis_arena.json"
	Save.delete_save()
	Game.new_game(false)
	Game.ukoncz_prolog()
	Game.state["korony"] = 5000

func after_each():
	Data.arena["wymagani_bohaterowie"] = _wymagani
	Save.delete_save()
	Save.save_path = _stara_sciezka

func otworz_koszary() -> void:
	main = load("res://scripts/main.gd").new()
	add_child_autofree(main)
	main.go("koszary")
	await wait_frames(2)
	k = main.current

func klik(nazwa: String) -> void:
	var b := k.znajdz(nazwa)
	assert_not_null(b, "jest przycisk " + nazwa)
	if b != null:
		assert_false(b.disabled, "przycisk %s jest aktywny" % nazwa)
		b.pressed.emit()
	await wait_frames(2)

func test_arena_zamknieta_ponizej_10_bohaterow():
	assert_eq(Game.arena_wymagani(), 10)
	assert_false(Game.arena_odblokowana(), "dwóch bohaterów to za mało")
	await otworz_koszary()
	await klik("kafel_arena")
	assert_eq(k.ekran(), "arena", "zamkniętą arenę można obejrzeć")
	assert_true(k.znajdz("btn_arena_start").disabled, "ale nie da się walczyć")
	await klik("btn_do_tawerny")
	assert_eq(k.ekran(), "tawerna", "zamknięta arena prowadzi do rekrutacji")

func test_drabinka_nagrody_i_rekord():
	var lista := Data.arena_lista()
	assert_eq(str(lista[0]["id"]), "szczurza_banda")
	var sklad: Array = lista[0]["sklad"]
	assert_eq(sklad.count("szczur"), 5)
	assert_eq(sklad.count("szczur_strzelec"), 3)
	assert_eq(sklad.count("szczur_mag"), 2)
	assert_eq(Game.arena_status("szczurza_banda"), "dostepny")
	assert_eq(Game.arena_status(str(lista[1]["id"])), "wkrotce", "drugi szczebel wyszarzony do zaprojektowania")
	var kor := int(Game.state["korony"])
	var n := Game.arena_wygrana("szczurza_banda", 30.0)
	assert_true(bool(n["pierwszy_raz"]))
	assert_eq(int(Game.state["korony"]), kor + 150)
	assert_eq(int(n["klejnoty"]), 5)
	assert_eq(Game.arena_status("szczurza_banda"), "pokonany")
	assert_eq(Game.arena_status(str(lista[1]["id"])), "wkrotce", "szczebel 'wkrótce' nie otwiera się mimo zwycięstwa")
	var n2 := Game.arena_wygrana("szczurza_banda", 40.0)
	assert_false(bool(n2["pierwszy_raz"]))
	assert_eq(int(n2["klejnoty"]), 0, "powtórka bez klejnotów")
	assert_lt(int(n2["korony"]), 150, "powtórka daje część koron")
	assert_false(bool(n2["rekord"]), "gorszy czas nie bije rekordu")
	assert_almost_eq(float(Game.state["arena"]["rekordy"]["szczurza_banda"]), 30.0, 0.01)

func test_osobny_szyk_areny_bez_limitu_miejsc():
	Game.kup("modraszka")
	Game.kup("ursa")
	var kampania: Array = Game.state["formacja"].duplicate()
	Game.arena_auto()
	assert_eq(Game.w_formacji("arena").size(), 4, "na arenę wchodzą wszyscy, bez limitu miejsc z kampanii")
	assert_eq(Game.state["formacja"], kampania, "szyk kampanii się nie zmienił")
	assert_true(Game.ustaw("ivo", 9, "arena"))
	assert_eq(Game.pole_bohatera("ivo", "arena"), 9)
	assert_ne(Game.pole_bohatera("ivo"), 9)
	Game.zdejmij("ivo", "arena")
	assert_eq(Game.pole_bohatera("ivo", "arena"), -1)
	assert_ne(Game.pole_bohatera("ivo"), -1, "zdjęcie z areny nie rusza kampanii")

func test_walka_na_arenie():
	Game.kup("modraszka")
	Game.kup("ursa")
	Game.arena_auto()
	var c := Combat.new()
	c.setup(Game.arena_druzyna(), Game.arena_przygoda("szczurza_banda"), 0, Data.difficulty("normal"), 5)
	assert_eq(c.enemies.size(), 10, "cała drużyna przeciwnika stoi od początku")
	for e in c.enemies:
		var front := Formation.rzad(e.slot) == 0
		assert_eq(e.id == "szczur", front, "szczury z przodu, strzelcy i magowie z tyłu")
		assert_eq(e.tor, Formation.tor(e.slot))
	assert_false(c.strzal_gracza(c.enemies[0].x, c.enemies[0].y - 30), "na arenie gracz nie strzela")
	var zloto := 0
	for i in 3000:
		c.step(0.1)
		for ev in c.events:
			if str(ev["typ"]) == "zloto":
				zloto += 1
		c.events.clear()
		if c.result != "":
			break
	assert_eq(c.result, "wygrana")
	assert_eq(zloto, 0, "z wrogów na arenie nie wypadają monety")
	assert_eq(c.zabici, 10)

func test_ultimate_na_arenie_sam_sie_odpala():
	Game.kup("ursa")
	Game.state["bohaterowie"]["ursa"]["poziom"] = 20
	var adv := Game.arena_przygoda("szczurza_banda")
	adv["skala_hp"] = 40.0                 # długa walka, żeby Ultimate zdążył się naładować
	var h := Progression.bohater("ursa", 20, "", {}, 7)
	assert_false(h.ult.is_empty())
	var c := Combat.new()
	c.setup([h, Progression.bohater("borubar", 20, "", {}, 2)], adv, 0, Data.difficulty("normal"), 1)
	assert_gt(h.ult_cd, 0.0, "Ultimate nie jest gotowy od pierwszej sekundy")
	var uzyty := false
	for i in 3000:
		c.step(0.1)
		for ev in c.events:
			if str(ev["typ"]) == "ultimate":
				uzyty = true
		c.events.clear()
		if uzyty or c.result != "":
			break
	assert_true(uzyty, "bohater sam użył Ultimate")

func test_pelna_sciezka_w_koszarach():
	Data.arena["wymagani_bohaterowie"] = 4
	Game.kup("modraszka")
	Game.kup("ursa")
	await otworz_koszary()
	await klik("kafel_arena")
	assert_eq(k.ekran(), "arena")
	assert_true(k.znajdz("btn_arena_start").disabled, "bez drużyny areny nie ma walki")
	await klik("btn_druzyna_areny")
	assert_eq(k.ekran(), "formacja_areny")
	assert_eq(Game.w_formacji("arena").size(), 4, "pierwsze wejście układa drużynę areny")
	await klik("lawka_ivo")
	await klik("pole_3")
	assert_eq(Game.pole_bohatera("ivo", "arena"), 3)
	await klik("btn_wroc")
	await klik("btn_arena_start")
	var b: BattleScene = main.current
	assert_eq(b.arena_id, "szczurza_banda")
	assert_true(b.ult_btns.is_empty(), "na arenie nie ma przycisków Ultimate")
	for i in 4000:
		b._process(0.1)
		if b.faza == "pauza":
			break
	assert_eq(b.sim.result, "wygrana")
	assert_true(Game.arena_pokonany("szczurza_banda"))
	assert_false(Game.ranny("ivo") or Game.polegly("ivo"), "arena nie zostawia ran")
	main.go("koszary", {"ekran": "arena"})
	await wait_frames(2)
	k = main.current
	assert_eq(k.ekran(), "arena", "po walce wraca się prosto na arenę")
	assert_eq(k.stos.size(), 2, "pod areną jest Hub")

func test_stary_zapis_bez_areny():
	Save.write({"wersja": 1, "prolog_ukonczony": true, "korony": 10, "klejnoty": 0, "favor": 0.0,
		"bohaterowie": {"ivo": {"poziom": 2, "spec": "", "ekwipunek": {}}}, "formacja": ["", "", "ivo"], "magazyn": [], "postep": {}, "ranking": []})
	assert_true(Game.load_game())
	assert_eq(Game.szyk("arena").size(), Formation.POLA)
	assert_eq(Game.arena_status("szczurza_banda"), "dostepny")
