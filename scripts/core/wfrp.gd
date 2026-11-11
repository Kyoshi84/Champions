class_name Wfrp
extends RefCounted
## Uproszczona mechanika Warhammer Fantasy Roleplay przeniesiona na walkę w czasie rzeczywistym.
## Każda cecha ma realne zastosowanie:
##   WW  - szansa trafienia wręcz (i obrona przed trafieniem wręcz)
##   US  - szansa trafienia z dystansu
##   K   - Siła (S = K/10) dodawana do obrażeń fizycznych
##   Odp - Wytrzymałość (Wt = Odp/10) odejmowana od obrażeń fizycznych
##   Zr  - szansa uniku
##   Int - moc i celność magii, siła leczenia
##   SW  - odporność na magię i skracanie ogłuszeń
##   Ogd - premia do zdobywanych koron (targowanie się)
##   Zyw - punkty życia
##   Sz  - czas między atakami
## Wszystkie współczynniki: data/balance.json -> "walka".

static func B() -> Dictionary:
	return Data.walka()

static func sila(c: Dictionary) -> float:
	return float(c.get("K", 0)) / 10.0

static func wytrzymalosc(c: Dictionary) -> float:
	return float(c.get("Odp", 0)) / 10.0

static func max_hp(c: Dictionary) -> float:
	return maxf(1.0, float(c.get("Zyw", 1)) * float(B().get("hp_na_zyw", 10.0)))

## Szansa trafienia (0..1) przed unikiem.
static func szansa_trafienia(typ: String, att: Dictionary, def: Dictionary) -> float:
	var b := B()
	var s := 0.5
	match typ:
		"wrecz":
			s = float(b.get("szansa_bazowa_wrecz", 0.55)) + (float(att.get("WW", 0)) - float(def.get("WW", 0))) / 100.0
		"dystans":
			s = float(b.get("szansa_bazowa_dystans", 0.35)) + float(att.get("US", 0)) / 100.0
		"magia":
			s = float(b.get("szansa_bazowa_magia", 0.6)) + (float(att.get("Int", 0)) - float(def.get("SW", 0))) / 100.0
	return clampf(s, float(b.get("min_szansa", 0.2)), float(b.get("max_szansa", 0.95)))

static func unik(def: Dictionary) -> float:
	return clampf(float(def.get("Zr", 0)) / float(B().get("unik_dzielnik", 500.0)), 0.0, 0.5)

## Obrażenia po redukcji celu. Fizyczne: (broń + S) x mnożnik - (Wt + pancerz). Magia omija pancerz i Wt,
## zmniejsza ją tylko Siła Woli celu. Zawsze co najmniej 1.
static func obrazenia(typ: String, bron: float, att: Dictionary, def: Dictionary, pancerz: float, mnoznik: float) -> float:
	var dmg := 0.0
	match typ:
		"wrecz":
			dmg = (bron + sila(att)) * mnoznik - (wytrzymalosc(def) + pancerz)
		"dystans":
			dmg = (bron + sila(att) * 0.5) * mnoznik - (wytrzymalosc(def) + pancerz)
		"magia":
			dmg = (bron + float(att.get("Int", 0)) / 10.0) * mnoznik - float(def.get("SW", 0)) / float(B().get("odpornosc_magii_dzielnik", 20.0))
	return maxf(1.0, dmg)

## Czas między atakami: każdy punkt Sz powyżej bazowej skraca go o 'sz_krok'.
static func czas_ataku(bazowy: float, c: Dictionary) -> float:
	var b := B()
	var k := 1.0 - (float(c.get("Sz", 4)) - float(b.get("sz_bazowa", 4.0))) * float(b.get("sz_krok", 0.06))
	return maxf(float(b.get("min_czas_ataku", 0.8)), bazowy * clampf(k, 0.4, 1.6))

static func czas_ogluszenia(czas: float, c: Dictionary, odp_ogluszenie: float) -> float:
	return czas * clampf(1.0 - float(c.get("SW", 0)) / 100.0, 0.2, 1.0) * clampf(1.0 - odp_ogluszenie, 0.1, 1.0)

static func leczenie(moc: float, c: Dictionary) -> float:
	return moc + float(c.get("Int", 0)) / 10.0

## Premia do złota od Ogłady jednego bohatera (ułamek).
static func premia_zlota(c: Dictionary) -> float:
	return float(c.get("Ogd", 0)) / float(Data.balance.get("ekonomia", {}).get("ogd_na_procent_zlota", 10.0)) / 100.0
