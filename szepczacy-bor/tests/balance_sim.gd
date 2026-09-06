extends SceneTree
const Rules=preload("res://scripts/state.gd")
func _initialize():call_deferred("run")

func run():
	# A purchase policy, not a guarantee: active player sells only the wood beyond
	# the next purchase's construction reserve, and buys available growth upgrades.
	for cadence in [0.24,0.4,0.65]:
		var s=Rules.new()
		root.add_child(s)
		s.rng.seed=1234
		var first_buy=-1.0
		var first_home=-1.0
		var old_forest=-1.0
		var warped_forest=-1.0
		var next_hit=0.0
		var milestones=[]
		for tick in range(108000):
			s.advance(.1)
			next_hit-=.1
			if next_hit<=0:
				next_hit+=cadence
				s.chop()
			if tick%10!=0: continue
			if s.event_window>0:s.take_whisper()
			# Pick the available building with smallest equivalent wood cost.
			var target=-1
			var best=1e20
			for i in range(6):
				if s.buildings[i]>=3 or not s.requirements_met(i):continue
				var c=s.building_cost(i)
				var cost=c[0]+c[1]/s.sale_price()
				if cost<best:best=cost;target=i
			# Compare an upgrade against the next building before spending.
			var up=-1
			var up_cost=1e20
			for i in [0,2,1]:
				if s.upgrade_level(i)>=s.upgrade_cap(i):continue
				var weighted=s.upgrade_cost(i)*[1.0,2.7,1.4][i]
				if weighted<up_cost:up_cost=weighted;up=i
			var reserve=0.0
			var choose_upgrade=up>=0 and up_cost/s.sale_price()<best*.50
			if not choose_upgrade and target>=0:reserve=s.building_cost(target)[0]
			var sale=floor(maxf(0,s.wood-reserve))
			if sale>0:
				var keep=s.wood-sale
				s.wood=sale;s.sell();s.wood=keep
			if choose_upgrade:
				if s.buy_upgrade(up) and first_buy<0:first_buy=s.play_time
			elif target>=0 and s.build(target):
				milestones.append("%s %d @ %.1f min"%[s.BUILDINGS[target].short,s.buildings[target],s.play_time/60])
				if target==0 and first_home<0:first_home=s.play_time
			if s.tree_unlocked(2) and s.tree_kind!=2:
				s.select_tree(2);warped_forest=s.play_time
			elif s.tree_unlocked(1) and s.tree_kind==0:
				s.select_tree(1);old_forest=s.play_time
			if s.completed:break
		print(JSON.stringify({"clicks_per_second":1.0/cadence,"first_upgrade_s":first_buy,"first_building_s":first_home,"old_forest_min":old_forest/60,"warped_forest_min":warped_forest/60,"complete_min":s.play_time/60,"completed":s.completed,"milestones":milestones}))
		s.free()
	quit()
