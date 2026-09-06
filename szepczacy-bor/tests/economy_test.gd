extends SceneTree
const Rules = preload("res://scripts/state.gd")
var checks = 0
var failed = 0
var s

func _initialize():
	call_deferred("run")

func check(ok: bool,description: String):
	checks+=1
	if not ok:
		failed+=1
		push_error("FAIL: "+description)
	else: print("PASS: "+description)

func fresh():
	if is_instance_valid(s): s.free()
	s=Rules.new()
	root.add_child(s)
	s.save_path="user://test_economy_only.json"
	s.rng.seed=23

func run():
	fresh()
	check(not s.buy_upgrade(0) and not s.build(0) and s.sell()==0,"Pusty magazyn blokuje zakupy i sprzedaż")
	var c=s.chop(1.0)
	check(c.damage==2 and s.tree_hp==16,"Zwykły cios odejmuje wytrzymałość")
	check(s.chop().is_empty(),"Odnowienie ciosu zapobiega wielokrotnemu naliczeniu")
	s.advance(.2)
	c=s.chop(0.0)
	check(c.critical and c.damage==5 and s.tree_hp==11,"Krytyk zadaje 2,5× obrażeń")
	while s.respawn==0:
		s.advance(.2)
		c=s.chop(1.0)
	check(s.wood==6 and s.total_trees==1 and c.felled,"Ścięcie daje jedną nagrodę i zwiększa licznik")
	check(s.chop().is_empty() and s.wood==6,"Animacja upadku nie duplikuje nagrody")
	s.advance(.8)
	check(s.tree_hp==18 and s.respawn==0,"Nowe drzewo odrasta z pełnym zdrowiem")
	s.wood=11.75
	check(s.sell(true)==5 and s.wood==6.75 and s.coins==5,"Połowa drewna: zaokrąglenie i zachowanie ułamków")
	check(s.sell()==6 and s.wood==.75 and s.coins==11,"Całe drewno: zachowanie ułamków i poprawne monety")
	s.coins=55
	check(s.buy_upgrade(0) and s.damage()==4 and s.coins==0,"Pierwsze ulepszenie: dokładny koszt i nowa siła")
	s.wood=100;s.coins=160
	check(s.build(0) and s.wood==0 and s.coins==0,"Pierwszy budynek odejmuje oba koszty")
	s.advance(10)
	check(is_equal_approx(s.wood,7.5),"Chata produkuje 0,75 drewna/s")
	s.wood=1e6;s.coins=1e6
	check(not s.build(5),"Latarnia nie omija wymagań pomimo posiadania zasobów")
	check(s.build(1) and s.tree_unlocked(1),"Tartak odblokowuje prastare drzewa")
	check(is_equal_approx(s.passive_rate(),.9375),"Bonus tartaku obejmuje drwali")
	check(s.select_tree(1) and s.tree_hp==88 and s.tree_reward()==52.5,"Nowy las: zdrowie i nagroda z bonusem")
	s.axe=4
	var before=s.coins
	check(not s.buy_upgrade(0) and s.coins==before,"Limit siekiery przed kuźnią nie pobiera monet")
	check(s.build(2) and s.axe_cap()==8 and s.buy_upgrade(0),"Kuźnia odblokowuje mocniejszą siekierę")
	s.build(3)
	s.wood=10
	check(is_equal_approx(s.sell(),13),"Targ poprawnie mnoży cenę sprzedaży")
	s.wood=1e6;s.coins=1e6
	# Topological build order must reach every level without a dependency deadlock.
	var loops=0
	while not s.completed and loops<20:
		for i in range(6): s.build(i)
		loops+=1
	check(s.buildings==[3,3,3,3,3,3] and s.completed,"Wszystkie 18 poziomów da się odblokować bez zablokowania zależności")
	before=s.wood
	check(not s.build(5) and s.wood==before,"Budynek III nie może zostać kupiony ponownie")
	check(s.tree_unlocked(2) and s.select_tree(2) and s.tree_hp==420,"Latarnia otwiera Spaczony Bór")
	check(is_equal_approx(s.passive_rate(),6*3.2*1.7*2.2),"Łączenie bonusów chaty, karczmy, latarni i tartaku")
	s.yield_level=3
	check(is_equal_approx(s.passive_rate(),6*3.2*1.7*2.2*1.36),"Uzysk mnoży końcową produkcję drwali")
	s.wood=0;s.boost_left=2
	var rate=s.passive_rate(false)
	s.advance(10)
	check(is_equal_approx(s.wood,rate*11) and s.boost_left==0,"Wygasający bonus nalicza tylko aktywne 2 sekundy")
	s.event_window=0
	check(not s.take_whisper(),"Nieaktywny szept nie daje bonusu")
	s.event_window=20
	check(s.take_whisper() and s.boost_left==35 and s.event_window==0,"Szept jest jednorazowym opcjonalnym bonusem")
	s.wood=0;s.last_seen=100000
	var report=s.grant_offline(100000+90000)
	check(report.seconds==28800 and is_equal_approx(s.wood,rate*28800),"Offline ograniczone do 8 godzin bez bonusu szeptu")
	before=s.wood
	s.grant_offline(100000+90000)
	check(s.wood==before,"Powtórne rozliczenie tego samego momentu nic nie dodaje")
	s.grant_offline(1000)
	check(s.wood==before,"Cofnięcie zegara nie odejmuje zasobów")
	var d=s.snapshot(200000)
	check(s.save_game(200000),"Zapis JSON na dysk")
	fresh()
	check(s.load_game(200060),"Odczyt pliku w nowej instancji reguł")
	check(s.buildings==[3,3,3,3,3,3] and s.axe==d.axe and is_equal_approx(s.wood,d.wood+rate*60),"Wczytanie odtwarza postęp i dokładnie minutę offline")
	before=s.wood
	check(s.load_game(200060) and is_equal_approx(s.wood,before),"Ponowne otwarcie nie duplikuje produkcji offline")
	s.save_game(200060)
	var file=FileAccess.open(s.save_path,FileAccess.WRITE)
	file.store_string("{damaged")
	file.close()
	check(s.load_game(200060) and not s.load_warning.is_empty(),"Uszkodzony zapis jest odzyskiwany z kopii")
	var bad=s.snapshot()
	bad.wood=-99;bad.coins="xyz";bad.axe=999;bad.crit=-5
	check(s.restore(bad) and s.wood==0 and s.coins==0 and s.axe==16 and s.crit==0,"Błędne wartości są ograniczane bez ujemnych zasobów")
	bad.version=999
	check(not s.restore(bad),"Nieznana wersja zapisu jest odrzucana")
	bad.version=1;bad.buildings=[null,0,0,0,0,0]
	check(not s.restore(bad),"Uszkodzona tablica budynków nie mutuje stanu")
	s.reset_game()
	check(s.buildings==[0,0,0,0,0,0] and s.wood==0 and s.coins==0 and s.total_trees==0,"Reset usuwa cały postęp")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(s.save_path+suffix): DirAccess.remove_absolute(s.save_path+suffix)
	s.free()
	print("RESULT: %d/%d passed"%[checks-failed,checks])
	quit(0 if failed==0 else 1)
