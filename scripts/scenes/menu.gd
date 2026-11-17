class_name MenuScene
extends Control
## Menu główne: nocny Carroburg w tle, logo „Carroburg Champions” jako główny znak gry, pod nim przyciski.

var main: Node

func _ready() -> void:
	theme = Gk.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Audio.play_track("menu")
	add_child(TloKoszar.dla("hub"))

	var srodek := CenterContainer.new()
	srodek.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(srodek)
	var v := Gk.vb(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	srodek.add_child(v)

	var logo := LogoCC.nowe(210.0)
	logo.name = "logo"
	logo.custom_minimum_size = Vector2(760, 210)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(logo)
	var pod := Gk.tekst("Taktyczny auto-battler w Starym Świecie", 20, Gk.PRZYG, false)
	pod.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pod)
	v.add_child(Gk.rozpor(0, 10))

	var r := Gk.rama(18.0, 0.88)
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pv := Gk.vb(10)
	r.add_child(pv)
	if Save.has_save():
		pv.add_child(_btn("Kontynuuj", _kontynuuj, true, "miecze"))
	pv.add_child(_btn("Nowa gra", _nowa, not Save.has_save(), "zwoj"))
	pv.add_child(_btn("Pomiń prolog (od razu Koszary)", _pomin, false, "dalej"))
	pv.add_child(_btn(_muzyka_txt(), _muzyka, false, "menu"))
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		pv.add_child(_btn("Wyjście", func(): get_tree().quit(), false, "wstecz"))
	v.add_child(r)

	var herb := Gk.herb(54.0)
	herb.anchor_left = 0.0
	herb.anchor_top = 1.0
	herb.anchor_bottom = 1.0
	herb.offset_left = 18.0
	herb.offset_top = -72.0
	herb.offset_bottom = -18.0
	herb.offset_right = 72.0
	add_child(herb)
	var wersja := Gk.tekst("Szkarłatna Gwardia z Carroburga  ·  wersja %s" % str(ProjectSettings.get_setting("application/config/version", "0.1")), 14, Gk.PRZYG, false)
	wersja.anchor_left = 0.0
	wersja.anchor_top = 1.0
	wersja.anchor_bottom = 1.0
	wersja.offset_left = 84.0
	wersja.offset_top = -52.0
	wersja.offset_bottom = -30.0
	wersja.offset_right = 600.0
	add_child(wersja)


func _btn(t: String, cb: Callable, glowny: bool = false, ikona: String = "") -> Button:
	var b := Gk.przycisk(t, cb, glowny, 440.0, 52.0, ikona)
	b.name = "btn_" + t.get_slice(" ", 0).to_lower()
	b.add_theme_font_size_override("font_size", 20)
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
