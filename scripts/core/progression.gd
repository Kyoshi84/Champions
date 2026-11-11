class_name Progression
extends RefCounted
## Rozwój bohatera: poziomy, progi umiejętności, specjalizacje i ekwipunek składane w gotowy "zestaw bojowy".
## Wszystko wynika z danych (data/heroes.json, data/items.json) - bez wyjątków w kodzie dla konkretnych postaci.

static func max_poziom() -> int:
	return int(Data.balance.get("progresja", {}).get("max_poziom", 20))

## Koszt awansu z poziomu 'poziom' na następny (złote korony).
static func koszt_poziomu(poziom: int) -> int:
	var p: Dictionary = Data.balance.get("progresja", {})
	return roundi(float(p.get("koszt_poziomu_baza", 15)) * pow(float(p.get("koszt_poziomu_mnoznik", 1.4)), poziom - 1))

static func cechy_na_poziomie(def: Dictionary, poziom: int) -> Dictionary:
	var c: Dictionary = def.get("profil", {}).duplicate(true)
	var wz: Dictionary = def.get("wzrost", {})
	for k in wz:
		c[k] = float(c.get(k, 0)) + float(wz[k]) * (poziom - 1)
	return c

static func galaz(def: Dictionary, spec_id: String) -> Dictionary:
	for g in def.get("specjalizacja", {}).get("galezie", []):
		if str(g.get("id", "")) == spec_id:
			return g
	return {}

static func moze_wybrac_spec(def: Dictionary, poziom: int, spec_id: String) -> bool:
	var sp: Dictionary = def.get("specjalizacja", {})
	return not sp.is_empty() and spec_id == "" and poziom >= int(sp.get("prog", 999))

## Zwraca {cechy, atak, umiejetnosci (odblokowane), wszystkie (z polem 'odblokowana'), pancerz, odp_ogluszenie}.
static func zbuduj(def: Dictionary, poziom: int, spec_id: String, ekwipunek: Dictionary) -> Dictionary:
	var cechy := cechy_na_poziomie(def, poziom)
	var atak: Dictionary = def.get("atak", {}).duplicate(true)
	var wszystkie: Array = []
	var odblokowane: Array = []
	for s in def.get("umiejetnosci", []):
		var kopia: Dictionary = s.duplicate(true)
		kopia["odblokowana"] = poziom >= int(s.get("prog", 1))
		wszystkie.append(kopia)
		if kopia["odblokowana"]:
			odblokowane.append(kopia)
	var ctx := {"cechy": cechy, "atak": atak, "umiejetnosci": odblokowane, "pancerz": float(def.get("pancerz", 0.0)), "odp_ogluszenie": 0.0}
	# 1. umiejętności typu "modyfikacja" (np. Super Cios zaczyna odpychać)
	for s in odblokowane:
		if str(s.get("typ", "")) == "modyfikacja":
			for m in s.get("modyfikacje", []):
				_zastosuj(m, ctx)
		elif str(s.get("typ", "")) == "stat":
			var d: Dictionary = s.get("cechy", {})
			for k in d:
				_dodaj_ceche(ctx, k, float(d[k]))
	# 2. wybrana specjalizacja
	var sp: Dictionary = def.get("specjalizacja", {})
	if spec_id != "" and poziom >= int(sp.get("prog", 999)):
		for m in galaz(def, spec_id).get("modyfikacje", []):
			_zastosuj(m, ctx)
	# 3. ekwipunek
	for slot in ekwipunek:
		var it: Dictionary = Data.item(str(ekwipunek[slot]))
		var d: Dictionary = it.get("cechy", {})
		for k in d:
			_dodaj_ceche(ctx, k, float(d[k]))
	ctx["wszystkie"] = wszystkie
	return ctx

static func _dodaj_ceche(ctx: Dictionary, k: String, v: float) -> void:
	match k:
		"bron":
			ctx["atak"]["bron"] = float(ctx["atak"].get("bron", 0.0)) + v
		"pancerz":
			ctx["pancerz"] = float(ctx["pancerz"]) + v
		"odp_ogluszenie":
			ctx["odp_ogluszenie"] = minf(0.8, float(ctx["odp_ogluszenie"]) + v)
		_:
			ctx["cechy"][k] = float(ctx["cechy"].get(k, 0)) + v

## Modyfikacja: {umiejetnosc, pole, razy|dodaj|ustaw} albo {atak: pole, ...} albo {cecha: nazwa, ...}.
## 'pole' może być zagnieżdżone, np. "efekty.redukcja".
static func _zastosuj(m: Dictionary, ctx: Dictionary) -> void:
	if m.has("cecha"):
		var k := str(m["cecha"])
		var cur := float(ctx["cechy"].get(k, 0))
		ctx["cechy"][k] = _nowa(cur, m)
		return
	var cel: Dictionary = {}
	var pole := ""
	if m.has("atak"):
		cel = ctx["atak"]
		pole = str(m["atak"])
	elif m.has("umiejetnosc"):
		for s in ctx["umiejetnosci"]:
			if str(s.get("id", "")) == str(m["umiejetnosc"]):
				cel = s
		pole = str(m.get("pole", ""))
		if cel.is_empty():
			return      # umiejętność jeszcze nieodblokowana
	else:
		return
	var parts := pole.split(".")
	for i in parts.size() - 1:
		if not cel.has(parts[i]) or not cel[parts[i]] is Dictionary:
			return
		cel = cel[parts[i]]
	var last := parts[parts.size() - 1]
	cel[last] = _nowa(cel.get(last, 0), m)

static func _nowa(cur, m: Dictionary):
	if m.has("ustaw"):
		return m["ustaw"]
	var v := float(cur)
	if m.has("razy"):
		v *= float(m["razy"])
	if m.has("dodaj"):
		v += float(m["dodaj"])
	return v

# ---------------------------------------------------------------- budowanie jednostek
static func bohater(id: String, poziom: int, spec_id: String, ekwipunek: Dictionary, slot: int) -> CUnit:
	var def := Data.hero(id)
	var z := zbuduj(def, poziom, spec_id, ekwipunek)
	var u := CUnit.new()
	u.id = id
	u.nazwa = str(def.get("imie", id))
	u.team = 0
	u.def = def
	u.poziom = poziom
	u.cechy = z["cechy"]
	u.atak = z["atak"]
	u.skills = z["umiejetnosci"]
	u.pancerz = float(z["pancerz"])
	u.odp_ogluszenie = float(z["odp_ogluszenie"])
	u.max_hp = Wfrp.max_hp(u.cechy)
	u.hp = u.max_hp
	u.slot = slot
	u.tor = Formation.tor(slot)
	var p := Formation.pozycja(slot)
	u.x = p.x
	u.y = p.y
	var ults := u.skills_of("ultimate")
	if not ults.is_empty():
		u.ult = ults[0]
	return u

static func wrog(id: String, skala_hp: float, skala_obr: float) -> CUnit:
	var def := Data.enemy(id)
	var u := CUnit.new()
	u.id = id
	u.nazwa = str(def.get("nazwa", id))
	u.team = 1
	u.def = def
	u.cechy = def.get("profil", {}).duplicate(true)
	u.atak = def.get("atak", {}).duplicate(true)
	u.skills = def.get("umiejetnosci", []).duplicate(true)
	u.pancerz = float(def.get("pancerz", 0.0))
	u.boss = bool(def.get("boss", false))
	u.zachowanie = str(def.get("zachowanie", "wrecz"))
	u.predkosc = float(def.get("predkosc", 60))
	u.zloto = float(def.get("zloto", 1))
	u.max_hp = Wfrp.max_hp(u.cechy) * skala_hp
	u.hp = u.max_hp
	u.skala_obrazen = skala_obr
	return u
