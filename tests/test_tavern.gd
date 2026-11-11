extends GutTest
## Prolog w karczmie: Borubar łapie kufle sam, strzały gracza odpychają gości.

func graj(bot: bool, seed_: int, limit: float = 240.0) -> TavernSim:
	var s := TavernSim.new()
	s.setup(Data.adventures["prolog_karczma"], seed_)
	while not s.koniec and s.time < limit:
		s.step(0.05)
		if bot and not s.kufel.is_empty() and float(s.kufel["T"]) - float(s.kufel["t"]) < 1.2:
			var x1: float = float(s.kufel["x1"])
			for k in s.klienci:
				if k["aktywny"] and absf(float(k["x"]) - x1) < 120.0:
					s.strzal(float(k["x"]))
					break
	return s

func test_ze_strzalami_borubar_lapie_wszystkie_kufle():
	for seed_ in [1, 2, 3, 4]:
		var s := graj(true, seed_)
		assert_true(s.koniec, "minigra kończy się, gdy gracz odpycha gości (ziarno %d)" % seed_)
		assert_eq(s.zlapane, s.cel())
		assert_eq(s.rozbite, 0, "Borubar zawsze zdąży dobiec do kufla")
		gut.p("karczma ze strzałami: %.0f s, skradzione %d" % [s.time, s.skradzione])

func test_bez_strzalow_goscie_kradna_kufle():
	var s := graj(false, 1, 120.0)
	assert_false(s.koniec, "bez strzałów nie da się skończyć - goście zabierają kufle")
	assert_gt(s.skradzione, 5)
	assert_gte(s.zlapane, 1, "pierwszy kufel (bez gości) Borubar łapie sam")

func test_strzal_odpycha_od_kufla_i_spowalnia():
	var s := TavernSim.new()
	s.setup(Data.adventures["prolog_karczma"], 1)
	s.kufel = {"x0": 1100.0, "x1": 500.0, "t": 0.0, "T": 3.0}
	s.klienci[0]["x"] = 520.0
	s.klienci[0]["aktywny"] = true
	assert_true(s.strzal(520.0))
	for i in 10:
		s.step(0.05)
	assert_gt(float(s.klienci[0]["x"]), 600.0, "gość odepchnięty od miejsca upadku")
	assert_gt(float(s.klienci[0]["slow_t"]), 0.0)
	assert_false(s.strzal(520.0) and s.strzal(520.0), "strzał ma odnowienie")
