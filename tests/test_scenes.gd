extends GutTest
## Przepływ ekranów od prologu do Koszar - na prawdziwych scenach, z przyspieszonym czasem.

var main: Node
var _stara_sciezka: String

func before_each():
	_stara_sciezka = Save.save_path
	Save.save_path = "user://test_zapis.json"
	Save.delete_save()
	Game.new_game(false)
	main = load("res://scripts/main.gd").new()
	add_child_autofree(main)

func after_each():
	Save.delete_save()
	Save.save_path = _stara_sciezka

func zamknij_opowiesci(scena: Node) -> void:
	# przeklikuje plansze fabularne (przycisk na każdej stronie)
	for i in 12:
		var znaleziono := false
		if not is_instance_valid(scena):
			break
		for l in scena.get_children():
			if l is CanvasLayer and l.layer >= 40:
				var btns := l.find_children("*", "Button", true, false)
				if not btns.is_empty():
					btns[0].pressed.emit()
					znaleziono = true
		await wait_frames(2)
		if not znaleziono:
			break

func test_menu_i_karczma():
	await wait_frames(2)
	assert_true(main.current is MenuScene)
	main.go("karczma")
	await wait_frames(2)
	var k: TavernScene = main.current
	assert_false(k.aktywna, "przed startem jest plansza fabularna")
	await zamknij_opowiesci(k)
	assert_true(k.aktywna)
	# gramy: strzał w gości tuż przed upadkiem kufla
	for i in 4000:
		k._process(0.05)
		if not k.sim.kufel.is_empty() and float(k.sim.kufel["T"]) - float(k.sim.kufel["t"]) < 1.2:
			for g in k.sim.klienci:
				if g["aktywny"] and absf(float(g["x"]) - float(k.sim.kufel["x1"])) < 120.0:
					k.sim.strzal(float(g["x"]))
					break
		if k.sim.koniec:
			break
	assert_true(k.sim.koniec, "karczma ukończona")
	await zamknij_opowiesci(k)
	await wait_frames(2)
	assert_true(main.current is BattleScene, "po karczmie - ucieczka przez wieś")
	assert_eq(main.current.adv_id, "prolog_wies")

func test_prolog_wies_konczy_sie_w_koszarach():
	main.go("bitwa", {"przygoda": "prolog_wies", "trudnosc": "normal"})
	await wait_frames(2)
	var b: BattleScene = main.current
	assert_eq(b.heroes.size(), 1)
	assert_eq(b.heroes[0].id, "borubar")
	var najdalej := 0
	for i in 6000:
		if not is_instance_valid(b) or main.current != b:
			break
		b._process(0.1)
		najdalej = maxi(najdalej, b.plansza)
		if b.faza == "walka":
			var best: CUnit = null
			for e in b.sim.enemies:
				if e.alive and e.x < 1250 and (best == null or e.x < best.x):
					best = e
			if best != null:
				b.sim.strzal_gracza(best.x, best.y - 30)
		elif b.faza == "pauza":
			break
	assert_eq(najdalej, 4, "Borubar dociera do Championa Chaosu (plansza 5)")
	assert_eq(b.sim.result, "przegrana", "i z nim przegrywa")
	assert_true(bool(Game.state["prolog_ukonczony"]))
	assert_true(Game.ma("borubar"), "po prologu Borubar dołącza do drużyny")
	await zamknij_opowiesci(b)
	await wait_frames(2)
	assert_true(main.current is BarracksScene, "po przegranej trafiamy do Koszar")

func test_koszary_i_pierwsza_przygoda():
	Game.ukoncz_prolog()
	Game.state["korony"] = 500
	main.go("koszary")
	await wait_frames(2)
	var k: BarracksScene = main.current
	assert_eq(Game.w_formacji().size(), 2, "Ivo i Borubar w formacji")
	assert_eq(Game.miejsca(), 2)
	assert_true(Game.kup("modraszka"))
	assert_eq(Game.pole_bohatera("modraszka"), -1, "brak wolnego miejsca - Modraszka w rezerwie")
	assert_false(Game.ustaw("modraszka", 7), "nie da się przekroczyć limitu miejsc")
	assert_true(Game.ustaw("ivo", 1), "przestawienie w formacji")
	assert_true(Game.awansuj("ivo"))
	assert_eq(Game.poziom("ivo"), 2)
	k._buduj()
	await wait_frames(2)
	main.go("bitwa", {"przygoda": "piwnice_carroburga", "trudnosc": "normal"})
	await wait_frames(2)
	var b: BattleScene = main.current
	assert_eq(b.heroes.size(), 2)
	var korony := int(Game.state["korony"])
	for i in 9000:
		b._process(0.1)
		if b.faza == "walka":
			var best: CUnit = null
			for e in b.sim.enemies:
				if e.alive and e.x < 1250 and (best == null or e.x < best.x):
					best = e
			if best != null:
				b.sim.strzal_gracza(best.x, best.y - 30)
		elif b.faza == "pauza":
			break
	assert_eq(b.sim.result, "wygrana", "Ivo + Borubar przechodzą Piwnice")
	assert_true(Game.ukonczona("piwnice_carroburga", "normal"))
	assert_gt(int(Game.state["korony"]), korony, "przygoda daje korony")
	assert_eq(Game.miejsca(), 4, "ukończona przygoda odblokowuje kolejne miejsca")
	assert_ne(Game.pole_bohatera("modraszka"), -1, "rezerwowa Modraszka wchodzi na wolne miejsce")
	assert_true(Game.dostepna("trakt_do_hufduhofu", "normal"))
	assert_true(Game.dostepna("piwnice_carroburga", "hard"))
	# zapis i odczyt
	var k2 := int(Game.state["korony"])
	Game.new_game(false)
	assert_true(Game.load_game())
	assert_eq(int(Game.state["korony"]), k2, "zapis progresji działa")
