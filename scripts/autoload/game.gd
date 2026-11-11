extends Node
## Stan gry między ekranami: bohaterowie, formacja, waluty, postęp przygód, ranking. Zapis po każdej zmianie.

signal changed

var state: Dictionary = {}

func _ready() -> void:
	new_game(false)

func new_game(zapisz: bool = true) -> void:
	state = {
		"wersja": 1,
		"prolog_ukonczony": false,
		"korony": 0,
		"klejnoty": 0,
		"favor": 0.0,
		"bohaterowie": {},        # id -> {poziom, spec, ekwipunek{slot:item}}
		"formacja": [],           # 10 pól: id bohatera albo ""
		"magazyn": [],            # id przedmiotów bez właściciela
		"postep": {},             # id przygody -> {trudność: true}
		"ranking": []
	}
	for i in Formation.POLA:
		state["formacja"].append("")
	for id in Data.hero_ids():
		if str(Data.hero(id).get("odblokowanie", {}).get("typ", "")) == "start":
			_odblokuj(id)
	_auto_formacja()
	if zapisz:
		save()

func save() -> void:
	Save.write(state)
	changed.emit()

func load_game() -> bool:
	var d := Save.read()
	if d.is_empty() or not d.has("bohaterowie"):
		return false
	new_game(false)
	for k in d:
		state[k] = d[k]
	while state["formacja"].size() < Formation.POLA:
		state["formacja"].append("")
	changed.emit()
	return true

# ---------------------------------------------------------------- bohaterowie
func _odblokuj(id: String) -> void:
	if state["bohaterowie"].has(id):
		return
	state["bohaterowie"][id] = {"poziom": 1, "spec": "", "ekwipunek": Data.hero(id).get("ekwipunek", {}).duplicate(true)}

func ma(id: String) -> bool:
	return state["bohaterowie"].has(id)

func poziom(id: String) -> int:
	return int(state["bohaterowie"].get(id, {}).get("poziom", 1))

func spec(id: String) -> String:
	return str(state["bohaterowie"].get(id, {}).get("spec", ""))

func ekwipunek(id: String) -> Dictionary:
	return state["bohaterowie"].get(id, {}).get("ekwipunek", {})

func koszt_zakupu(id: String) -> int:
	return int(Data.hero(id).get("odblokowanie", {}).get("koszt", 0))

func moze_kupic(id: String) -> bool:
	var o: Dictionary = Data.hero(id).get("odblokowanie", {})
	return not ma(id) and str(o.get("typ", "")) == "sklep" and int(state["korony"]) >= int(o.get("koszt", 0))

func kup(id: String) -> bool:
	if not moze_kupic(id):
		return false
	state["korony"] = int(state["korony"]) - koszt_zakupu(id)
	_odblokuj(id)
	_auto_formacja()
	save()
	return true

func koszt_awansu(id: String) -> int:
	return Progression.koszt_poziomu(poziom(id))

func moze_awansowac(id: String) -> bool:
	return ma(id) and poziom(id) < Progression.max_poziom() and int(state["korony"]) >= koszt_awansu(id)

func awansuj(id: String) -> bool:
	if not moze_awansowac(id):
		return false
	state["korony"] = int(state["korony"]) - koszt_awansu(id)
	state["bohaterowie"][id]["poziom"] = poziom(id) + 1
	save()
	return true

func wybierz_spec(id: String, spec_id: String) -> bool:
	var def := Data.hero(id)
	if not ma(id) or not Progression.moze_wybrac_spec(def, poziom(id), spec(id)):
		return false
	if Progression.galaz(def, spec_id).is_empty():
		return false
	state["bohaterowie"][id]["spec"] = spec_id
	save()
	return true

func zestaw(id: String) -> Dictionary:
	return Progression.zbuduj(Data.hero(id), poziom(id), spec(id), ekwipunek(id))

# ---------------------------------------------------------------- ekwipunek
func pasuje(item_id: String, hero_id: String, slot: String) -> bool:
	var it := Data.item(item_id)
	if it.is_empty() or str(it.get("slot", "")) != slot:
		return false
	var tylko: Array = it.get("tylko", [])
	return tylko.is_empty() or tylko.has(hero_id)

## Zakłada następny pasujący przedmiot z magazynu w danym slocie (albo zdejmuje, gdy nie ma kolejnego).
func przelacz_przedmiot(hero_id: String, slot: String) -> void:
	if not ma(hero_id):
		return
	var ekw: Dictionary = state["bohaterowie"][hero_id]["ekwipunek"]
	var obecny := str(ekw.get(slot, ""))
	var kandydaci: Array = []
	for it in state["magazyn"]:
		if pasuje(str(it), hero_id, slot):
			kandydaci.append(str(it))
	if obecny != "":
		state["magazyn"].append(obecny)
		ekw.erase(slot)
	if not kandydaci.is_empty():
		var nowy: String = kandydaci[0]
		state["magazyn"].erase(nowy)
		ekw[slot] = nowy
	save()

func losuj_przedmiot(rng: RandomNumberGenerator) -> String:
	var wagi: Dictionary = Data.balance.get("ekonomia", {}).get("wagi_rzadkosci", {})
	var pula: Array = []
	var suma := 0.0
	for id in Data.items.get("przedmioty", {}):
		var it := Data.item(id)
		if bool(it.get("loot", false)):
			var w := float(wagi.get(str(it.get("rzadkosc", "common")), 1))
			pula.append([id, w])
			suma += w
	if pula.is_empty():
		return ""
	var r := rng.randf() * suma
	for p in pula:
		r -= float(p[1])
		if r <= 0.0:
			return str(p[0])
	return str(pula[pula.size() - 1][0])

# ---------------------------------------------------------------- formacja
func miejsca() -> int:
	var p: Dictionary = Data.balance.get("progresja", {})
	var n := int(p.get("miejsca_start", 2))
	for id in state["postep"]:
		if not state["postep"][id].is_empty():
			n += int(p.get("miejsca_za_ukonczone_przygody", 2))
	return mini(n, int(p.get("miejsca_max", 10)))

func w_formacji() -> Array:
	var out: Array = []
	for id in state["formacja"]:
		if str(id) != "":
			out.append(str(id))
	return out

func pole_bohatera(id: String) -> int:
	return state["formacja"].find(id)

## Ustawia bohatera na polu. Jeśli pole jest zajęte - zamienia miejscami. Zwraca false, gdy brak wolnych miejsc.
func ustaw(id: String, pole: int) -> bool:
	if not ma(id) or pole < 0 or pole >= Formation.POLA:
		return false
	var f: Array = state["formacja"]
	var stare := f.find(id)
	var kto := str(f[pole])
	if stare == -1 and kto == "" and w_formacji().size() >= miejsca():
		return false
	if stare != -1:
		f[stare] = kto
	f[pole] = id
	save()
	return true

func zdejmij(id: String) -> void:
	var i: int = state["formacja"].find(id)
	if i != -1:
		state["formacja"][i] = ""
		save()

func _auto_formacja() -> void:
	# nowy bohater trafia na pierwsze wolne pole odpowiedniego rzędu (wręcz -> przód, reszta -> tył)
	for id in state["bohaterowie"]:
		if pole_bohatera(id) != -1 or w_formacji().size() >= miejsca():
			continue
		var wrecz := str(Data.hero(id).get("atak", {}).get("typ", "wrecz")) == "wrecz"
		var kolej: Array = [2, 1, 3, 0, 4] if wrecz else [7, 6, 8, 5, 9]
		kolej.append_array([7, 6, 8, 5, 9] if wrecz else [2, 1, 3, 0, 4])
		for p in kolej:
			if str(state["formacja"][p]) == "":
				state["formacja"][p] = id
				break

## Jednostki bojowe dla przygody (wymuszona drużyna prologu albo formacja gracza).
func druzyna(adv: Dictionary) -> Array:
	var out: Array = []
	var wym: Array = adv.get("druzyna_wymuszona", [])
	if not wym.is_empty():
		var pola := [2, 1, 3, 0, 4]
		for i in wym.size():
			var id := str(wym[i])
			out.append(Progression.bohater(id, 1, "", Data.hero(id).get("ekwipunek", {}), pola[i % pola.size()]))
		return out
	for pole in Formation.POLA:
		var id := str(state["formacja"][pole])
		if id != "" and ma(id):
			out.append(Progression.bohater(id, poziom(id), spec(id), ekwipunek(id), pole))
	return out

# ---------------------------------------------------------------- przygody
func ukonczona(adv_id: String, trudnosc: String = "") -> bool:
	var p: Dictionary = state["postep"].get(adv_id, {})
	if trudnosc == "":
		return not p.is_empty()
	return bool(p.get(trudnosc, false))

func dostepna(adv_id: String, trudnosc: String) -> bool:
	var adv := Data.adventure(adv_id)
	var wym := str(adv.get("wymaga", ""))
	if wym != "" and not ukonczona(wym):
		return false
	var kol: Array = Data.adventures.get("kolejnosc_trudnosci", ["normal"])
	var i := kol.find(trudnosc)
	return i <= 0 or ukonczona(adv_id, str(kol[i - 1]))

func dodaj_korony(ile: float) -> void:
	state["korony"] = int(state["korony"]) + roundi(ile)

func ukoncz_prolog() -> void:
	state["prolog_ukonczony"] = true
	for id in Data.hero_ids():
		if str(Data.hero(id).get("odblokowanie", {}).get("typ", "")) == "prolog":
			_odblokuj(id)
	_auto_formacja()
	save()

## Nagrody za ukończenie przygody. Zwraca opis nagród do pokazania graczowi.
func ukoncz_przygode(adv_id: String, trudnosc: String, rng: RandomNumberGenerator) -> Dictionary:
	var adv := Data.adventure(adv_id)
	var d := Data.difficulty(trudnosc)
	var pierwszy := not ukonczona(adv_id, trudnosc)
	var nagroda := {"korony": 0, "klejnoty": 0, "przedmiot": "", "favor": 0.0, "pierwszy_raz": pierwszy}
	nagroda["korony"] = roundi(float(adv.get("nagroda_korony", 0)) * float(d.get("zloto", 1.0)) * (1.0 if pierwszy else 0.25))
	nagroda["klejnoty"] = int(d.get("klejnoty_za_bossa", 0))
	var eko: Dictionary = Data.balance.get("ekonomia", {})
	if rng.randf() <= float(eko.get("szansa_przedmiotu_boss", 1.0)):
		nagroda["przedmiot"] = losuj_przedmiot(rng)
		if nagroda["przedmiot"] != "":
			state["magazyn"].append(nagroda["przedmiot"])
	if pierwszy:
		nagroda["favor"] = float(eko.get("favor_za_przygode", 0.05))
		state["favor"] = float(state["favor"]) + float(nagroda["favor"])
	if not state["postep"].has(adv_id):
		state["postep"][adv_id] = {}
	state["postep"][adv_id][trudnosc] = true
	state["korony"] = int(state["korony"]) + int(nagroda["korony"])
	state["klejnoty"] = int(state["klejnoty"]) + int(nagroda["klejnoty"])
	_auto_formacja()
	save()
	return nagroda

func zapisz_ranking(adv_id: String, trudnosc: String, plansza: int, czas: float, sklad: Array) -> void:
	if not bool(Data.difficulty(trudnosc).get("ranking", false)):
		return
	state["ranking"].append({"przygoda": str(Data.adventure(adv_id).get("nazwa", adv_id)), "trudnosc": trudnosc,
		"plansza": plansza, "czas": snappedf(czas, 0.1), "sklad": sklad})
	state["ranking"].sort_custom(func(a, b): return float(a["czas"]) < float(b["czas"]))
	if state["ranking"].size() > 50:
		state["ranking"].resize(50)
