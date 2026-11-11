# Mechanika — jak to jest zbudowane

Krótki opis szkieletu. Wszystkie liczby są w `data/*.json`; kod ich nie zawiera.

## 1. Pętla gry

Menu → prolog w karczmie → prolog we wsi (przegrana z Championem Chaosu) → **Koszary** ⇄ przygoda (5 plansz, boss na piątej).

Przygoda **nie resetuje** bohaterów: poziomy, specjalizacje i ekwipunek zostają. Między planszami polegli wstają,
a wszyscy odzyskują 30% życia.

## 2. Cechy WFRP w walce (`scripts/core/wfrp.gd`)

| Cecha | Działanie |
|---|---|
| WW | szansa trafienia wręcz: 55% + (WW atakującego − WW celu) |
| US | szansa trafienia z dystansu: 35% + US |
| K | Siła S = K/10, dodawana do obrażeń fizycznych |
| Odp | Wytrzymałość Wt = Odp/10, odejmowana od obrażeń fizycznych |
| Zr | unik: Zr/5 % |
| Int | moc i celność magii, siła leczenia |
| SW | zmniejsza obrażenia od magii (SW/20) i skraca ogłuszenia |
| Ogd | każde 10 punktów = +1% zdobywanych koron |
| Żyw | punkty życia = Żyw × 10 |
| Sz | każdy punkt powyżej 4 skraca czas między atakami o 6% |

Obrażenia fizyczne: `(broń + S) × mnożniki − (Wt + pancerz)`, minimum 1.
**Magia omija Wt i pancerz** — dlatego Ursa jest odpowiedzią na opancerzonych wrogów (Champion Chaosu ma pancerz 3).
Bazowy czas między atakami: 5 s.

## 3. Walka (`scripts/core/combat.gd`)

- Jeden zegar: stały krok 0,1 s. Symulacja nie zna grafiki; ekran bitwy tylko ją pokazuje. To samo ziarno losowości = ten sam przebieg.
- Pole: 5 torów. Bohaterowie stoją na polach formacji, wrogowie wchodzą z prawej.
- Zachowania wrogów: `wrecz` (idzie na pierwszą linię), `dystans` (strzela w losowego bohatera — omija pierwszą linię),
  `magia` (celuje w tylny rząd, nakłada klątwę), `skok` (Pies Chaosu przeskakuje pierwszą linię).
- Bohater walczący wręcz dosięga wroga tylko z pierwszej linii.
- **Strzał gracza**: dotknięcie pola bitwy — małe obrażenia w promieniu i krótkie ogłuszenie; odnowienie 0,6 s.
  Po ogłuszeniu wróg jest chwilę odporny, bossów ogłusza znacznie krócej. W prologu strzał jest 3× silniejszy.
- **Boss**: co 10 s rośnie furia (+10% obrażeń, +6% szybkości na stopień) — warto trzymać Ultimate na właściwy moment.
- Cele plansz: pokonaj wszystkich, zabij bossa, przetrwaj czas, zbierz łup.

## 4. Formacja (`scripts/core/formation.gd`)

10 pól: przedni rząd (pola 0–4) i tylny rząd (5–9); pola 2 i 7 leżą w tym samym torze.
Zasięgi aur: sąsiednie pola, zasięg 2, ten sam tor, pole przed / za bohaterem, cały przedni / tylny rząd, cała drużyna.
Efekty aur: obrażenia, szybkość ataku, redukcja obrażeń, złoto, regeneracja.
W Koszarach widać, które pola obejmuje aura wybranego bohatera i od kogo dostaje on buffy.

Liczba miejsc w drużynie: 2 na start, +2 za każdą ukończoną przygodę (maks. 10).

## 5. Rozwój (`scripts/core/progression.gd`)

- Poziomy za korony (koszt rośnie o 30% na poziom), cechy rosną według pola `wzrost` bohatera.
- Umiejętności odblokowują się na progach (`prog`). Typy: `atak_mnoznik`, `co_n_atak`, `stat`, `aura`, `leczenie`,
  `status_przy_trafieniu`, `prowokacja`, `modyfikacja`, `ultimate`.
- Specjalizacja (poziom 10): jedna z dwóch gałęzi; każda to lista modyfikacji umiejętności, ataku lub cech.
- Ekwipunek: 6 slotów, przedmioty dodają cechy, obrażenia broni, pancerz, odporność na ogłuszenie.

## 6. Ekonomia

- **Korony**: z wrogów (z mnożnikiem), za ukończenie przygody. Wydawane na poziomy i bohaterów.
- **Favor**: +5% do wszystkich koron za pierwsze ukończenie każdej przygody na każdej trudności.
- **Klejnoty**: za bossów na Hard i Hardcore. Na razie tylko się zbierają (sklep — do zrobienia).
- **Łup z bossa**: losowy przedmiot do magazynu.
- **Hardcore**: limit czasu na planszę i zapis najlepszych czasów (przygoda, plansza, czas, skład).

## 7. Jak dodać zawartość bez programowania

| Co | Gdzie |
|---|---|
| nowy bohater | wpis w `data/heroes.json` + folder z grafiką |
| nowy wróg | wpis w `data/enemies.json` |
| nowa przygoda / plansza | `data/adventures.json` (liczba plansz = wielokrotność 5, boss na co piątej) |
| nowa trudność | wpis w `trudnosci` i `kolejnosc_trudnosci` |
| nowy poziom graficzny | wpis w `data/levels_art.json` + pliki według `SPECYFIKACJA_GRAFIKI_POZIOMOW.md` |
| inna muzyka | podmiana pliku w `assets/audio/music/` albo ścieżki w `data/music.json` |

## 8. Czego jeszcze nie ma

Sklep za klejnoty i skrzynie, ekran rankingu, osiągnięcia, role „Healer" jako osobny bohater, animacje gości w karczmie,
docelowe grafiki poziomów oraz sprite'y Psa Chaosu, Zwierzoczłeka i Championa Chaosu.
