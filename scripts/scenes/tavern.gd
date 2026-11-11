class_name TavernScene
extends Node2D
## Prolog, część 1: karczma "Pod Złotym Kuflem". Nauka strzelania.
## Borubar sam biega po kufle (TavernSim), gracz dotyka ekranu, żeby odepchnąć gości.

var main: Node
var sim := TavernSim.new()
var cfg: Dictionary = {}
var bg: LevelBg
var world: Node2D
var borubar: Actor
var barman: Sprite2D
var goscie: Array = []        # Array[Node2D]
var kufel: Sprite2D
var lbl_licznik: Label
var lbl_podp: Label
var aktywna: bool = false
var _etap: int = -1
var py: float = 600.0

func _ready() -> void:
	cfg = Data.adventures.get("prolog_karczma", {})
	py = float(cfg.get("podloga_y", 600))
	sim.setup(cfg, int(Time.get_ticks_usec()))
	Audio.play_track(str(cfg.get("muzyka", "karczma")))
	bg = LevelBg.new()
	add_child(bg)
	bg.setup(str(cfg.get("poziom_grafiki", "karczma")))
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	var folder := "res://assets/levels/karczma/props"
	# barman za ladą
	barman = _sprite(folder + "/barman.png", Vector2(float(cfg.get("barman_x", 1140)), float(cfg.get("barman_y", 600)) - 60.0))
	world.add_child(barman)
	var lada := Art.tex(folder + "/lada.png")
	if lada != null:
		var s := Sprite2D.new()
		s.texture = lada
		s.centered = false
		s.position = Vector2(1280 - lada.get_width(), py + 40 - lada.get_height())
		s.z_index = 5
		add_child(s)
	else:
		# placeholder lady (rysowany przed barmanem, tak jak docelowa grafika)
		for r in [[Rect2(1040, py - 96, 240, 136), Color(0.24, 0.14, 0.08)], [Rect2(1030, py - 108, 250, 18), Color(0.42, 0.27, 0.14)]]:
			var c := ColorRect.new()
			c.position = r[0].position
			c.size = r[0].size
			c.color = r[1]
			c.z_index = 5
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(c)
	# goście
	var i := 1
	for k in sim.klienci:
		var g := _sprite("%s/klient_%d.png" % [folder, i], Vector2(float(k["x"]), py))
		world.add_child(g)
		goscie.append(g)
		i += 1
	borubar = Actor.new()
	world.add_child(borubar)
	borubar.setup("res://assets/characters/borubar", "east", Data.hero("borubar").get("placeholder", {}), "Borubar", false)
	borubar.pokaz_hp = false
	borubar.position = Vector2(sim.borubar_x, py)
	kufel = _sprite(folder + "/kufel.png", Vector2(-100, -100))
	kufel.z_index = 60
	kufel.visible = false
	add_child(kufel)
	_hud()
	main.opowiesc(self, "Pod Złotym Kuflem", [
		"Hufduhof, wieczór. W karczmie Borubara tłok jak nigdy - barman rzuca kufle przez całą salę, a kto pierwszy złapie, ten pije.",
		"Borubar łapie kufle do beczki. Sam wie, dokąd biec - ty mu tylko pomagasz.\n\nDotknij ekranu, żeby strzelić piorunem z nieba. Strzał odpycha i spowalnia gości, którzy pchają się po kufel."
	], func(): aktywna = true, "Zaczynamy")

func _sprite(path: String, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	var t := Art.tex(path)
	if t == null:
		var img := Image.create(40, 96, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.45, 0.4, 0.5))
		t = ImageTexture.create_from_image(img)
	s.texture = t
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -Vector2(t.get_width() * 0.5, t.get_height())
	s.position = pos
	return s

func _hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.theme = UiKit.theme()
	UiKit.full_rect(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	lbl_licznik = UiKit.outlined(UiKit.label("", 30, UiKit.GOLD, false))
	lbl_licznik.position = Vector2(24, 16)
	root.add_child(lbl_licznik)
	var p := PanelContainer.new()
	p.position = Vector2(240, 70)
	p.custom_minimum_size = Vector2(800, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(p)
	lbl_podp = UiKit.label("", 22)
	lbl_podp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_podp.custom_minimum_size = Vector2(770, 0)
	p.add_child(lbl_podp)
	var skip := UiKit.button("Pomiń", _koniec, 130.0, 46.0)
	skip.position = Vector2(1130, 14)
	root.add_child(skip)

func _unhandled_input(ev: InputEvent) -> void:
	if not aktywna:
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * ev.position
		if sim.strzal(pos.x):
			Audio.play("lightning", 1.4)
			Fx.bolt(self, Vector2(pos.x, py - 46.0), float(cfg.get("strzal", {}).get("promien", 115)))

func _process(delta: float) -> void:
	if aktywna:
		sim.step(minf(delta, 0.05))
		for ev in sim.events:
			_zdarzenie(ev)
		sim.events.clear()
	borubar.position.x = sim.borubar_x
	borubar.play("walk" if sim.borubar_idzie else "idle")
	for i in goscie.size():
		var k: Dictionary = sim.klienci[i]
		var g: Sprite2D = goscie[i]
		var cel_x := float(k["x"])
		if absf(cel_x - g.position.x) > 0.5:
			g.flip_h = cel_x < g.position.x
		g.position.x = cel_x
		g.modulate = Color(0.6, 0.75, 1.0) if float(k["slow_t"]) > 0.0 else Color(1, 1, 1)
		g.position.y = py - (absf(sin(sim.time * 14.0 + i)) * 5.0 if k["aktywny"] else 0.0)
	if sim.kufel.is_empty():
		kufel.visible = false
	else:
		var u := clampf(float(sim.kufel["t"]) / float(sim.kufel["T"]), 0.0, 1.0)
		var a := Vector2(float(sim.kufel["x0"]), py - 150.0)
		var b := Vector2(float(sim.kufel["x1"]), py - 96.0)
		kufel.visible = true
		kufel.position = a.lerp(b, u) - Vector2(0, sin(u * PI) * 330.0)
		kufel.rotation = u * TAU * 2.0
	var e := sim.etap_podpowiedzi()
	if e != _etap:
		_etap = e
		lbl_podp.text = str(cfg.get("podpowiedzi", [""])[e])
	lbl_licznik.text = "Kufle w beczce: %d/%d      Zabrane przez gości: %d" % [sim.zlapane, sim.cel(), sim.skradzione]
	queue_redraw()

func _draw() -> void:
	# cień w miejscu, gdzie spadnie kufel
	if not sim.kufel.is_empty():
		var u := clampf(float(sim.kufel["t"]) / float(sim.kufel["T"]), 0.0, 1.0)
		var c := Vector2(float(sim.kufel["x1"]), py + 6.0)
		var r := 22.0 + 26.0 * u
		draw_set_transform(c, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.25 + 0.35 * u))
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1.0, 0.85, 0.3, 0.9), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _zdarzenie(ev: Dictionary) -> void:
	var pos := Vector2(float(ev.get("x", 0.0)), py - 150.0)
	match str(ev["typ"]):
		"rzut":
			Audio.play("swing")
		"zlapany":
			Audio.play("mug_catch")
			Fx.tekst(self, pos, "Złapany!", Color(0.5, 1.0, 0.4), 28)
		"skradziony":
			Audio.play("miss")
			Fx.tekst(self, pos, "Gość zabrał kufel!", Color(1.0, 0.5, 0.3), 26)
		"rozbity":
			Audio.play("mug_break")
			var r := _sprite("res://assets/levels/karczma/props/kufel_rozbity.png", Vector2(float(ev["x"]), py + 8.0))
			add_child(r)
			var tw := r.create_tween()
			tw.tween_interval(1.2)
			tw.tween_property(r, "modulate:a", 0.0, 0.5)
			tw.tween_callback(r.queue_free)
			Fx.tekst(self, pos, "Rozbity...", Color(0.8, 0.8, 0.8), 26)
		"koniec":
			_koniec()

var _zakonczono: bool = false

func _koniec() -> void:
	if _zakonczono:
		return
	_zakonczono = true
	aktywna = false
	Audio.play("door")
	main.opowiesc(self, "Szczury!", [
		"Drzwi wylatują z zawiasów. Do karczmy wpadają szczuroludzie, a za nimi - coś znacznie gorszego.",
		"Borubar zarzuca na plecy ostatnią pełną beczkę i ucieka przez wieś.\n\nDotykaj wrogów, żeby razić ich piorunami. Borubar jest twardy, ale sam się nie obroni."
	], func(): main.go("bitwa", {"przygoda": "prolog_wies", "trudnosc": "normal"}), "W nogi!")
