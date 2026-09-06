extends Node
## All game rules and save data live here. No scene/UI dependency.

signal changed
signal message(text: String)
signal building_changed(id: int, level: int)
signal goal_completed

const VERSION = 1
const OFFLINE_LIMIT = 28800.0
const TREES = [
	{"name":"Sosna", "hp":18.0, "wood":6.0, "lore":"Żywica pachnie ciepłem. Jeszcze zwyczajnie."},
	{"name":"Prastary dąb", "hp":88.0, "wood":42.0, "lore":"W słojach zapisano zimy, których nikt nie pamięta."},
	{"name":"Spaczone drzewo", "hp":420.0, "wood":250.0, "lore":"Jego cień porusza się odrobinę za późno."}
]
const BUILDINGS = [
	{"name":"Chata drwala", "short":"Chata", "costs":[[100,160],[800,1040],[3840,6080]], "bonuses":["1 drwal · bazowo +0,75 drewna/s", "3 drwali · bazowo 2,4 drewna/s", "7 drwali · bazowo 6 drewna/s"], "lore":"Pod dachem schną płaszcze. O świcie ruszą do pracy."},
	{"name":"Tartak", "short":"Tartak", "costs":[[150,225],[1440,2400],[9600,17600]], "bonuses":["+25% drewna z drzew i od drwali", "+60% drewna z drzew i od drwali", "+120% drewna z drzew i od drwali"], "lore":"Piła zagłusza to, co czasem słychać między drzewami."},
	{"name":"Kuźnia", "short":"Kuźnia", "costs":[[300,560],[2880,5440],[14400,32000]], "bonuses":["Odblokowuje siekierę do poziomu 8", "Odblokowuje siekierę do poziomu 12", "Odblokowuje siekierę do poziomu 16"], "lore":"Żelazo i ogień. Dwie rzeczy, którym można ufać."},
	{"name":"Targ", "short":"Targ", "costs":[[400,700],[3520,7520],[16000,36800]], "bonuses":["Cena drewna: 1,30 monety", "Cena drewna: 1,70 monety", "Cena drewna: 2,20 monety"], "lore":"Kupiec płaci uczciwie. Nie pyta o ciemniejsze deski."},
	{"name":"Karczma", "short":"Karczma", "costs":[[750,1375],[5280,12000],[23200,54400]], "bonuses":["Drwale pracują o 50% wydajniej", "Drwale pracują o 120% wydajniej", "Drwale pracują o 220% wydajniej"], "lore":"Zupa, śmiech i ogień. Za oknem ktoś liczy gwiazdy."},
	{"name":"Latarnia", "short":"Latarnia", "costs":[[1875,3750],[17600,44800],[60800,160000]], "bonuses":["Otwiera Spaczony Bór · drwale +20%", "Silniejsze światło · drwale +40%", "Cel osady osiągnięty · drwale +70%"], "lore":"Nie pokazuje drogi do domu. Pokazuje, gdzie kończy się noc."}
]
const UPGRADES = ["Ostrze siekiery", "Pewna ręka", "Lepszy uzysk"]

var wood = 0.0
var coins = 0.0
var axe = 0
var crit = 0
var yield_level = 0
var buildings = [0,0,0,0,0,0]
var hired_workers = 0
var tree_kind = 0
var tree_hp = 18.0
var respawn = 0.0
var hit_cooldown = 0.0
var total_trees = 0
var total_wood = 0.0
var play_time = 0.0
var event_next = 200.0
var event_window = 0.0
var boost_left = 0.0
var completed = false
var last_seen = 0.0
var music_volume = 0.35
var effects_volume = 0.65
var music_muted = false
var effects_muted = false
var reduced_motion = false
var save_path = "user://bor_save_v1.json"
var save_error = ""
var load_warning = ""
var offline_report = {}
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func damage() -> float:
	return 2.0 + axe * 2.0 + floor(axe / 4.0)

func crit_chance() -> float:
	return 0.05 + crit * 0.03

func wood_multiplier() -> float:
	return (1.0 + yield_level * 0.12) * [1.0,1.25,1.6,2.2][buildings[1]]

func tree_reward() -> float:
	return TREES[tree_kind].wood * wood_multiplier() * (1.5 if boost_left > 0 else 1.0)

func passive_rate(include_boost: bool = true) -> float:
	return ([0.0,0.75,2.4,6.0][buildings[0]] + hired_workers * 0.75) * [1.0,1.5,2.2,3.2][buildings[4]] * [1.0,1.2,1.4,1.7][buildings[5]] * wood_multiplier() * (1.5 if include_boost and boost_left > 0 else 1.0)

func worker_capacity() -> int:
	return [0,3,8,16][buildings[0]]

func worker_count() -> int:
	return [0,1,3,7][buildings[0]] + hired_workers

func worker_cost() -> float:
	return ceil(180.0 * pow(1.55, hired_workers))

func worker_bonus() -> float:
	return 0.75 * [1.0,1.5,2.2,3.2][buildings[4]] * [1.0,1.2,1.4,1.7][buildings[5]] * wood_multiplier() * (1.5 if boost_left > 0 else 1.0)

func can_hire_worker() -> bool:
	return hired_workers < worker_capacity() and coins >= worker_cost()

func hire_worker() -> bool:
	if not can_hire_worker():
		return false
	coins = maxf(0.0, coins - worker_cost())
	hired_workers += 1
	changed.emit()
	message.emit("Nowy drwal dołączył do osady. Ekipa liczy %d osób." % worker_count())
	return true

func sale_price() -> float:
	return [1.0,1.3,1.7,2.2][buildings[3]]

func axe_cap() -> int:
	return 4 + buildings[2] * 4

func tree_unlocked(kind: int) -> bool:
	return kind == 0 or (kind == 1 and buildings[1] > 0) or (kind == 2 and buildings[5] > 0)

func select_tree(kind: int) -> bool:
	if kind < 0 or kind > 2 or not tree_unlocked(kind) or kind == tree_kind:
		return false
	tree_kind = kind
	tree_hp = TREES[kind].hp
	respawn = 0.0
	changed.emit()
	return true

func chop(forced_roll: float = -1.0) -> Dictionary:
	if respawn > 0.0 or hit_cooldown > 0.0:
		return {}
	hit_cooldown = 0.18
	var critical = (rng.randf() if forced_roll < 0.0 else forced_roll) < crit_chance()
	var dealt = damage() * (2.5 if critical else 1.0)
	tree_hp = maxf(0.0, tree_hp - dealt)
	var result = {"damage":dealt, "critical":critical, "felled":tree_hp <= 0.0, "reward":0.0}
	if tree_hp <= 0.0:
		result.reward = tree_reward()
		add_wood(result.reward)
		total_trees += 1
		respawn = 0.7
		if total_trees == 1:
			message.emit("Pierwsze drewno! Sprzedaj część i naostrz siekierę.")
		elif total_trees == 25:
			message.emit("Wśród gałęzi na chwilę ucichły ptaki.")
	changed.emit()
	return result

func add_wood(amount: float):
	if not is_finite(amount) or amount <= 0:
		return
	wood = minf(1.0e12, wood + amount)
	total_wood = minf(1.0e15, total_wood + amount)

func advance(dt: float):
	if not is_finite(dt) or dt <= 0:
		return
	# Integrate a boost only for the part of the interval for which it is active.
	var base = passive_rate(false)
	add_wood(base * dt + base * 0.5 * minf(dt, boost_left))
	boost_left = maxf(0.0, boost_left - dt)
	hit_cooldown = maxf(0.0, hit_cooldown - dt)
	if respawn > 0.0:
		respawn = maxf(0.0, respawn - dt)
		if respawn <= 0.0:
			tree_hp = TREES[tree_kind].hp
	play_time += dt
	if event_window > 0.0:
		event_window = maxf(0.0, event_window - dt)
	else:
		event_next -= dt
		if event_next <= 0.0:
			event_window = 25.0
			event_next = rng.randf_range(190.0,250.0)
			message.emit("Szept boru… Między drzewami zapalił się błędny ognik.")

func take_whisper() -> bool:
	if event_window <= 0.0:
		return false
	event_window = 0.0
	boost_left = 35.0
	changed.emit()
	message.emit("Dobry szept · +50% drewna przez 35 sekund.")
	return true

func sell(half: bool = false) -> float:
	var amount = floor(wood / 2.0) if half else floor(wood)
	if amount < 1.0:
		return 0.0
	wood = maxf(0.0, wood - amount)
	var income = amount * sale_price()
	coins = minf(1.0e12, coins + income)
	changed.emit()
	return income

func upgrade_level(id: int) -> int:
	return [axe,crit,yield_level][id]

func upgrade_cap(id: int) -> int:
	return [axe_cap(),10,8][id]

func upgrade_cost(id: int) -> float:
	return ceil([55.0,70.0,55.0][id] * pow([1.68,1.72,1.95][id], upgrade_level(id)))

func upgrade_bonus(id: int) -> String:
	match id:
		0:
			var next = 2.0 + (axe+1)*2.0 + floor((axe+1)/4.0)
			return "Siła %d → %d" % [damage(),next]
		1:
			return "Krytyk %d%% → %d%% · cios ×2,5" % [round(crit_chance()*100),round((crit_chance()+0.03)*100)]
		_:
			return "Uzysk +%d%% → +%d%%" % [yield_level*12,(yield_level+1)*12]

func buy_upgrade(id: int) -> bool:
	if id < 0 or id > 2 or upgrade_level(id) >= upgrade_cap(id):
		return false
	var cost = upgrade_cost(id)
	if coins + 0.000001 < cost:
		return false
	coins = maxf(0.0, coins - cost)
	match id:
		0: axe += 1
		1: crit += 1
		2: yield_level += 1
	changed.emit()
	return true

func requirements(id: int) -> Array:
	var level = buildings[id]
	match id:
		0: return [[],[[1,1]],[[4,1]]][level] if level < 3 else []
		1: return [[[0,1]],[[2,1]],[[3,2]]][level] if level < 3 else []
		2: return [[[1,1]],[[3,1]],[[5,1]]][level] if level < 3 else []
		3: return [[[0,1]],[[4,1]],[[5,2]]][level] if level < 3 else []
		4: return [[[0,2]],[[5,1]],[[0,3]]][level] if level < 3 else []
		5: return [[[3,1],[2,1]],[[0,2],[1,2],[2,2],[3,2],[4,2]],[[0,3],[1,3],[2,3],[3,3],[4,3]]][level] if level < 3 else []
	return []

func requirements_met(id: int) -> bool:
	for req in requirements(id):
		if buildings[req[0]] < req[1]:
			return false
	return true

func requirements_text(id: int) -> String:
	var parts = PackedStringArray()
	for req in requirements(id):
		if buildings[req[0]] < req[1]:
			parts.append("%s %s" % [BUILDINGS[req[0]].short, roman(req[1])])
	return ", ".join(parts)

func building_cost(id: int) -> Array:
	if buildings[id] >= 3:
		return [0,0]
	return BUILDINGS[id].costs[buildings[id]]

func can_build(id: int) -> bool:
	if id < 0 or id >= 6 or buildings[id] >= 3 or not requirements_met(id):
		return false
	var c = building_cost(id)
	return wood + 0.000001 >= c[0] and coins + 0.000001 >= c[1]

func build(id: int) -> bool:
	if not can_build(id):
		return false
	var c = building_cost(id)
	wood = maxf(0.0, wood - c[0])
	coins = maxf(0.0, coins - c[1])
	buildings[id] += 1
	building_changed.emit(id,buildings[id])
	message.emit("%s %s · %s" % [BUILDINGS[id].name,roman(buildings[id]),BUILDINGS[id].bonuses[buildings[id]-1]])
	changed.emit()
	if buildings[5] == 3 and not completed:
		completed = true
		goal_completed.emit()
	return true

func next_goal() -> String:
	if buildings[0] == 0: return "Rozpalmy pierwszy dom. Zbuduj chatę drwala."
	if buildings[1] == 0: return "Zbuduj tartak, by odkryć prastare dęby."
	if buildings[5] == 0: return "Wznieś latarnię i odnajdź Spaczony Bór."
	if buildings[5] < 3: return "Rozbuduj osadę. Niech latarnia osiągnie poziom III."
	return "Światło zostało z nami. Osada jest bezpieczna."

static func roman(n: int) -> String:
	return ["—","I","II","III"][clampi(n,0,3)]

func snapshot(now: float = -1.0) -> Dictionary:
	return {"version":VERSION,"hired_workers":hired_workers,"wood":wood,"coins":coins,"axe":axe,"crit":crit,"yield":yield_level,"buildings":buildings.duplicate(),"tree_kind":tree_kind,"tree_hp":tree_hp,"respawn":respawn,"total_trees":total_trees,"total_wood":total_wood,"play_time":play_time,"event_next":event_next,"event_window":event_window,"boost_left":boost_left,"completed":completed,"last_seen":Time.get_unix_time_from_system() if now < 0 else now,"music_volume":music_volume,"effects_volume":effects_volume,"music_muted":music_muted,"effects_muted":effects_muted,"reduced_motion":reduced_motion}

func safe_number(d: Dictionary, key: String, fallback: float, low: float, high: float) -> float:
	var value = d.get(key, fallback)
	if not (value is int or value is float) or not is_finite(float(value)):
		return fallback
	return clampf(float(value),low,high)

func restore(d: Dictionary) -> bool:
	if d.get("version",0) != VERSION or not d.get("buildings",null) is Array or d.buildings.size() != 6:
		return false
	# Validate before mutating so a malformed save can safely fall back to backup.
	for n in d.buildings:
		if not (n is float or n is int) or not is_finite(float(n)):
			return false
	for i in range(6): buildings[i] = clampi(int(d.buildings[i]),0,3)
	hired_workers = int(safe_number(d,"hired_workers",0,0,worker_capacity()))
	wood = safe_number(d,"wood",0,0,1e12)
	coins = safe_number(d,"coins",0,0,1e12)
	axe = int(safe_number(d,"axe",0,0,axe_cap()))
	crit = int(safe_number(d,"crit",0,0,10))
	yield_level = int(safe_number(d,"yield",0,0,8))
	tree_kind = int(safe_number(d,"tree_kind",0,0,2))
	if not tree_unlocked(tree_kind): tree_kind = 0
	tree_hp = safe_number(d,"tree_hp",TREES[tree_kind].hp,0,TREES[tree_kind].hp)
	respawn = safe_number(d,"respawn",0,0,0.7)
	if tree_hp <= 0 and respawn <= 0: tree_hp = TREES[tree_kind].hp
	total_trees = int(safe_number(d,"total_trees",0,0,1e12))
	total_wood = safe_number(d,"total_wood",0,0,1e15)
	play_time = safe_number(d,"play_time",0,0,1e12)
	event_next = safe_number(d,"event_next",200,1,250)
	event_window = safe_number(d,"event_window",0,0,25)
	boost_left = safe_number(d,"boost_left",0,0,35)
	completed = buildings[5] == 3
	last_seen = safe_number(d,"last_seen",0,0,1e12)
	music_volume = safe_number(d,"music_volume",0.35,0,1)
	effects_volume = safe_number(d,"effects_volume",0.65,0,1)
	music_muted = d.get("music_muted",false) == true
	effects_muted = d.get("effects_muted",false) == true
	reduced_motion = d.get("reduced_motion",false) == true
	hit_cooldown = 0
	changed.emit()
	return true

func grant_offline(now: float) -> Dictionary:
	var elapsed = clampf(now-last_seen,0.0,OFFLINE_LIMIT) if last_seen > 0 else 0.0
	var amount = passive_rate(false) * elapsed
	add_wood(amount)
	boost_left = 0.0
	event_window = 0.0
	last_seen = now
	offline_report = {"seconds":elapsed,"wood":amount}
	return offline_report

func save_game(now: float = -1.0) -> bool:
	var payload = JSON.stringify(snapshot(now))
	var web_saved = false
	if OS.has_feature("web"):
		var js = "(function(){try{var k='szepczacy-bor-v1',old=localStorage.getItem(k);if(old)localStorage.setItem(k+'.bak',old);localStorage.setItem(k,%s);return true}catch(e){return false}})()" % JSON.stringify(payload)
		web_saved = JavaScriptBridge.eval(js,true) == true
	var temp = save_path + ".tmp"
	var file = FileAccess.open(temp,FileAccess.WRITE)
	if file == null:
		if web_saved: return true
		save_error = "Nie udało się zapisać postępu. Sprawdź wolne miejsce."
		return false
	file.store_string(payload)
	file.flush()
	file.close()
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path,save_path+".bak")
	var error = DirAccess.rename_absolute(temp,save_path)
	if error != OK:
		if web_saved: return true
		save_error = "Zapis nie powiódł się. Poprzedni zapis jest zachowany."
		return false
	save_error = ""
	return true

func load_game(now: float = -1.0) -> bool:
	if OS.has_feature("web"):
		for key in ["szepczacy-bor-v1","szepczacy-bor-v1.bak"]:
			var raw = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||''}catch(e){return ''}})()" % JSON.stringify(key),true)
			if raw is String and not raw.is_empty():
				var parser = JSON.new()
				if parser.parse(raw) == OK and parser.data is Dictionary and restore(parser.data):
					if key.ends_with(".bak"):
						load_warning = "Odzyskano postęp z ostatniej kopii zapisu."
						JavaScriptBridge.eval("try{localStorage.removeItem('szepczacy-bor-v1')}catch(e){}",true)
					grant_offline(Time.get_unix_time_from_system() if now < 0 else now)
					save_game(now)
					return true
	for path in [save_path,save_path+".bak"]:
		if not FileAccess.file_exists(path): continue
		var text = FileAccess.get_file_as_string(path)
		var parser = JSON.new()
		var parse_error = parser.parse(text)
		var parsed = parser.data if parse_error == OK else null
		if parsed is Dictionary and restore(parsed):
			if path.ends_with(".bak"):
				load_warning = "Odzyskano postęp z ostatniej kopii zapisu."
				# Preserve the known-good backup when replacing a damaged primary.
				DirAccess.remove_absolute(save_path)
			grant_offline(Time.get_unix_time_from_system() if now < 0 else now)
			save_game(now)
			return true
		load_warning = "Poprzedni zapis był uszkodzony. Rozpoczynasz nową osadę."
	return false

func reset_game():
	var fresh = {"version":VERSION,"buildings":[0,0,0,0,0,0],"music_volume":music_volume,"effects_volume":effects_volume,"music_muted":music_muted,"effects_muted":effects_muted,"reduced_motion":reduced_motion}
	restore(fresh)
	offline_report = {}
	load_warning = ""
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try{localStorage.removeItem('szepczacy-bor-v1');localStorage.removeItem('szepczacy-bor-v1.bak')}catch(e){}",true)
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(save_path+suffix): DirAccess.remove_absolute(save_path+suffix)
	save_game()
	changed.emit()
