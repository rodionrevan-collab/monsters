extends Control

var status: Label
var egg_panel: VBoxContainer
var timer_label: Label

func _process(_delta: float) -> void:
    _refresh_timer()

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
    root.position = Vector2(80, 50)
    root.size = Vector2(1120, 620)
    root.add_theme_constant_override("separation", 14)
    add_child(root)

    var title := _label("INCUBATOR", 32)
    root.add_child(title)

    var subtitle := _label("Breed eggs, wait for incubation, then hatch new monsters.", 14)
    subtitle.modulate = Color("#9fb0c8")
    root.add_child(subtitle)

    var panel := _panel()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(panel)

    egg_panel = VBoxContainer.new()
    egg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    egg_panel.offset_left = 24
    egg_panel.offset_top = 24
    egg_panel.offset_right = -24
    egg_panel.offset_bottom = -24
    egg_panel.add_theme_constant_override("separation", 12)
    panel.add_child(egg_panel)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var hatch := _button("Hatch Now", 150)
    hatch.pressed.connect(_hatch)
    footer.add_child(hatch)

    var back := _button("Return to Island", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

    status = _label("", 13)
    status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    footer.add_child(status)

func _refresh() -> void:
    if not egg_panel:
        return

    for child in egg_panel.get_children():
        child.queue_free()

    if GameState.incubating.is_empty():
        egg_panel.add_child(_label("INCUBATOR EMPTY", 26))
        var hint := _label("Breed two compatible monsters from the island to create an egg.", 14)
        hint.modulate = Color("#9fb0c8")
        egg_panel.add_child(hint)
        return

    var monster_id := str(GameState.incubating.get("monster_id", ""))
    var data: Dictionary = MonsterDatabase.get_monster(monster_id)
    var remaining := _remaining_text(int(GameState.incubating.get("ready_at", 0)))

    egg_panel.add_child(_label("EGG READYING", 22))
    egg_panel.add_child(_label(str(data.get("name", "Unknown Egg")), 30))
    egg_panel.add_child(_label("Rarity: %s" % str(data.get("rarity", "Unknown")), 15))
    egg_panel.add_child(_label("Element: %s" % str(data.get("element", "Unknown")), 15))
    timer_label = _label("", 18)
    egg_panel.add_child(timer_label)

    var lore := _label(str(data.get("lore", "")), 13)
    lore.modulate = Color("#a9bad1")
    lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    egg_panel.add_child(lore)

func _refresh_timer() -> void:
    if not timer_label or GameState.incubating.is_empty():
        return
    timer_label.text = "Hatch timer: %s" % _remaining_text(int(GameState.incubating.get("ready_at", 0)))

func _hatch() -> void:
    if not GameState.claim_incubation():
        _show_status("The egg is not ready yet.")
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
