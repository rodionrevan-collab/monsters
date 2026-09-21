extends Control

var item_list: VBoxContainer
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
    root.position = Vector2(38, 22)
    root.size = Vector2(1204, 678)
    root.add_theme_constant_override("separation", 12)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 68)
    root.add_child(header)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)
    title_box.add_child(_label("BUILDING SHOP", 29))
    var subtitle := _label("Buy habitats, farms and production buildings for the current island.", 13)
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
    scroll.offset_left = 14
    scroll.offset_top = 14
    scroll.offset_right = -14
    scroll.offset_bottom = -14
    panel.add_child(scroll)

    item_list = VBoxContainer.new()
    item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    item_list.add_theme_constant_override("separation", 8)
    scroll.add_child(item_list)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var back := _button("Return to Island", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

func _refresh() -> void:
    if not item_list:
        return
    for child in item_list.get_children():
        child.queue_free()

    var items: Dictionary = BuildingCatalog.all_items()
    for item_id in items.keys():
        var item: Dictionary = items[item_id]
        var card := _panel()
        card.custom_minimum_size = Vector2(0, 104)
        item_list.add_child(card)

        var row := HBoxContainer.new()
        row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        row.offset_left = 12
        row.offset_top = 10
        row.offset_right = -12
        row.offset_bottom = -10
        row.add_theme_constant_override("separation", 12)
        card.add_child(row)

        var icon := _label(_item_icon(str(item.get("type", ""))), 30)
        icon.custom_minimum_size = Vector2(52, 0)
        row.add_child(icon)

        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)

        info.add_child(_label(str(item.get("name", item_id)), 17))
        var element_text := str(item.get("element", ""))
        if element_text.is_empty():
            element_text = "Utility"
        info.add_child(_label(
            "%s • Lv.%d • %d Gold" % [
                element_text,
                int(item.get("level", 1)),
                int(item.get("cost", 0))
            ],
            11
        ))
        info.add_child(_label(str(item.get("description", "")), 12))

        var buy := _button("Build", 100)
        buy.disabled = not GameState.can_build_item(str(item_id))
        buy.pressed.connect(_buy.bind(str(item_id)))
        row.add_child(buy)

    var slots := _label(
        "Current island: %s • Building slots: %d / %d" % [
            GameState.current_island_name(),
            GameState.island_building_slots_used(),
            GameState.island_building_slots_max()
        ],
        13
    )
    slots.modulate = Color("#82d5ff")
    item_list.add_child(slots)

func _buy(item_id: String) -> void:
    if not GameState.build_item(item_id):
        _show_status("Unable to build that item.")

func _item_icon(type: String) -> String:
    match type:
        "habitat":
            return "◆"
        "farm":
            return "♣"
        "gold_mine":
            return "◈"
        _:
            return "■"

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
