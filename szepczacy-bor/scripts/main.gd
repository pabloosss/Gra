extends Control

const WorldScript = preload("res://scripts/world.gd")
const IconScript = preload("res://scripts/pixel_icon.gd")
const FONT = preload("res://assets/DejaVuSans.ttf")
const TITLE_FONT = preload("res://assets/DejaVuSerif-Bold.ttf")
const C_TEXT = Color("e0e5d5")
const C_MUTED = Color("94a89c")
const C_GOLD = Color("ebc18a")
const C_GREEN = Color("aad0a4")
var resource_values = []
var world
var viewport: SubViewport
var world_image: TextureRect
var goal_label: Label
var progress_label: Label
var tree_name: Label
var tree_lore: Label
var hp_bar: ProgressBar
var hit_label: Label
var forest_buttons = []
var half_button: Button
var all_button: Button
var sale_label: Label
var reserve_label: Label
var worker_info: Label
var worker_requirement: Label
var hire_button: Button
var build_cards = []
var upgrade_cards = []
var tabs = []
var pages = []
var build_scroll: ScrollContainer
var selected = 0
var toast: Label
var toast_left = 0.0
var save_status: Label
var event_button: Button
var lore_content: Label
var overlay: ColorRect
var modal_box: PanelContainer
var modal_content: VBoxContainer
var refresh_left = 0.0
var save_left = 10.0
var hold_left = 0.0
var space_held = false
var focused_out_at = 0.0
var focused_out_play_time = 0.0
var ui_ready = false
var testing = false
var sidebar: VBoxContainer
var world_panel: PanelContainer
var outer_margin: MarginContainer

func _ready():
	testing = "--test-ui" in OS.get_cmdline_user_args()
	get_tree().auto_accept_quit = false
	get_viewport().gui_embed_subwindows = true
	setup_theme()
	if not testing: State.load_game()
	Sound.apply_settings()
	build_ui()
	ui_ready = true
	resized.connect(adapt_layout)
	adapt_layout()
	State.message.connect(show_toast)
	State.goal_completed.connect(show_ending)
	State.building_changed.connect(func(_id,_level): update_ui())
	update_ui()
	if not State.load_warning.is_empty():
		show_toast(State.load_warning)
	elif State.offline_report.get("wood",0)>0.1 and State.offline_report.get("seconds",0)>30:
		show_offline()
	else:
		show_toast("Dobrze, że jesteś. Zacznij od drzewa i pierwszej kupki drewna.")

func setup_theme():
	var t=Theme.new()
	t.default_font=FONT
	t.default_font_size=14
	t.set_color("font_color","Label",C_TEXT)
	t.set_color("font_color","Button",C_TEXT)
	t.set_color("font_hover_color","Button",Color("fcf1ce"))
	t.set_color("font_pressed_color","Button",Color("fcf1ce"))
	t.set_color("font_disabled_color","Button",Color("8a9a90"))
	t.set_stylebox("normal","Button",box(Color("1d3535"),Color("3b5550"),10))
	t.set_stylebox("hover","Button",box(Color("2a4842"),Color("99b08a"),10))
	t.set_stylebox("pressed","Button",box(Color("3a5143"),C_GOLD,10))
	t.set_stylebox("disabled","Button",box(Color("192929"),Color("30413c"),10))
	t.set_stylebox("focus","Button",box(Color.TRANSPARENT,C_GOLD,1))
	t.set_stylebox("background","ProgressBar",box(Color("101f25"),Color("30473f"),0))
	t.set_stylebox("fill","ProgressBar",box(Color("91b485"),Color("a8c896"),0))
	t.set_stylebox("scroll","VScrollBar",box(Color("142626"),Color("142626"),0))
	t.set_stylebox("grabber","VScrollBar",box(Color("456256"),Color("456256"),2))
	t.set_stylebox("grabber_highlight","VScrollBar",box(Color("729077"),Color("729077"),2))
	t.set_stylebox("grabber_pressed","VScrollBar",box(C_GOLD,C_GOLD,2))
	t.set_constant("separation","VBoxContainer",10)
	t.set_constant("separation","HBoxContainer",12)
	theme=t

func box(fill: Color,border: Color,pad: int) -> StyleBoxFlat:
	var b=StyleBoxFlat.new()
	b.bg_color=fill
	b.border_color=border
	b.set_border_width_all(1)
	b.content_margin_left=pad
	b.content_margin_right=pad
	b.content_margin_top=pad
	b.content_margin_bottom=pad
	b.corner_radius_top_left=3
	b.corner_radius_top_right=3
	b.corner_radius_bottom_left=3
	b.corner_radius_bottom_right=3
	return b

func label(text: String,font_size=14,color=C_TEXT,wrap=false) -> Label:
	var l=Label.new()
	l.text=text
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	if wrap: l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return l

func button(text: String,fn: Callable) -> Button:
	var b=Button.new()
	b.text=text
	b.focus_mode=Control.FOCUS_NONE
	b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	b.pressed.connect(fn)
	return b

func panel(parent: Node,pad=14,fill=Color("152a2b")) -> PanelContainer:
	var p=PanelContainer.new()
	p.add_theme_stylebox_override("panel",box(fill,Color("344c44"),pad))
	parent.add_child(p)
	return p

func vbox(parent: Node,separation=10) -> VBoxContainer:
	var v=VBoxContainer.new()
	v.add_theme_constant_override("separation",separation)
	parent.add_child(v)
	return v

func hbox(parent: Node,separation=12) -> HBoxContainer:
	var h=HBoxContainer.new()
	h.add_theme_constant_override("separation",separation)
	parent.add_child(h)
	return h

func icon(kind: int) -> Control:
	var i=Control.new()
	i.set_script(IconScript)
	i.kind=kind
	return i

func build_ui():
	var bg=ColorRect.new()
	bg.color=Color("0d1b20")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin=MarginContainer.new()
	outer_margin=margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,22)
	add_child(margin)
	var root=vbox(margin,14)
	var header=hbox(root,13)
	header.add_child(icon(4))
	var title_stack=vbox(header,1)
	title_stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var title=label("Szepczący Bór",27,C_TEXT)
	title.add_theme_font_override("font",TITLE_FONT)
	title_stack.add_child(title)
	title_stack.add_child(label("Osada na skraju niewypowiedzianego",12,C_MUTED))
	header.add_child(button("Jak grać",show_help))
	header.add_child(button("Ustawienia",show_settings))
	var resources=hbox(root,12)
	for i in range(4):
		var p=panel(resources,11)
		p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var row=hbox(p,12)
		row.add_child(icon(i))
		var stack=vbox(row,0)
		stack.add_child(label(["DREWNO","MONETY","SIŁA UDERZENIA","DREWNO / SEK."][i],11,C_MUTED))
		var n=label("0",24,C_GOLD if i==1 else C_TEXT)
		stack.add_child(n)
		resource_values.append(n)
	var body=hbox(root,18)
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var left=vbox(body,10)
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var goal=panel(left,10,Color("192f2e"))
	var grow=hbox(goal,10)
	var gs=vbox(grow,3)
	gs.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	gs.add_child(label("ŚWIATŁO DLA OSADY",10,C_GOLD))
	goal_label=label("",14,C_TEXT,true)
	gs.add_child(goal_label)
	progress_label=label("0 / 18",15,C_GOLD)
	grow.add_child(progress_label)
	var frame=panel(left,0,Color("132627"))
	world_panel=frame
	frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
	frame.custom_minimum_size.y=310
	viewport=SubViewport.new()
	viewport.size=Vector2i(WorldScript.VIEW_SIZE)
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	world=Node2D.new()
	world.set_script(WorldScript)
	viewport.add_child(world)
	world_image=TextureRect.new()
	world_image.texture=viewport.get_texture()
	world_image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	world_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	world_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	world_image.mouse_filter=Control.MOUSE_FILTER_STOP
	world_image.gui_input.connect(world_input)
	world_image.mouse_exited.connect(func(): world.hover_tree=false;world.hover_building=-1)
	frame.add_child(world_image)
	var info=panel(left,12)
	var info_v=vbox(info,7)
	var tree_row=hbox(info_v)
	tree_name=label("Sosna",17,C_TEXT)
	tree_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	tree_row.add_child(tree_name)
	hit_label=label("18 / 18",13,C_MUTED)
	tree_row.add_child(hit_label)
	hp_bar=ProgressBar.new()
	hp_bar.show_percentage=false
	hp_bar.custom_minimum_size.y=7
	info_v.add_child(hp_bar)
	tree_lore=label("",12,C_MUTED,true)
	info_v.add_child(tree_lore)
	var forests=hbox(left,8)
	for i in range(3):
		var b=button(["Sosnowa polana","Prastary las","Spaczony Bór"][i],func(): change_forest(i))
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size",13)
		forests.add_child(b)
		forest_buttons.append(b)
	var instruction=label("Klikaj drzewo lub przytrzymaj Spację. Kliknij parcelę, aby wybrać budynek.",12,C_MUTED,true)
	left.add_child(instruction)
	# The economy stays visible above the scrolling construction / upgrades panel.
	var side=vbox(body,10)
	sidebar=side
	side.custom_minimum_size.x=372
	var trade=panel(side,14)
	var tv=vbox(trade,8)
	var trade_title=hbox(tv)
	trade_title.add_child(label("Handel drewnem",17,C_TEXT))
	sale_label=label("1,00 monety / szt.",12,C_GOLD)
	sale_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	sale_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	trade_title.add_child(sale_label)
	var sell_row=hbox(tv,8)
	half_button=button("Sprzedaj połowę",func(): sell_wood(true))
	all_button=button("Sprzedaj wszystko",func(): sell_wood(false))
	half_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	all_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	sell_row.add_child(half_button)
	sell_row.add_child(all_button)
	reserve_label=label("",12,C_MUTED,true)
	tv.add_child(reserve_label)
	event_button=button("Szept boru · przyjmij dar",take_event)
	event_button.add_theme_stylebox_override("normal",box(Color("344a48"),C_GREEN,10))
	side.add_child(event_button)
	event_button.visible=false
	var nav=hbox(side,5)
	for i in range(3):
		var b=button(["Osada","Narzędzia","Kronika"][i],func(): show_tab(i))
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		nav.add_child(b)
		tabs.append(b)
	var page_holder=Control.new()
	page_holder.size_flags_vertical=Control.SIZE_EXPAND_FILL
	side.add_child(page_holder)
	for i in range(3):
		var scroll=ScrollContainer.new()
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		page_holder.add_child(scroll)
		pages.append(scroll)
		var contents=vbox(scroll,9)
		contents.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		if i==0:
			build_scroll=scroll
			make_worker_card(contents)
			for id in range(6): make_build_card(contents,id)
		elif i==1:
			for id in range(3): make_upgrade_card(contents,id)
			contents.add_child(label("Bonusy do uzysku i tartak wzmacniają także drwali. Trafienie krytyczne zadaje 2,5× obrażeń.",13,C_MUTED,true))
		else:
			var lpanel=panel(contents,15)
			var ls=vbox(lpanel,12)
			ls.add_child(label("Zapisy z polany",19,C_GOLD))
			lore_content=label("",14,C_TEXT,true)
			ls.add_child(lore_content)
			contents.add_child(label("„Las nie jest zły. Po prostu pamięta więcej niż my.”",14,C_MUTED,true))
	show_tab(0)
	var bottom=hbox(root)
	toast=label("",12,C_GREEN,true)
	toast.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bottom.add_child(toast)
	save_status=label("Zapis automatyczny",11,C_MUTED)
	bottom.add_child(save_status)
	# In-game overlays, including an explicit two-step reset confirmation.
	overlay=ColorRect.new()
	overlay.color=Color(0.025,0.055,0.065,.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index=20
	add_child(overlay)
	var center=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	modal_box=panel(center,28,Color("1a302f"))
	modal_box.custom_minimum_size.x=610
	modal_content=vbox(modal_box,15)
	overlay.visible=false

func make_worker_card(parent: Node):
	var card=panel(parent,12,Color("203930"))
	var content=vbox(card,7)
	content.add_child(label("Zatrudnij drwali",18,C_GOLD))
	worker_info=label("",13,C_GREEN,true)
	content.add_child(worker_info)
	worker_requirement=label("",12,C_MUTED,true)
	content.add_child(worker_requirement)
	hire_button=button("",hire_worker)
	hire_button.add_theme_font_size_override("font_size",13)
	content.add_child(hire_button)

func hire_worker():
	if State.hire_worker():
		Sound.play("upgrade")
		persist_purchase()

func make_build_card(parent: Node,id: int):
	var card=panel(parent,12,Color("172d2c"))
	var content=vbox(card,7)
	var row=hbox(content,10)
	var tex=TextureRect.new()
	tex.texture=load("res://assets/building_%d_1.png"%id)
	tex.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	tex.custom_minimum_size=Vector2(48,48)
	row.add_child(tex)
	var names=vbox(row,3)
	names.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var title=label(State.BUILDINGS[id].name,16)
	names.add_child(title)
	var level=label("POZIOM — / III",11,C_MUTED)
	names.add_child(level)
	var bonus=label("",13,C_GREEN,true)
	content.add_child(bonus)
	var req=label("",11,C_MUTED,true)
	content.add_child(req)
	var buy=button("",func(): buy_building(id))
	buy.add_theme_font_size_override("font_size",13)
	content.add_child(buy)
	card.tooltip_text=State.BUILDINGS[id].lore
	build_cards.append({"card":card,"level":level,"bonus":bonus,"req":req,"buy":buy,"texture":tex})

func make_upgrade_card(parent: Node,id: int):
	var card=panel(parent,15)
	var v=vbox(card,10)
	var row=hbox(v)
	row.add_child(icon([2,4,0][id]))
	var text=vbox(row,3)
	text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text.add_child(label(State.UPGRADES[id],17))
	var level=label("",12,C_MUTED)
	text.add_child(level)
	var bonus=label("",14,C_GREEN,true)
	v.add_child(bonus)
	var buy=button("",func(): buy_upgrade(id))
	v.add_child(buy)
	var req=label("",12,C_MUTED,true)
	v.add_child(req)
	upgrade_cards.append({"level":level,"bonus":bonus,"buy":buy,"req":req})

func _process(dt):
	if not ui_ready: return
	State.advance(dt)
	if space_held and not overlay.visible:
		hold_left-=dt
		if hold_left<=0:
			hold_left=.24
			chop()
	refresh_left-=dt
	if refresh_left<=0:
		refresh_left=.15
		update_ui()
	toast_left-=dt
	if toast_left<=0: toast.text="Światło w oknach. Szum w koronach. Jeszcze jeden dzień."
	save_left-=dt
	if save_left<=0 and not testing:
		save_left=10
		State.save_game()
		save_status.text="Postęp zapisany" if State.save_error.is_empty() else "Błąd zapisu"
		if not State.save_error.is_empty(): show_toast(State.save_error)

func _input(event):
	if not ui_ready: return
	if event is InputEventMouseButton and event.pressed or event is InputEventKey and event.pressed:
		Sound.begin()
	if event is InputEventKey:
		if event.keycode==KEY_SPACE:
			if overlay.visible:
				space_held=false
			else:
				space_held=event.pressed
				if event.pressed and not event.echo:
					chop()
					hold_left=.24
			get_viewport().set_input_as_handled()
		elif event.keycode==KEY_ESCAPE and event.pressed:
			if overlay.visible: close_modal()
			else: show_settings()
			get_viewport().set_input_as_handled()
		elif event.keycode==KEY_F11 and event.pressed:
			var full=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)

func world_point(pos: Vector2) -> Vector2:
	var scale_factor=minf(world_image.size.x/WorldScript.VIEW_SIZE.x,world_image.size.y/WorldScript.VIEW_SIZE.y)
	var start=(world_image.size-WorldScript.VIEW_SIZE*scale_factor)/2
	return (pos-start)/scale_factor

func adapt_layout():
	if not ui_ready: return
	sidebar.custom_minimum_size.x=338 if size.x<1180 else 372
	world_panel.custom_minimum_size.y=180 if size.y<780 else 310
	for edge in ["left","right","top","bottom"]: outer_margin.add_theme_constant_override("margin_"+edge,14 if size.x<1180 else 22)

func world_input(event):
	if overlay.visible: return
	if event is InputEventMouseMotion:
		var p=world_point(event.position)
		world.hover_tree=WorldScript.TREE_RECT.has_point(p)
		world.hover_building=world.building_at(p)
		world_image.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if world.hover_tree or world.hover_building>=0 else Control.CURSOR_ARROW
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var p=world_point(event.position)
		if State.event_window>0 and p.distance_to(Vector2(320,256))<30:
			take_event()
		elif WorldScript.TREE_RECT.has_point(p):
			chop()
		else:
			var id=world.building_at(p)
			if id>=0: select_building(id)

func chop():
	var result=State.chop()
	if result.is_empty(): return
	world.hit(result)
	Sound.play("chop_%d"%randi_range(0,2),randf_range(.94,1.06))
	if result.felled: Sound.play("fell")
	update_ui()

func sell_wood(half: bool):
	var value=State.sell(half)
	if value<=0: return
	Sound.play("coins")
	show_toast("Sprzedane · +%s monet"%num(value))
	persist_purchase()

func buy_upgrade(id: int):
	if State.buy_upgrade(id):
		Sound.play("upgrade")
		show_toast("%s · poziom %d"%[State.UPGRADES[id],State.upgrade_level(id)])
		persist_purchase()

func buy_building(id: int):
	selected=id
	world.selected_building=id
	if State.build(id):
		Sound.play("build")
		persist_purchase()

func persist_purchase():
	if not testing: State.save_game()
	update_ui()

func select_building(id: int):
	selected=id
	world.selected_building=id
	show_tab(0)
	build_scroll.ensure_control_visible(build_cards[id].card)
	update_ui()

func change_forest(id: int):
	if State.select_tree(id):
		world.fall_time=0
		Sound.play("whisper",1.15)
		show_toast(State.TREES[id].lore)
		persist_purchase()

func take_event():
	if State.take_whisper():
		Sound.play("whisper")
		persist_purchase()

func show_tab(id: int):
	for i in range(pages.size()):
		pages[i].visible=i==id
		tabs[i].add_theme_stylebox_override("normal",box(Color("314940") if i==id else Color("152829"),Color("8aa37d") if i==id else Color("34473f"),10))

func update_ui():
	if not ui_ready: return
	worker_info.text="Ekipa: %d · dodatkowi: %d / %d\nNowy drwal: +%s drewna/s"%[State.worker_count(),State.hired_workers,State.worker_capacity(),num(State.worker_bonus(),true)]
	worker_requirement.text="Wymaga chaty drwala I." if State.buildings[0]==0 else ("Brak miejsc — rozbuduj chatę." if State.hired_workers>=State.worker_capacity() and State.buildings[0]<3 else ("Wszystkie miejsca zajęte." if State.hired_workers>=State.worker_capacity() else "Stała praca, także offline. Koszt jednorazowy."))
	hire_button.text="Zatrudnij · %s monet"%num(State.worker_cost()) if State.hired_workers<State.worker_capacity() else "Zbuduj chatę drwala" if State.buildings[0]==0 else "Brak wolnych miejsc"
	hire_button.disabled=not State.can_hire_worker()
	var values=[State.wood,State.coins,State.damage(),State.passive_rate()]
	for i in range(4):
		resource_values[i].text=num(values[i],i==3)
		resource_values[i].tooltip_text=("%.2f"%values[i]).replace(".",",")
	goal_label.text=State.next_goal()
	var sum_levels=0
	for l in State.buildings: sum_levels+=l
	progress_label.text="%d / 18"%sum_levels
	tree_name.text=State.TREES[State.tree_kind].name+"  ·  +%s drewna"%num(State.tree_reward(),true)
	tree_lore.text=State.TREES[State.tree_kind].lore
	hp_bar.max_value=State.TREES[State.tree_kind].hp
	hp_bar.value=State.tree_hp
	hit_label.text="Nowe drzewo…" if State.respawn>0 else "%d / %d"%[ceil(State.tree_hp),hp_bar.max_value]
	for i in range(3):
		forest_buttons[i].disabled=not State.tree_unlocked(i)
		forest_buttons[i].tooltip_text=["Zwykłe sosny · 18 wytrzymałości · 6 drewna bazowo","Wymaga tartaku I · 88 wytrzymałości · 42 drewna bazowo","Wymaga latarni I · 420 wytrzymałości · 250 drewna bazowo"][i]
		forest_buttons[i].add_theme_stylebox_override("normal",box(Color("314940") if i==State.tree_kind else Color("1c3230"),C_GOLD if i==State.tree_kind else Color("3c5548"),10))
	half_button.disabled=State.wood<2
	all_button.disabled=State.wood<1
	half_button.tooltip_text="Otrzymasz %s monet"%num(floor(State.wood/2)*State.sale_price())
	all_button.tooltip_text="Otrzymasz %s monet"%num(floor(State.wood)*State.sale_price())
	sale_label.text=("%.2f monety / szt."%State.sale_price()).replace(".",",")
	var c=State.building_cost(selected)
	reserve_label.text="%s: zachowaj %s drewna na kolejny poziom."%[State.BUILDINGS[selected].short,num(c[0])] if State.buildings[selected]<3 else "Drewno z ułamków zostaje w magazynie."
	event_button.visible=State.event_window>0 or State.boost_left>0
	event_button.disabled=State.boost_left>0
	event_button.text="Dobry szept · +50%% drewna · %ds"%ceil(State.boost_left) if State.boost_left>0 else "Szept boru · przyjmij dar (%ds)"%ceil(State.event_window)
	for i in range(6):
		var card=build_cards[i]
		var level=State.buildings[i]
		card.level.text="POZIOM %s / III"%State.roman(level)
		card.texture.texture=load("res://assets/building_%d_%d.png"%[i,maxi(1,level)])
		card.bonus.text=("Po ulepszeniu: " if level>0 and level<3 else "")+State.BUILDINGS[i].bonuses[mini(level,2)]
		if i==0: card.bonus.text+=" · miejsca dla dodatkowych: %d"%[3,8,16][mini(level,2)]
		var req=State.requirements_text(i)
		card.req.text="Wymaga: "+req if not req.is_empty() else ("Osada dziękuje za ten dom." if level>=3 else "Wymagania spełnione")
		card.req.add_theme_color_override("font_color",Color("bb9c88") if not req.is_empty() else C_MUTED)
		var cost=State.building_cost(i)
		card.buy.text="Poziom III · ukończono" if level>=3 else "%s · %s drewna + %s monet"%["Buduj" if level==0 else "Ulepsz",num(cost[0]),num(cost[1])]
		card.buy.disabled=not State.can_build(i)
		card.card.add_theme_stylebox_override("panel",box(Color("1c3430") if selected==i else Color("172d2c"),Color("8c9f76") if selected==i else Color("344c44"),12))
	for i in range(3):
		var card=upgrade_cards[i]
		var level=State.upgrade_level(i)
		var cap=State.upgrade_cap(i)
		card.level.text="Poziom %d / %d"%[level,cap]
		card.bonus.text=State.upgrade_bonus(i) if level<cap else "Osiągnięto dostępny poziom."
		card.buy.text="Ulepsz · %s monet"%num(State.upgrade_cost(i)) if level<cap else "Maksymalny poziom"
		card.buy.disabled=level>=cap or State.coins<State.upgrade_cost(i)
		card.req.text="Rozbuduj kuźnię, by odblokować silniejsze ostrze." if i==0 and level>=cap and cap<16 else ["Mocniejsze ostrze ścina szybciej.","Każdy cios może być krytyczny.","Więcej drewna z każdego drzewa i od drwali."][i]
	var text="Ścięte drzewa: %s\nZebrane drewno: %s\nCzas przy ognisku: %s\nSzansa na krytyk: %d%%\n\n"%[num(State.total_trees),num(State.total_wood),duration(State.play_time),round(State.crit_chance()*100)]
	text+="Przybyliśmy tu z jedną siekierą. Pod mchami znaleźliśmy kamień, a na nim znak podobny do rozgałęzionego drzewa.\n"
	for i in range(6):
		if State.buildings[i]>0: text+="\n"+State.BUILDINGS[i].name+"\n"+State.BUILDINGS[i].lore+"\n"
	if State.completed: text+="\nLatarnia płonie. Coś w głębi lasu zamknęło oczy. Możesz spokojnie zostać na polanie."
	lore_content.text=text

func show_toast(text: String):
	if toast==null: return
	toast.text=text
	toast_left=7

func open_modal(title: String):
	space_held=false
	for child in modal_content.get_children():
		modal_content.remove_child(child)
		child.queue_free()
	var heading=label(title,25,C_GOLD,true)
	heading.add_theme_font_override("font",TITLE_FONT)
	modal_content.add_child(heading)
	overlay.visible=true

func close_modal():
	overlay.visible=false
	if not testing: State.save_game()

func show_help():
	open_modal("Witaj na polanie")
	modal_content.add_child(label("1. Klikaj drzewo lub przytrzymaj Spację, by je ścinać.\n2. Sprzedawaj drewno za monety. Część zachowaj na domy.\n3. W zakładce Narzędzia ulepszaj siekierę, krytyk i uzysk.\n4. Zbuduj chatę — drwale zaczną zbierać drewno sami. W panelu Osada zatrudnij dodatkowych za monety; rozbudowa chaty daje więcej miejsc.\n5. Tartak otwiera prastary las, a latarnia — Spaczony Bór.\n6. Rozbuduj wszystkie domy i doprowadź latarnię do III poziomu.",15,C_TEXT,true))
	modal_content.add_child(label("Kliknięcie parceli wybiera budynek. Jego cena i brakujące wymagania są pokazane w panelu Osada. Bonusy budynku podają łączny efekt danego poziomu.",14,C_MUTED,true))
	modal_content.add_child(label("Postęp zapisuje się co 10 sekund i po zakupach. Drwale pracują podczas nieobecności do 8 godzin. Szept boru jest opcjonalnym prezentem — nic nie tracisz, jeśli go pominiesz.\n\nEsc: ustawienia / zamknij okno  ·  F11: pełny ekran",14,C_MUTED,true))
	modal_content.add_child(button("Wracam do lasu",close_modal))

func show_settings():
	open_modal("Przy ogniu")
	for i in range(2):
		var row=hbox(modal_content)
		var l=label("Muzyka" if i==0 else "Efekty i odgłosy lasu",15)
		l.custom_minimum_size.x=195
		row.add_child(l)
		var slider=HSlider.new()
		slider.min_value=0
		slider.max_value=100
		slider.step=1
		slider.value=(State.music_volume if i==0 else State.effects_volume)*100
		slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.x=150
		slider.value_changed.connect(func(value):
			if i==0: State.music_volume=value/100.0
			else: State.effects_volume=value/100.0
			Sound.apply_settings())
		row.add_child(slider)
		var mute=CheckButton.new()
		mute.text="Wycisz"
		mute.button_pressed=State.music_muted if i==0 else State.effects_muted
		mute.toggled.connect(func(on):
			if i==0: State.music_muted=on
			else: State.effects_muted=on
			Sound.apply_settings())
		row.add_child(mute)
	var reduce=CheckButton.new()
	reduce.text="Spokojniejsze animacje (mniej ruchu i wiórów)"
	reduce.button_pressed=State.reduced_motion
	reduce.toggled.connect(func(on): State.reduced_motion=on)
	modal_content.add_child(reduce)
	modal_content.add_child(label("Zapis jest przechowywany na tym urządzeniu. Niczego nie musisz zakładać ani instalować w grze.",14,C_MUTED,true))
	modal_content.add_child(button("Zapisz i wróć do gry",close_modal))
	var reset=button("Rozpocznij nową osadę…",confirm_reset)
	reset.add_theme_color_override("font_color",Color("d7a899"))
	modal_content.add_child(reset)

func confirm_reset():
	open_modal("Opuścić tę osadę?")
	modal_content.add_child(label("Usuniesz cały postęp: drewno, monety, ulepszenia i budynki. Tej decyzji nie można cofnąć. Ustawienia dźwięku zostaną zachowane.",15,C_TEXT,true))
	modal_content.add_child(button("Zostaję · zachowaj postęp",close_modal))
	modal_content.add_child(button("Tak, usuń postęp i zacznij od nowa",func():
		State.reset_game()
		world.fall_time=0
		world.particles.clear()
		world.floats.clear()
		selected=0
		world.selected_building=-1
		close_modal()
		show_tab(0)
		update_ui()
		show_toast("Nowa polana. Jedna siekiera. Wszystko jeszcze przed nami.")))

func show_offline():
	open_modal("Ogień jeszcze nie zgasł")
	modal_content.add_child(label("Drwale pracowali przez %s.\nW magazynie czeka dodatkowe drewno."%duration(State.offline_report.seconds),16,C_TEXT,true))
	modal_content.add_child(label("+%s drewna"%num(State.offline_report.wood),32,C_GREEN))
	modal_content.add_child(label("Uwzględniono maksymalnie 8 godzin. Chwilowe szepty nie działają podczas nieobecności.",13,C_MUTED,true))
	modal_content.add_child(button("Dobrze znów tu być",close_modal))

func show_ending():
	open_modal("Światło zostało z nami")
	Sound.play("win")
	modal_content.add_child(label("Latarnia sięgnęła ponad czubki sosen. Na chwilę las ucichł — jakby ktoś bardzo stary zamknął oczy.\n\nW karczmie ktoś stawia na stole chleb. W kuźni stygnie żelazo. To już dom.",17,C_TEXT,true))
	modal_content.add_child(label("Osada ukończona: 18 / 18 poziomów\nŚcięte drzewa: %s\nCzas w grze: %s"%[num(State.total_trees),duration(State.play_time)],15,C_GREEN,true))
	modal_content.add_child(button("Zostaję na polanie · graj dalej",close_modal))

func _notification(what):
	if not ui_ready or testing: return
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		State.save_game()
		get_tree().quit()
	elif what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		space_held=false
		focused_out_at=Time.get_unix_time_from_system()
		focused_out_play_time=State.play_time
		State.save_game()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN and focused_out_at>0:
		var now=Time.get_unix_time_from_system()
		var already_simulated=maxf(0.0,State.play_time-focused_out_play_time)
		var missing=maxf(0.0,now-focused_out_at-already_simulated)
		focused_out_at=0.0
		if missing>1.0:
			State.last_seen=now-missing
			State.grant_offline(now)
			State.save_game()
			if missing>30 and State.offline_report.wood>0: show_offline()
	elif what==NOTIFICATION_APPLICATION_PAUSED:
		State.save_game()

static func num(value: float,decimal=false) -> String:
	if value>=1000000: return ("%.2f mln"%(value/1000000)).replace(".",",")
	if value>=10000: return ("%.1f tys."%(value/1000)).replace(".",",")
	if decimal and value<1000: return ("%.1f"%value).replace(".",",")
	var s=str(int(floor(value)))
	if s.length()>3: s=s.substr(0,s.length()-3)+" "+s.right(3)
	return s

static func duration(seconds: float) -> String:
	var mins=int(seconds/60)
	return "%d godz. %d min"%[mins/60,mins%60] if mins>=60 else "%d min %d s"%[mins,int(seconds)%60]
