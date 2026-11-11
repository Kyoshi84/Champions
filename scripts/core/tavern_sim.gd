class_name TavernSim
extends RefCounted
## Logika minigry w karczmie (prolog). Borubar SAM biegnie po kufle rzucane przez barmana.
## Gracz tylko strzela: strzał odpycha gości od miejsca upadku kufla i ich spowalnia.
## Kufel łapie gość, jeśli w chwili upadku stoi w zasięgu; w przeciwnym razie Borubar (jeśli zdążył).
## Liczby: data/adventures.json -> "prolog_karczma".

var cfg: Dictionary = {}
var rng := RandomNumberGenerator.new()
var time: float = 0.0
var borubar_x: float = 0.0
var borubar_idzie: bool = false
var zlapane: int = 0
var skradzione: int = 0
var rozbite: int = 0
var klienci: Array = []        # [{x, dom, slow_t, odrzut, aktywny}]
var kufel: Dictionary = {}     # {x0, x1, t, T}
var przerwa_t: float = 1.5
var strzal_cd: float = 0.0
var events: Array = []
var koniec: bool = false

func setup(c: Dictionary, seed_: int) -> void:
	cfg = c
	rng.seed = seed_
	borubar_x = float(cfg.get("borubar_start_x", 560))
	klienci.clear()
	for hx in cfg.get("klienci_domy_x", []):
		klienci.append({"x": float(hx), "dom": float(hx), "slow_t": 0.0, "odrzut": 0.0, "aktywny": false})

func cel() -> int:
	return int(cfg.get("kufle_cel", 6))

func liczba_aktywnych() -> int:
	var arr: Array = cfg.get("klienci_po_zlapanych", [0])
	return mini(int(arr[mini(zlapane, arr.size() - 1)]), klienci.size())

func etap_podpowiedzi() -> int:
	return mini(liczba_aktywnych(), cfg.get("podpowiedzi", []).size() - 1)

func step(dt: float) -> void:
	if koniec:
		return
	time += dt
	strzal_cd = maxf(0.0, strzal_cd - dt)
	if kufel.is_empty():
		przerwa_t -= dt
		if przerwa_t <= 0.0:
			_rzut()
	else:
		kufel["t"] = float(kufel["t"]) + dt
	var fx: Array = cfg.get("podloga_x", [150, 1000])
	# Borubar
	borubar_idzie = false
	if not kufel.is_empty():
		var d: float = float(kufel["x1"]) - borubar_x
		var krok: float = float(cfg.get("borubar_predkosc", 150)) * dt
		if absf(d) > 2.0:
			borubar_x += clampf(d, -krok, krok)
			borubar_idzie = true
	# goście
	for k in klienci:
		k["slow_t"] = maxf(0.0, float(k["slow_t"]) - dt)
		if absf(float(k["odrzut"])) > 0.5:
			var mv: float = clampf(float(k["odrzut"]), -700.0 * dt, 700.0 * dt)
			k["x"] = clampf(float(k["x"]) + mv, float(fx[0]), float(fx[1]))
			k["odrzut"] = float(k["odrzut"]) - mv
			continue
		var cel_x: float = float(k["dom"])
		if k["aktywny"] and not kufel.is_empty():
			cel_x = float(kufel["x1"])
		var v: float = float(cfg.get("klient_predkosc", 205))
		if float(k["slow_t"]) > 0.0:
			v *= 1.0 - float(cfg.get("strzal", {}).get("spowolnienie", 0.6))
		var dd: float = cel_x - float(k["x"])
		k["x"] = float(k["x"]) + clampf(dd, -v * dt, v * dt)
	if not kufel.is_empty() and float(kufel["t"]) >= float(kufel["T"]):
		_ladowanie()

func _rzut() -> void:
	var fx: Array = cfg.get("podloga_x", [150, 1000])
	var T: float = float(cfg.get("czas_lotu", 3.2))
	var maks: float = float(cfg.get("borubar_predkosc", 150)) * T * 0.85
	var x1 := borubar_x
	for i in 12:
		var d := rng.randf_range(130.0, maks) * (1.0 if rng.randf() < 0.5 else -1.0)
		x1 = borubar_x + d
		if x1 >= float(fx[0]) + 20.0 and x1 <= float(fx[1]) - 20.0:
			break
		x1 = clampf(x1, float(fx[0]) + 20.0, float(fx[1]) - 20.0)
	kufel = {"x0": float(cfg.get("barman_x", 1140)) - 40.0, "x1": x1, "t": 0.0, "T": T}
	# do kufla ruszają goście siedzący najbliżej miejsca upadku
	var n := liczba_aktywnych()
	var kolej: Array = range(klienci.size())
	kolej.sort_custom(func(a, b): return absf(float(klienci[a]["dom"]) - x1) < absf(float(klienci[b]["dom"]) - x1))
	for i in klienci.size():
		klienci[kolej[i]]["aktywny"] = i < n
	events.append({"typ": "rzut", "x": x1})

func _ladowanie() -> void:
	var x1: float = float(kufel["x1"])
	var r: float = float(cfg.get("promien_lapania", 46))
	var gosc := false
	for k in klienci:
		if k["aktywny"] and absf(float(k["x"]) - x1) <= r:
			gosc = true
	if gosc:
		skradzione += 1
		events.append({"typ": "skradziony", "x": x1})
	elif absf(borubar_x - x1) <= r:
		zlapane += 1
		events.append({"typ": "zlapany", "x": x1})
	else:
		rozbite += 1
		events.append({"typ": "rozbity", "x": x1})
	kufel = {}
	for k in klienci:
		k["aktywny"] = false
	przerwa_t = float(cfg.get("przerwa", 1.3))
	if zlapane >= cel():
		koniec = true
		events.append({"typ": "koniec"})

## Strzał gracza w punkt x podłogi. Odpycha gości w promieniu od miejsca upadku kufla i spowalnia ich.
func strzal(x: float) -> bool:
	if koniec or strzal_cd > 0.0:
		return false
	var s: Dictionary = cfg.get("strzal", {})
	strzal_cd = float(s.get("odnowienie", 0.35))
	var trafieni := 0
	for k in klienci:
		if absf(float(k["x"]) - x) > float(s.get("promien", 115)):
			continue
		var od: float = x
		if not kufel.is_empty():
			od = float(kufel["x1"])
		var kier := signf(float(k["x"]) - od)
		if kier == 0.0:
			kier = signf(float(k["x"]) - borubar_x)
		if kier == 0.0:
			kier = 1.0
		k["odrzut"] = kier * float(s.get("odrzut", 180))
		k["slow_t"] = float(s.get("czas", 1.8))
		trafieni += 1
	events.append({"typ": "strzal", "x": x, "trafieni": trafieni})
	return true
