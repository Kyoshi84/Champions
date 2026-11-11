extends Node
## Wczytuje wszystkie dane gry z res://data/*.json. Kod nie zawiera liczb balansu - wszystko jest tutaj.

var balance: Dictionary = {}
var heroes: Dictionary = {}
var enemies: Dictionary = {}
var adventures: Dictionary = {}
var items: Dictionary = {}
var music: Dictionary = {}
var art: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	balance = _load("balance")
	heroes = _load("heroes")
	enemies = _load("enemies")
	adventures = _load("adventures")
	items = _load("items")
	music = _load("music")
	art = _load("levels_art")

func _load(n: String) -> Dictionary:
	var path := "res://data/%s.json" % n
	if not FileAccess.file_exists(path):
		push_error("Brak pliku danych: " + path)
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary:
		push_error("Błąd składni JSON: " + path)
		return {}
	return d

func hero(id: String) -> Dictionary:
	return heroes.get("bohaterowie", {}).get(id, {})

func hero_ids() -> Array:
	return heroes.get("kolejnosc", [])

func enemy(id: String) -> Dictionary:
	return enemies.get("wrogowie", {}).get(id, {})

func adventure(id: String) -> Dictionary:
	return adventures.get("przygody", {}).get(id, {})

func adventure_ids() -> Array:
	return adventures.get("kolejnosc", [])

func difficulty(id: String) -> Dictionary:
	return adventures.get("trudnosci", {}).get(id, {})

func item(id: String) -> Dictionary:
	return items.get("przedmioty", {}).get(id, {})

func walka() -> Dictionary:
	return balance.get("walka", {})
