# Champions of Carroburg

Taktyczny auto-battler / idle RPG w świecie Warhammer Fantasy. Godot 4.3, GDScript, ekran 1280×720 (poziomo, Android).

Stan: **szkielet mechaniki** — grywalny przepływ od prologu do pierwszych przygód, na grafikach tymczasowych.

## Co już działa

1. **Prolog, część 1 — karczma.** Nauka strzelania: Borubar sam biega po kufle rzucane przez barmana,
   gracz dotknięciem ekranu odpycha i spowalnia gości.
2. **Prolog, część 2 — ucieczka przez Hufduhof.** Borubar (bardzo twardy, bije rzadko i słabo) ucieka z beczką;
   gracz strzałami z nieba pomaga pokonać szczury, strzelców, maga, Psy Chaosu i Zwierzoczłeka. Na piątej planszy
   Champion Chaosu — tej walki nie da się wygrać i tak ma być.
3. **Koszary.** Lista bohaterów, formacja 2×5 (przeciąganie albo dotknięcia), karta bohatera z cechami WFRP,
   awanse, umiejętności, specjalizacje, ekwipunek, wybór przygody i trudności.
4. **Walka automatyczna** na kolejnych planszach, boss co piątą, trzy przygody, trudności Normal / Hard / Hardcore.
5. **Zapis gry** po każdej zmianie.

Bohaterowie: Ivo Eggert (DPS wręcz), Borubar (tank, złoto, leczenie), Modraszka (łuczniczka, spowolnienie, szybkość),
Ursa (magia ognia — omija pancerz).

## Jak uruchomić

- **Na telefonie:** zakładka *Actions* w repozytorium → ostatnie uruchomienie „Testy i APK" → *Artifacts* → `champions-apk`.
- **Na komputerze:** otwórz folder w Godot 4.3 i naciśnij F5.

## Gdzie co jest

| Folder | Zawartość |
|---|---|
| `data/` | **wszystkie liczby i treści**: bohaterowie, wrogowie, przygody, przedmioty, balans, muzyka, grafika poziomów |
| `scripts/core/` | mechanika bez grafiki: zasady WFRP, walka, formacja, progresja, minigra karczmy |
| `scripts/scenes/` | ekrany: menu, karczma, bitwa, Koszary |
| `scripts/view/` | rysowanie: tła warstwowe, postacie, efekty, wygląd interfejsu |
| `assets/` | grafika i muzyka (muzyka i postacie przeniesione z projektu Hufduhof) |
| `tests/` | testy automatyczne (GUT) |
| `docs/` | `SPECYFIKACJA_GRAFIKI_POZIOMOW.md`, `MECHANIKA.md` |

Testy: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`
