class_name CUnit
extends RefCounted
## Jednostka w walce (bohater albo wróg). Same dane - logikę prowadzi Combat.

var uid: int = 0
var id: String = ""
var nazwa: String = ""
var team: int = 0              # 0 = bohater, 1 = wróg
var def: Dictionary = {}
var poziom: int = 1
var cechy: Dictionary = {}
var atak: Dictionary = {}
var skills: Array = []         # odblokowane umiejętności po modyfikacjach
var max_hp: float = 1.0
var hp: float = 1.0
var pancerz: float = 0.0
var odp_ogluszenie: float = 0.0
var x: float = 0.0
var y: float = 0.0
var slot: int = -1
var tor: int = 0
var alive: bool = true
var boss: bool = false
var niesmiertelny: bool = false
var zachowanie: String = "wrecz"
var predkosc: float = 0.0
var zloto: float = 0.0
var cd: float = 0.0            # czas do następnego ataku
var licznik_atakow: int = 0
var statusy: Array = []        # [{typ, czas, wartosc}]
var aury: Dictionary = {}
var aury_zrodla: Array = []
var ult: Dictionary = {}
var ult_cd: float = 0.0
var leczenie_cd: float = 0.0
var furia: int = 0
var skala_obrazen: float = 1.0
var skok_wykonany: bool = false
var cel: CUnit = null
var odporny_t: float = 0.0     # po ogłuszeniu chwilowa odporność (żeby nie dało się ogłuszać bez końca)
var w_kontakcie: bool = false
var _acc: float = 0.0

func status(typ: String) -> float:
	var w := 0.0
	for s in statusy:
		if s["typ"] == typ:
			w = maxf(w, float(s["wartosc"]))
	return w

func ma_status(typ: String) -> bool:
	for s in statusy:
		if s["typ"] == typ:
			return true
	return false

func dodaj_status(typ: String, wartosc: float, czas: float) -> void:
	for s in statusy:
		if s["typ"] == typ:
			s["wartosc"] = maxf(float(s["wartosc"]), wartosc)
			s["czas"] = maxf(float(s["czas"]), czas)
			return
	statusy.append({"typ": typ, "wartosc": wartosc, "czas": czas})

func skills_of(typ: String) -> Array:
	var out: Array = []
	for s in skills:
		if str(s.get("typ", "")) == typ:
			out.append(s)
	return out

func hp_ulamek() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)
