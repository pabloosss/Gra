extends SceneTree
var failures = 0
var checks = 0
func check(ok: bool, title: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + title)
func _initialize(): call_deferred("run")
func run():
	var s=root.get_node("State")
	s.coins=10000
	check(not s.hire_worker() and s.coins==10000,"Zatrudnianie bez chaty zablokowane")
	s.buildings[0]=1;s.coins=179
	check(not s.hire_worker() and s.coins==179,"Brak monet nie zmienia stanu")
	s.coins=180
	check(s.hire_worker() and s.coins==0 and s.hired_workers==1,"Dokładny koszt 180 monet")
	check(is_equal_approx(s.passive_rate(),1.5),"Nowy drwal zwiększa produkcję o 0,75/s")
	check(s.worker_cost()==279,"Cena kolejnego drwala rośnie")
	s.coins=100000
	s.hire_worker();s.hire_worker()
	var before=s.coins
	check(not s.hire_worker() and s.coins==before and s.worker_count()==4,"Limit trzech dodatkowych w chacie I")
	s.buildings[0]=2
	check(s.worker_capacity()==8 and s.hire_worker(),"Chata II daje osiem miejsc")
	s.buildings=[3,3,3,3,3,3];s.yield_level=2
	var base=s.passive_rate(false)
	var bonus=s.worker_bonus()
	s.hire_worker()
	check(is_equal_approx(s.passive_rate(false)-base,bonus),"Nowi drwale korzystają z wszystkich bonusów osady")
	var wood=s.wood
	s.advance(10)
	check(is_equal_approx(s.wood-wood,s.passive_rate(false)*10),"Produkcja zatrudnionych naliczana w czasie")
	s.save_path="user://workers_test_only.json"
	check(s.save_game(1000),"Zapis zatrudnionych na dysk")
	var count=s.hired_workers
	var rate=s.passive_rate(false)
	s.hired_workers=0
	check(s.load_game(1060) and s.hired_workers==count,"Wczytanie zachowuje zatrudnionych")
	check(is_equal_approx(s.offline_report.wood,rate*60),"Zatrudnieni pracują offline")
	var old=s.snapshot();old.erase("hired_workers")
	check(s.restore(old) and s.hired_workers==0 and s.worker_count()==7,"Stary zapis zachowuje podstawową ekipę")
	old.hired_workers=999
	check(s.restore(old) and s.hired_workers==16,"Uszkodzony zapis nie przekracza limitu")
	old.hired_workers=-3
	check(s.restore(old) and s.hired_workers==0,"Ujemna liczba zatrudnionych jest odrzucana")
	s.hired_workers=2;s.reset_game()
	check(s.hired_workers==0,"Reset usuwa zatrudnionych")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(s.save_path+suffix):DirAccess.remove_absolute(s.save_path+suffix)
	print("WORKERS RESULT: %d/%d"%[checks-failures,checks])
	quit(1 if failures else 0)
