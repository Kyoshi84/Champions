class_name Formation
extends RefCounted
## Formacja 2 rzędy x 5 torów. Pole 0-4 = przedni rząd (bliżej wrogów), 5-9 = tylny rząd.
## Tor (0-4) to pozycja w pionie na polu bitwy; pola 2 i 7 leżą w tym samym torze (jedno za drugim).

const RZAD := 5
const POLA := 10

static func rzad(slot: int) -> int:
	return slot / RZAD          # 0 = przedni, 1 = tylny

static func tor(slot: int) -> int:
	return slot % RZAD

static func pozycja(slot: int) -> Vector2:
	var b := Data.walka()
	var tory: Array = b.get("tory_y", [340, 410, 480, 550, 620])
	var x: float = float(b.get("linia_frontu_x", 430)) if rzad(slot) == 0 else float(b.get("linia_tylu_x", 290))
	# lekkie przesunięcie w poziomie, żeby postacie w sąsiednich torach się nie zasłaniały
	x += (tor(slot) % 2) * 46.0
	return Vector2(x, float(tory[tor(slot)]))

## Czy pole 'cel' leży w zasięgu aury bohatera stojącego na polu 'zrodlo'.
static func w_zasiegu(zrodlo: int, cel: int, zasieg: String) -> bool:
	if zrodlo < 0 or cel < 0:
		return false
	var dr := absi(rzad(zrodlo) - rzad(cel))
	var dt := absi(tor(zrodlo) - tor(cel))
	match zasieg:
		"ja":
			return zrodlo == cel
		"druzyna":
			return true
		"sasiednie":
			return dr + dt == 1
		"zasieg_2":
			return zrodlo != cel and dr + dt <= 2
		"kolumna":
			return zrodlo != cel and dt == 0
		"przed_mna":
			return dt == 0 and rzad(zrodlo) == 1 and rzad(cel) == 0
		"za_mna":
			return dt == 0 and rzad(zrodlo) == 0 and rzad(cel) == 1
		"rzad_przedni":
			return rzad(cel) == 0
		"rzad_tylny":
			return rzad(cel) == 1
	return false

static func nazwa_zasiegu(zasieg: String) -> String:
	match zasieg:
		"ja": return "tylko on sam"
		"druzyna": return "cała drużyna"
		"sasiednie": return "sąsiednie pola"
		"zasieg_2": return "pola w zasięgu 2"
		"kolumna": return "ten sam tor"
		"przed_mna": return "pole przed nim"
		"za_mna": return "pole za nim"
		"rzad_przedni": return "cały przedni rząd"
		"rzad_tylny": return "cały tylny rząd"
	return zasieg

static func nazwa_efektu(klucz: String, w: float) -> String:
	match klucz:
		"obrazenia": return "+%d%% obrażeń" % roundi(w * 100.0)
		"szybkosc": return "+%d%% szybkości ataku" % roundi(w * 100.0)
		"redukcja": return "-%d%% otrzymywanych obrażeń" % roundi(w * 100.0)
		"zloto": return "+%d%% koron" % roundi(w * 100.0)
		"regeneracja": return "+%.1f HP/s" % w
	return "%s %s" % [klucz, str(w)]

## Przelicza aury pozycyjne. units: Array[CUnit] (bohaterowie). Martwi nie dają i nie dostają aur.
static func przelicz_aury(units: Array) -> void:
	for h in units:
		h.aury = {}
		h.aury_zrodla = []
	for src in units:
		if not src.alive:
			continue
		for s in src.skills_of("aura"):
			var zasieg: String = str(s.get("zasieg", "sasiednie"))
			for h in units:
				if not h.alive:
					continue
				if not w_zasiegu(src.slot, h.slot, zasieg):
					continue
				var ef: Dictionary = s.get("efekty", {})
				for k in ef:
					h.aury[k] = float(h.aury.get(k, 0.0)) + float(ef[k])
				h.aury_zrodla.append({"od": src.nazwa, "nazwa": str(s.get("nazwa", "")), "zasieg": zasieg, "efekty": ef})
	for h in units:
		h.aury["redukcja"] = minf(float(h.aury.get("redukcja", 0.0)), 0.75)
