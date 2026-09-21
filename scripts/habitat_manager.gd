extends Control

var monster_list: VBoxContainer
var habitat_list: VBoxContainer
var status: Label

func _ready() -> void:
    _build_ui()
    GameState.state_changed.connect(_refresh)
    GameState.log_message.connect(_show_status)
    _refresh()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#0a101d")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := VBoxContainer.new()
    root.position = Vector2(26, 20)
    root.size = Vector2(1228, 680)
    root.add_theme_constant_override("separation", 12)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 64)
    root.add_child(header)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)

    var title := _label("HABITAT MANAGEMENT", 27)
    title_box.add_child(title)
    var subtitle := _label("Place compatible monsters into habitats. Capacity and elements matter.", 13)
    subtitle.modulate = Color("#9fb0c8")
    title_box.add_child(subtitle)

    status = _label("", 13)
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(status)

    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    columns.add_theme_constant_override("separation", 14)
    root.add_child(columns)

    var habitats_panel := _panel()
    habitats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(habitats_panel)

    var habitats_root := VBoxContainer.new()
    habitats_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    habitats_root.offset_left = 14
    habitats_root.offset_top = 12
    habitats_root.offset_right = -14
    habitats_root.offset_bottom = -12
    habitats_root.add_theme_constant_override("separation", 8)
    habitats_panel.add_child(habitats_root)

    habitats_root.add_child(_label("YOUR HABITATS", 20))

    var habitat_scroll := ScrollContainer.new()
    habitat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    habitats_root.add_child(habitat_scroll)

    habitat_list = VBoxContainer.new()
    habitat_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    habitat_list.add_theme_constant_override("separation", 8)
    habitat_scroll.add_child(habitat_list)

    var monster_panel := _panel()
    monster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(monster_panel)

    var monster_root := VBoxContainer.new()
    monster_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    monster_root.offset_left = 14
    monster_root.offset_top = 12
    monster_root.offset_right = -14
    monster_root.offset_bottom = -12
    monster_root.add_theme_constant_override("separation", 8)
    monster_panel.add_child(monster_root)

    monster_root.add_child(_label("MONSTERS", 20))
    monster_root.add_child(_label("Pick a monster, then choose its compatible habitat.", 12))

    var monster_scroll := ScrollContainer.new()
    monster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    monster_root.add_child(monster_scroll)

    monster_list = VBoxContainer.new()
    monster_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    monster_list.add_theme_constant_override("separation", 7)
    monster_scroll.add_child(monster_list)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var back := _button("Return to Island", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

func _refresh() -> void:
    _refresh_habitats()
    _refresh_monsters()
    _show_status("Select a monster to see valid habitats.")

func _refresh_habitats() -> void:
    if not habitat_list:
        return
    for child in habitat_list.get_children():
        child.queue_free()

    for i in GameState.habitats.size():
        var habitat: Dictionary = GameState.habitats[i]
        var card := _panel()
        card.custom_minimum_size = Vector2(0, 150)
        habitat_list.add_child(card)

        var root := VBoxContainer.new()
        root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        root.offset_left = 10
        root.offset_top = 9
        root.offset_right = -10
        root.offset_bottom = -9
        root.add_theme_constant_override("separation", 4)
        card.add_child(root)

        var title := HBoxContainer.new()
        root.add_child(title)

        var name := _label(str(habitat.get("name", "Habitat")), 17)
        name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        title.add_child(name)

        var capacity := GameState.habitat_capacity(i)
        var occupied: Array = habitat.get("monsters", [])
        title.add_child(_label("%d / %d slots" % [occupied.size(), capacity], 13))

        root.add_child(_label("Element: %s" % str(habitat.get("element", "Unknown")), 12))

        var occupants := _label(_occupant_text(occupied), 12)
        occupants.modulate = Color("#a9bad1")
        occupants.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        root.add_child(occupants)

        var empty := _button("Clear Habitat", 130)
        empty.disabled = occupied.is_empty()
        empty.pressed.connect(_clear_habitat.bind(i))
        root.add_child(empty)

func _refresh_monsters() -> void:
    if not monster_list:
        return
    for child in monster_list.get_children():
        child.queue_free()

    for i in GameState.monsters.size():
        var monster: Dictionary = GameState.monsters[i]
        var data: Dictionary = MonsterDatabase.get_monster(str(monster.get("id", "")))
        var current := GameState.habitat_for_monster(i)

        var card := _panel()
        card.custom_minimum_size = Vector2(0, 88)
        monster_list.add_child(card)

        var root := HBoxContainer.new()
        root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        root.offset_left = 10
        root.offset_top = 8
        root.offset_right = -10
        root.offset_bottom = -8
        card.add_child(root)

        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        root.add_child(info)

        info.add_child(_label(str(monster.get("nickname", "Monster")), 15))
        var state := "Unassigned"
        if current != -1:
            state = str(GameState.habitats[current].get("name", "Habitat"))
        var detail := _label("%s • Lv.%d • %s" % [
            str(data.get("element", "Unknown")),
            int(monster.get("level", 1)),
            state
        ], 11)
        detail.modulate = Color("#a9bad1")
        info.add_child(detail)

        for h in GameState.habitats.size():
            var habitat: Dictionary = GameState.habitats[h]
            var button := _button(str(h + 1), 42)
            button.tooltip_text = "Assign to %s" % habitat.get("name", "Habitat")
            button.disabled = not GameState.can_assign_monster(i, h)
            button.pressed.connect(_assign.bind(i, h))
            root.add_child(button)

        var remove := _button("Remove", 74)
        remove.disabled = current == -1
        remove.pressed.connect(_remove.bind(i))
        root.add_child(remove)

func _occupant_text(occupied: Array) -> String:
    if occupied.is_empty():
        return "No monsters assigned."
    var names: Array[String] = []
    for index in occupied:
        if int(index) >= 0 and int(index) < GameState.monsters.size():
            names.append(str(GameState.monsters[int(index)].get("nickname", "Monster")))
    return "Monsters: " + ", ".join(names)

func _assign(monster_index: int, habitat_index: int) -> void:
    if not GameState.assign_monster_to_habitat(monster_index, habitat_index):
        _show_status("That monster cannot live in this habitat.")
    _refresh()

func _remove(monster_index: int) -> void:
    if not GameState.remove_monster_from_habitat(monster_index):
        _show_status("Monster is not assigned to a habitat.")
    _refresh()

func _clear_habitat(habitat_index: int) -> void:
    var occupied: Array = GameState.habitats[habitat_index].get("monsters", [])
    for index in occupied.duplicate():
        GameState.remove_monster_from_habitat(int(index))
    _refresh()

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
    button.custom_minimum_size = Vector2(width, 36)
    return button

func _panel() -> PanelContainer:
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#151f31")
    style.border_color = Color("#27354c")
    style.set_border_width_all(1)
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    panel.add_theme_stylebox_override("panel", style)
    return panel
