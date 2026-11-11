class_name MenuScene
extends Control
## Menu główne.

var main: Node

func _ready() -> void:
	theme = UiKit.theme()
	UiKit.full_rect(self)
	Audio.play_track("menu")
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	UiKit.full_rect(bg)
	add_child(bg)
	var hb := HBoxContainer.new()
	UiKit.full_rect(hb)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 60)
	add_child(hb)
	var crest := UiKit.icon("res://assets/ui/crest/crest_menu.png", 300.0)
	crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(crest)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	hb.add_child(vb)
	vb.add_child(UiKit.outlined(UiKit.label("Champions of Carroburg", 54, UiKit.RED)))
	vb.add_child(UiKit.label("Taktyczny auto-battler w Starym Świecie", 22, UiKit.DIM))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	vb.add_child(gap)
	if Save.has_save():
		vb.add_child(_btn("Kontynuuj", _kontynuuj))
	vb.add_child(_btn("Nowa gra", _nowa))
	vb.add_child(_btn("Pomiń prolog (od razu Koszary)", _pomin))
	vb.add_child(_btn(_muzyka_txt(), _muzyka))
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		vb.add_child(_btn("Wyjście", func(): get_tree().quit()))

func _btn(t: String, cb: Callable) -> Button:
	var b := UiKit.button(t, cb, 420.0)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b

func _muzyka_txt() -> String:
	return "Muzyka: %s" % ("włączona" if Save.music_volume > 0.01 else "wyłączona")

func _muzyka() -> void:
	Save.music_volume = 0.0 if Save.music_volume > 0.01 else 0.8
	Save.save_settings()
	Audio.apply_volumes()
	main.go("menu")

func _kontynuuj() -> void:
	if not Game.load_game():
		Game.new_game()
	main.go("koszary" if bool(Game.state.get("prolog_ukonczony", false)) else "karczma")

func _nowa() -> void:
	Game.new_game()
	main.go("karczma")

func _pomin() -> void:
	Game.new_game()
	Game.ukoncz_prolog()
	main.go("koszary")
