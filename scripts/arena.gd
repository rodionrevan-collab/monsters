extends Control

var list: VBoxContainer
var status: Label
var rating: Label

func _ready() -> void:
    _build_ui()
    GameState.state_changed.connect(_refresh)
    GameState.log_message.connect(_show_status)
    _refresh()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#090f1b")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := VBoxContainer.new()
    root.position = Vector2(38, 22)
    root.size = Vector2(1204, 678)
    root.add_theme_constant_override("separation", 12)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 72)
    root.add_child(header)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)
    title_box.add_child(_label("ARENA", 30))
    var subtitle := _label("Fight AI champions, earn trophies and climb the arena ladder.", 13)
    subtitle.modulate = Color("#9fb0c8")
    title_box.add_child(subtitle)

    rating = _label("", 18)
    rating.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(rating)

    var panel := _panel()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(panel)

    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 14
    scroll.offset_top = 14
    scroll.offset_right = -14
    scroll.offset_bottom = -14
    panel.add_child(scroll)

    list = VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 8)
    scroll.add_child(list)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var team := _button("Battle Team", 150)
    team.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Team.tscn"))
    footer.add_child(team)

    var back := _button("Return to Island", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

    status = _label("", 13)
    status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    footer.add_child(status)

func _refresh() -> void:
    if rating:
        rating.text = "%d Trophies   •   W %d / L %d" % [
            GameState.arena_trophies,
            GameState.arena_wins,
            GameState.arena_losses
        ]

    if not list:
        return
    for child in list.get_children():
        child.queue_free()

    var opponents := GameState.arena_opponents()
    for i in opponents.size():
        var opponent: Dictionary = opponents[i]
        var required := int(opponent.get("trophies", 0))
        var unlocked := GameState.can_enter_arena(i)

        var card := _panel()
        card.custom_minimum_size = Vector2(0, 118)
        list.add_child(card)

        var row := HBoxContainer.new()
        row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        row.offset_left = 12
        row.offset_top = 10
        row.offset_right = -12
        row.offset_bottom = -10
        row.add_theme_constant_override("separation", 10)
        card.add_child(row)

        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        info.add_child(_label(str(opponent.get("name", "Opponent")), 18))
        info.add_child(_label("Requires %d trophies" % required, 11))
        var team_text := ""
        for unit in opponent.get("team", []):
            if not team_text.is_empty():
                team_text += "  •  "
            team_text += "%s [%s]" % [unit.get("name", "Monster"), unit.get("element", "Unknown")]
        info.add_child(_label(team_text, 11))

        var fight := _button("Fight", 110)
        fight.disabled = not unlocked
        fight.text = "Locked" if not unlocked else "Fight"
        fight.pressed.connect(_fight.bind(i))
        row.add_child(fight)

func _fight(index: int) -> void:
    if not GameState.start_arena(index):
        _show_status("You need more trophies or a valid battle team.")
        return
    get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _show_status(message: String) -> void:
    if status:
        status.text = message

func _label(text: String, size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", size)
    return label

func _button(text: String, width: int) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(width, 40)
    return button

func _panel() -> PanelContainer:
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#151f31")
    style.border_color = Color("#27354c")
    style.set_border_width_all(1)
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    panel.add_theme_stylebox_override("panel", style)
    return panel
