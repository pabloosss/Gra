extends Control
class_name DiceView

var value: int = 20
var face_color := Color("20263d")
var edge_color := Color("c6d3ff")
var line_color := Color("59658a")

func set_value(new_value: int) -> void:
    value = clampi(new_value, 1, 20)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    var radius := minf(size.x, size.y) * 0.43
    var points := PackedVector2Array()

    for i in range(10):
        var angle := -PI * 0.5 + TAU * float(i) / 10.0
        var local_radius := radius if i % 2 == 0 else radius * 0.78
        points.append(center + Vector2(cos(angle), sin(angle)) * local_radius)

    draw_colored_polygon(points, face_color)

    var border := points.duplicate()
    border.append(points[0])
    draw_polyline(border, edge_color, 3.0, true)

    for i in range(0, 10, 2):
        draw_line(center, points[i], line_color, 1.0, true)

    var font := ThemeDB.fallback_font
    var font_size := 30
    var text := str(value)
    var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
    var pos := Vector2(center.x - text_size.x * 0.5, center.y + text_size.y * 0.35)
    draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
