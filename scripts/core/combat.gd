class_name Combat
extends RefCounted
## Symulacja walki na jednej planszy. Jeden wspólny zegar: stały krok (tick) z data/balance.json,
## wszystkie jednostki liczą swoje czasy w tym samym kroku - żadnych niezależnych timerów.
## Symulacja nie zna grafiki: widok woła step(delta), czyta listy heroes/enemies i opróżnia 'events'.
## Przy tym samym ziarnie i tych samych akcjach gracza wynik jest identyczny (testy).

var B: Dictionary = {}
var heroes: Array = []          # Array[CUnit] - żyją między planszami przygody
var enemies: Array = []         # Array[CUnit]
var events: Array = []
var time: float = 0.0
var rng := RandomNumberGenerator.new()
var board: Dictionary = {}
var adv: Dictionary = {}
var diff: Dictionary = {}
var result: String = ""         # "" | "wygrana" | "przegrana"
var powod: String = ""
var zloto: float = 0.0
var lup: int = 0
var zabici: int = 0
var favor: float = 0.0
var mnoznik_zlota: float = 1.0
var strzal_cd: float = 0.0
var strzal_mnoznik: float = 1.0
var _acc: float = 0.0
var _uid: int = 1000
var _fale: Array = []
var _fale_baza: float = 0.0
var _ostatni_spawn: float = 0.0
var _furia_t: float = 0.0
var _skala_hp: float = 1.0
var _skala_obr: float = 1.0
var _boss_pojawil_sie: bool = false

func setup(hero_units: Array, adventure: Dictionary, board_idx: int, difficulty: Dictionary, seed_: int, favor_: float = 0.0) -> void:
	B = Data.walka()
	heroes = hero_units
	adv = adventure
	board = adventure.get("plansze", [])[board_idx]
	diff = difficulty
	favor = favor_
	rng.seed = seed_
	strzal_mnoznik = float(adventure.get("strzal_mnoznik", 1.0))
	_skala_hp = float(adventure.get("skala_hp", 1.0)) * float(board.get("skala_hp", 1.0)) * float(diff.get("hp", 1.0))
	_skala_obr = float(adventure.get("skala_obrazen", 1.0)) * float(board.get("skala_obrazen", 1.0)) * float(diff.get("obrazenia", 1.0))
	_fale = []
	for f in board.get("fale", []):
		_fale.append({"t": float(f.get("t", 0.0)), "wrogowie": f.get("wrogowie", {}), "done": false})
	var i := 0
	for h in heroes:
		if h.uid == 0:
			_uid += 1
			h.uid = _uid
		h.cd = 1.0 + 0.35 * i
		h.cel = null
		h.statusy = []
		i += 1
	Formation.przelicz_aury(heroes)
	_przelicz_zloto()

func step(delta: float) -> void:
	var tick: float = float(B.get("tick", 0.1))
	_acc += delta
	var guard := 0
	while _acc >= tick and guard < 50:
		_acc -= tick
		guard += 1
		_tick(tick)

func _tick(dt: float) -> void:
	if result != "":
		return
	time += dt
	strzal_cd = maxf(0.0, strzal_cd - dt)
	_spawn()
	for u in heroes:
		_tick_statusy(u, dt)
	for u in enemies:
		_tick_statusy(u, dt)
	for h in heroes:
		if h.alive:
			_ruch_bohatera(h, dt)
	for e in enemies:
		if e.alive:
			_ruch_wroga(e, dt)
	_furia(dt)
	enemies = enemies.filter(func(e): return e.alive)
	_sprawdz_koniec()

# ---------------------------------------------------------------- fale
func _spawn() -> void:
	var tory: Array = B.get("tory_y", [340, 410, 480, 550, 620])
	var wszystkie := true
	for f in _fale:
		if f["done"]:
			continue
		if time < _fale_baza + float(f["t"]):
			wszystkie = false
			continue
		f["done"] = true
		_ostatni_spawn = time
		var n := 0
		var ids: Array = f["wrogowie"].keys()
		ids.sort()
		for id in ids:
			var def := Data.enemy(str(id))
			if def.is_empty():
				push_error("Nieznany wróg w planszy: " + str(id))
				continue
			var ile := int(f["wrogowie"][id])
			if not bool(def.get("boss", false)):
				ile = ceili(ile * float(diff.get("liczba", 1.0)))
			for k in ile:
				var e := Progression.wrog(str(id), _skala_hp, _skala_obr)
				_uid += 1
				e.uid = _uid
				e.tor = 2 if e.boss else rng.randi_range(0, tory.size() - 1)
				e.x = float(B.get("spawn_x", 1340)) + n * 46.0 + rng.randf_range(0.0, 30.0)
				e.y = float(tory[e.tor]) + rng.randf_range(-8.0, 8.0)
				e.cd = float(e.atak.get("czas", 3.0)) * rng.randf_range(0.3, 0.9)
				e.niesmiertelny = board.get("niesmiertelni", []).has(str(id))
				if e.boss:
					_boss_pojawil_sie = true
				enemies.append(e)
				events.append({"typ": "spawn", "uid": e.uid})
				n += 1
	var petla: float = float(board.get("petla_fal", 0.0))
	if wszystkie and petla > 0.0 and time >= _ostatni_spawn + petla:
		_fale_baza = time
		for f in _fale:
			f["done"] = false

func fale_skonczone() -> bool:
	for f in _fale:
		if not f["done"]:
			return false
	return true

# ---------------------------------------------------------------- statusy
func _tick_statusy(u: CUnit, dt: float) -> void:
	if not u.alive:
		return
	u.odporny_t = maxf(0.0, u.odporny_t - dt)
	var ogien := u.status("podpalenie")
	for s in u.statusy:
		s["czas"] = float(s["czas"]) - dt
	u.statusy = u.statusy.filter(func(s): return float(s["czas"]) > 0.0)
	if ogien > 0.0:
		u._acc += ogien * dt
		if u._acc >= 1.0:
			var d := floorf(u._acc)
			u._acc -= d
			_zadaj(u, d, "ogien")
	var reg := float(u.aury.get("regeneracja", 0.0))
	if reg > 0.0 and u.alive:
		u.hp = minf(u.max_hp, u.hp + reg * dt)

func _status(t: CUnit, typ: String, wartosc: float, czas: float) -> void:
	if not t.alive or czas <= 0.0:
		return
	if typ == "ogluszenie":
		if t.odporny_t > 0.0:
			return
		czas = Wfrp.czas_ogluszenia(czas, t.cechy, t.odp_ogluszenie)
		t.odporny_t = czas + float(B.get("odpornosc_na_ogluszenie_po", 1.5))
	t.dodaj_status(typ, wartosc, czas)
	events.append({"typ": "status", "uid": t.uid, "status": typ, "czas": czas})

# ---------------------------------------------------------------- bohaterowie
func _ruch_bohatera(h: CUnit, dt: float) -> void:
	h.ult_cd = maxf(0.0, h.ult_cd - dt)
	if h.ma_status("ogluszenie"):
		return
	for s in h.skills_of("leczenie"):
		h.leczenie_cd -= dt
		if h.leczenie_cd <= 0.0:
			var ranny := _najbardziej_ranny()
			if ranny != null:
				h.leczenie_cd = float(s.get("co_s", 8.0))
				_ulecz(ranny, Wfrp.leczenie(float(s.get("moc", 5.0)), h.cechy), h)
			else:
				h.leczenie_cd = 0.0
	var tempo := (1.0 + float(h.aury.get("szybkosc", 0.0))) * (1.0 - h.status("spowolnienie"))
	h.cd -= dt * tempo
	if h.cd > 0.0:
		return
	var cel := _cel_bohatera(h)
	if cel == null:
		h.cd = 0.0
		return
	_atak(h, cel)
	h.cd = Wfrp.czas_ataku(float(h.atak.get("czas", 5.0)), h.cechy)

func _cel_bohatera(h: CUnit) -> CUnit:
	var kand: Array = []
	var wrecz := str(h.atak.get("typ", "wrecz")) == "wrecz"
	var zasieg := float(h.atak.get("zasieg", 200))
	for e in enemies:
		if not e.alive or e.x > float(B.get("ekran_x", 1260)):
			continue
		if wrecz and Vector2(e.x - h.x, (e.y - h.y) * 0.5).length() > zasieg:
			continue
		kand.append(e)
	if kand.is_empty():
		return null
	match str(h.atak.get("cel", "najblizszy")):
		"losowy":
			return kand[rng.randi_range(0, kand.size() - 1)]
		"najmniej_hp":
			kand.sort_custom(func(a, b): return a.hp < b.hp if a.hp != b.hp else a.uid < b.uid)
		"najwiecej_hp":
			kand.sort_custom(func(a, b): return a.hp > b.hp if a.hp != b.hp else a.uid < b.uid)
		_:
			kand.sort_custom(func(a, b):
				var da := Vector2(a.x - h.x, (a.y - h.y) * 0.5).length()
				var db := Vector2(b.x - h.x, (b.y - h.y) * 0.5).length()
				return da < db if da != db else a.uid < b.uid)
	return kand[0]

func _najbardziej_ranny() -> CUnit:
	var best: CUnit = null
	for h in heroes:
		if h.alive and h.hp < h.max_hp - 0.5:
			if best == null or h.hp_ulamek() < best.hp_ulamek():
				best = h
	return best

func _ulecz(t: CUnit, ile: float, src: CUnit) -> void:
	var przed := t.hp
	t.hp = minf(t.max_hp, t.hp + ile)
	events.append({"typ": "leczenie", "uid": t.uid, "ile": t.hp - przed, "od": src.uid})

# ---------------------------------------------------------------- wrogowie
func _zywi_bohaterowie() -> Array:
	return heroes.filter(func(h): return h.alive)

func _cel_wrecz(e: CUnit) -> CUnit:
	var zywi := _zywi_bohaterowie()
	if zywi.is_empty():
		return null
	var front := zywi.filter(func(h): return Formation.rzad(h.slot) == 0)
	var kand: Array = front if not front.is_empty() else zywi
	var best: CUnit = null
	var best_s := 999.0
	for h in kand:
		var s := float(absi(h.tor - e.tor))
		for p in h.skills_of("prowokacja"):
			if absi(h.tor - e.tor) <= int(p.get("zasieg_torow", 1)):
				s -= 10.0
		if s < best_s:
			best_s = s
			best = h
	return best

func _cel_dystans(e: CUnit) -> CUnit:
	var zywi := _zywi_bohaterowie()
	if zywi.is_empty():
		return null
	if str(e.atak.get("cel", "losowy")) == "tyl":
		var tyl := zywi.filter(func(h): return Formation.rzad(h.slot) == 1)
		if not tyl.is_empty():
			zywi = tyl
	return zywi[rng.randi_range(0, zywi.size() - 1)]

func _ruch_wroga(e: CUnit, dt: float) -> void:
	if e.ma_status("ogluszenie"):
		return
	var slow := 1.0 - e.status("spowolnienie")
	var v := e.predkosc * slow * dt
	var kontakt: float = float(B.get("kontakt_wrecz", 78))
	var na_miejscu := false
	match e.zachowanie:
		"dystans", "magia":
			var stop_x := float(e.def.get("dystans_x", 930))
			if e.x > stop_x:
				e.x = maxf(stop_x, e.x - v)
			else:
				na_miejscu = true
			if na_miejscu and (e.cel == null or not e.cel.alive or e.cd <= 0.0):
				e.cel = _cel_dystans(e)
		"skok":
			if e.cel == null or not e.cel.alive:
				e.cel = _cel_wrecz(e)
			if e.cel != null:
				var front_x: float = float(B.get("linia_frontu_x", 430)) + kontakt + 60.0
				if not e.skok_wykonany and e.x <= front_x:
					e.skok_wykonany = true
					var tyl := _zywi_bohaterowie().filter(func(h): return Formation.rzad(h.slot) == 1)
					if not tyl.is_empty():
						e.cel = tyl[rng.randi_range(0, tyl.size() - 1)]
						e.x = e.cel.x + kontakt
						e.y = e.cel.y + 6.0
						events.append({"typ": "skok", "uid": e.uid})
				na_miejscu = _podejdz(e, v, kontakt)
		_:
			if e.cel == null or not e.cel.alive:
				e.cel = _cel_wrecz(e)
			if e.cel != null:
				na_miejscu = _podejdz(e, v, kontakt)
	e.w_kontakcie = na_miejscu
	if not na_miejscu or e.cel == null:
		return
	var tempo := slow * (1.0 + e.furia * float(Data.balance.get("boss", {}).get("furia_szybkosc", 0.06)))
	e.cd -= dt * tempo
	if e.cd <= 0.0:
		_atak(e, e.cel)
		e.cd = Wfrp.czas_ataku(float(e.atak.get("czas", 3.0)), e.cechy)

func _podejdz(e: CUnit, v: float, kontakt: float) -> bool:
	var dest_x := e.cel.x + kontakt
	if e.x > dest_x:
		e.x = maxf(dest_x, e.x - v)
	var dy := e.cel.y + 6.0 - e.y
	e.y += clampf(dy, -v * 0.7, v * 0.7)
	return e.x <= dest_x + 0.5 and absf(dy) < 30.0

func _furia(dt: float) -> void:
	var b: Dictionary = Data.balance.get("boss", {})
	var jest := false
	for e in enemies:
		if e.alive and e.boss and e.x <= float(B.get("ekran_x", 1260)):
			jest = true
	if not jest:
		return
	_furia_t += dt
	if _furia_t >= float(b.get("furia_co_s", 10.0)):
		_furia_t = 0.0
		for e in enemies:
			if e.alive and e.boss and e.furia < int(b.get("furia_max", 12)):
				e.furia += 1
				events.append({"typ": "furia", "uid": e.uid, "stopien": e.furia})

# ---------------------------------------------------------------- atak i obrażenia
func _atak(att: CUnit, cel: CUnit) -> void:
	att.licznik_atakow += 1
	var typ := str(att.atak.get("typ", "wrecz"))
	var mnoznik := att.skala_obrazen
	for s in att.skills_of("atak_mnoznik"):
		mnoznik *= float(s.get("mnoznik", 1.0))
	var specjalny: Dictionary = {}
	for s in att.skills_of("co_n_atak"):
		if att.licznik_atakow % maxi(1, int(s.get("n", 3))) == 0:
			specjalny = s
			break
	if not specjalny.is_empty():
		mnoznik *= float(specjalny.get("mnoznik", 1.0))
	mnoznik *= 1.0 + float(att.aury.get("obrazenia", 0.0)) + att.status("wzmocnienie")
	mnoznik *= 1.0 - att.status("oslabienie")
	if att.furia > 0:
		mnoznik *= 1.0 + att.furia * float(Data.balance.get("boss", {}).get("furia_obrazenia", 0.15))
	var cele: Array = [cel]
	var promien := float(specjalny.get("promien", 0.0))
	if promien > 0.0:
		var pula: Array = enemies if att.team == 0 else heroes
		for o in pula:
			if o != cel and o.alive and Vector2(o.x - cel.x, o.y - cel.y).length() <= promien:
				cele.append(o)
	events.append({"typ": "atak", "od": att.uid, "do": cel.uid, "rodzaj": typ, "specjalny": str(specjalny.get("nazwa", "")),
		"pocisk": str(att.atak.get("pocisk", "")), "dzwiek": str(att.atak.get("dzwiek", "hit")), "promien": promien})
	for t in cele:
		_trafienie(att, t, typ, mnoznik, specjalny)

func _trafienie(att: CUnit, t: CUnit, typ: String, mnoznik: float, specjalny: Dictionary) -> void:
	if rng.randf() > Wfrp.szansa_trafienia(typ, att.cechy, t.cechy):
		events.append({"typ": "pudlo", "uid": t.uid})
		return
	if not t.ma_status("ogluszenie") and rng.randf() < Wfrp.unik(t.cechy):
		events.append({"typ": "unik", "uid": t.uid})
		return
	var dmg := Wfrp.obrazenia(typ, float(att.atak.get("bron", 1.0)), att.cechy, t.cechy, t.pancerz, mnoznik)
	dmg *= 1.0 - float(t.aury.get("redukcja", 0.0))
	dmg *= 1.0 - t.status("tarcza")
	_zadaj(t, maxf(1.0, dmg), typ)
	if not t.alive:
		return
	for s in att.skills_of("status_przy_trafieniu"):
		if rng.randf() <= float(s.get("szansa", 1.0)):
			_status(t, str(s.get("status", "")), float(s.get("wartosc", 0.0)), float(s.get("czas", 0.0)))
	if float(specjalny.get("ogluszenie", 0.0)) > 0.0:
		_status(t, "ogluszenie", 1.0, float(specjalny.get("ogluszenie", 0.0)))
	var odrzut := float(specjalny.get("odrzut", 0.0))
	if odrzut > 0.0 and t.team == 1 and not t.boss:
		t.x = minf(t.x + odrzut, float(B.get("ekran_x", 1260)))
		events.append({"typ": "odrzut", "uid": t.uid})

func _zadaj(t: CUnit, dmg: float, rodzaj: String) -> void:
	if not t.alive:
		return
	t.hp -= dmg
	events.append({"typ": "obrazenia", "uid": t.uid, "ile": dmg, "rodzaj": rodzaj})
	if t.hp > 0.0:
		return
	if t.niesmiertelny:
		t.hp = 1.0
		return
	t.hp = 0.0
	t.alive = false
	events.append({"typ": "smierc", "uid": t.uid, "team": t.team})
	if t.team == 1:
		zabici += 1
		lup += 1
		var z := t.zloto * mnoznik_zlota * float(diff.get("zloto", 1.0))
		zloto += z
		events.append({"typ": "zloto", "uid": t.uid, "ile": z})
	else:
		Formation.przelicz_aury(heroes)
		_przelicz_zloto()

func _przelicz_zloto() -> void:
	var m := 1.0 + favor
	for h in heroes:
		if not h.alive:
			continue
		m += Wfrp.premia_zlota(h.cechy)
		for s in h.skills_of("aura"):
			m += float(s.get("efekty", {}).get("zloto", 0.0))
	mnoznik_zlota = m

# ---------------------------------------------------------------- akcje gracza
## Strzał z nieba w punkt pola bitwy. Zwraca true, jeśli strzał padł (nie był w odnowieniu).
func strzal_gracza(px: float, py: float) -> bool:
	if result != "" or strzal_cd > 0.0:
		return false
	var s: Dictionary = Data.balance.get("strzal_gracza", {})
	strzal_cd = float(s.get("odnowienie", 0.6))
	var trafieni: Array = []
	for e in enemies:
		if not e.alive:
			continue
		var h := float(e.def.get("placeholder", {}).get("h", 70))
		var srodek := Vector2(e.x, e.y - h * 0.5)
		if Vector2(px, py).distance_to(srodek) <= float(s.get("promien", 64)) + h * 0.3:
			trafieni.append(e)
	events.append({"typ": "strzal", "x": px, "y": py, "trafieni": trafieni.size()})
	for e in trafieni:
		var czas := float(s.get("ogluszenie", 0.5))
		if e.boss:
			czas *= float(s.get("ogluszenie_bossa_mnoznik", 0.3))
		_zadaj(e, float(s.get("obrazenia", 1.5)) * strzal_mnoznik, "strzal")
		_status(e, "ogluszenie", 1.0, czas)
	enemies = enemies.filter(func(e): return e.alive)
	_sprawdz_koniec()
	return true

func ult_gotowy(h: CUnit) -> bool:
	return result == "" and h.alive and not h.ult.is_empty() and h.ult_cd <= 0.0 and not h.ma_status("ogluszenie")

func uzyj_ult(h: CUnit) -> bool:
	if not ult_gotowy(h):
		return false
	var u := h.ult
	h.ult_cd = float(u.get("odnowienie", 60.0))
	events.append({"typ": "ultimate", "uid": h.uid, "nazwa": str(u.get("nazwa", "")), "efekt": str(u.get("efekt", ""))})
	match str(u.get("efekt", "")):
		"ogluszenie_wszystkich":
			for e in enemies:
				if e.alive and e.x <= float(B.get("ekran_x", 1260)):
					e.odporny_t = 0.0
					_status(e, "ogluszenie", 1.0, float(u.get("czas", 3.0)) * (0.5 if e.boss else 1.0))
			if float(u.get("wzmocnienie", 0.0)) > 0.0:
				for o in heroes:
					_status(o, "wzmocnienie", float(u.get("wzmocnienie", 0.0)), float(u.get("wzmocnienie_czas", 6.0)))
		"leczenie_druzyny":
			for o in heroes:
				if o.alive:
					_ulecz(o, o.max_hp * float(u.get("moc", 0.3)), h)
		"status_wszystkich":
			for e in enemies:
				if e.alive:
					_status(e, str(u.get("status", "spowolnienie")), float(u.get("wartosc", 0.5)), float(u.get("czas", 5.0)))
		"obrazenia_wszystkich":
			for e in enemies.duplicate():
				if e.alive and e.x <= float(B.get("ekran_x", 1260)):
					_zadaj(e, Wfrp.obrazenia("magia", float(u.get("moc", 10.0)), h.cechy, e.cechy, e.pancerz, 1.0), "magia")
		"tarcza_druzyny":
			for o in heroes:
				_status(o, "tarcza", float(u.get("moc", 0.5)), float(u.get("czas", 5.0)))
	enemies = enemies.filter(func(e): return e.alive)
	_sprawdz_koniec()
	return true

# ---------------------------------------------------------------- cel planszy
func opis_celu() -> String:
	match str(board.get("cel", "pokonaj_wszystkich")):
		"zabij_bossa":
			return "Pokonaj bossa"
		"przetrwaj":
			return "Przetrwaj: %d s" % maxi(0, ceili(float(board.get("czas", 30)) - time))
		"zbierz_lup":
			return "Zbierz łup: %d/%d" % [mini(lup, int(board.get("ile", 5))), int(board.get("ile", 5))]
	return "Pokonaj wszystkich wrogów (%d)" % _pozostalo()

func _pozostalo() -> int:
	var n := enemies.size()
	for f in _fale:
		if not f["done"]:
			for id in f["wrogowie"]:
				var ile := int(f["wrogowie"][id])
				if not bool(Data.enemy(str(id)).get("boss", false)):
					ile = ceili(ile * float(diff.get("liczba", 1.0)))
				n += ile
	return n

func _sprawdz_koniec() -> void:
	if result != "":
		return
	if _zywi_bohaterowie().is_empty():
		_koniec("przegrana", "druzyna")
		return
	var limit := float(diff.get("limit_czasu", 0))
	if limit > 0.0 and time >= limit:
		_koniec("przegrana", "czas")
		return
	match str(board.get("cel", "pokonaj_wszystkich")):
		"zabij_bossa":
			if _boss_pojawil_sie and enemies.filter(func(e): return e.boss).is_empty():
				_koniec("wygrana", "boss")
		"przetrwaj":
			if time >= float(board.get("czas", 30)):
				_koniec("wygrana", "czas")
		"zbierz_lup":
			if lup >= int(board.get("ile", 5)):
				_koniec("wygrana", "lup")
		_:
			if fale_skonczone() and enemies.is_empty():
				_koniec("wygrana", "wszyscy")

func _koniec(r: String, p: String) -> void:
	result = r
	powod = p
	events.append({"typ": "koniec", "wynik": r, "powod": p})

## Po wygranej planszy: polegli wstają, wszyscy odzyskują część zdrowia.
func odpoczynek() -> void:
	var u := float(B.get("leczenie_miedzy_planszami", 0.3))
	for h in heroes:
		h.alive = true
		h.statusy = []
		h.hp = minf(h.max_hp, maxf(h.hp, 0.0) + h.max_hp * u)
