extends Control
class_name MonsterAvatar

var monster_id: String = ""
var element: String = "Nature"
var rarity: String = "Common"
var accent := Color("#7acb7a")
var body_color := Color("#5a9b62")

func setup(p_id: String, p_element: String, p_rarity: String) -> void:
    monster_id = p_id
    element = p_element
    rarity = p_rarity
    _set_palette()
    queue_redraw()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(64, 64)

func _set_palette() -> void:
    match element:
        "Fire":
            accent = Color("#ff835c")
            body_color = Color("#c94f3e")
        "Water":
            accent = Color("#6bbfff")
            body_color = Color("#3979b9")
        "Air":
            accent = Color("#d5e7ff")
            body_color = Color("#8397bf")
        "Nature":
            accent = Color("#91e08b")
            body_color = Color("#4f9860")
        _:
            accent = Color("#c0c7d4")
            body_color = Color("#737b8e")

func _draw() -> void:
    var center := size * 0.5
    var radius := min(size.x, size.y) * 0.43

    draw_circle(center, radius, Color("#0d1726"))
    draw_arc(center, radius, 0.0, TAU, 40, accent, 3.0)

    var body_center := center + Vector2(0, 5)
    var body_radius := radius * 0.68

    if rarity == "Epic":
        var spikes := PackedVector2Array()
        for i in 8:
            var a := TAU * float(i) / 8.0
            spikes.append(body_center + Vector2(cos(a), sin(a)) * body_radius * 1.08)
        draw_colored_polygon(spikes, body_color)
    elif rarity == "Rare":
        draw_circle(body_center, body_radius, body_color)
    else:
        draw_circle(body_center, body_radius * 0.9, body_color)

    var eye_y := body_center.y - body_radius * 0.12
    var eye_dx := body_radius * 0.28
    draw_circle(Vector2(body_center.x - eye_dx, eye_y), 4.0, Color.WHITE)
    draw_circle(Vector2(body_center.x + eye_dx, eye_y), 4.0, Color.WHITE)
    draw_circle(Vector2(body_center.x - eye_dx + 1, eye_y + 1), 1.8, Color("#111827"))
    draw_circle(Vector2(body_center.x + eye_dx + 1, eye_y + 1), 1.8, Color("#111827"))

    var mouth_left := body_center + Vector2(-body_radius * 0.2, body_radius * 0.34)
    var mouth_right := body_center + Vector2(body_radius * 0.2, body_radius * 0.34)
    draw_line(mouth_left, mouth_right, Color("#1a2230"), 2.0)

    if element == "Fire":
        draw_circle(body_center + Vector2(0, -body_radius * 0.82), body_radius * 0.16, accent)
    elif element == "Water":
        draw_circle(body_center + Vector2(0, -body_radius * 0.82), body_radius * 0.14, accent)
        draw_circle(body_center + Vector2(body_radius * 0.45, -body_radius * 0.65), body_radius * 0.08, accent)
    elif element == "Air":
        draw_arc(body_center + Vector2(0, -body_radius * 0.2), body_radius * 0.9, PI, TAU, 16, accent, 2.0)
    elif element == "Nature":
        draw_line(
            body_center + Vector2(-body_radius * 0.5, -body_radius * 0.75),
            body_center + Vector2(-body_radius * 0.85, -body_radius * 1.05),
            accent,
            3.0
        )

    if rarity == "Epic":
        draw_arc(center, radius * 0.84, 0.2, 2.0, 18, Color.WHITE, 1.5)
