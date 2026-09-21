extends Control

var list: VBoxContainer
var stats: Label

func _ready() -> void:
    _build_ui()
    _refresh()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#0a101d")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := VBoxContainer.new()
    root.position = Vector2(32, 22)
    root.size = Vector2(1216, 678)
    root.add_theme_constant_override("separation", 12)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 68)
    root.add_child(header)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)

    var title := _label("MONSTER BOOK", 28)
    title_box.add_child(title)

    var subtitle := _label("Discovered species, elements, rarity and lore.", 13)
    subtitle.modulate = Color("#9fb0c8")
    title_box.add_child(subtitle)

    stats = _label("", 15)
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(stats)

    var panel := _panel()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(panel)

    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 12
    scroll.offset_top = 12
    scroll.offset_right = -12
    scroll.offset_bottom = -12
    panel.add_child(scroll)

    list = VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 8)
    scroll.add_child(list)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var back := _button("Return to Island", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

func _refresh() -> void:
    if not list:
        return

    for child in list.get_children():
        child.queue_free()

    var all: Dictionary = MonsterDatabase.all_monsters()
    var discovered := 0

    for monster_id in all.keys():
        var data: Dictionary = all[monster_id]
        var found := _is_discovered(str(monster_id))
        if found:
            discovered += 1

        var row := _panel()
        row.custom_minimum_size = Vector2(0, 86)
        list.add_child(row)

        var box := HBoxContainer.new()
        box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        box.offset_left = 12
        box.offset_top = 9
        box.offset_right = -12
        box.offset_bottom = -9
        row.add_child(box)

        var icon := Label.new()
        icon.text = "★" if found else "?"
        icon.custom_minimum_size = Vector2(40, 0)
        icon.add_theme_font_size_override("font_size", 24)
        box.add_child(icon)

        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        box.add_child(info)

        var name_label := _label(
            "%s  •  %s  •  %s" % [
                str(data.get("name", "Unknown")),
                str(data.get("rarity", "Unknown")),
                str(data.get("element", "Unknown"))
            ] if found else "Undiscovered Species",
            17
        )
        info.add_child(name_label)

        var lore := _label(
            str(data.get("lore", "No entry yet.")) if found else "Breed or hatch this monster to unlock its entry.",
            11
        )
        lore.modulate = Color("#a9bad1")
        lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        info.add_child(lore)

        if found:
            var stats_label := _label(_monster_stats(str(monster_id)), 11)
            stats_label.modulate = Color("#8298b4")
            info.add_child(stats_label)

    if stats:
        stats.text = "Discovered %d / %d" % [discovered, all.size()]

func _is_discovered(monster_id: String) -> bool:
    for monster in GameState.monsters:
        if str(monster.get("id", "")) == monster_id:
            return true
    return false

func _monster_stats(monster_id: String) -> String:
    var best_level := 0
    var count := 0
    for monster in GameState.monsters:
        if str(monster.get("id", "")) == monster_id:
            count += 1
            best_level = maxi(best_level, int(monster.get("level", 1)))
    var skills: Array[Dictionary] = MonsterDatabase.get_skills(monster_id)
    return "Owned %d • Highest Lv.%d • Skills: %s, %s, %s, %s" % [
        count,
        best_level,
        skills[0]["name"],
        skills[1]["name"],
        skills[2]["name"],
        skills[3]["name"]
    ]

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
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    panel.add_theme_stylebox_override("panel", style)
    return panel
