extends Control

var list: VBoxContainer
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
    root.position = Vector2(40, 24)
    root.size = Vector2(1200, 674)
    root.add_theme_constant_override("separation", 12)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 68)
    root.add_child(header)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)
    title_box.add_child(_label("ACHIEVEMENTS", 30))
    var subtitle := _label("Long-term milestones with bonus rewards.", 13)
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

    list = VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 8)
    scroll.add_child(list)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var back := _button("Return to Quests", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Quests.tscn"))
    footer.add_child(back)

func _refresh() -> void:
    if not list:
        return
    for child in list.get_children():
        child.queue_free()

    for achievement in GameState.achievement_definitions():
        var id := str(achievement.get("id", ""))
        var state: Dictionary = GameState.achievement_status(id)

        var card := _panel()
        card.custom_minimum_size = Vector2(0, 94)
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
        info.add_child(_label(str(achievement.get("title", id)), 17))
        info.add_child(_label(str(achievement.get("description", "")), 12))
        var reward_parts: Array[String] = [
            "%d Gold" % int(achievement.get("gold", 0))
        ]
        if int(achievement.get("food", 0)) > 0:
            reward_parts.append("%d Food" % int(achievement.get("food", 0)))
        if int(achievement.get("gems", 0)) > 0:
            reward_parts.append("%d Gems" % int(achievement.get("gems", 0)))
        var progress := _label(
            "%d / %d   •   Reward: %s" % [
                int(state.get("progress", 0)),
                int(state.get("goal", 1)),
                ", ".join(reward_parts)
            ],
            11
        )
        progress.modulate = Color("#a9bad1")
        info.add_child(progress)

        var claim := _button("Claimed" if bool(state.get("claimed", false)) else "Claim", 100)
        claim.disabled = not bool(state.get("completed", false)) or bool(state.get("claimed", false))
        claim.pressed.connect(_claim.bind(id))
        row.add_child(claim)

func _claim(id: String) -> void:
    if GameState.claim_achievement(id):
        _show_status("Achievement reward claimed.")
    else:
        _show_status("Achievement is not ready yet.")

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
