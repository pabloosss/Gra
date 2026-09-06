# Szepczący Bór

Kompletna niewielka gra clicker/idle w **Godot 4.5.1**. Ścinaj drzewa, sprzedawaj drewno, ulepszaj narzędzia i doprowadź latarnię do poziomu III. Po zakończeniu opowieści możesz grać dalej.

## Aktualizacja: zatrudnianie drwali

W zakładce **Osada**, nad budynkami, znajduje się karta **Zatrudnij drwali**. Chata nadal zapewnia swoją podstawową ekipę. Dodatkowi drwale kosztują jednorazowo monety: pierwszy 180, następny 279, kolejne ceny rosną ×1,55 (zaokrąglenie w górę). Każdy dodaje bazowo 0,75 drewna/s i korzysta z tartaku, uzysku, karczmy, latarni oraz aktywnego szeptu. Nie pobiera pensji.

Chata I/II/III zapewnia 3/8/16 dodatkowych miejsc. Licznik pokazuje całą ekipę i zajęte miejsca dodatkowe. Na planszy widocznych jest do ośmiu drwali. Nowi pracownicy zapisują się i pracują offline. Stare zapisy działają bez resetowania — zaczynają z zerem dodatkowych drwali i zachowują podstawową ekipę.

W tej aktualizacji: **16/16 testów zatrudniania**, **39/39 testów dotychczasowych reguł**, test przycisku zatrudniania zdarzeniami myszy oraz układu 960×680 w trybie headless. Eksport Windows wykonany; EXE nie uruchamiano na Windows. Poniższe wyniki wizualne i balans dotyczą pierwotnej wersji bez dodatkowych zakupów drwali; zatrudnianie może skrócić rozgrywkę.

Gotowa aktualna wersja Windows została dołączona do rozmowy jako `Szepczacy_Bor_Windows.zip`. Wypakuj i otwórz `SzepczacyBor.exe`. Pełny projekt jest w tym folderze (`project.godot`). Starszy pakiet wieloplatformowy opisany poniżej nie zawiera tej aktualizacji.

## Uruchomienie pierwotnego pakietu gry

1. Wypakuj całe archiwum ZIP.
2. Windows 10/11 (64-bit): otwórz **GRA-WINDOWS/SzepczacyBor.exe**. Nie potrzebujesz Godota, Pythona, instalatora ani konta. Pierwsze uruchomienie może potrwać kilka sekund.
3. Linux (64-bit): uruchom **GRA-LINUX/SzepczacyBor.x86_64**. Jeśli rozpakowywacz usunął uprawnienie wykonywania, nadaj je w właściwościach pliku albo poleceniem `chmod +x SzepczacyBor.x86_64`.
4. Wersja przeglądarkowa jest w **GRA-WEB**. Wymaga serwowania przez HTTP(S), nie otwierania `index.html` jako pliku. Najwygodniejszy jest podgląd udostępniony z grą. Do lokalnego uruchomienia opcjonalnie użyj `python -m http.server 8000` w folderze GRA-WEB i otwórz `http://localhost:8000`.

Zapis Windows, Linux i przeglądarki jest osobny. Przenoszenie ZIP nie przenosi zapisu.

## Sterowanie

- Kliknięcie drzewa: pojedynczy zamach.
- Spacja: pojedynczy zamach; przytrzymana — kolejne zamachy.
- Kliknięcie parceli/budynku: wybór odpowiedniej karty w panelu Osada.
- Sprzedaj połowę / Sprzedaj wszystko: zamiana całych sztuk drewna na monety; ułamki zostają.
- Narzędzia: siła, krytyk, uzysk. Osada: budynki i ich ulepszenia. Kronika: statystyki i odkryte opisy.
- Esc: ustawienia / zamknięcie okna. F11: pełny ekran.
- Muzyka i efekty mają osobne suwaki i wyciszenie; ruszają dopiero po pierwszej interakcji.

## Jak zacząć

Pierwsze ostrze kosztuje 55 monet. Chata drwala kosztuje 100 drewna i 160 monet: część drewna sprzedaj, resztę zachowaj. Chata zatrudnia drwali i daje stałą produkcję; tartak odblokowuje prastary las. Kuźnia zwiększa dostępny limit ulepszeń siekiery. Targ podnosi ceny, karczma wspiera drwali, latarnia otwiera Spaczony Bór.

Każdy z sześciu budynków ma trzy osobne grafiki poziomów. Opis przy zakupie pokazuje **łączny bonus docelowego poziomu**, a nie bonus dodawany jeszcze raz do poprzedniego. Bonusy różnych źródeł mnożą się.

Szept boru pojawia się co kilka minut. Przyjęty daje +50% drewna na 35 sekund. Pominięcie nie ma konsekwencji.

## Zapis

Automatycznie co 10 sekund, po zakupie/sprzedaży i przy utracie fokusu/zamykaniu. Plik JSON ma kopię zapasową; nowe dane są najpierw zapisywane do pliku tymczasowego.

- Windows: `%APPDATA%/Godot/app_userdata/Szepczący Bór/bor_save_v1.json`.
- Linux: `~/.local/share/godot/app_userdata/Szepczący Bór/bor_save_v1.json`.
- Web: localStorage, klucz `szepczacy-bor-v1`, kopia `.bak`; dodatkowo pliki `user://` w pamięci przeglądarki. Wyczyszczenie danych witryny usuwa zapis.

Przy powrocie naliczana jest produkcja drwali za maksymalnie 8 godzin. Chwilowy szept nie wzmacnia produkcji offline. Gra pokazuje podsumowanie. Reset w ustawieniach wymaga dodatkowego potwierdzenia i zachowuje ustawienia dźwięku.

## Projekt Godot

Folder **PROJEKT-GODOT** jest pełnym projektem, niezależnym od eksportów. W Godot wybierz Importuj, wskaż `project.godot`, a następnie naciśnij F6/F5. Projekt przygotowano i sprawdzono w 4.5.1; nie wymaga wtyczek ani zewnętrznych pakietów. Wszystkie PNG, fonty i WAV są dołączone. Eksporty Windows/Linux/Web są zdefiniowane w `export_presets.cfg`.

- `scripts/state.gd`: ekonomia, wymagania, wydarzenia, zapis i offline.
- `scripts/main.gd`: polski interfejs, obsługa wejścia, podsumowania i ustawienia.
- `scripts/world.gd`: świat, budynki, animacje, cząsteczki i reakcje na ścinanie.
- `scripts/sound.gd`: muzyka, głosy efektów i niezależne głośności.
- `scripts/pixel_icon.gd`: ikony interfejsu.
- `assets/`: wszystkie materiały, w tym źródłowy atlas drzew.
- `tools_generate_assets.py`: źródło proceduralnych budynków, drwala, zapasowych drzew i syntezy audio. Opcjonalne; wymaga Pillow i NumPy. Nie zmienia wygenerowanego tła ani finalnych drzew `tree_painted_*`.

Świat renderuje się w rozdzielczości 960×480 i jest skalowany filtrem najbliższego sąsiada. Interfejs zachowuje czytelne rozmiary czcionki i dostosowuje się do okna od 960×680.

## Rzeczywista weryfikacja

**39/39 kontroli reguł w Godot:** obrażenia, krytyk, odnowienie ciosu, jednorazowa nagroda, odrastanie, obie sprzedaże, ułamki, koszty, brak ujemnych zasobów, limity siekiery, wymagania, wszystkie 18 poziomów budynków, bonusy, wydarzenia, zapis/wczytanie, odzyskanie kopii, błędne dane, reset, 8 godzin offline i brak podwójnego naliczania.

**24/24 kontrole sceny z działającym rendererem Godot/OpenGL pod Linux:** 16 kontroli zachowania, w tym wejście klawiaturą i zdarzeniami myszy, oraz 8 poprawnie zapisanych zrzutów. Sprawdzono ścinanie, sprzedaż, zakup chaty, wzrost drewna, ulepszenie siekiery, wydarzenie, rozbudowaną osadę, blokadę resetu przed potwierdzeniem, zapis/wczytanie z offline i zakończenie. Zrzuty przejrzano w rozmiarach 1440×900 i 960×680. Testy używają własnego zapisu, nie zapisu gracza.

**Symulacja balansu w tych samych regułach:** przy aktywnych 2,5 kliknięcia/s pierwszy zakup około 38 s, pierwsza chata około 150 s, latarnia III około 39 min. Przy ciągłej Spacji około 30 min. Wolniejsze granie i inne zakupy wydłużają rozgrywkę; nie jest to pomiar 39 minut ręcznej gry. Symulacja aktywnie przyjmuje szepty i rozsądnie odkłada drewno.

Eksporty Windows, Linux i Web ukończyły się bez błędów. Zweryfikowano format PE64 pliku Windows. **Plik EXE nie został uruchomiony na Windows w tym środowisku.** Interakcje sprawdzono w natywnym Godot pod Linux; podglądu Web nie przetestowano klikaniem w przeglądarce. Sprawdzono kompletność jego zasobów, składnię JavaScript i zgodność odtworzonego pliku WebAssembly.

Odtworzenie kontroli: `godot --headless --path . --script res://tests/economy_test.gd`, analogicznie `balance_sim.gd`; scenariusz wizualny `godot --path . --script res://tests/ui_test.gd -- --test-ui` wymaga wyświetlacza. Testy wizualne używają przygotowanych zasobów na potrzeby sprawdzenia dalszych etapów; normalna gra zaczyna się od zera.

## Materiały i licencje

Tło i finalne drzewa powstały z ImageGen. Budynki, postać, ikony i animacje są autorskimi materiałami przygotowanymi dla tej gry; dźwięki i 48-sekundowe pętle muzyki i lasu są syntetyzowane przez dołączony skrypt. Nie ma pobierania zasobów podczas rozgrywki ani płatnych usług.

Dołączono licencje Godot i fontów DejaVu w folderze LICENSES. Informacje o narzędziu: https://godotengine.org/download/archive/4.5.1-stable/ i https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html.
