class_name Actor
extends Node2D
## Widok postaci: animowany sprite z folderu (anim/kierunek/N.png + sprite.json) albo placeholder (kolorowa sylwetka).
## Pasek życia i znaczniki statusów rysuje sam. Punkt (0,0) = stopy postaci.

var folder: String = ""
var dir: String = "east"
var ph: Dictionary = {}
var etykieta: String = ""
var wrog: bool = false
var boss: bool = false
var anims: Dictionary = {}
var fps: Dictionary = {}
var spr: Sprite2D
var anim: String = ""
var _t: float = 0.0
var _petla: bool = true
var _czas_jednorazowy: float = 0.4
var hp: float = 1.0
var pokaz_hp: bool = true
var statusy: Array = []
var wys: float = 100.0
var _blysk: float = 0.0
var martwy: bool = false

func setup(folder_: String, dir_: String, placeholder: Dictionary, nazwa: String, wrog_: bool, boss_: bool = false) -> void:
	folder = folder_
	dir = dir_
	ph = placeholder
	etykieta = nazwa
	wrog = wrog_
	boss = boss_
	wys = float(ph.get("h", 100))
	var meta := Art.sprite_meta(folder)
	fps = meta.get("fps", {})
	for a in ["idle", "walk", "attack", "hurt", "death"]:
		var fr := Art.frames(folder, a, dir)
		if not fr.is_empty():
			anims[a] = fr
	if anims.has("idle"):
		spr = Sprite2D.new()
		spr.centered = false
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var piv: Array = meta.get("pivot", [0, 0])
		var t: Texture2D = anims["idle"][0]
		if meta.has("pivot"):
			spr.offset = -Vector2(float(piv[0]), float(piv[1]))
		else:
			spr.offset = -Vector2(t.get_width() * 0.5, t.get_height())
		add_child(spr)
	play("idle")

func ma_sprite() -> bool:
	return spr != null

func play(a: String, petla: bool = true, czas: float = 0.4) -> void:
	if a == anim and petla:
		return
	if not anims.has(a):
		if a == "walk" and anims.has("idle"):
			a = "idle"
		elif spr != null:
			return
	anim = a
	_t = 0.0
	_petla = petla
	_czas_jednorazowy = czas
	_klatka()

func _klatka() -> void:
	if spr == null or not anims.has(anim):
		return
	var fr: Array = anims[anim]
	var f := float(fps.get(anim, 6))
	var i := 0
	if _petla:
		i = int(_t * maxf(f, 1.0)) % fr.size()
	else:
		i = mini(fr.size() - 1, int(_t / maxf(_czas_jednorazowy, 0.05) * fr.size()))
	spr.texture = fr[i]

func _process(delta: float) -> void:
	_t += delta
	if not _petla and _t >= _czas_jednorazowy and anim != "death":
		play("idle")
	_klatka()
	if _blysk > 0.0:
		_blysk = maxf(0.0, _blysk - delta * 5.0)
		modulate = Color(1, 1, 1).lerp(Color(3, 1.2, 1.2), _blysk) if not martwy else modulate
	if spr == null:
		queue_redraw()

func blysk() -> void:
	_blysk = 1.0

func ustaw(hp_: float, statusy_: Array) -> void:
	if absf(hp_ - hp) > 0.001 or statusy_ != statusy:
		hp = hp_
		statusy = statusy_
		queue_redraw()

func umrzyj() -> void:
	martwy = true
	pokaz_hp = false
	play("death", false, 0.6)
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	queue_redraw()

func _draw() -> void:
	var w := float(ph.get("w", 40))
	if spr == null:
		# placeholder: sylwetka w kolorze postaci
		var c := Art.col(str(ph.get("kolor", "#777777")))
		var bob := sin(_t * (9.0 if anim == "walk" else 2.5)) * (3.0 if anim == "walk" else 1.0)
		var body := Rect2(-w * 0.5, -wys + bob + w * 0.45, w, wys - w * 0.45)
		draw_rect(body.grow(2), Color(0.05, 0.03, 0.03))
		draw_rect(body, c)
		draw_circle(Vector2(0, -wys + bob + w * 0.3), w * 0.36 + 2, Color(0.05, 0.03, 0.03))
		draw_circle(Vector2(0, -wys + bob + w * 0.3), w * 0.36, c.lightened(0.25))
		var kier := -1.0 if wrog else 1.0
		draw_rect(Rect2(kier * w * 0.5 - (6 if kier < 0 else 0), -wys * 0.62 + bob, 6, wys * 0.3), c.darkened(0.3))
		if anim == "attack":
			draw_line(Vector2(kier * w * 0.5, -wys * 0.6), Vector2(kier * (w * 0.5 + 46), -wys * 0.75), Color(0.9, 0.9, 0.85), 4)
	if pokaz_hp:
		var bw := 86.0 if boss else 46.0
		var by := -wys - (22.0 if spr == null else 14.0)
		draw_rect(Rect2(-bw * 0.5 - 1, by - 1, bw + 2, 8), Color(0.03, 0.02, 0.02))
		draw_rect(Rect2(-bw * 0.5, by, bw * clampf(hp, 0.0, 1.0), 6), Color(0.75, 0.16, 0.13) if wrog else Color(0.35, 0.72, 0.28))
		var sx := -bw * 0.5
		for s in statusy:
			var kol := Color(1, 0.9, 0.2)
			match str(s):
				"spowolnienie": kol = Color(0.35, 0.6, 1.0)
				"podpalenie": kol = Color(1.0, 0.5, 0.1)
				"oslabienie": kol = Color(0.7, 0.3, 0.9)
				"wzmocnienie": kol = Color(1.0, 0.3, 0.3)
				"tarcza": kol = Color(0.8, 0.8, 0.9)
			draw_rect(Rect2(sx, by - 10, 8, 8), kol)
			sx += 10.0
