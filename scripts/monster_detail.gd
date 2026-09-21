extends Control

var monster_index: int = 0
var title_label: Label
var stats_label: Label
var xp_bar: ProgressBar
var rank_label: Label
var rank_button: Button
var status: Label
var skills_box: VBoxContainer

func _ready() -> void:
    monster_index = clampi(GameState.selected_monster, 0, maxi(0, GameState.monsters.size() - 1))
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
    root.position = Vector2(70, 28)
    root.size = Vector2(1140, 664)
    root.add_theme_constant_override("separation", 12)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 68)
    root.add_child(header)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)

    title_label = _label("", 29)
    title_box.add_child(title_label)

    var sub := _label("Monster progression", 13)
    sub.modulate = Color("#9fb0c8")
    title_box.add_child(sub)

    rank_label = _label("", 20)
    rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(rank_label)

    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    columns.add_theme_constant_override("separation", 14)
    root.add_child(columns)

    var left := _panel()
    left.custom_minimum_size = Vector2(440, 0)
    columns.add_child(left)

    var left_root := VBoxContainer.new()
    left_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    left_root.offset_left = 18
    left_root.offset_top = 18
    left_root.offset_right = -18
    left_root.offset_bottom = -18
    left_root.add_theme_constant_override("separation", 10)
    left.add_child(left_root)

    stats_label = _label("", 16)
    stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    left_root.add_child(stats_label)

    xp_bar = ProgressBar.new()
    xp_bar.custom_minimum_size = Vector2(0, 26)
    xp_bar.show_percentage = true
    left_root.add_child(xp_bar)

    var feed_title := _label("FEED MONSTER", 17)
    left_root.add_child(feed_title)

    var feed_row := HBoxContainer.new()
    left_root.add_child(feed_row)

    for amount in [1, 5, 10]:
        var button := _button("Feed ×%d" % amount, 118)
        button.pressed.connect(_feed.bind(amount))
        feed_row.add_child(button)

    var rank_title := _label("RANK", 17)
    left_root.add_child(rank_title)

    rank_button = _button("", 300)
    rank_button.pressed.connect(_rank_up)
    left_root.add_child(rank_button)

    status = _label("", 12)
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.modulate = Color("#82d5ff")
    left_root.add_child(status)

    var right := _panel()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(right)

    var right_root := VBoxContainer.new()
    right_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    right_root.offset_left = 18
    right_root.offset_top = 18
    right_root.offset_right = -18
    right_root.offset_bottom = -18
    right_root.add_theme_constant_override("separation", 8)
    right.add_child(right_root)

    right_root.add_child(_label("ABILITIES", 20))

    skills_box = VBoxContainer.new()
    skills_box.add_theme_constant_override("separation", 7)
    right_root.add_child(skills_box)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var previous := _button("Previous", 120)
    previous.pressed.connect(_previous)
    footer.add_child(previous)

    var back := _button("Return to Island", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

    var next := _button("Next", 120)
    next.pressed.connect(_next)
    footer.add_child(next)

func _refresh() -> void:
    if GameState.monsters.is_empty():
        return
    monster_index = clampi(monster_index, 0, GameState.monsters.size() - 1)
    var monster: Dictionary = GameState.monsters[monster_index]
    var data: Dictionary = MonsterDatabase.get_monster(str(monster.get("id", "")))

    title_label.text = "%s  •  %s" % [monster.get("nickname", "Monster"), data.get("name", "Unknown")]
    rank_label.text = _stars(int(monster.get("rank", 1)))

    stats_label.text = "Level %d / 50\nElement: %s\nRarity: %s\nHP: %d\nATK: %d" % [
        int(monster.get("level", 1)),
        data.get("element", "Unknown"),
        data.get("rarity", "Unknown"),
        int(monster.get("hp", 0)),
        int(monster.get("attack", 0))
    ]

    var level := int(monster.get("level", 1))
    xp_bar.max_value = GameState.xp_to_next_level(level) if level < 50 else 1
    xp_bar.value = int(monster.get("xp", 0)) if level < 50 else 1
    xp_bar.tooltip_text = "XP: %d / %d" % [int(monster.get("xp", 0)), GameState.xp_to_next_level(level)] if level < 50 else "MAX LEVEL"

    var rank := int(monster.get("rank", 1))
    if rank >= 5:
        rank_button.text = "MAX RANK ★★★★★"
        rank_button.disabled = true
    else:
        var cost: Dictionary = GameState.rank_upgrade_cost(monster)
        var required := GameState.rank_level_requirement(rank)
        rank_button.text = "Upgrade to %s  •  Lv.%d required  •  %d Gold + %d Food" % [
            _stars(rank + 1),
            required,
            int(cost["gold"]),
            int(cost["food"])
        ]
        rank_button.disabled = not GameState.can_rank_up(monster_index)

    _refresh_skills(str(monster.get("id", "")))

func _refresh_skills(monster_id: String) -> void:
    for child in skills_box.get_children():
        child.queue_free()
    for skill in MonsterDatabase.get_skills(monster_id):
        var card := _panel()
        card.custom_minimum_size = Vector2(0, 68)
        skills_box.add_child(card)

        var box := VBoxContainer.new()
        box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        box.offset_left = 10
        box.offset_top = 8
        box.offset_right = -10
        box.offset_bottom = -8
        card.add_child(box)

        var title := _label(
            "%s  •  x%.1f" % [str(skill.get("name", "Skill")), float(skill.get("power", 1.0))],
            15
        )
        box.add_child(title)

        var detail := _label(
            "%s • Cooldown %d • %s" % [
                str(skill.get("element", "Neutral")),
                int(skill.get("cooldown", 0)),
                "Recovery" if str(skill.get("kind", "")) == "heal_self" else "Damage"
            ],
            11
        )
        detail.modulate = Color("#a9bad1")
        box.add_child(detail)

func _feed(amount: int) -> void:
    if GameState.feed_monster(monster_index, amount):
        _show_status("Fed %s ×%d." % [GameState.monsters[monster_index].get("nickname", "Monster"), amount])

func _rank_up() -> void:
    GameState.rank_up_monster(monster_index)

func _previous() -> void:
    if GameState.monsters.is_empty():
        return
    monster_index = posmod(monster_index - 1, GameState.monsters.size())
    GameState.selected_monster = monster_index
    _refresh()

func _next() -> void:
    if GameState.monsters.is_empty():
        return
    monster_index = posmod(monster_index + 1, GameState.monsters.size())
    GameState.selected_monster = monster_index
    _refresh()

func _stars(rank: int) -> String:
    var text := ""
    for i in 5:
        text += "★" if i < rank else "☆"
    return text

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
