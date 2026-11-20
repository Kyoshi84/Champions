class_name Sklep
extends RefCounted
## Losowanie towaru kupca. Zasady i pule w data/items.json -> "sklep" (przedmioty z "sklep": true).

## Zwraca listę id przedmiotów: po jednym ze slotów "stale" (broń, pancerz, wstęga), potem "dodatkowe" z pozostałych slotów.
## Najpierw bierze przedmioty, które ktoś z drużyny może nosić; gdy takich nie ma - dowolne z puli.
static func losuj_oferte(rng: RandomNumberGenerator, druzyna: Array) -> Array:
	var cfg: Dictionary = Data.items.get("sklep", {})
	var stale: Array = cfg.get("stale", [])
	var out: Array = []
	for slot in stale:
		var id := _wybierz(rng, pula(func(it: Dictionary): return str(it.get("slot", "")) == str(slot)), druzyna)
		if id != "":
			out.append(id)
	for i in int(cfg.get("dodatkowe", 0)):
		var id := _wybierz(rng, pula(func(it: Dictionary): return not stale.has(str(it.get("slot", "")))), druzyna, out)
		if id != "":
			out.append(id)
	return out

## Id przedmiotów sklepowych spełniających warunek.
static func pula(warunek: Callable) -> Array:
	var out: Array = []
	for id in Data.items.get("przedmioty", {}):
		var it := Data.item(str(id))
		if bool(it.get("sklep", false)) and warunek.call(it):
			out.append(str(id))
	return out

## Czy ktoś z podanych bohaterów może nosić przedmiot.
static func przydatny(item_id: String, druzyna: Array) -> bool:
	var tylko: Array = Data.item(item_id).get("tylko", [])
	if tylko.is_empty():
		return true
	for h in druzyna:
		if tylko.has(str(h)):
			return true
	return false

static func _wybierz(rng: RandomNumberGenerator, kandydaci: Array, druzyna: Array, bez: Array = []) -> String:
	var wolne: Array = kandydaci.filter(func(id): return not bez.has(id))
	var dla_druzyny: Array = wolne.filter(func(id): return przydatny(str(id), druzyna))
	var z: Array = dla_druzyny if not dla_druzyny.is_empty() else wolne
	if z.is_empty():
		return ""
	return str(z[rng.randi_range(0, z.size() - 1)])
