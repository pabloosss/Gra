# Żelazny Bór — Survivors 0.1

Grywalny prototyp inspirowany gatunkiem survivor / bullet heaven. Własny silnik 2D w JavaScript i Canvas; bez Godota, Unity, CDN i instalowania zależności przez gracza.

## Uruchomienie na Windows

1. Pobierz **tylko `survivors/index.html`** (na GitHubie otwórz plik i wybierz **Download raw file**).
2. Otwórz pobrany plik dwuklikiem w Chrome, Edge albo Firefox.
3. Kliknij **Rozpocznij wyprawę**.

Nie musisz pobierać całego repozytorium ani ponad 4 GB źródłowego audio. Wszystkie używane grafiki i trzy efekty dźwiękowe są osadzone w HTML. Gra działa offline. To wersja komputerowa, sterowana klawiaturą.

## Rozgrywka

- WASD lub strzałki: ruch; miecz i łuk atakują automatycznie.
- Niebieskie kryształy: doświadczenie; przy awansie wybierz ulepszenie myszką lub klawiszami 1–3.
- 11 rodzajów ulepszeń, w tym obrażenia, tempo ataku, dodatkowe strzały, przebicie, zdrowie, zbroja, regeneracja i orbitujące kule.
- Orkowie: podstawowy, szybki, ciężki, elitarny i boss. Warianty korzystają z tej samej grafiki z różną skalą i parametrami.
- Elita pojawia się co minutę i zostawia skrzynię z dodatkowym ulepszeniem oraz leczeniem.
- Po 10 minutach pojawia się wódz. Pokonaj go, żeby wygrać.
- Esc lub przycisk: pauza. Zmiana okna też zatrzymuje walkę.
- Przycisk dźwięku: wyciszenie. Rekordy są zapisywane lokalnie, jeśli przeglądarka na to pozwala.

## Zakres pierwszej wersji

Jedna nieskończona leśna arena. Podłoże i efekty kręgu miecza są rysowane kodem. Rośliny i skały są dekoracją, nie blokują ruchu. Bez muzyki, kampanii, sklepu między podejściami i natywnego EXE. Balans wymaga jeszcze dłuższych testów z graczami.

Silnik: krok symulacji 60 Hz, kamera, animacje atlasowe, siatka przestrzenna dla trafień, kolizje pocisków po odcinku, limity przeciwników/efektów/łupów i kolejka awansów.

## Źródła i przebudowanie

- `game.template.html`: czytelne źródło silnika, gry i UI.
- `assets.json`: wybrane assety osadzone jako data URI.
- `build.py`: `python build.py` generuje gotowy `index.html`; tylko standardowa biblioteka Pythona.
- `tests/logic.cjs`: `node tests/logic.cjs` sprawdza mechaniki bez przeglądarki.
- `tests/browser.cjs`: test w prawdziwej przeglądarce z Playwright, patrz komentarz w pliku.

Tryb `?test=1` udostępnia hooki testowe. W zwykłym uruchomieniu nie są wystawiane.

## Assety

Wykorzystano materiały już dodane przez właściciela repozytorium w commicie `2a6226b378cf99730ec9abbcddbe8acd566b08ed`:

- `Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc`: Soldier, Orc, strzała.
- `FreeEnvironment/FreeEnvironment/FreePack.png`: wybrane drzewa i skała.
- `coins-chests-etc-2-0.png`: kryształy, serce i skrzynia.
- `Free-Basic-Pixel-Art-UI-for-RPG/PNG/Icons.png`: ikony ulepszeń.
- `Helton Yan's Pixel Combat - Single Files`: Positive Click, Simple Whoosh i Deflected Hit (warianty 001).

Trzy efekty WAV przekonwertowano do mono 22,05 kHz i przycięto ciszę. Oryginały pozostają nietknięte. Interfejs jest własnym HTML/CSS.

Paczki graficzne i audio zachowują licencje autorów. Repozytorium nie zawiera kompletu ich warunków; przed publicznym wydaniem należy uzupełnić pochodzenie i wymagane credits. Ten plik nie nadaje nowej licencji cudzym assetom.
