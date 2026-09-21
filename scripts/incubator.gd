extends Control

var status: Label
var incubator_grid: GridContainer
var egg_list: VBoxContainer

func _ready() -> void:
    _build_ui()
    GameState.state_changed.connect(_refresh)
    GameState.log_message.connect(_show_status)
    _refresh()

func _process(_delta: float) -> void:
    _refresh_timers()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#0a101d")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := VBoxContainer.new()
    root.position = Vector2(28, 22)
    root.size = Vector2(1224, 678)
    root.add_theme_constant_override("separation", 12)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 66)
    root.add_child(header)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)
    title_box.add_child(_label("INCUBATOR & EGG COLLECTION", 28))
    var subtitle := _label("Three incubators can hatch eggs while new eggs wait in your collection.", 13)
    subtitle.modulate = Color("#9fb0c8")
    title_box.add_child(subtitle)

    status = _label("", 13)
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(status)

    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    columns.add_theme_constant_override("separation", 12)
    root.add_child(columns)

    var incubators_panel := _panel()
    incubators_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(incubators_panel)

    var incubators_root := VBoxContainer.new()
    incubators_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    incubators_root.offset_left = 14
    incubators_root.offset_top = 14
    incubators_root.offset_right = -14
    incubators_root.offset_bottom = -14
    incubators_root.add_theme_constant_override("separation", 8)
    incubators_panel.add_child(incubators_root)
    incubators_root.add_child(_label("INCUBATORS", 20))

    incubator_grid = GridContainer.new()
    incubator_grid.columns = 1
    incubator_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    incubator_grid.add_theme_constant_override("v_separation", 8)
    incubators_root.add_child(incubator_grid)

    var eggs_panel := _panel()
    eggs_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(eggs_panel)

    var eggs_root := VBoxContainer.new()
    eggs_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    eggs_root.offset_left = 14
    eggs_root.offset_top = 14
    eggs_root.offset_right = -14
    eggs_root.offset_bottom = -14
    eggs_root.add_theme_constant_override("separation", 8)
    eggs_panel.add_child(eggs_root)

    eggs_root.add_child(_label("EGG COLLECTION", 20))

    var eggs_scroll := ScrollContainer.new()
    eggs_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    eggs_root.add_child(eggs_scroll)

    egg_list = VBoxContainer.new()
    egg_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    egg_list.add_theme_constant_override("separation", 7)
    eggs_scroll.add_child(egg_list)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var back := _button("Return to Island", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

func _refresh() -> void:
    _refresh_incubators()
    _refresh_eggs()

func _refresh_incubators() -> void:
    if not incubator_grid:
        return

    for child in incubator_grid.get_children():
        child.queue_free()

    for i in GameState.incubators.size():
        var slot: Dictionary = GameState.incubators[i]
        var card := _panel()
        card.custom_minimum_size = Vector2(0, 120)
        incubator_grid.add_child(card)

        var box := VBoxContainer.new()
        box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        box.offset_left = 10
        box.offset_top = 8
        box.offset_right = -10
        box.offset_bottom = -8
        box.add_theme_constant_override("separation", 4)
        card.add_child(box)

        var title_row := HBoxContainer.new()
        box.add_child(title_row)
        var title := _label("INCUBATOR %d" % (i + 1), 16)
        title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        title_row.add_child(title)

        if slot.is_empty():
            box.add_child(_label("Empty • load an egg from the collection.", 12))
        else:
            var id := str(slot.get("monster_id", ""))
            var data: Dictionary = MonsterDatabase.get_monster(id)
            box.add_child(_label("%s • %s • %s" % [
                data.get("name", id),
                data.get("rarity", "Unknown"),
                data.get("element", "Unknown")
            ], 13))

            var timer := _label("", 12)
            timer.name = "IncubationTimer"
            timer.set_meta("ready_at", int(slot.get("ready_at", 0)))
            box.add_child(timer)

            var hatch := _button("Hatch", 100)
            hatch.disabled = GameState.incubation_time_left(i) > 0 and not GameState.developer_mode
            hatch.pressed.connect(_hatch.bind(i))
            box.add_child(hatch)

func _refresh_eggs() -> void:
    if not egg_list:
        return

    for child in egg_list.get_children():
        child.queue_free()

    if GameState.egg_inventory.is_empty():
        egg_list.add_child(_label("No eggs waiting.", 14))
        return

    for i in GameState.egg_inventory.size():
        var egg: Dictionary = GameState.egg_inventory[i]
        var id := str(egg.get("monster_id", ""))
        var data: Dictionary = MonsterDatabase.get_monster(id)

        var row := _panel()
        row.custom_minimum_size = Vector2(0, 88)
        egg_list.add_child(row)

        var box := HBoxContainer.new()
        box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        box.offset_left = 10
        box.offset_top = 8
        box.offset_right = -10
        box.offset_bottom = -8
        row.add_child(box)

        var avatar: MonsterAvatar = preload("res://scripts/monster_avatar.gd").new()
        avatar.setup(id, str(data.get("element", "Nature")), str(data.get("rarity", "Common")))
        avatar.custom_minimum_size = Vector2(64, 64)
        box.add_child(avatar)

        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        box.add_child(info)
        info.add_child(_label(str(data.get("name", id)), 15))
        info.add_child(_label("%s • %s" % [data.get("rarity", "Unknown"), data.get("element", "Unknown")], 11))

        var parents: Array = egg.get("parents", [])
        info.add_child(_label("Parents: %s + %s" % [
            parents[0] if parents.size() > 0 else "?",
            parents[1] if parents.size() > 1 else "?"
        ], 10))

        for incubator_index in GameState.incubators.size():
            var load_button := _button("Load %d" % (incubator_index + 1), 70)
            load_button.disabled = not GameState.incubators[incubator_index].is_empty()
            load_button.pressed.connect(_load_egg.bind(i, incubator_index))
            box.add_child(load_button)

func _refresh_timers() -> void:
    if not incubator_grid:
        return

    for card in incubator_grid.get_children():
        for node in card.find_children("IncubationTimer", "Label", true, false):
            var target := int(node.get_meta("ready_at", 0))
            node.text = "Time: %s" % _remaining_text(target)

func _load_egg(egg_index: int, incubator_index: int) -> void:
    if not GameState.load_egg_to_incubator(egg_index, incubator_index):
        _show_status("That incubator is already occupied.")

func _hatch(index: int) -> void:
    if not GameState.claim_incubation(index):
        _show_status("That incubator is not ready yet.")
    else:
        _show_status("Monster hatched!")

func _remaining_text(target: int) -> String:
    if GameState.developer_mode:
        return "READY"
    var left := maxi(0, target - int(Time.get_unix_time_from_system()))
    return "%02d:%02d" % [left / 60, left % 60]

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
