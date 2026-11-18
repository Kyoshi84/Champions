class_name Wfrp
extends RefCounted
## Uproszczona mechanika Warhammer Fantasy Roleplay dla walki automatycznej („Carroburg WFRP-lite”).
## Atakujący rzuca tylko na własne cechy, cel broni się pancerzem (przed czarami: Siłą Woli). Ataki zawsze trafiają.
##   WW  - szansa krytyka wręcz              US  - szansa krytyka z dystansu       Op - szansa krytyka czarem
##   Zr  - siła krytyka (×1,5 + Zr/100)      K   - Siła S = K/10, + broń = obrażenia fizyczne
##   Odp - Wytrzymałość Wt = Odp/10, razem ze zbroją tworzy pancerz (procentowa redukcja obrażeń fizycznych)
##   Int - moc czarów i leczenia (jak S dla czarów)   SW - odporność na czary
##   Zyw - punkty życia (×10)    Sz - długość cyklu ataku    A - liczba ciosów w cyklu
##   CP  - zasięg aur przywódczych i umiejętności obszarowych
##   Ogd - mnożnik pasywnych umiejętności złota i klejnotów
## Wszystkie współczynniki: data/balance.json -> "walka".

static func B() -> Dictionary:
	return Data.walka()

static func sila(c: Dictionary) -> float:
	return float(c.get("K", 0)) / 10.0

static func wytrzymalosc(c: Dictionary) -> float:
	return float(c.get("Odp", 0)) / 10.0

static func max_hp(c: Dictionary) -> float:
	return maxf(1.0, float(c.get("Zyw", 1)) * float(B().get("hp_na_zyw", 10.0)))

# ---------------------------------------------------------------- pancerz
## Pancerz = Wt + zbroja (punkty pancerza z przedmiotów i umiejętności).
static func pancerz(c: Dictionary, zbroja: float) -> float:
	return wytrzymalosc(c) + zbroja

## Ułamek obrażeń fizycznych zatrzymany przez pancerz: P / (P + stała). Nigdy 100%, każdy punkt coś daje.
static func redukcja(p: float) -> float:
	p = maxf(p, 0.0)
	return p / (p + float(B().get("pancerz_stala", 10.0)))

# ---------------------------------------------------------------- krytyki
static func cecha_krytyka(typ: String) -> String:
	match typ:
		"dystans": return "US"
		"magia": return "Op"
	return "WW"

## Szansa krytyka (0..1): WW, US albo Op podzielone przez 'krytyk_dzielnik', najwyżej 'krytyk_max'.
static func szansa_krytyka(typ: String, c: Dictionary) -> float:
	var b := B()
	return clampf(float(c.get(cecha_krytyka(typ), 0)) / float(b.get("krytyk_dzielnik", 3.0)) / 100.0, 0.0, float(b.get("krytyk_max", 0.5)))

## Mnożnik krytyka: ×1,5 + Zr/100.
static func sila_krytyka(c: Dictionary) -> float:
	return float(B().get("krytyk_baza", 1.5)) + float(c.get("Zr", 0)) / 100.0

# ---------------------------------------------------------------- obrażenia
## Fizyczne: (broń + S) × mnożnik × krytyk × (1 − redukcja pancerza celu).
## Czar: moc × mnożnik × krytyk × (1 + (Int − SW celu) / 50), w granicach ×0,3..×2,5; czar omija pancerz.
static func obrazenia(typ: String, bron: float, att: Dictionary, def: Dictionary, zbroja: float, mnoznik: float, krytyk: bool = false) -> float:
	var k := sila_krytyka(att) if krytyk else 1.0
	if typ == "magia":
		return maxf(0.1, bron * mnoznik * k * mnoznik_czaru(att, def))
	var surowe := (bron + sila(att)) * mnoznik * k
	return maxf(0.1, surowe * (1.0 - redukcja(pancerz(def, zbroja))))

static func mnoznik_czaru(att: Dictionary, def: Dictionary) -> float:
	var b := B()
	var r := (float(att.get("Int", 0)) - float(def.get("SW", 0))) / float(b.get("magia_dzielnik", 50.0))
	return clampf(1.0 + r, float(b.get("magia_min", 0.3)), float(b.get("magia_max", 2.5)))

## Średnie obrażenia jednego ciosu z uwzględnieniem krytyków (do kart i kręgów pod bohaterem).
static func obrazenia_srednie(typ: String, bron: float, att: Dictionary, def: Dictionary, zbroja: float, mnoznik: float) -> float:
	var p := szansa_krytyka(typ, att)
	return obrazenia(typ, bron, att, def, zbroja, mnoznik) * (1.0 + p * (sila_krytyka(att) - 1.0))

# ---------------------------------------------------------------- tempo
## Długość cyklu ataku: czas broni × Sz bazowa / Sz.
static func czas_ataku(bazowy: float, c: Dictionary) -> float:
	var b := B()
	var sz := maxf(1.0, float(c.get("Sz", 4)))
	return maxf(float(b.get("min_czas_ataku", 0.8)), bazowy * float(b.get("sz_bazowa", 4.0)) / sz)

## Liczba ciosów w jednym cyklu (cecha A).
static func ataki(c: Dictionary) -> int:
	return maxi(1, roundi(float(c.get("A", 1))))

# ---------------------------------------------------------------- reszta
static func czas_ogluszenia(czas: float, c: Dictionary, odp_ogluszenie: float) -> float:
	return czas * clampf(1.0 - float(c.get("SW", 0)) / 100.0, 0.2, 1.0) * clampf(1.0 - odp_ogluszenie, 0.1, 1.0)

static func leczenie(moc: float, c: Dictionary) -> float:
	return moc + float(c.get("Int", 0)) / 10.0

## Mnożnik pasywnych umiejętności złota i klejnotów z Ogłady (Ogd 30 = ×1).
static func mnoznik_ogd(c: Dictionary) -> float:
	return float(c.get("Ogd", 0)) / float(B().get("ogd_dzielnik", 30.0))

## Zasięg aury przywódczej z CP: „sąsiednie” rośnie do skosów (CP 35+) i dwóch pól (CP 50+). Inne kształty bez zmian.
static func zasieg_cp(zasieg: String, c: Dictionary) -> String:
	if zasieg != "sasiednie":
		return zasieg
	var cp := float(c.get("CP", 0))
	var progi: Array = B().get("cp_progi", [35, 50])
	if cp >= float(progi[1]):
		return "zasieg_2"
	if cp >= float(progi[0]):
		return "sasiednie_skos"
	return "sasiednie"

## Promień umiejętności obszarowej z CP: × (0,6 + CP/100), czyli CP 40 = bez zmian.
static func promien_cp(promien: float, c: Dictionary) -> float:
	return promien * (float(B().get("cp_promien_baza", 0.6)) + float(c.get("CP", 0)) / 100.0)
