extends Node2D

const SCREEN := Vector2(640, 360)

const CLASSES := [
	{
		"id": "wojownik", "name": "WOJOWNIK", "hp": 26, "cha": 1, "per": 1,
		"description": "Najtwardszy z bohaterów. Dużo zdrowia, proste rozwiązania i stal pod ręką.",
		"accent": Color("b88b58")
	},
	{
		"id": "lotrzyk", "name": "ŁOTRZYK", "hp": 18, "cha": 2, "per": 3,
		"description": "Szybki, sprytny i uważny. Najlepiej czuje się tam, gdzie inni niczego nie zauważają.",
		"accent": Color("7b96a6")
	},
	{
		"id": "lowca", "name": "ŁOWCA", "hp": 20, "cha": 1, "per": 4,
		"description": "Tropiciel i zwiadowca. Najwyższa percepcja, idealny do odkrywania sekretów.",
		"accent": Color("6f8d58")
	},
	{
		"id": "mag", "name": "MAG", "hp": 14, "cha": 3, "per": 2,
		"description": "Kruchy, ale obdarzony ogromnym potencjałem. Jego słowa i wiedza często otwierają drzwi.",
		"accent": Color("806aa9")
	},
	{
		"id": "kaplan", "name": "KAPŁAN", "hp": 20, "cha": 4, "per": 1,
		"description": "Charyzmatyczny sługa wiary. Najłatwiej przekonuje ludzi i budzi zaufanie.",
		"accent": Color("b8a46a")
	}
]

var selected := 0
var hover_index := -1
var idle_time := 0.0
var fire_time := 0.0

var name_input: LineEdit
var class_name_label: Label
var description_label: Label
var stats_label: Label
var start_button: Button
var hit_buttons: Array[Button] = []

var positions := [
	Vector2(116, 202),
	Vector2(205, 187),
	Vector2(300, 177),
	Vector2(397, 187),
	Vector2(486, 202)
]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_ui()
	_refresh_details()
	queue_redraw()

func _process(delta: float) -> void:
	idle_time += delta
	fire_time += delta * 7.0
	queue_redraw()

func _draw() -> void:
	_draw_background()
	_draw_camp()
	for i in range(CLASSES.size()):
		_draw_character(i)

func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("090a0d"), true)
	draw_rect(Rect2(0, 0, 640, 236), Color("11151a"), true)
	var mountain := PackedVector2Array([
		Vector2(0,150), Vector2(70,95), Vector2(128,135), Vector2(190,72),
		Vector2(248,128), Vector2(330,58), Vector2(390,122), Vector2(465,82),
		Vector2(530,130), Vector2(610,75), Vector2(640,105), Vector2(640,236), Vector2(0,236)
	])
	draw_colored_polygon(mountain, Color("151b20"))
	for x in [38, 548]:
		draw_rect(Rect2(x, 68, 18, 138), Color("26282a"), true)
		draw_rect(Rect2(x + 18, 68, 37, 15), Color("26282a"), true)
		draw_rect(Rect2(x + 47, 68, 10, 58), Color("26282a"), true)
	draw_rect(Rect2(0, 206, 640, 30), Color(0.22, 0.23, 0.24, 0.20), true)

func _draw_camp() -> void:
	draw_rect(Rect2(0, 226, 640, 134), Color("17120e"), true)
	for i in range(42):
		var x := float((i * 83) % 640)
		var y := 228.0 + float((i * 37) % 100)
		draw_rect(Rect2(x, y, 4, 2), Color("2a2118"), true)
	var fire_x := 320.0
	var fire_y := 230.0
	draw_line(Vector2(fire_x - 18, fire_y + 9), Vector2(fire_x + 15, fire_y + 1), Color("69462f"), 5.0)
	draw_line(Vector2(fire_x - 15, fire_y + 1), Vector2(fire_x + 18, fire_y + 9), Color("69462f"), 5.0)
	var flicker := sin(fire_time) * 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(fire_x - 10, fire_y + 4), Vector2(fire_x - 4, fire_y - 16 - flicker),
		Vector2(fire_x + 1, fire_y - 5), Vector2(fire_x + 7, fire_y - 22 + flicker),
		Vector2(fire_x + 11, fire_y + 4)
	]), Color("d76d32"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(fire_x - 5, fire_y + 3), Vector2(fire_x, fire_y - 11 + flicker),
		Vector2(fire_x + 5, fire_y + 3)
	]), Color("efb24b"))

func _draw_character(index: int) -> void:
	var data: Dictionary = CLASSES[index]
	var base: Vector2 = positions[index]
	var bob := sin(idle_time * 2.0 + float(index)) * 1.5
	var p := base + Vector2(0, bob)
	var accent: Color = data["accent"]
	var is_selected := index == selected
	var is_hovered := index == hover_index
	if is_selected:
		draw_circle(p + Vector2(0, 32), 31, Color(accent, 0.18))
		draw_arc(p + Vector2(0, 32), 29, 0, TAU, 32, accent, 2.0)
	elif is_hovered:
		draw_circle(p + Vector2(0, 32), 29, Color(1,1,1,0.06))
	draw_circle(p + Vector2(0, 61), 20, Color(0,0,0,0.45))
	var body_color := accent.lightened(0.04 if is_selected else -0.12)
	var dark := body_color.darkened(0.33)
	var skin := Color("c5a47e")
	draw_rect(Rect2(p.x - 12, p.y + 38, 9, 25), dark, true)
	draw_rect(Rect2(p.x + 3, p.y + 38, 9, 25), dark, true)
	draw_rect(Rect2(p.x - 17, p.y + 3, 34, 39), body_color, true)
	draw_rect(Rect2(p.x - 24, p.y + 8, 7, 29), dark, true)
	draw_rect(Rect2(p.x + 17, p.y + 8, 7, 29), dark, true)
	draw_rect(Rect2(p.x - 10, p.y - 17, 20, 20), skin, true)
	match data["id"]:
		"wojownik":
			draw_rect(Rect2(p.x - 12, p.y - 20, 24, 9), Color("6b6f72"), true)
			draw_rect(Rect2(p.x + 20, p.y + 10, 5, 37), Color("9a9da0"), true)
		"lotrzyk":
			draw_rect(Rect2(p.x - 13, p.y - 22, 26, 15), dark, true)
			draw_line(p + Vector2(-20, 30), p + Vector2(-29, 51), Color("a5a8ab"), 3.0)
		"lowca":
			draw_rect(Rect2(p.x - 12, p.y - 20, 24, 7), Color("554632"), true)
			draw_arc(p + Vector2(20, 22), 23, -1.2, 1.2, 14, Color("7d5d38"), 3.0)
		"mag":
			draw_colored_polygon(PackedVector2Array([
				Vector2(p.x - 15,p.y - 17), Vector2(p.x,p.y - 39), Vector2(p.x + 14,p.y - 17)
			]), dark)
			draw_line(p + Vector2(23, 7), p + Vector2(27, 51), Color("70523a"), 4.0)
			draw_circle(p + Vector2(23, 5), 5, Color("916bc0"))
		"kaplan":
			draw_rect(Rect2(p.x - 12, p.y - 20, 24, 8), Color("d0c18d"), true)
			draw_line(p + Vector2(22, 3), p + Vector2(22, 49), Color("8e784b"), 4.0)
			draw_circle(p + Vector2(22, 0), 5, Color("d7c46f"))
	draw_rect(Rect2(p.x - 6, p.y - 9, 3, 2), Color("e8e1d0"), true)
	draw_rect(Rect2(p.x + 3, p.y - 9, 3, 2), Color("e8e1d0"), true)
	var font := ThemeDB.fallback_font
	var name_text: String = data["name"]
	var tw := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, Vector2(p.x - tw/2.0, p.y + 80), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, accent if is_selected else Color("b9b2a4"))

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var title := Label.new()
	title.text = "WYBIERZ BOHATERA"
	title.position = Vector2(0, 12)
	title.size = Vector2(640, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("d6b36a"))
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Każda klasa rozpoczyna historię z innymi predyspozycjami"
	subtitle.position = Vector2(0, 38)
	subtitle.size = Vector2(640, 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 9)
	subtitle.add_theme_color_override("font_color", Color("9f9a90"))
	root.add_child(subtitle)
	for i in range(CLASSES.size()):
		var button := Button.new()
		button.position = positions[i] + Vector2(-37, -44)
		button.size = Vector2(74, 135)
		button.flat = true
		button.text = ""
		button.mouse_entered.connect(_on_character_hover.bind(i))
		button.mouse_exited.connect(_on_character_exit.bind(i))
		button.pressed.connect(_select_character.bind(i))
		root.add_child(button)
		hit_buttons.append(button)
	_build_details_panel(root)

func _build_details_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 278)
	panel.size = Vector2(604, 70)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("120f0c"), Color("6f5530"), 2))
	root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(320, 0)
	row.add_child(info)
	class_name_label = Label.new()
	class_name_label.add_theme_font_size_override("font_size", 12)
	class_name_label.add_theme_color_override("font_color", Color("e3c37b"))
	info.add_child(class_name_label)
	description_label = Label.new()
	description_label.custom_minimum_size = Vector2(310, 32)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 9)
	description_label.add_theme_color_override("font_color", Color("c8c2b5"))
	info.add_child(description_label)
	stats_label = Label.new()
	stats_label.custom_minimum_size = Vector2(110, 0)
	stats_label.add_theme_font_size_override("font_size", 9)
	stats_label.add_theme_color_override("font_color", Color("d8d0bd"))
	row.add_child(stats_label)
	var controls := VBoxContainer.new()
	controls.custom_minimum_size = Vector2(138, 0)
	controls.add_theme_constant_override("separation", 5)
	row.add_child(controls)
	name_input = LineEdit.new()
	name_input.text = "Wędrowiec"
	name_input.placeholder_text = "Imię bohatera"
	name_input.max_length = 18
	name_input.add_theme_font_size_override("font_size", 9)
	controls.add_child(name_input)
	start_button = Button.new()
	start_button.text = "ROZPOCZNIJ GRĘ"
	start_button.add_theme_font_size_override("font_size", 10)
	start_button.add_theme_color_override("font_color", Color("f5dfaa"))
	start_button.add_theme_stylebox_override("normal", _button_style(Color("352717"), Color("9c7440")))
	start_button.add_theme_stylebox_override("hover", _button_style(Color("4a351c"), Color("d2a55e")))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color("23190f"), Color("e1bd76")))
	start_button.pressed.connect(_start_game)
	controls.add_child(start_button)

func _select_character(index: int) -> void:
	selected = index
	_refresh_details()
	queue_redraw()

func _on_character_hover(index: int) -> void:
	hover_index = index
	queue_redraw()

func _on_character_exit(index: int) -> void:
	if hover_index == index:
		hover_index = -1
	queue_redraw()

func _refresh_details() -> void:
	var data: Dictionary = CLASSES[selected]
	class_name_label.text = data["name"]
	class_name_label.add_theme_color_override("font_color", data["accent"])
	description_label.text = data["description"]
	stats_label.text = "HP      %d\nPERS.   %+d\nPER.    %+d" % [data["hp"], data["cha"], data["per"]]

func _start_game() -> void:
	GameState.set_character(CLASSES[selected], name_input.text)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _panel_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
