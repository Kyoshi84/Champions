class_name BarracksScene
extends Control
## Koszary Szkarłatnej Gwardii - powłoka: tło, nagłówek z herbem i walutami, stos ekranów (Wróć / Hub).
## Każdy ekran to osobny plik w scripts/scenes/koszary/ i ma jedną funkcję. Po każdej zmianie stanu bieżący ekran
## buduje się od nowa z danych gry, więc widok nigdy nie rozjeżdża się ze stanem.
##
## Hub ─┬─ Drużyna ── Bohater ─┬─ Rozwój i drzewko umiejętności
##      │                      └─ Ekwipunek
##      ├─ Formacja
##      ├─ Misje ── Szczegóły misji (trudność, nagrody, rekord Hardcore) ── start
##      ├─ Tawerna „Złoty Prosiak” ── Najemnik ── rekrutacja
##      ├─ Sklep (zamknięty)
##      └─ Osiągnięcia

const EKRANY := {
	"hub": "Koszary Szkarłatnej Gwardii", "druzyna": "Drużyna", "bohater": "Bohater", "rozwoj": "Rozwój i umiejętności",
	"ekwipunek": "Ekwipunek", "formacja": "Formacja drużyny", "misje": "Misje i kampanie", "misja": "Szczegóły misji",
	"tawerna": "Tawerna „Złoty Prosiak”", "najemnik": "Najemnik", "sklep": "Sklep", "osiagniecia": "Osiągnięcia"}

var main: Node
var stos: Array = [["hub", {}]]      # [nazwa ekranu, parametry]
var komunikat: String = ""           # jednorazowa informacja pokazywana na bieżącym ekranie
var zywe: Array = []                 # funkcje odświeżane co sekundę (liczniki lazaretu, paski zdrowia)
var _tresc: Control = null
var _podpis_zdrowia: String = ""
var _sek: float = 0.0
var _stary_aspekt: int = Window.CONTENT_SCALE_ASPECT_KEEP

func _ready() -> void:
	theme = Gk.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Audio.play_track("koszary")
	# Koszary wypełniają cały ekran także na szerszych i węższych proporcjach (reszta gry trzyma 16:9)
	var okno := get_tree().root
	_stary_aspekt = okno.content_scale_aspect
	okno.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_tree().set_quit_on_go_back(false)
	_buduj()

func _exit_tree() -> void:
	get_tree().root.content_scale_aspect = _stary_aspekt
	get_tree().set_quit_on_go_back(true)

# ---------------------------------------------------------------- nawigacja
func ekran() -> String:
	return str(stos[stos.size() - 1][0])

func parametry() -> Dictionary:
	return stos[stos.size() - 1][1]

func idz(nazwa: String, p: Dictionary = {}) -> void:
	if not EKRANY.has(nazwa):
		return
	komunikat = ""
	stos.append([nazwa, p])
	_buduj()

func wroc() -> void:
	komunikat = ""
	if stos.size() > 1:
		stos.pop_back()
		_buduj()
	else:
		main.go("menu")

func hub() -> void:
	komunikat = ""
	stos = [["hub", {}]]
	_buduj()

## Przebudowuje bieżący ekran po zmianie stanu gry.
func odswiez(info: String = "") -> void:
	komunikat = info
	_buduj()

func wyrusz(adv_id: String, trudnosc: String) -> void:
	main.go("bitwa", {"przygoda": adv_id, "trudnosc": trudnosc})

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		wroc()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		wroc()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_sek += delta
	if _sek < 1.0:
		return
	_sek = 0.0
	if _podpis() != _podpis_zdrowia:       # ktoś wrócił z lazaretu albo wyzdrowiał
		_buduj()
		return
	for f in zywe:
		f.call()

func _podpis() -> String:
	var s := ""
	for id in Game.state["bohaterowie"]:
		s += "p" if Game.polegly(id) else ("r" if Game.ranny(id) else "z")
	return s

# ---------------------------------------------------------------- budowa
func _buduj() -> void:
	var przewiniecia: Array = []
	for s in find_children("*", "ScrollContainer", true, false):
		przewiniecia.append([s.scroll_vertical, s.scroll_horizontal])
	var poprzedni := str(get_meta("ekran", ""))
	for c in get_children():
		remove_child(c)
		c.queue_free()
	zywe.clear()
	_podpis_zdrowia = _podpis()
	var nazwa := ekran()
	set_meta("ekran", nazwa)
	add_child(TloKoszar.dla(nazwa))
	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["left", "right"]:
		mc.add_theme_constant_override("margin_" + m, 18)
	mc.add_theme_constant_override("margin_top", 10)
	mc.add_theme_constant_override("margin_bottom", 12)
	add_child(mc)
	var v := Gk.vb(10)
	mc.add_child(v)
	v.add_child(_naglowek(nazwa))
	if komunikat != "":
		var k := Gk.rama(8.0)
		k.name = "komunikat"
		k.add_child(Gk.tekst(komunikat, 17, Gk.ZLOTO_J))
		v.add_child(k)
	_tresc = Control.new()
	_tresc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tresc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_tresc)
	var p := parametry()
	match nazwa:
		"druzyna": KDruzyna.buduj(self, _tresc, p)
		"bohater": KBohater.buduj(self, _tresc, p)
		"rozwoj": KRozwoj.buduj(self, _tresc, p)
		"ekwipunek": KEkwipunek.buduj(self, _tresc, p)
		"formacja": KFormacja.buduj(self, _tresc, p)
		"misje": KMisje.buduj(self, _tresc, p)
		"misja": KMisja.buduj(self, _tresc, p)
		"tawerna": KTawerna.buduj(self, _tresc, p)
		"najemnik": KTawerna.najemnik(self, _tresc, p)
		"sklep": KInne.sklep(self, _tresc, p)
		"osiagniecia": KInne.osiagniecia(self, _tresc, p)
		_: KHub.buduj(self, _tresc, p)
	if poprzedni == nazwa and not przewiniecia.is_empty():
		_przywroc_przewiniecia.call_deferred(przewiniecia)

func _przywroc_przewiniecia(stare: Array) -> void:
	var nowe := find_children("*", "ScrollContainer", true, false)
	for i in mini(stare.size(), nowe.size()):
		nowe[i].scroll_vertical = stare[i][0]
		nowe[i].scroll_horizontal = stare[i][1]

## Kontener wypełniający obszar treści - ekrany wkładają tu swój układ.
func pelny(c: Control, do: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	do.add_child(c)
	return c

func _naglowek(nazwa: String) -> Control:
	var h := Gk.hb(12)
	h.custom_minimum_size = Vector2(0, 62)
	var na_hubie := stos.size() <= 1
	if not na_hubie:
		var w := Gk.przycisk("Wróć", wroc, false, 118.0, 50.0, "wstecz")
		w.name = "btn_wroc"
		w.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(w)
	# herb: znak rozpoznawczy na każdym ekranie; poza Hubem jest też przyciskiem powrotu do Hubu
	var herb_k := Gk.karta(hub, false, 2.0)
	var hp: PanelContainer = herb_k[0]
	hp.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	Gk.do_karty(herb_k, Gk.herb(88.0 if na_hubie else 60.0))
	herb_k[1].name = "btn_hub"
	herb_k[1].disabled = na_hubie
	herb_k[1].add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	herb_k[1].tooltip_text = "" if na_hubie else "Hub Koszar"
	hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(hp)
	var tv := Gk.vb(0)
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := tytul_ekranu(stos.size() - 1)
	tv.add_child(Gk.tytul(t, 40 if na_hubie else 32, Gk.SZKARLAT_J if na_hubie else Gk.ZLOTO_J))
	if na_hubie:
		tv.add_child(Gk.tekst("Carroburg  ·  Twierdza Gwardii", 15, Gk.PRZYG, false))
	else:
		var sciezka: Array = []
		for i in stos.size() - 1:
			sciezka.append(tytul_ekranu(i) if i > 0 else "Koszary")
		tv.add_child(Gk.tekst("  ›  ".join(sciezka), 15, Gk.PRZYG, false))
	h.add_child(tv)
	var wal := Gk.rama(8.0, 0.85)
	wal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var wh := Gk.hb(18)
	wal.add_child(wh)
	var st := wal.get_theme_stylebox("panel").duplicate()
	st.content_margin_left = 18
	st.content_margin_right = 18
	wal.add_theme_stylebox_override("panel", st)
	var kor := Gk.waluta("korona", str(int(Game.state["korony"])))
	kor.name = "korony"
	wh.add_child(kor)
	wh.add_child(Gk.waluta("klejnot", str(int(Game.state["klejnoty"])), Color(0.92, 0.36, 0.42)))
	var fav := Gk.gruby("Favor +%d%%" % roundi(float(Game.state["favor"]) * 100.0), 18, Gk.ZLOTO)
	fav.tooltip_text = "Favor: stała premia do wszystkich zdobywanych koron. Rośnie za pierwsze ukończenie przygody."
	fav.mouse_filter = Control.MOUSE_FILTER_STOP
	wh.add_child(fav)
	h.add_child(wal)
	if not na_hubie and stos.size() > 2:
		var hb2 := Gk.przycisk("Hub", hub, false, 96.0, 50.0)
		hb2.name = "btn_hub2"
		hb2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(hb2)
	return h

func tytul_ekranu(i: int) -> String:
	var nazwa := str(stos[i][0])
	var p: Dictionary = stos[i][1]
	match nazwa:
		"bohater", "najemnik":
			return str(Data.hero(str(p.get("id", ""))).get("imie", EKRANY[nazwa]))
		"misja":
			return str(Data.adventure(str(p.get("id", ""))).get("nazwa", EKRANY[nazwa]))
	return str(EKRANY.get(nazwa, nazwa))

## Do testów i skrótów: przycisk o podanej nazwie węzła.
func znajdz(nazwa_wezla: String) -> Button:
	return find_child(nazwa_wezla, true, false) as Button
