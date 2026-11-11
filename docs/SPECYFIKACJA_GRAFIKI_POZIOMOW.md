# Specyfikacja grafiki poziomów — Champions of Carroburg

Dokument mówi, **co dokładnie narysować, w jakim rozmiarze i pod jaką nazwą zapisać**, żeby gra sama podmieniła
tymczasowe placeholdery. Wszystkie liczby poniżej są wzięte z kodu i danych gry (`data/levels_art.json`,
`data/adventures.json`, `data/balance.json`) — jeśli grafika trzyma się tej specyfikacji, nie trzeba zmieniać ani linijki kodu.

Zakres: **Poziom 1 — prolog w karczmie** i **Poziom 2 — wieś Hufduhof (ucieczka Borubara)**.
Na końcu krótka tabela dla kolejnych poziomów, które korzystają z tego samego schematu warstw.

Szablony z naniesionymi strefami (do podłożenia jako warstwa pomocnicza w programie graficznym):

- `docs/szablony/szablon_karczma.png`
- `docs/szablony/szablon_hufduhof.png`

---

## 1. Zasady wspólne

| Zasada | Wartość |
|---|---|
| Ekran gry | **1280×720 px**, poziomo. 1 piksel obrazka = 1 piksel gry (bez skalowania) |
| Format | PNG, 32-bit z kanałem alfa |
| Przezroczystość | tylko 0 albo 255 — bez półprzezroczystych krawędzi i wygładzania |
| Styl | pixel-art jak dotychczasowe postacie (Ivo, Ursa, Modraszka, Borubar): ciemny kontur 1 px, 3–4 tony na materiał, bez gradientów i rozmyć |
| Paleta | ta sama co w Hufduhofie (256 kolorów): brudne brązy, ciemne szarości, wyblakła zieleń, przygaszona czerwień i czerń Carroburga |
| **Rzut** | **widok z boku** (jak w Idle Champions), a nie izometria z Hufduhofu. Podłoga/droga jest lekko „położona" w stronę widza: im niżej na ekranie, tym bliżej |
| Kierunek gry | bohaterowie stoją po lewej i patrzą **w prawo**; wrogowie wchodzą z prawej i patrzą **w lewo** |
| Światło | z lewej-góry |
| Cienie postaci | **nie rysuj** cieni pod postaciami na tle — postacie się ruszają |
| Napisy | żadnych napisów „wtopionych" w tło w strefie interfejsu (góra ekranu) |

**Kotwica rekwizytów i postaci:** środek dolnej krawędzi obrazka = punkt, w którym postać stoi (stopy).
Postacie animowane mają własny punkt stóp w pliku `sprite.json` (patrz rozdział 4).

**Jak gra szuka plików:** każdy poziom ma folder `assets/levels/<poziom>/`. Jeśli pliku warstwy nie ma — gra rysuje
w jego miejscu kolorowy placeholder. Wystarczy wrzucić plik o właściwej nazwie; można dostarczać warstwy pojedynczo.

---

## 2. Poziom 1 — karczma „Pod Złotym Kuflem" (prolog, nauka strzelania)

**Co się dzieje:** barman stoi za ladą po prawej i rzuca kufle łukiem w głąb sali. Borubar sam biegnie po podłodze
pod miejsce upadku (żółty owal na podłodze). Goście wstają z miejsc i też biegną po kufel. Gracz dotyka ekranu —
piorun z nieba odpycha i spowalnia gości. Scena **nie przewija się**: jeden nieruchomy kadr.

Folder: `assets/levels/karczma/`

### 2.1. Warstwy

| Plik | Rozmiar | Przezroczystość | Co zawiera |
|---|---|---|---|
| `tlo.png` | **1280×720** | brak (pełne krycie) | cała sala: ściana tylna i podłoga. Rysowana **za** postaciami |
| `przod.png` (opcjonalna) | **1280×720** | tak | elementy **przed** postaciami: belka stropowa, wisząca lampa, róg stołu na samym dole. Nie może nic zasłaniać w pasie gry |
| `props/lada.png` | **250×148** | tak | lada szynkwasu, rysowana **przed** barmanem (zasłania go od pasa w dół). Gra ustawia ją tak, że **prawy dolny róg obrazka = punkt (1280, 640)** — przy innym rozmiarze też zadziała |

### 2.2. Strefy na `tlo.png` (współrzędne ekranu)

| Strefa | Obszar | Co tam rysować / czego unikać |
|---|---|---|
| Strefa napisów | y 0–140, cała szerokość | licznik kufli, podpowiedź, przycisk „Pomiń". Ciemne belki stropu, okopcony sufit — **spokojnie i ciemno**, bez jasnych detali |
| Ściana tylna | y 0–470 | mur pruski / deski, okna z okiennicami, kominek, półki z kuflami, trofea, tarcza z herbem Carroburga, świece |
| Tor lotu kufli | łuk od lady do sali, szczyt ok. y 120–200 | kufel ma 24 px — tło za nim nie może być pstrokate; unikaj drobnych jasnych elementów między y 140 a 440 w pasie x 150–1100 |
| Linia podłogi | **y = 470** | tu ściana styka się z podłogą (listwa, cień) |
| Podłoga | y 470–720 | deski biegnące w głąb, plamy piwa, słoma. Bez mebli stojących w pasie gry |
| **Pas gry** | **x 150–1000, y 440–612** | tu biegają Borubar i goście (stopy na **y = 600**, głowy sięgają ok. y 455). Tło w tym pasie ma być mało kontrastowe |
| Miejsca gości | x = **220, 420, 760, 930** (stopy y = 600) | tu goście stoją, gdy czekają. **Za** nimi (powyżej y 560) dorysuj ławy i stoły przy ścianie — tak, żeby wyglądało, że od nich wstali |
| Borubar — start | x = 560 | środek sali, wolna podłoga |
| Strefa lady | x 1030–1280, y 440–640 | na `tlo.png` narysuj to, co jest **za** ladą: regał z beczkami, kurki, półka z butelkami. Samą ladę rysujesz osobno (`props/lada.png`) |
| Barman | x = 1140, stopy y = 540 | stoi za ladą; widać go od pasa w górę |
| Dół ekranu | y 612–720 | bliższa część podłogi; dobre miejsce na rozlane piwo, kości, śpiącego psa (płasko!) |

### 2.3. Rekwizyty i postacie karczmy — `assets/levels/karczma/props/`

W repozytorium są już wersje tymczasowe z Hufduhofu (rzut izometryczny) — do zastąpienia wersjami **z boku**.

| Plik | Rozmiar (obecny → zalecany) | Kotwica | Opis |
|---|---|---|---|
| `barman.png` | 84×100 → do 100×120 | dolny środek | karczmarz zwrócony **w lewo / przodem do sali**, ręka uniesiona do rzutu. Dolna połowa będzie zasłonięta ladą |
| `klient_1.png` … `klient_4.png` | 54×92 → do 70×110 | dolny środek | czterech różnych gości, każdy zwrócony **w prawo** (gra sama odbija obrazek, gdy idą w lewo). Propozycje: chłop, najemnik, krasnolud, flisak |
| `kufel.png` | 24×28 | dolny środek | kufel z pianą; w locie gra go obraca |
| `kufel_rozbity.png` | ok. 40×20 | dolny środek | skorupy i plama piwa na podłodze (pojawia się, gdy nikt nie złapie) |
| `lada.png` | 250×148 | prawy dolny róg = (1280, 640) | patrz 2.1 |

Borubar w karczmie to ta sama postać co w walce — patrz rozdział 4 (`assets/characters/borubar/`).

Na razie goście i barman to **pojedyncze obrazki** (gra dodaje im podskok i odbicie lustrzane). Animację chodu można
dodać później bez zmiany tej specyfikacji.

---

## 3. Poziom 2 — wieś Hufduhof (ucieczka Borubara)

**Co się dzieje:** Borubar z beczką na plecach ucieka przez płonącą wieś w prawo. Stoi w lewej części ekranu,
a **tło przesuwa się w lewo** (70 px/s w trakcie walki, 340 px/s między planszami). Wrogowie wchodzą z prawej
krawędzi. Pięć plansz; na ostatniej Champion Chaosu. Cały prolog to ok. 2–3 minuty, więc droga przewinie się
kilka razy — warstwy muszą się **bezszwowo zapętlać w poziomie**.

Folder: `assets/levels/hufduhof/`

### 3.1. Warstwy (od najdalszej)

| Plik | Rozmiar | Paralaksa | Przezroczystość | Co zawiera | Gdzie w pionie |
|---|---|---|---|---|---|
| `niebo.png` | **1280×720** | 0 (stoi) | brak | niebo o zmierzchu, łuna pożaru, słupy dymu | widać tylko y 0–300; niżej wypełnij jednolitym kolorem |
| `daleko.png` | **2560×720** | 0,15 | tak | linia Drakwaldu, wzgórza, daleki wiatrak, dymy | treść w y 150–300; dół sylwetek dociągnij do y 320 (żeby nie było szpary) |
| `wies.png` | **2560×720** | 0,5 | tak | domy Hufduhofu, karczma z wyłamanymi drzwiami, płonące strzechy, płoty, studnia, kapliczka | treść w y 60–330; podstawy budynków na y 300–330 |
| `droga.png` | **2560×720** | 1,0 | tak, **powyżej y 290**; od **y 300 w dół pełne krycie** | błotnista droga przez wieś — podłoże, po którym chodzą postacie | y 300–720 |
| `przod.png` (opcjonalna) | **2560×720** | 1,4 | tak | pierwszy plan: kępy trawy, kamienie, połamany płot, porzucone wiadro | tylko **y 640–720** |

Warstwy 2560 px mają się zapętlać: lewa i prawa krawędź muszą do siebie pasować (bez budynku przeciętego na łączeniu).
Szerokość może być inna (minimum 1280) — gra powtarza obrazek co jego szerokość.

Charakterystyczne obiekty (karczma „Pod Złotym Kuflem", kapliczka) narysuj **raz** na 2560 px — na warstwie `wies.png`
wrócą na ekran dopiero po ok. 70 sekundach walki.

### 3.2. Strefy (współrzędne ekranu)

| Strefa | Obszar | Uwagi |
|---|---|---|
| Strefa napisów | y 0–110 | nazwa przygody, cel, korony (lewy górny róg, x 0–450), pasek życia bossa (x 390–890, y 8–62), przyciski (x 960–1270, y 12–56). Niebo w tym miejscu ciemne i spokojne |
| Linia horyzontu | **y = 300** | tu zaczyna się droga |
| **Pas walki** | **y 320–640**, cała szerokość | pięć torów, po których chodzą postacie: stopy na **y = 340, 410, 480, 550, 620**. Na drodze w tym pasie tylko **płaskie** detale (koleiny, kałuże, kamyki, rozsypana słoma, deski). Nic, co stoi pionowo — postacie by przez to „przechodziły" |
| Pola drużyny | tylny rząd x = 290 / 336, przedni rząd x = 430 / 476 | pozycje bohaterów (w prologu tylko Borubar: x = 430, y = 480). Nie ma potrzeby niczego tu rysować — to informacja, gdzie stoją postacie |
| Pozycje strzelców | x = 930 (Szczur Strzelec), x = 990 (Szczur Mag) | wrogowie dystansowi zatrzymują się w tych liniach |
| Wejście wrogów | prawa krawędź, x > 1280 | wrogowie wchodzą zza ekranu |
| Pierwszy plan | y 640–720 | elementy z `przod.png` zasłaniają stopy postaci z najniższego toru — to celowe. W lewym dolnym rogu (x 16–760, y 650–706) są przyciski Ultimate |

### 3.3. Nastrój i treść

- Zmierzch, pożar, panika: część strzech płonie (sam płomień — bez poświaty i rozmycia), w oknach pusto, na drodze porzucony dobytek.
- Ta sama wieś co w Hufduhofie: mur pruski, strzechy i gonty, kuźnia, kapliczki Ulryka i Rhyi, karczma z szyldem złotego kufla.
- Kolory przygaszone; najjaśniejsze punkty to ogień i łuna na niebie — dzięki temu postacie i żółte liczby obrażeń pozostają czytelne.
- Droga wyraźnie ciemniejsza i mniej kontrastowa niż postacie (czerwień Borubara, brązy szczurów).

---

## 4. Postacie potrzebne na obu poziomach

Format taki sam jak w Hufduhofie, ale wystarczy **jeden kierunek**: bohaterowie `east`, wrogowie `west`.

```
assets/characters/<bohater>/<animacja>/east/0.png, 1.png, 2.png ...
assets/enemies/<wróg>/<animacja>/west/0.png, 1.png, 2.png ...
assets/.../sprite.json      { "canvas": [szer, wys], "pivot": [x_stóp, y_stóp], "fps": { "idle": 2, "walk": 8, "attack": 0, "hurt": 1, "death": 6 } }
```

Wszystkie klatki jednej postaci mają ten sam rozmiar płótna (`canvas`), a `pivot` to punkt stóp na tym płótnie.
`fps = 0` przy `attack` oznacza: klatki rozłożone na czas ciosu (0,4 s), ostatnia = trafienie.
Animacje: `idle`, `walk`, `attack`, `hurt`, `death`. Obowiązkowa jest tylko `idle` — brakujące animacje gra zastępuje.

| Postać | Folder | Wysokość postaci | Płótno (propozycja) | Stan obecny |
|---|---|---|---|---|
| Borubar | `assets/characters/borubar` | ok. 105 px + beczka | 128×160 | 1 poza (z Hufduhofu). Potrzebne: `idle` 2 kl., `walk` 6–8 kl. (bieg z beczką na plecach), `attack` 3 kl. (cios beczką), `hurt`, `death` |
| Ivo, Modraszka | `assets/characters/ivo`, `.../modraszka` | ok. 120 px | bez zmian | są animacje z Hufduhofu (kierunek east) |
| Ursa | `assets/characters/ursa` | ok. 120 px | 96×128 | tylko `idle` |
| Szczur | `assets/enemies/skaven_spear` | ok. 60 px | 96×112 | jest komplet (west) |
| Szczur Strzelec | `assets/enemies/skaven_slinger` | ok. 60 px | 96×112 | jest komplet |
| Szczur Mag | `assets/enemies/skaven_warlock` | ok. 65 px | 96×112 | jest komplet |
| Pies Chaosu | `assets/enemies/pies_chaosu` | ok. 46 px, długość ok. 72 px | 128×96 | **brak** — placeholder |
| Zwierzoczłek | `assets/enemies/zwierzoczlek` | ok. 124 px | 160×176 | **brak** — placeholder |
| Champion Chaosu | `assets/enemies/czempion_chaosu` | ok. 170 px | 224×224 | **brak** — placeholder |

Wysokość postaci jest też wpisana w danych (`placeholder.h` w `data/heroes.json` i `data/enemies.json`) — od niej
zależy położenie paska życia i pole trafienia strzałem. Jeśli narysujesz postać wyraźnie wyższą lub niższą, podaj
mi nową wysokość, poprawię jedną liczbę.

Pociski (`assets/fx/`): `arrow.png` 30×7, `fireball.png` 24×24, `magic_bolt.png`, `stone.png` — są, rysowane zwrócone **w prawo**.

---

## 5. Kolejne poziomy (ten sam schemat warstw)

| Poziom | Folder | Warstwy za postaciami (paralaksa) | Pierwszy plan |
|---|---|---|---|
| Piwnice Carroburga | `assets/levels/piwnice` | `tlo.png` (0), `sciana.png` (0,6), `podloga.png` (1,0) | `przod.png` (1,4) |
| Trakt do Hufduhofu | `assets/levels/trakt` | `niebo.png` (0), `daleko.png` (0,15), `las.png` (0,5), `droga.png` (1,0) | `przod.png` (1,4) |
| Odbicie Hufduhofu | `assets/levels/hufduhof` | te same pliki co w prologu | — |

Rozmiary i strefy jak w rozdziale 3 (horyzont y = 300, pas walki y 320–640).
Nowy poziom dodaje się jednym wpisem w `data/levels_art.json`.

---

## 6. Lista kontrolna przed wrzuceniem pliku

1. Nazwa i folder dokładnie jak w tabelach (małe litery, bez polskich znaków).
2. Rozmiar zgodny z tabelą; warstwy przewijane zapętlają się w poziomie.
3. Tło naprawdę przezroczyste tam, gdzie ma być (nie biała ani „szachownicowa" plama).
4. Pas gry / pas walki wolny od stojących i kontrastowych elementów.
5. Strefa napisów u góry ciemna i spokojna.
6. Po wrzuceniu do repozytorium nic więcej nie trzeba robić — przy następnym zbudowaniu gry placeholder zniknie.
