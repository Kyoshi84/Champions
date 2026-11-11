extends Node
## Zapis gry (jeden slot) i ustawień w katalogu użytkownika (user://).

const SETTINGS_PATH := "user://champions_ustawienia.json"

var music_volume: float = 0.8
var sfx_volume: float = 0.9
var save_path: String = "user://champions_zapis.json"   # testy podmieniają ścieżkę

func _ready() -> void:
	load_settings()

func has_save() -> bool:
	return FileAccess.file_exists(save_path)

func write(state: Dictionary) -> bool:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_error("Nie można zapisać gry: " + save_path)
		return false
	f.store_string(JSON.stringify(state, " "))
	f.close()
	return true

func read() -> Dictionary:
	if not has_save():
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if d is Dictionary:
		return d
	return {}

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if d is Dictionary:
		music_volume = float(d.get("music", music_volume))
		sfx_volume = float(d.get("sfx", sfx_volume))

func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"music": music_volume, "sfx": sfx_volume}))
		f.close()
