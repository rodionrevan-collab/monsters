extends Control

var grid: GridContainer
var info: Label

func _ready() -> void:
    _build_ui()
    _refresh()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#0a101d")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := VBoxContainer.new()
    root.position = Vector2(28, 24)
    root.size = Vector2(1224, 672)
    root.add_theme_constant_override("separation", 14)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 66)
    root.add_child(header)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)

    var title := _label("CAMPAIGN MAP", 28)
    title_box.add_child(title)
    var subtitle := _label("Clear stages, collect rewards and unlock new regions.", 13)
    subtitle.modulate = Color("#9fb0c8")
    title_box.add_child(subtitle)

    info = _label("", 15)
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(info)

    var map_panel := _panel()
    map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(map_panel)

    var map_root := VBoxContainer.new()
    map_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    map_root.offset_left = 20
    map_root.offset_top = 16
    map_root.offset_right = -20
    map_root.offset_bottom = -16
    map_root.add_theme_constant_override("separation", 12)
    map_panel.add_child(map_root)

    var zone_info := _label("GREEN ISLE  •  STAGES 1–10     |     MYSTIC SHOALS  •  11–20     |     VOLCANIC CROWN  •  21–30", 13)
    zone_info.modulate = Color("#9fb0c8")
    map_root.add_child(zone_info)

    grid = GridContainer.new()
    grid.columns = 5
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    map_root.add_child(grid)

    var tip := _label("First victory unlocks the next stage. Completed stages can be replayed for rewards only once.", 12)
    tip.modulate = Color("#8397b3")
    map_root.add_child(tip)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var back := _button("Return to Island", 170)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

func _refresh() -> void:
    if info:
        info.text = "Unlocked: %d / 30    •    Total Stars: %d / 90    •    Island Lv.%d" % [GameState.campaign_stage, _total_stars(), GameState.level]

    if not grid:
        return

    for child in grid.get_children():
        child.queue_free()

    for stage in range(1, 31):
        var button := Button.new()
        button.custom_minimum_size = Vector2(190, 72)

        var unlocked := GameState.is_stage_unlocked(stage)
        var completed := GameState.completed_stages.has(stage)

        var zone := "Green Isle"
        if stage > 20:
            zone = "Volcanic Crown"
        elif stage > 10:
            zone = "Mystic Shoals"

        var stars := ""
        var earned_stars := int(GameState.stage_stars.get(str(stage), 0))
        for star in 3:
            stars += "★" if star < earned_stars else "☆"

        if completed:
            button.text = "✓  Stage %02d\n%s\n%s" % [stage, zone, stars]
        elif unlocked:
            button.text = "▶  Stage %02d\n%s\nREADY" % [stage, zone]
        else:
            button.text = "🔒  Stage %02d\n%s\nLOCKED" % [stage, zone]
            button.disabled = true

        button.pressed.connect(_play_stage.bind(stage))
        grid.add_child(button)

func _total_stars() -> int:
    var total := 0
    for stage in range(1, 31):
        total += int(GameState.stage_stars.get(str(stage), 0))
    return total

func _play_stage(stage: int) -> void:
    if not GameState.is_stage_unlocked(stage):
        return
    GameState.selected_stage = stage
    get_tree().change_scene_to_file("res://scenes/Battle.tscn")

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
