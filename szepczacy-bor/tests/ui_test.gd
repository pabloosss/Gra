extends SceneTree
var ui
var s
var failed=0
var count=0

func _initialize(): call_deferred("run")

func check(ok: bool,title: String):
	count+=1
	if ok:print("PASS UI: "+title)
	else:failed+=1;push_error("FAIL UI: "+title)

func frames(n=5):
	for i in range(n):await process_frame

func click_button(b: Button):
	var pos=b.get_global_rect().get_center()
	var down=InputEventMouseButton.new()
	down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=pos;down.global_position=pos
	root.push_input(down)
	await frames(2)
	var up=down.duplicate();up.pressed=false
	root.push_input(up)
	await frames(3)

func capture(name: String):
	await frames(8)
	await RenderingServer.frame_post_draw
	var im=root.get_texture().get_image()
	var result=im.save_png("res://tests/"+name+".png")
	check(result==OK,"Zrzut ekranu "+name)

func run():
	s=root.get_node("State")
	s.save_path="user://test_ui_only.json"
	ui=load("res://main.tscn").instantiate()
	root.add_child(ui)
	current_scene=ui
	await frames(15)
	check(ui.build_cards.size()==6 and ui.upgrade_cards.size()==3,"Sześć budynków i trzy ulepszenia w scenie")
	check(root.get_node("Sound").started==false,"Dźwięk czeka na pierwszą interakcję")
	await capture("poczatek")
	var key=InputEventKey.new();key.keycode=KEY_SPACE;key.pressed=true
	root.push_input(key)
	await create_timer(3.1).timeout
	key=InputEventKey.new();key.keycode=KEY_SPACE;key.pressed=false;root.push_input(key)
	check(s.total_trees>=1 and s.wood>=6,"Przytrzymanie Spacji ścina drzewa i daje drewno")
	check(root.get_node("Sound").started,"Pierwsza interakcja uruchamia audio")
	var before=s.coins
	await click_button(ui.all_button)
	check(s.coins>before,"Kliknięcie Sprzedaj wszystko daje monety")
	s.wood=100;s.coins=160;ui.update_ui()
	await click_button(ui.build_cards[0].buy)
	check(s.buildings[0]==1 and s.wood<1 and s.coins==0,"Kliknięcie Buduj: koszty i widoczna chata")
	var w=s.wood;await create_timer(1.1).timeout
	check(s.wood>w+.7,"Drwale produkują drewno w działającej scenie")
	await click_button(ui.tabs[1])
	s.coins=55;ui.update_ui();await frames(3)
	await click_button(ui.upgrade_cards[0].buy)
	check(s.axe==1 and s.damage()==4,"Narzędzia: prawdziwy przycisk zwiększa siłę")
	s.event_window=20;ui.update_ui();await frames(5)
	await click_button(ui.event_button)
	check(s.boost_left>30 and s.event_window==0,"Kliknięcie wydarzenia daje czasowy bonus")
	# Buy a grown village through the same production purchase methods.
	s.wood=1e7;s.coins=1e7
	for round_index in range(6):
		for id in range(6):
			if s.buildings[id] < (1 if id==5 else 2): s.build(id)
	s.wood=1275;s.coins=864;s.select_tree(1);ui.show_tab(0);ui.select_building(5);ui.update_ui()
	await frames(8)
	check(s.buildings==[2,2,2,2,2,1],"Rozwinięta osada ma rzeczywiste budynki i ich ulepszenia")
	await capture("osada")
	ui.show_settings();await frames(10)
	check(ui.overlay.visible,"Ustawienia otwierają się nad grą")
	await capture("ustawienia")
	ui.confirm_reset();await frames(5)
	check(ui.overlay.visible and s.buildings[0]==2,"Prośba o reset nie kasuje postępu bez potwierdzenia")
	await capture("reset_potwierdzenie")
	ui.close_modal()
	check(s.save_game(500000),"Zapis postępu rozbudowanej osady")
	var w2=s.wood;var rate=s.passive_rate(false)
	check(s.load_game(500060) and abs(s.wood-w2-rate*60)<.001,"Wczytanie i podsumowanie produkcji offline")
	ui.show_offline();await capture("powrot")
	ui.close_modal()
	root.size=Vector2i(960,680)
	await frames(15)
	await capture("male_okno")
	check(ui.all_button.get_global_rect().end.x<=ui.size.x+2,"Przyciski handlu mieszczą się w mniejszym oknie")
	# Check the end condition and all visual upgrade levels.
	root.size=Vector2i(1440,900)
	s.wood=1e9;s.coins=1e9
	for r in range(6):
		for id in range(6):s.build(id)
	check(s.completed and ui.overlay.visible,"Latarnia III kończy opowieść i pokazuje zakończenie")
	await capture("zakonczenie")
	ui.close_modal();s.select_tree(2);s.wood=5721;s.coins=2903;ui.update_ui()
	await capture("pelna_osada")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(s.save_path+suffix):DirAccess.remove_absolute(s.save_path+suffix)
	print("UI RESULT: %d/%d passed"%[count-failed,count])
	ui.queue_free()
	await frames(4)
	ui=null
	quit(0 if failed==0 else 1)
