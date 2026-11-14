class_name KW
extends RefCounted
## Wspólne klocki ekranów Koszar: teksty statusów, opisy przedmiotów i umiejętności, karta bohatera w rosterze.

const CECHY := ["WW", "US", "K", "Odp", "Zr", "Int", "SW", "Ogd", "Zyw", "Sz"]
const CECHY_OPIS := {"WW": "Walka wręcz", "US": "Umiejętności strzeleckie", "K": "Krzepa", "Odp": "Odporność", "Zr": "Zręczność",
	"Int": "Inteligencja", "SW": "Siła woli", "Ogd": "Ogłada", "Zyw": "Żywotność", "Sz": "Szybkość"}

static func cecha(k: String) -> String:
	return "Żyw" if k == "Zyw" else k

static func status_zdrowia(id: String) -> String:
	if Game.polegly(id):
		return "W lazarecie — wróci za %s" % Gk.czas(Game.czas_do_zdrowia(id))
	if Game.ranny(id):
		return "Ranny — pełnia sił za %s" % Gk.czas(Game.czas_do_zdrowia(id))
	return "Zdrowy"

static func kolor_zdrowia(id: String) -> Color:
	if Game.polegly(id):
		return Gk.PRZYG
	return Gk.SZKARLAT_J if Game.ranny(id) else Gk.ZIELEN

static func miejsce(id: String) -> String:
	var pole := Game.pole_bohatera(id)
	if pole == -1:
		return "Rezerwa"
	return "Przedni rząd" if Formation.rzad(pole) == 0 else "Tylny rząd"

static func opis_cech(it: Dictionary) -> String:
	var out: Array = []
	var c: Dictionary = it.get("cechy", {})
	for k in c:
		var w := float(c[k])
		match str(k):
			"bron": out.append("obrażenia +%s" % _liczba(w))
			"pancerz": out.append("pancerz +%s" % _liczba(w))
			"odp_ogluszenie": out.append("ogłuszenia krótsze o %d%%" % roundi(w * 100.0))
			_: out.append("%s +%s" % [cecha(str(k)), _liczba(w)])
	return ",  ".join(out)

static func _liczba(w: float) -> String:
	return str(roundi(w)) if is_equal_approx(w, roundf(w)) else "%.1f" % w

static func typ_umiejetnosci(s: Dictionary) -> String:
	match str(s.get("typ", "")):
		"ultimate": return "Ultimate · odnowienie %d s" % roundi(float(s.get("odnowienie", 60)))
		"aura": return "Aura · %s" % Formation.nazwa_zasiegu(str(s.get("zasieg", "")))
		"modyfikacja", "atak_mnoznik", "stat": return "Ulepszenie ataku"
		"leczenie": return "Leczenie"
		"prowokacja": return "Prowokacja"
	return "Pasywna"

static func nazwa_trudnosci(t: String) -> String:
	return str(Data.difficulty(t).get("nazwa", t))

## Karta bohatera w rosterze: portret, imię, poziom, HP z paskiem, ranny = czerwony krzyżyk, poległy = wyszarzony.
static func karta_bohatera(k: BarracksScene, id: String, cb: Callable, wybrana: bool = false, portret_px: float = 84.0, maly: bool = false) -> Array:
	var def := Data.hero(id)
	var karta := Gk.karta(cb, wybrana, 8.0 if maly else 10.0)
	var h := Gk.hb(12)
	h.add_child(Gk.portret(id, Vector2(portret_px, portret_px), Gk.stan_bohatera(id)))
	var v := Gk.vb(3 if maly else 5)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var g := Gk.hb(8)
	var imie := Gk.tytul(str(def.get("imie", id)), 20 if maly else 24, Gk.PRZYG if Game.polegly(id) else Gk.ZLOTO_J)
	imie.clip_text = true
	imie.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(imie)
	g.add_child(Gk.odznaka("poz. %d" % Game.poziom(id)))
	v.add_child(g)
	var pasek := Gk.pasek_hp(id, 16.0 if maly else 20.0)
	v.add_child(pasek)
	var d := Gk.hb(8)
	if not maly:
		d.add_child(Gk.odznaka(miejsce(id), Gk.ZLOTO if Game.pole_bohatera(id) != -1 else Gk.PRZYG))
	var st := Gk.tekst(status_zdrowia(id), 14 if maly else 15, kolor_zdrowia(id), false)
	st.clip_text = true
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d.add_child(st)
	v.add_child(d)
	h.add_child(v)
	Gk.do_karty(karta, h)
	k.zywe.append(func():
		pasek.queue_redraw()
		st.text = status_zdrowia(id))
	return karta

## Przycisk leczenia (albo null, gdy bohater zdrowy).
static func przycisk_lazaretu(k: BarracksScene, id: String, min_w: float = 0.0) -> Button:
	if not Game.polegly(id) and not Game.ranny(id):
		return null
	var b := Gk.przycisk("", func():
		if Game.ulecz(id):
			Audio.play("coin")
			k.odswiez("%s wraca do pełni sił." % str(Data.hero(id).get("imie", id))), false, min_w, 46.0, "krzyz")
	b.name = "btn_ulecz"
	var odswiez := func():
		b.text = "%s · %d koron" % ["Postaw na nogi" if Game.polegly(id) else "Opatrz rany", Game.koszt_leczenia(id)]
		b.disabled = not Game.moze_uleczyc(id)
	odswiez.call()
	k.zywe.append(odswiez)
	return b
