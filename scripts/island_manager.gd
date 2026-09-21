extends Control

var island_list: VBoxContainer
var status: Label

func _ready() -> void:
    _build_ui()
    GameState.state_changed.connect(_refresh)
    GameState.log_message.connect(_show_status)
    _refresh()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#07111c")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := VBoxContainer.new()
    root.position = Vector2(42, 28)
    root.size = Vector2(1196, 664)
    root.add_theme_constant_override("separation", 12)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 72)
    root.add_child(header)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)

    title_box.add_child(_label("ISLANDS", 30))
    var subtitle := _label("Expand your world and give every elemental family its own home.", 13)
    subtitle.modulate = Color("#9fb0c8")
    title_box.add_child(subtitle)

    status = _label("", 13)
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(status)

    var panel := _panel()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(panel)

    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 16
    scroll.offset_top = 16
    scroll.offset_right = -16
    scroll.offset_bottom = -16
    panel.add_child(scroll)

    island_list = VBoxContainer.new()
    island_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    island_list.add_theme_constant_override("separation", 10)
    scroll.add_child(island_list)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var back := _button("Return to Island", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

func _refresh() -> void:
    if not island_list:
        return

    for child in island_list.get_children():
        child.queue_free()

    for i in GameState.islands.size():
        var island: Dictionary = GameState.islands[i]
        var card := _panel()
        card.custom_minimum_size = Vector2(0, 150)
        island_list.add_child(card)

        var row := HBoxContainer.new()
        row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        row.offset_left = 14
        row.offset_top = 12
        row.offset_right = -14
        row.offset_bottom = -12
        row.add_theme_constant_override("separation", 12)
        card.add_child(row)

        var art := ColorRect.new()
        art.custom_minimum_size = Vector2(120, 120)
        art.color = _island_color(i)
        row.add_child(art)

        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)

        var name := _label(str(island.get("name", "Island")), 20)
        info.add_child(name)

        info.add_child(_label("Theme: %s" % str(island.get("theme", "Unknown")), 12))
        info.add_child(_label("Habitats: %d" % island.get("habitats", []).size(), 12))
        info.add_child(_label(
            "Current island" if i == GameState.selected_island else (
                "Unlocked" if bool(island.get("unlocked", false)) else "Locked"
            ),
            12
        ))

        var action := _button("", 180)
        if i == GameState.selected_island:
            action.text = "CURRENT ISLAND"
            action.disabled = true
        elif bool(island.get("unlocked", false)):
            action.text = "Travel Here"
            action.pressed.connect(_travel.bind(i))
        else:
            action.text = "Unlock — %d Gold" % GameState.island_unlock_cost(i)
            action.disabled = not GameState.can_unlock_island(i)
            action.pressed.connect(_unlock.bind(i))
        row.add_child(action)

func _unlock(index: int) -> void:
    GameState.unlock_island(index)

func _travel(index: int) -> void:
    GameState.switch_island(index)

func _island_color(index: int) -> Color:
    if index == 1:
        return Color("#1d4d62")
    return Color("#245438")

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
