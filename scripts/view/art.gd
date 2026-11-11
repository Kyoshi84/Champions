class_name Art
extends RefCounted
## Wczytywanie grafik z możliwością podmiany. Jeśli pliku nie ma, zwraca null - wtedy rysowany jest placeholder.
## Dzięki temu docelowe grafiki wystarczy wrzucić pod właściwą nazwą (docs/SPECYFIKACJA_GRAFIKI_POZIOMOW.md).

static var _cache: Dictionary = {}

static func tex(path: String) -> Texture2D:
	if path == "":
		return null
	if _cache.has(path):
		return _cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	_cache[path] = t
	return t

## Klatki animacji: <folder>/<anim>/<kierunek>/0.png, 1.png, ...
static func frames(folder: String, anim: String, dir: String) -> Array:
	var out: Array = []
	var i := 0
	while true:
		var t := tex("%s/%s/%s/%d.png" % [folder, anim, dir, i])
		if t == null:
			break
		out.append(t)
		i += 1
	return out

static func sprite_meta(folder: String) -> Dictionary:
	var p := folder + "/sprite.json"
	if not FileAccess.file_exists(p):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	return d if d is Dictionary else {}

static func col(hex: String, def: Color = Color(0.4, 0.4, 0.4)) -> Color:
	return Color.from_string(hex, def)
