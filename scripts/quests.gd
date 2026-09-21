extends Control

var quest_list: VBoxContainer
var daily_button: Button
var status: Label
var daily_info: Label

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
    header.custom_minimum_size = Vector2(0, 72)
    root.add_child(header)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)
    title_box.add_child(_label("QUESTS & DAILY REWARD", 29))
    var subtitle := _label("Complete objectives through normal play and claim extra resources.", 13)
    subtitle.modulate = Color("#9fb0c8")
    title_box.add_child(subtitle)

    daily_info = _label("", 14)
    daily_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(daily_info)

    var daily_panel := _panel()
    daily_panel.custom_minimum_size = Vector2(0, 110)
    root.add_child(daily_panel)

    var daily_root := HBoxContainer.new()
    daily_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    daily_root.offset_left = 16
    daily_root.offset_top = 12
    daily_root.offset_right = -16
    daily_root.offset_bottom = -12
    daily_panel.add_child(daily_root)

    var daily_text := VBoxContainer.new()
    daily_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    daily_root.add_child(daily_text)
    daily_text.add_child(_label("DAILY LOGIN", 19))
    daily_text.add_child(_label("Seven-day reward cycle. The next day gives a larger reward.", 12))

    daily_button = _button("Claim Daily Reward", 190)
    daily_button.pressed.connect(_claim_daily)
    daily_root.add_child(daily_button)

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

    quest_list = VBoxContainer.new()
    quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    quest_list.add_theme_constant_override("separation", 8)
    scroll.add_child(quest_list)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var back := _button("Return to Island", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

    status = _label("", 13)
    status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    footer.add_child(status)

func _refresh() -> void:
    if daily_button:
        daily_button.disabled = not GameState.daily_reward_available()
        daily_button.text = "Claim Daily Reward" if not daily_button.disabled else "Claimed Today"
    if daily_info:
        daily_info.text = "Streak: %d days" % GameState.daily_reward_streak

    if not quest_list:
        return

    for child in quest_list.get_children():
        child.queue_free()

    for quest in GameState.quest_definitions():
        var quest_id := str(quest.get("id", ""))
        var state: Dictionary = GameState.quest_status(quest_id)
        var card := _panel()
        card.custom_minimum_size = Vector2(0, 94)
        quest_list.add_child(card)

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

        info.add_child(_label(str(quest.get("title", quest_id)), 17))
        info.add_child(_label(str(quest.get("description", "")), 12))

        var progress := _label(
            "Progress: %d / %d    •    Reward: %d Gold + %d Food + %d Gems" % [
                int(state.get("progress", 0)),
                int(state.get("goal", 1)),
                int(quest.get("gold", 0)),
                int(quest.get("food", 0)),
                int(quest.get("gems", 0))
            ],
            11
        )
        progress.modulate = Color("#a9bad1")
        info.add_child(progress)

        var claim := _button("Claim", 95)
        claim.disabled = not bool(state.get("completed", false)) or bool(state.get("claimed", false))
        claim.text = "Claimed" if bool(state.get("claimed", false)) else "Claim"
        claim.pressed.connect(_claim_quest.bind(quest_id))
        row.add_child(claim)

func _claim_daily() -> void:
    if GameState.claim_daily_reward():
        _show_status("Daily reward claimed.")
    else:
        _show_status("Daily reward already claimed.")

func _claim_quest(quest_id: String) -> void:
    if GameState.claim_quest(quest_id):
        _show_status("Quest reward claimed.")
    else:
        _show_status("Quest is not ready yet.")

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
