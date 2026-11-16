class_name BattleScene
extends Node2D
## Ekran walki: pokazuje symulację Combat. Sam nie liczy żadnych zasad - tylko rysuje, gra dźwięki
## i przekazuje akcje gracza (strzał z nieba, Ultimate). Obsługuje też prolog (ucieczka Borubara).

var main: Node
var adv_id: String = "piwnice_carroburga"
var trudnosc: String = "normal"
var adv: Dictionary = {}
var diff: Dictionary = {}
var heroes: Array = []
var sim: Combat
var plansza: int = 0
var faza: String = "pauza"      # walka | pauza
var _t: float = 0.0
var tempo: float = 1.0
var bg: LevelBg
var world: Node2D
var aktorzy: Dictionary = {}    # uid -> Actor
var hud: Control
var lbl_cel: Label
var lbl_korony: Label
var lbl_podp: Label
var panel_podp: PanelContainer
var boss_bar: ProgressBar
var lbl_boss: Label
var ult_btns: Dictionary = {}   # uid -> Button
var btn_tempo: Button
var _podp_t: float = 0.0
var _zebrane: float = 0.0
var slady: Fx.Krew                # plamy krwi na ziemi
var podloze: Node2D               # kręgi pod bohaterami (pod postaciami)
var kregi: Dictionary = {}        # uid -> Fx.Krag
var dom: Dictionary = {}          # uid -> pole bohatera w formacji (tam wraca po doskoku)
var _scroll_t: float = 0.0        # marsz na następną planszę - tło jedzie, walka trwa
var _w_locie: float = 0.0         # korony w monetach, które jeszcze nie doleciały do licznika
var panel_celu: PanelContainer
var lbl_nazwa: Label
var pasek_celu: Control
var _postep: float = 0.0
var tor_plansz: HBoxContainer
const LICZNIK := Vector2(34, 30)  # dokąd lecą monety
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	adv = Data.adventure(adv_id)
	diff = Data.difficulty(trudnosc)
	bg = LevelBg.new()
	add_child(bg)
	bg.setup(str(adv.get("poziom_grafiki", "hufduhof")))
	slady = Fx.Krew.new()
	add_child(slady)
	podloze = Node2D.new()
	add_child(podloze)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	heroes = Game.druzyna(adv)
	for h in heroes:
		h.uid = 100 + h.slot
		var a := Actor.new()
		world.add_child(a)
		a.setup(str(h.def.get("grafika", "")), "east", h.def.get("placeholder", {}), h.nazwa, false)
		a.position = Vector2(h.x, h.y)
		aktorzy[h.uid] = a
		dom[h.uid] = a.position
		var k := Fx.Krag.new()
		k.position = a.position + Vector2(0, 4)
		podloze.add_child(k)
		kregi[h.uid] = k
	_buduj_hud()
	if heroes.is_empty():
		faza = "pauza"
		_nakladka("Brak drużyny", "Ustaw w formacji przynajmniej jednego zdrowego bohatera.", [["Koszary", func(): main.go("koszary")]])
		return
	_start(0)

# ---------------------------------------------------------------- przebieg
func _start(idx: int) -> void:
	plansza = idx
	for uid in aktorzy.keys():
		if uid >= 1000:          # niedobitki z poprzedniej planszy rozpierzchają się
			var stary: Actor = aktorzy[uid]
			stary.pokaz_hp = false
			var tw := stary.create_tween()
			tw.set_parallel(true)
			tw.tween_property(stary, "position:x", stary.position.x + 260.0, 0.6)
			tw.tween_property(stary, "modulate:a", 0.0, 0.6)
			tw.chain().tween_callback(stary.queue_free)
			aktorzy.erase(uid)
	sim = Combat.new()
	sim.setup(heroes, adv, idx, diff, int(rng.randi()), float(Game.state.get("favor", 0.0)))
	var b: Dictionary = sim.board
	Audio.play_track("boss" if bool(b.get("boss", false)) else str(adv.get("muzyka", "walka")))
	_odswiez_tor()
	var podp := str(b.get("podpowiedz", ""))
	if podp == "":
		podp = str(b.get("opis", ""))
	_podpowiedz(podp, 7.0 if b.has("podpowiedz") else 3.0)
	for h in heroes:
		aktorzy[h.uid].pokaz_hp = true
		aktorzy[h.uid].martwy = false
		aktorzy[h.uid].modulate = Color(1, 1, 1, 1)
		aktorzy[h.uid].play("idle")
	faza = "walka"

func _process(delta: float) -> void:
	_podp_t -= delta
	if _podp_t <= 0.0 and panel_podp.visible:
		panel_podp.visible = false
	match faza:
		"walka":
			sim.step(delta * tempo)
			_zdarzenia()
			_synchronizuj(delta)
			_odswiez_hud()
			if bool(adv.get("ucieczka", false)):
				var kontakt := false
				for e in sim.enemies:
					if e.w_kontakcie:
						kontakt = true
				if not kontakt:
					bg.przesun(70.0 * delta * tempo)
					slady.przesun(70.0 * delta * tempo)
				for h in heroes:
					if h.alive and aktorzy[h.uid].anim != "attack":
						aktorzy[h.uid].play("idle" if kontakt else "walk")
			elif _scroll_t > 0.0:      # marsz na kolejną planszę w trakcie walki
				_scroll_t -= delta
				bg.przesun(340.0 * delta)
				slady.przesun(340.0 * delta)
				for h in heroes:
					if h.alive and aktorzy[h.uid].anim != "attack":
						aktorzy[h.uid].play("walk" if _scroll_t > 0.0 else "idle")
			if sim.result != "":
				_koniec_planszy()

func _unhandled_input(ev: InputEvent) -> void:
	if faza != "walka":
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * ev.position
		sim.strzal_gracza(pos.x, pos.y)

func _koniec_planszy() -> void:
	faza = "pauza"
	_zdarzenia()
	var b: Dictionary = sim.board
	var ostatnia: bool = plansza >= adv.get("plansze", []).size() - 1
	if sim.result == "wygrana":
		_zebrane += sim.zloto
		Game.dodaj_korony(sim.zloto)
		Game.zapisz_ranking(adv_id, trudnosc, plansza + 1, sim.time, heroes.map(func(h): return h.id))
		Audio.play("levelup")
		if not ostatnia:
			sim.odpoczynek()
			Game.save()
			# bez zatrzymywania walki: napis przejeżdża przez ekran, drużyna rusza dalej, wrogowie już napływają
			_baner("Plansza ukończona")
			if not bool(adv.get("ucieczka", false)):
				_scroll_t = 1.2
			_start(plansza + 1)
			return
		if bool(adv.get("prolog", false)):
			_koniec_prologu()
			return
		Game.zapisz_zdrowie(heroes)
		var n := Game.ukoncz_przygode(adv_id, trudnosc, rng)
		var opis := "Zdobyte w walce: %d koron\nNagroda za przygodę: %d koron" % [roundi(_zebrane), int(n["korony"])]
		if int(n["klejnoty"]) > 0:
			opis += "\nKlejnoty: +%d" % int(n["klejnoty"])
		if str(n["przedmiot"]) != "":
			opis += "\nŁup z bossa: %s" % str(Data.item(str(n["przedmiot"])).get("nazwa", ""))
		if float(n["favor"]) > 0.0:
			opis += "\nFavor: +%d%% do wszystkich zdobywanych koron" % roundi(float(n["favor"]) * 100.0)
		_nakladka("Zwycięstwo!", opis, [["Do Koszar", func(): main.go("koszary")]])
		return
	# przegrana
	Audio.play("death")
	if bool(b.get("przegrana_fabularna", false)):
		_koniec_prologu()
		return
	Game.save()
	var powod := "Upłynął limit czasu." if sim.powod == "czas" else "Cała drużyna poległa."
	var przyciski: Array = [["Spróbuj ponownie", func():
		for h in heroes:
			h.alive = true
			h.hp = h.max_hp
		_start(plansza)]]
	if not bool(adv.get("prolog", false)):
		przyciski.append(["Koszary (drużyna trafi do lazaretu)", func():
			Game.zapisz_zdrowie(heroes)
			main.go("koszary")])
		powod += "\nWzmocnij bohaterów, zmień formację albo dobierz inny skład."
	_nakladka("Porażka", powod, przyciski)

func _koniec_prologu() -> void:
	Game.ukoncz_prolog()
	main.opowiesc(self, "Upadek Hufduhofu", adv.get("po_przegranej", ["..."]), func(): main.go("koszary"), "Do Koszar")

# ---------------------------------------------------------------- widok
func _aktor_wroga(e: CUnit) -> Actor:
	var a := Actor.new()
	world.add_child(a)
	a.setup(str(e.def.get("grafika", "")), "west", e.def.get("placeholder", {}), e.nazwa, true, e.boss)
	a.position = Vector2(e.x, e.y)
	aktorzy[e.uid] = a
	return a

func _jednostka(uid: int) -> CUnit:
	for h in heroes:
		if h.uid == uid:
			return h
	for e in sim.enemies:
		if e.uid == uid:
			return e
	return null

func _synchronizuj(delta: float) -> void:
	for e in sim.enemies:
		var a: Actor = aktorzy.get(e.uid)
		if a == null:
			a = _aktor_wroga(e)
		var cel := Vector2(e.x, e.y)
		var ruch: bool = cel.distance_to(a.position) > 0.6
		a.position = a.position.lerp(cel, minf(1.0, delta * 14.0))
		if a.anim != "attack" and a.anim != "hurt":
			a.play("walk" if ruch and not e.ma_status("ogluszenie") else "idle")
		a.ustaw(e.hp_ulamek(), e.statusy.map(func(s): return s["typ"]), e.hp, e.max_hp)
	for h in heroes:
		var a: Actor = aktorzy[h.uid]
		if h.alive:
			a.ustaw(h.hp_ulamek(), h.statusy.map(func(s): return s["typ"]))
		kregi[h.uid].ustaw("%d obr." % roundi(_obrazenia(h)), 1.0 - clampf(h.cd / maxf(h.cd_max, 0.1), 0.0, 1.0), h.alive)

## Obrażenia jednego ciosu bohatera przed pancerzem celu (liczba w kręgu pod bohaterem).
func _obrazenia(h: CUnit) -> float:
	var mn := h.skala_obrazen * (1.0 + float(h.aury.get("obrazenia", 0.0)))
	for s in h.skills_of("atak_mnoznik"):
		mn *= float(s.get("mnoznik", 1.0))
	return Wfrp.obrazenia(str(h.atak.get("typ", "wrecz")), float(h.atak.get("bron", 1.0)), h.cechy, {}, 0.0, mn)

func _zdarzenia() -> void:
	for ev in sim.events:
		var uid := int(ev.get("uid", ev.get("do", 0)))
		var a: Actor = aktorzy.get(uid)
		match str(ev["typ"]):
			"atak":
				var od: Actor = aktorzy.get(int(ev["od"]))
				if od != null:
					var id_od := int(ev["od"])
					if str(ev["rodzaj"]) == "wrecz" and id_od < 1000 and a != null and not od.w_doskoku:
						# doskok bohatera do celu i powrót na pole - sama wizualizacja ciosu
						var przy := a.position + Vector2(-52, 2)
						Fx.smuga(self, od.position + Vector2(0, -od.wys * 0.5), przy + Vector2(0, -od.wys * 0.5))
						od.doskok(przy, dom[id_od], tempo)
						var gdzie := a.position + Vector2(-6, -a.wys * 0.5)
						get_tree().create_timer(0.13 / tempo).timeout.connect(func(): Fx.ciecie(self, gdzie))
					else:
						od.play("attack", false, 0.4)
					if str(ev["rodzaj"]) != "wrecz" and a != null:
						Fx.pocisk(self, od.position + Vector2(0, -od.wys * 0.6), a.position + Vector2(0, -a.wys * 0.5), str(ev["pocisk"]),
							Color(0.5, 1.0, 0.4) if str(ev["rodzaj"]) == "magia" else Color(0.9, 0.9, 0.8))
					if str(ev["specjalny"]) != "":
						Fx.tekst(self, od.position + Vector2(0, -od.wys - 30), str(ev["specjalny"]) + "!", UiKit.GOLD, 20)
						if float(ev["promien"]) > 0.0 and a != null:
							Fx.ring(self, a.position + Vector2(0, -20), float(ev["promien"]), Color(1.0, 0.6, 0.2))
				Audio.play(str(ev["dzwiek"]))
			"obrazenia":
				if a != null:
					a.blysk()
					var wrog: bool = uid >= 1000
					Fx.tekst(self, a.position + Vector2(0, -a.wys), str(maxi(1, roundi(float(ev["ile"])))),
						Color(1.0, 0.92, 0.5) if wrog else Color(1.0, 0.35, 0.3), 20 if wrog else 22)
					if not wrog:
						Audio.play("hurt")
					elif randf() < 0.5:
						slady.dodaj(a.position + Vector2(randf_range(-10, 24), randf_range(-4, 10)), randf_range(4.0, 7.0))
			"pudlo", "unik":
				if a != null:
					Fx.tekst(self, a.position + Vector2(0, -a.wys), "pudło" if str(ev["typ"]) == "pudlo" else "unik", Color(0.7, 0.7, 0.7), 16)
			"leczenie":
				if a != null and float(ev["ile"]) >= 1.0:
					Fx.tekst(self, a.position + Vector2(0, -a.wys), "+%d" % roundi(float(ev["ile"])), Color(0.4, 1.0, 0.5), 22)
			"smierc":
				if a != null:
					a.umrzyj()
					if int(ev["team"]) == 1:
						Audio.play("skaven_die")
						slady.dodaj(a.position + Vector2(8, 4), 26.0 if a.boss else randf_range(11.0, 16.0))
						aktorzy.erase(uid)
						get_tree().create_timer(1.0).timeout.connect(a.queue_free)
			"zloto":
				# monety wypadają z wroga i po chwili same lecą do licznika; licznik rośnie, gdy dolecą
				var ile := float(ev["ile"])
				var sztuk := clampi(1 + int(ile / 2.0), 2, 5)
				_w_locie += ile
				var czesc := ile / sztuk
				Fx.monety(self, Vector2(float(ev.get("x", 640)), float(ev.get("y", 480))), LICZNIK, sztuk, func():
					_w_locie = maxf(0.0, _w_locie - czesc)
					Audio.play("coin", 1.0 + randf() * 0.3), tempo)
			"strzal":
				Fx.bolt(self, Vector2(float(ev["x"]), float(ev["y"])), float(Data.balance.get("strzal_gracza", {}).get("promien", 64)))
				Audio.play("lightning", 1.5)
			"ultimate":
				if a != null:
					Fx.tekst(self, a.position + Vector2(0, -a.wys - 40), str(ev["nazwa"]) + "!", UiKit.RED, 30)
					Fx.ring(self, a.position + Vector2(0, -40), 420.0, Color(1.0, 0.3, 0.2))
				Audio.play("levelup", 0.7)
			"furia":
				if a != null:
					Fx.tekst(self, a.position + Vector2(0, -a.wys - 40), "FURIA %d" % int(ev["stopien"]), Color(1.0, 0.2, 0.2), 26)
			"skok":
				if a != null:
					a.position = Vector2(_jednostka(uid).x, _jednostka(uid).y) if _jednostka(uid) != null else a.position
					Fx.tekst(self, a.position + Vector2(0, -a.wys - 10), "Skok!", Color(1.0, 0.5, 0.4), 20)
	sim.events.clear()

# ---------------------------------------------------------------- HUD
func _buduj_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Control.new()
	hud.theme = UiKit.theme()
	UiKit.full_rect(hud)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	# licznik koron (tu lecą monety)
	var moneta := Ikona.nowa("korona", 34.0, Gk.ZLOTO_J)
	moneta.position = LICZNIK - Vector2(17, 17)
	hud.add_child(moneta)
	lbl_korony = Gk.tytul("", 28)
	lbl_korony.position = Vector2(60, 10)
	hud.add_child(lbl_korony)
	# panel przygody w rogu: nazwa, cel z paskiem postępu, tor plansz (ukończone / bieżąca / kłódki / boss)
	panel_celu = Gk.rama(10.0, 0.88)
	panel_celu.theme = Gk.theme()
	panel_celu.position = Vector2(920, 8)
	panel_celu.custom_minimum_size = Vector2(350, 0)
	panel_celu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pv := Gk.vb(4)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_celu.add_child(pv)
	lbl_nazwa = Gk.tytul(str(adv.get("nazwa", "")) + ("" if trudnosc == "normal" else "  ·  %s" % str(diff.get("nazwa", trudnosc))), 20)
	lbl_nazwa.clip_text = true
	pv.add_child(lbl_nazwa)
	lbl_cel = Gk.tekst("", 15, Gk.TEKST, false)
	lbl_cel.clip_text = true
	pv.add_child(lbl_cel)
	pasek_celu = Control.new()
	pasek_celu.custom_minimum_size = Vector2(0, 12)
	pasek_celu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pasek_celu.draw.connect(func():
		var r := Rect2(Vector2.ZERO, pasek_celu.size)
		pasek_celu.draw_rect(r, Color(0.03, 0.02, 0.02))
		pasek_celu.draw_rect(Rect2(1, 1, (r.size.x - 2) * clampf(_postep, 0.0, 1.0), r.size.y - 2), Color(0.93, 0.6, 0.12))
		pasek_celu.draw_rect(r, Gk.ZLOTO_C, false, 1.0))
	pv.add_child(pasek_celu)
	tor_plansz = Gk.hb(5)
	tor_plansz.alignment = BoxContainer.ALIGNMENT_CENTER
	tor_plansz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(tor_plansz)
	hud.add_child(panel_celu)
	btn_tempo = UiKit.button("Tempo x1", _zmien_tempo, 130.0, 44.0)
	btn_tempo.position = Vector2(1000, 664)
	hud.add_child(btn_tempo)
	if not bool(adv.get("prolog", false)):
		var w := UiKit.button("Koszary", func():
			if sim != null:
				Game.zapisz_zdrowie(heroes)
			main.go("koszary"), 130.0, 44.0)
		w.position = Vector2(1138, 664)
		hud.add_child(w)
	panel_podp = PanelContainer.new()
	panel_podp.position = Vector2(200, 110)
	panel_podp.custom_minimum_size = Vector2(700, 0)
	panel_podp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(panel_podp)
	lbl_podp = UiKit.label("", 22)
	lbl_podp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_podp.custom_minimum_size = Vector2(670, 0)
	panel_podp.add_child(lbl_podp)
	lbl_boss = UiKit.outlined(UiKit.label("", 22, UiKit.RED))
	lbl_boss.position = Vector2(400, 8)
	lbl_boss.custom_minimum_size = Vector2(480, 0)
	hud.add_child(lbl_boss)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(400, 40)
	boss_bar.custom_minimum_size = Vector2(480, 22)
	boss_bar.show_percentage = false
	boss_bar.max_value = 1.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.7, 0.12, 0.1)
	boss_bar.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.08, 0.05, 0.05)
	back.border_color = Color(0.62, 0.48, 0.22)
	back.set_border_width_all(2)
	boss_bar.add_theme_stylebox_override("background", back)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(boss_bar)
	var hb := HBoxContainer.new()
	hb.position = Vector2(16, 650)
	hb.add_theme_constant_override("separation", 10)
	hud.add_child(hb)
	for h in heroes:
		if h.ult.is_empty():
			continue
		var b := UiKit.button("", func(): sim.uzyj_ult(h), 230.0, 56.0)
		b.add_theme_font_size_override("font_size", 18)
		hb.add_child(b)
		ult_btns[h.uid] = b

## Tor plansz: ukończone na zielono, bieżąca z numerem, kolejne z kłódką, ostatnia to boss.
func _odswiez_tor() -> void:
	for c in tor_plansz.get_children():
		c.queue_free()
	var plansze: Array = adv.get("plansze", [])
	for i in plansze.size():
		var boss := bool(plansze[i].get("boss", false))
		var k := Control.new()
		k.custom_minimum_size = Vector2(34, 34)
		k.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var stan := 0 if i < plansza else (1 if i == plansza else 2)
		k.draw.connect(func():
			var r := Rect2(Vector2.ZERO, k.size)
			var tlo := Color(0.16, 0.42, 0.14) if stan == 0 else (Color(0.45, 0.07, 0.06) if stan == 1 else Color(0.08, 0.05, 0.05))
			k.draw_rect(r, tlo)
			k.draw_rect(r, Gk.ZLOTO_J if stan == 1 else Gk.ZLOTO_C, false, 3.0 if stan == 1 else 1.0)
			if stan == 1 and not boss:
				var f := Gk.f_tytul()
				var t := str(i + 1)
				var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
				k.draw_string(f, Vector2((r.size.x - w) * 0.5, 25), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Gk.ZLOTO_J))
		var ikona := ""
		if stan == 0:
			ikona = "ptaszek"
		elif boss:
			ikona = "czaszka"
		elif stan == 2:
			ikona = "klodka"
		if ikona != "":
			var ik := Ikona.nowa(ikona, 20.0, Color(0.75, 1.0, 0.7) if stan == 0 else (Gk.SZKARLAT_J if boss else Gk.PRZYG))
			ik.position = Vector2(7, 7)
			k.add_child(ik)
		tor_plansz.add_child(k)

## Pas z napisem przejeżdża przez ekran i znika; niczego nie blokuje.
func _baner(t: String) -> void:
	var pas := ColorRect.new()
	pas.color = Color(0.04, 0.02, 0.02, 0.72)
	pas.size = Vector2(1280, 64)
	pas.position = Vector2(-1280, 250)
	pas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := Gk.hb(18)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Gk.tytul(t.to_upper(), 46, Gk.TEKST)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	h.add_child(Ikona.nowa("dalej", 44.0, Gk.ZLOTO_J))
	pas.add_child(h)
	hud.add_child(pas)
	var tw := pas.create_tween()
	tw.tween_property(pas, "position:x", 0.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_interval(1.3)
	tw.tween_property(pas, "modulate:a", 0.0, 0.4)
	tw.tween_callback(pas.queue_free)

func _zmien_tempo() -> void:
	tempo = 2.0 if tempo < 1.5 else (3.0 if tempo < 2.5 else 1.0)
	btn_tempo.text = "Tempo x%d" % int(tempo)

func _podpowiedz(t: String, czas: float) -> void:
	if t == "":
		panel_podp.visible = false
		return
	lbl_podp.text = t
	panel_podp.visible = true
	panel_podp.reset_size()
	_podp_t = czas

func _odswiez_hud() -> void:
	var cel := sim.opis_celu()
	var limit := float(diff.get("limit_czasu", 0))
	if limit > 0.0:
		cel += "     Czas: %d/%d s" % [int(sim.time), int(limit)]
	lbl_cel.text = cel
	if absf(sim.postep_celu() - _postep) > 0.002:
		_postep = sim.postep_celu()
		pasek_celu.queue_redraw()
	lbl_korony.text = "%d" % maxi(0, int(Game.state["korony"]) + roundi(sim.zloto - _w_locie))
	var boss: CUnit = null
	for e in sim.enemies:
		if e.boss and e.alive:
			boss = e
	boss_bar.visible = boss != null
	lbl_boss.visible = boss != null
	if boss != null:
		boss_bar.value = boss.hp_ulamek()
		lbl_boss.text = boss.nazwa + ("" if boss.furia == 0 else "   furia %d" % boss.furia)
	for h in heroes:
		if not ult_btns.has(h.uid):
			continue
		var b: Button = ult_btns[h.uid]
		b.disabled = not sim.ult_gotowy(h)
		var nazwa := str(h.ult.get("nazwa", "Ultimate"))
		if not h.alive:
			b.text = "%s\n(poległ)" % h.nazwa
		elif h.ult_cd > 0.0:
			b.text = "%s\n%s (%d s)" % [h.nazwa, nazwa, ceili(h.ult_cd)]
		else:
			b.text = "%s\n%s" % [h.nazwa, nazwa]

func _nakladka(tytul: String, opis: String, przyciski: Array) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var opak: Array = []
	for p in przyciski:
		var cb: Callable = p[1]
		opak.append([p[0], func():
			layer.queue_free()
			cb.call()])
	layer.add_child(UiKit.overlay(tytul, opis, opak))
