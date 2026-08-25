extends Node2D

const BG := preload("res://assets/tavern_storm.png")
const PORTRAIT := preload("res://assets/companion_placeholder.png")
const DiceViewScript := preload("res://scripts/dice_view.gd")
const CompanionBrainScript := preload("res://scripts/companion_brain.gd")

const SCREEN := Vector2(640, 360)
const PREVIEW := Rect2(12, 12, 616, 182)
const DIALOG := Rect2(12, 202, 616, 146)

var rng := RandomNumberGenerator.new()
var rain_phase := 0.0
var window_phase := 0.0
var portrait_phase := 0.0
var next_lightning := 2.5

var companion
var dialogue_speaker: Label
var dialogue_text: Label
var choices_box: VBoxContainer
var player_stats_text: Label
var companion_stats_text: Label
var portrait_texture: TextureRect
var flash_rect: ColorRect
var dice_overlay: Control
var dice_view: Control
var dice_title: Label
var dice_details: Label

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.randomize()
	companion = CompanionBrainScript.new()
	_build_ui()
	_refresh_stats()
	_show_intro()
	queue_redraw()

func _process(delta: float) -> void:
	rain_phase += delta * 85.0
	window_phase += delta * 3.0
	portrait_phase += delta * 3.0
	next_lightning -= delta
	if portrait_texture:
		portrait_texture.modulate.a = 0.95 + (sin(portrait_phase) + 1.0) * 0.025
	if next_lightning <= 0.0:
		_trigger_lightning()
		next_lightning = rng.randf_range(4.0, 8.0)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("0b0f1a"), true)
	draw_rect(PREVIEW, Color("111728"), true)
	draw_texture_rect(BG, PREVIEW, false)
	_draw_glows()
	_draw_rain()

func _draw_glows() -> void:
	var glow := Color(1.0, 0.58, 0.18, 0.08 + (sin(window_phase) + 1.0) * 0.025)
	var sx := PREVIEW.size.x / 640.0
	var sy := PREVIEW.size.y / 360.0
	for r in [Rect2(135,188,34,31), Rect2(251,187,31,33), Rect2(375,179,17,21)]:
		var rr := Rect2(PREVIEW.position + r.position * Vector2(sx, sy), r.size * Vector2(sx, sy))
		draw_rect(rr.grow(4), glow, true)

func _draw_rain() -> void:
	for i in range(105):
		var x := PREVIEW.position.x + fmod(float(i * 73) + rain_phase * 2.1, PREVIEW.size.x + 60.0) - 20.0
		var y := PREVIEW.position.y + fmod(float(i * 41) + rain_phase * 3.8, PREVIEW.size.y + 60.0) - 20.0
		draw_line(Vector2(x, y), Vector2(x - 4, y + 11), Color(0.63, 0.74, 0.91, 0.48), 1.0, true)

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)

	flash_rect = ColorRect.new()
	flash_rect.color = Color(0.86, 0.91, 1.0, 0.0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(flash_rect)

	_build_portrait(root)
	_build_dialog_panel(root)
	_build_dice_overlay(root)

func _build_portrait(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(22, 22)
	panel.size = Vector2(124, 164)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.05, 0.09, 0.92), Color("8b7497"), 2))
	root.add_child(panel)

	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var title := Label.new()
	title.text = "MIRA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color("efd3f8"))
	box.add_child(title)

	portrait_texture = TextureRect.new()
	portrait_texture.texture = PORTRAIT
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_texture.custom_minimum_size = Vector2(96, 100)
	portrait_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.add_child(portrait_texture)

	var hint := Label.new()
	hint.text = "placeholder\nportret / gif"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color("b8bfd7"))
	box.add_child(hint)

func _build_dialog_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = DIALOG.position
	panel.size = DIALOG.size
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.04, 0.065, 0.96), Color("7f8bad"), 2))
	root.add_child(panel)

	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(m, 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	margin.add_child(content)

	dialogue_speaker = Label.new()
	dialogue_speaker.add_theme_font_size_override("font_size", 12)
	dialogue_speaker.add_theme_color_override("font_color", Color("e6b970"))
	content.add_child(dialogue_speaker)

	dialogue_text = Label.new()
	dialogue_text.custom_minimum_size = Vector2(0, 42)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size", 11)
	dialogue_text.add_theme_color_override("font_color", Color("edf0fa"))
	content.add_child(dialogue_text)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)

	var actions_col := VBoxContainer.new()
	actions_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_col.add_theme_constant_override("separation", 4)
	row.add_child(actions_col)

	var actions_title := Label.new()
	actions_title.text = "AKCJE"
	actions_title.add_theme_font_size_override("font_size", 10)
	actions_title.add_theme_color_override("font_color", Color("aab8df"))
	actions_col.add_child(actions_title)

	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 4)
	actions_col.add_child(choices_box)

	var stats_col := VBoxContainer.new()
	stats_col.custom_minimum_size = Vector2(176, 0)
	stats_col.add_theme_constant_override("separation", 6)
	row.add_child(stats_col)

	var stats_title := Label.new()
	stats_title.text = "STATYSTYKI"
	stats_title.add_theme_font_size_override("font_size", 10)
	stats_title.add_theme_color_override("font_color", Color("aab8df"))
	stats_col.add_child(stats_title)

	player_stats_text = _make_stats_card(stats_col, "POSTAĆ", Color("8aa0d0"))
	companion_stats_text = _make_stats_card(stats_col, "TOWARZYSZ", Color("d8a5d5"))

func _make_stats_card(parent: VBoxContainer, title: String, accent: Color) -> Label:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.10, 0.16, 0.95), accent, 1))
	parent.add_child(card)

	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(m, 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 10)
	heading.add_theme_color_override("font_color", accent)
	box.add_child(heading)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 10)
	body.add_theme_color_override("font_color", Color("edf0fa"))
	box.add_child(body)
	return body

func _build_dice_overlay(root: Control) -> void:
	dice_overlay = Control.new()
	dice_overlay.visible = false
	dice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	dice_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dice_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.02, 0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dice_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(210, 62)
	panel.size = Vector2(220, 236)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("101423"), Color("a8b7df"), 3))
	dice_overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	dice_title = Label.new()
	dice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_title.add_theme_font_size_override("font_size", 14)
	dice_title.add_theme_color_override("font_color", Color("e6b970"))
	box.add_child(dice_title)

	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, 125)
	box.add_child(holder)

	dice_view = DiceViewScript.new()
	dice_view.custom_minimum_size = Vector2(118, 118)
	holder.add_child(dice_view)

	dice_details = Label.new()
	dice_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_details.add_theme_font_size_override("font_size", 12)
	dice_details.add_theme_color_override("font_color", Color("dfe5fb"))
	box.add_child(dice_details)

func _show_intro() -> void:
	_set_dialogue("NARRATOR", "Burza rozrywa niebo nad wzgórzem. Na górze widzisz samotną karczmę. Mira spogląda na ciebie spod mokrego kaptura i czeka, co zrobisz dalej.")
	_clear_choices()
	_add_choice("[PERSWAZJA %+d] Przekonaj karczmarza.  DC 13" % GameState.charisma, _choice_persuasion)
	_add_choice("[PERCEPCJA %+d] Obejrzyj teren.  DC 11" % GameState.perception, _choice_perception)
	_add_choice("Zapytaj Mirę, co o tym myśli.", _choice_companion)

func _choice_persuasion() -> void:
	_run_check("PERSWAZJA", GameState.charisma, 13, _after_persuasion)

func _choice_perception() -> void:
	_run_check("PERCEPCJA", GameState.perception, 11, _after_perception)

func _choice_companion() -> void:
	_set_dialogue(companion.companion_name.to_upper(), companion.react("storm_tavern"))
	_clear_choices()
	_add_choice("Wróć do decyzji.", _show_intro)

func _after_persuasion(_roll: int, _total: int, success: bool) -> void:
	if success:
		companion.remember("keeper_let_us_in")
		_set_dialogue("KARCZMARZ", "Dobra, właźcie szybko! Jeszcze mi piorun drzwi wyłamie. Ale broni nie wyciągać przy gościach.")
		_clear_choices()
		_add_choice("Wejdź do karczmy.", _enter_tavern)
		_add_choice("Sprawdź jeszcze teren.", _choice_perception)
	else:
		_set_dialogue("KARCZMARZ", "Nie znam was. Nie otwieram. Idźcie szukać szczęścia gdzie indziej!")
		_clear_choices()
		_add_choice("Zapytaj Mirę.", _companion_after_failed_persuasion)
		_add_choice("Spróbuj rozejrzeć się wokół.", _choice_perception)

func _after_perception(_roll: int, _total: int, success: bool) -> void:
	if success:
		companion.remember("spotted_tracks")
		_set_dialogue("NARRATOR", "W błocie dostrzegasz świeże ślady trzech osób. Prowadzą od lasu do bocznego wejścia karczmy. Ktoś próbował zatrzeć je gałęzią.")
		_clear_choices()
		_add_choice("Powiedz o tym Mirze.", _choice_companion)
		_add_choice("Podejdź do bocznego wejścia.", _side_door)
		_add_choice("Wróć pod główne drzwi.", _show_intro)
	else:
		_set_dialogue("NARRATOR", "Deszcz zmył większość śladów. Widzisz tylko błoto, mokre kamienie i kołyszący się szyld karczmy.")
		_clear_choices()
		_add_choice("Zapytaj Mirę.", _choice_companion)
		_add_choice("Wróć pod drzwi.", _show_intro)

func _companion_after_failed_persuasion() -> void:
	_set_dialogue(companion.companion_name.to_upper(), companion.react("failed_persuasion"))
	_clear_choices()
	_add_choice("Wróć do decyzji.", _show_intro)

func _enter_tavern() -> void:
	_set_dialogue("NARRATOR", "Drzwi ustępują z ciężkim skrzypnięciem. Uderza w was ciepło paleniska, zapach mokrej wełny i pieczonego mięsa. To koniec pierwszej sceny prototypu.")
	_clear_choices()
	_add_choice("Zapytaj Mirę o wejście.", _companion_after_success)
	_add_choice("Zagraj scenę od początku.", _show_intro)

func _companion_after_success() -> void:
	_set_dialogue(companion.companion_name.to_upper(), companion.react("passed_persuasion"))
	_refresh_stats()
	_clear_choices()
	_add_choice("Zagraj scenę od początku.", _show_intro)

func _side_door() -> void:
	_set_dialogue("NARRATOR", "Boczne drzwi są uchylone o szerokość palca. Z wnętrza dobiega krótki metaliczny stuk, jakby ktoś właśnie odłożył ostrze na stół.")
	_clear_choices()
	_add_choice("[PERCEPCJA %+d] Nasłuchuj.  DC 11" % GameState.perception, _choice_perception)
	_add_choice("Wycofaj się do Miry.", _choice_companion)

func _run_check(skill: String, bonus: int, dc: int, callback: Callable) -> void:
	_clear_choices()
	var roll := rng.randi_range(1, 20)
	var total := roll + bonus
	await _animate_d20(skill, roll, bonus, dc)
	callback.call(roll, total, total >= dc)

func _animate_d20(skill: String, final_roll: int, bonus: int, dc: int) -> void:
	dice_overlay.visible = true
	dice_title.text = skill + "  •  D20"
	dice_details.text = "Rzut..."
	dice_view.rotation = 0.0
	dice_view.scale = Vector2.ONE

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dice_view, "rotation", TAU * 2.4, 0.68).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(dice_view, "scale", Vector2(1.18, 1.18), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	for i in range(10):
		dice_view.set_value(rng.randi_range(1, 20))
		await get_tree().create_timer(0.055 + float(i) * 0.006).timeout

	dice_view.set_value(final_roll)
	dice_view.scale = Vector2.ONE
	dice_view.rotation = 0.0

	var total := final_roll + bonus
	var verdict := "SUKCES" if total >= dc else "PORAŻKA"
	var bonus_text := "+%d" % bonus if bonus >= 0 else str(bonus)
	dice_details.text = "%d  %s  =  %d   |   DC %d   •   %s" % [final_roll, bonus_text, total, dc, verdict]

	await get_tree().create_timer(0.9).timeout
	dice_overlay.visible = false

func _trigger_lightning() -> void:
	flash_rect.color.a = 0.35
	var tween := create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.07)
	tween.tween_callback(func(): flash_rect.color.a = 0.18)
	tween.tween_property(flash_rect, "color:a", 0.0, 0.12)

func _set_dialogue(speaker: String, text: String) -> void:
	dialogue_speaker.text = speaker
	dialogue_text.text = text

func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()

func _add_choice(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 20)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", Color("eef1ff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color("171d30"), Color("475574")))
	button.add_theme_stylebox_override("hover", _button_style(Color("222c47"), Color("8aa0d0")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("111625"), Color("d4b46e")))
	button.pressed.connect(callback)
	choices_box.add_child(button)

func _panel_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style

func _refresh_stats() -> void:
	player_stats_text.text = "%s • %s\nHP: %d/%d\nPerswazja: %+d\nPercepcja: %+d" % [GameState.player_name, GameState.class_name, GameState.hp, GameState.max_hp, GameState.charisma, GameState.perception]
	companion_stats_text.text = "Imię: %s\nRelacja: %d\nNastrój: %s" % [companion.companion_name, companion.relation, companion.mood.capitalize()]
