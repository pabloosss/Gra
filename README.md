# Szepczący Bór — nowa gra idle

Aktualny clicker Godot jest w folderze [szepczacy-bor](szepczacy-bor).

Gotowy ZIP Windows został dołączony do rozmowy z aktualizacją. Wypakuj go i uruchom `SzepczacyBor.exe`. Godot nie jest potrzebny do grania. Repozytorium zawiera kompletny projekt i ustawienia eksportu Windows.

Do edycji w Godot 4.5.1 zaimportuj `szepczacy-bor/project.godot`. Aktualizacja dodaje kupowanie dodatkowych drwali za monety, miejsca w chacie, zapis i produkcję offline.

Poniżej dokumentacja wcześniejszego projektu RPG, który pozostaje w katalogu głównym.

---

# Gra Pixel DnD — prototyp 0.1

Pierwszy grywalny prototyp narracyjnego pixel-RPG inspirowanego sesją RPG/DnD.

## Co już działa

- pixelowa lokacja karczmy na wzgórzu,
- animowany deszcz,
- losowe błyski pioruna,
- migotanie okien i lampy,
- dialog narratora i NPC,
- wybory gracza,
- testy umiejętności oparte o D20,
- animowany ekran rzutu kością,
- prosty towarzysz **Mira** z relacją i pamięcią wydarzeń,
- kilka rozgałęzień pierwszej sceny.

## Wymagania

Projekt jest przygotowany pod **Godot 4.7.2 Standard** i GDScript.

## Jak uruchomić

1. Pobierz lub sklonuj repozytorium.
2. Otwórz Godot 4.7.2.
3. Wybierz `Import` i wskaż plik `project.godot`.
4. Otwórz projekt.
5. Naciśnij **F6/F5** i uruchom scenę.

## Sterowanie

Cały obecny prototyp obsługuje się myszką — wybierasz odpowiedzi w panelu na dole ekranu.

## Następny etap

- prawdziwy spritesheet karczmy i warstwy animacji,
- wnętrze karczmy jako druga scena,
- tworzenie postaci,
- karta postaci i ekwipunek,
- system questów,
- walka tekstowo-turowa,
- zapis/odczyt gry,
- właściwy moduł lokalnego AI dla towarzysza,
- dźwięki burzy, kostki i narracja.
