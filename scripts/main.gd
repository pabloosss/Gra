extends Node2D

const TAVERN_BACKGROUND := preload("res://assets/tavern_storm.png")
const DiceViewScript := preload("res://scripts/dice_view.gd")
const CompanionBrainScript := preload("res://scripts/companion_brain.gd")

var rng := RandomNumberGenerator.new()
var rain_phase := 0.0
var next_lightning := 2.5
var window_phase := 0.0

var dialogue_speaker: Label
var dialogue_text: Label
var choices_box: VBoxContainer
var flash_rect: ColorRect
var dice_overlay: Control
var dice_view: Control
var dice_title: Label
var dice_details: Label
var companion_status: Label
var companion

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    rng.randomize()
    companion = CompanionBrainScript.new()
    _build_ui()
    _show_intro()
    queue_redraw()

func _process(delta: float) -> void:
    rain_phase += delta * 85.0
    window_phase += delta * 3.4
    next_lightning -= delta

    if next_lightning <= 0.0:
        _trigger_lightning()
        next_lightning = rng.randf_range(4.0, 8.0)

    queue_redraw()

func _draw() -> void:
    draw_texture_rect(TAVERN_BACKGROUND, Rect2(0, 0, 640, 360), false)
    _draw_window_flicker()
    _draw_rain()

func _draw_window_flicker() -> void:
    var pulse := 0.08 + (sin(window_phase) + 1.0) * 0.025
    var glow := Color(1.0, 0.57, 0.18, pulse)
    draw_rect(Rect2(135, 188, 34, 31).grow(5), glow)
    draw_rect(Rect2(251, 187, 31, 33).grow(5), glow)
    draw_rect(Rect2(375, 179, 17, 21).grow(4), glow)

func _draw_rain() -> void:
    for i in range(105):
        var x := fmod(float(i * 73) + rain_phase * 2.1, 700.0) - 30.0
        var y := fmod(float(i * 41) + rain_phase * 3.8, 410.0) - 30.0
        draw_line(
            Vector2(x, y),
            Vector2(x - 4.0, y + 11.0),
            Color(0.63, 0.74, 0.91, 0.48),
            1.0,
            true
        )

func _build_ui() -> void:
    var ui := CanvasLayer.new()
    ui.layer = 10
    add_child(ui)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)

    flash_rect = ColorRect.new()
    flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flash_rect.color = Color(0.86, 0.91, 1.0, 0.0)
    flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(flash_rect)

    _build_status_panels(root)
    _build_dialogue_panel(root)
    _build_dice_overlay(root)

func _build_status_panels(root: Control) -> void:
    var player_panel := PanelContainer.new()
    player_panel.position = Vector2(12, 10)
    player_panel.size = Vector2(176, 42)
    player_panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.05, 0.06, 0.10, 0.88), Color("68759c"), 2)
    )
    root.add_child(player_panel)

    var player_label := Label.new()
    player_label.text = "WĘDROWIEC  •  HP 18/18\nCHA +3   PER +2"
    player_label.add_theme_font_size_override("font_size", 11)
    player_label.add_theme_color_override("font_color", Color("e7ebff"))
    player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    player_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    player_panel.add_child(player_label)

    var companion_panel := PanelContainer.new()
    companion_panel.position = Vector2(452, 10)
    companion_panel.size = Vector2(176, 42)
    companion_panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.05, 0.06, 0.10, 0.88), Color("8c6d77"), 2)
    )
    root.add_child(companion_panel)

    companion_status = Label.new()
    companion_status.add_theme_font_size_override("font_size", 11)
    companion_status.add_theme_color_override("font_color", Color("f2e8ec"))
    companion_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    companion_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    companion_panel.add_child(companion_status)
    _refresh_companion_status()

func _build_dialogue_panel(root: Control) -> void:
    var panel := PanelContainer.new()
    panel.anchor_left = 0.03
    panel.anchor_top = 0.61
    panel.anchor_right = 0.97
    panel.anchor_bottom = 0.97
    panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.035, 0.04, 0.065, 0.95), Color("7f8bad"), 2)
    )
    root.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    panel.add_child(margin)

    var columns := HBoxContainer.new()
    columns.add_theme_constant_override("separation", 14)
    margin.add_child(columns)

    var text_column := VBoxContainer.new()
    text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text_column.add_theme_constant_override("separation", 4)
    columns.add_child(text_column)

    dialogue_speaker = Label.new()
    dialogue_speaker.text = "NARRATOR"
    dialogue_speaker.add_theme_font_size_override("font_size", 12)
    dialogue_speaker.add_theme_color_override("font_color", Color("e6b970"))
    text_column.add_child(dialogue_speaker)

    dialogue_text = Label.new()
    dialogue_text.custom_minimum_size = Vector2(0, 76)
    dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
    dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue_text.add_theme_font_size_override("font_size", 12)
    dialogue_text.add_theme_color_override("font_color", Color("edf0fa"))
    text_column.add_child(dialogue_text)

    choices_box = VBoxContainer.new()
    choices_box.custom_minimum_size = Vector2(250, 0)
    choices_box.add_theme_constant_override("separation", 5)
    columns.add_child(choices_box)

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
    panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color("101423"), Color("a8b7df"), 3)
    )
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

    var dice_holder := CenterContainer.new()
    dice_holder.custom_minimum_size = Vector2(0, 125)
    box.add_child(dice_holder)

    dice_view = DiceViewScript.new()
    dice_view.custom_minimum_size = Vector2(118, 118)
    dice_holder.add_child(dice_view)

    dice_details = Label.new()
    dice_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    dice_details.add_theme_font_size_override("font_size", 12)
    dice_details.add_theme_color_override("font_color", Color("dfe5fb"))
    box.add_child(dice_details)

func _show_intro() -> void:
    _set_dialogue(
        "NARRATOR",
        "Burza rozrywa niebo nad wzgórzem. Na szczycie stoi samotna karczma. " +
        "W oknach pali się światło, ale drzwi są zamknięte. Mira spogląda na ciebie spod mokrego kaptura."
    )
    _clear_choices()
    _add_choice("[PERSWAZJA +3] Przekonaj karczmarza.  DC 13", _choice_persuasion)
    _add_choice("[PERCEPCJA +2] Obejrzyj teren.  DC 11", _choice_perception)
    _add_choice("Zapytaj Mirę, co o tym myśli.", _choice_companion)

func _choice_persuasion() -> void:
    _run_check("PERSWAZJA", 3, 13, _after_persuasion)

func _choice_perception() -> void:
    _run_check("PERCEPCJA", 2, 11, _after_perception)

func _choice_companion() -> void:
    _set_dialogue(companion.companion_name.to_upper(), companion.react("storm_tavern"))
    _clear_choices()
    _add_choice("Wróć do decyzji.", _show_intro)

func _after_persuasion(_roll: int, _total: int, success: bool) -> void:
    if success:
        companion.remember("keeper_let_us_in")
        _set_dialogue(
            "KARCZMARZ",
            "Dobra, właźcie szybko! Jeszcze mi piorun drzwi wyłamie. Ale broni nie wyciągać przy gościach."
        )
        _clear_choices()
        _add_choice("Wejdź do karczmy.", _enter_tavern)
        _add_choice("Sprawdź jeszcze teren.", _choice_perception)
    else:
        _set_dialogue(
            "KARCZMARZ",
            "Nie znam was. Nie otwieram. Idźcie szukać szczęścia gdzie indziej!"
        )
        _clear_choices()
        _add_choice("Zapytaj Mirę.", _companion_after_failed_persuasion)
        _add_choice("Spróbuj rozejrzeć się wokół.", _choice_perception)

func _after_perception(_roll: int, _total: int, success: bool) -> void:
    if success:
        companion.remember("spotted_tracks")
        _set_dialogue(
            "NARRATOR",
            "W błocie dostrzegasz świeże ślady trzech osób. Prowadzą od lasu do bocznego wejścia karczmy. " +
            "Ktoś próbował zatrzeć je gałęzią."
        )
        _clear_choices()
        _add_choice("Powiedz o tym Mirze.", _choice_companion)
        _add_choice("Podejdź do bocznego wejścia.", _side_door)
        _add_choice("Wróć pod główne drzwi.", _show_intro)
    else:
        _set_dialogue(
            "NARRATOR",
            "Deszcz zmył większość śladów. Widzisz tylko błoto, mokre kamienie i kołyszący się szyld karczmy."
        )
        _clear_choices()
        _add_choice("Zapytaj Mirę.", _choice_companion)
        _add_choice("Wróć pod drzwi.", _show_intro)

func _companion_after_failed_persuasion() -> void:
    _set_dialogue(companion.companion_name.to_upper(), companion.react("failed_persuasion"))
    _clear_choices()
    _add_choice("Wróć do decyzji.", _show_intro)

func _enter_tavern() -> void:
    _set_dialogue(
        "NARRATOR",
        "Drzwi ustępują z ciężkim skrzypnięciem. Uderza w was ciepło paleniska, zapach mokrej wełny " +
        "i pieczonego mięsa. To koniec pierwszej sceny prototypu."
    )
    _clear_choices()
    _add_choice("Zapytaj Mirę o wejście.", _companion_after_success)
    _add_choice("Zagraj scenę od początku.", _show_intro)

func _companion_after_success() -> void:
    _set_dialogue(companion.companion_name.to_upper(), companion.react("passed_persuasion"))
    _refresh_companion_status()
    _clear_choices()
    _add_choice("Zagraj scenę od początku.", _show_intro)

func _side_door() -> void:
    _set_dialogue(
        "NARRATOR",
        "Boczne drzwi są uchylone o szerokość palca. Z wnętrza dobiega krótki metaliczny stuk, " +
        "jakby ktoś właśnie odłożył ostrze na stół."
    )
    _clear_choices()
    _add_choice("[PERCEPCJA +2] Nasłuchuj.  DC 11", _choice_perception)
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
    dice_details.text = "%d  %s  =  %d   |   DC %d   •   %s" % [
        final_roll,
        bonus_text,
        total,
        dc,
        verdict
    ]

    await get_tree().create_timer(0.9).timeout
    dice_overlay.visible = false

func _trigger_lightning() -> void:
    flash_rect.color = Color(0.86, 0.91, 1.0, 0.35)
    var tween := create_tween()
    tween.tween_property(flash_rect, "color:a", 0.0, 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
    tween.tween_interval(0.07)
    tween.tween_callback(_second_lightning_flash)
    tween.tween_property(flash_rect, "color:a", 0.0, 0.12)

func _second_lightning_flash() -> void:
    flash_rect.color.a = 0.18

func _set_dialogue(speaker: String, text: String) -> void:
    dialogue_speaker.text = speaker
    dialogue_text.text = text

func _clear_choices() -> void:
    for child in choices_box.get_children():
        choices_box.remove_child(child)
        child.queue_free()

func _add_choice(text: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(0, 27)
    button.add_theme_font_size_override("font_size", 11)
    button.add_theme_color_override("font_color", Color("eef1ff"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override(
        "normal",
        _button_style(Color("171d30"), Color("475574"))
    )
    button.add_theme_stylebox_override(
        "hover",
        _button_style(Color("222c47"), Color("8aa0d0"))
    )
    button.add_theme_stylebox_override(
        "pressed",
        _button_style(Color("111625"), Color("d4b46e"))
    )
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
    style.content_margin_left = 7
    style.content_margin_right = 7
    return style

func _refresh_companion_status() -> void:
    companion_status.text = "%s  •  RELACJA %d\n%s" % [
        companion.companion_name.to_upper(),
        companion.relation,
        companion.mood.to_upper()
    ]
