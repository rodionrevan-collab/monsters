extends Control

var slots_box: HBoxContainer
var monster_list: VBoxContainer
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
    title_box.add_child(_label("BATTLE TEAM", 29))
    var subtitle := _label("Choose up to three monsters for campaign battles.", 13)
    subtitle.modulate = Color("#9fb0c8")
    title_box.add_child(subtitle)

    status = _label("", 13)
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(status)

    var team_panel := _panel()
    team_panel.custom_minimum_size = Vector2(0, 150)
    root.add_child(team_panel)

    slots_box = HBoxContainer.new()
    slots_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    slots_box.offset_left = 14
    slots_box.offset_top = 12
    slots_box.offset_right = -14
    slots_box.offset_bottom = -12
    slots_box.add_theme_constant_override("separation", 10)
    team_panel.add_child(slots_box)

    var collection_panel := _panel()
    collection_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(collection_panel)

    var collection_scroll := ScrollContainer.new()
    collection_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    collection_scroll.offset_left = 12
    collection_scroll.offset_top = 12
    collection_scroll.offset_right = -12
    collection_scroll.offset_bottom = -12
    collection_panel.add_child(collection_scroll)

    monster_list = VBoxContainer.new()
    monster_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    monster_list.add_theme_constant_override("separation", 7)
    collection_scroll.add_child(monster_list)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size = Vector2(0, 44)
    root.add_child(footer)

    var battle := _button("Campaign", 140)
    battle.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Campaign.tscn"))
    footer.add_child(battle)

    var back := _button("Return to Island", 180)
    back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
    footer.add_child(back)

func _refresh() -> void:
    _refresh_slots()
    _refresh_monsters()

func _refresh_slots() -> void:
    if not slots_box:
        return
    for child in slots_box.get_children():
        child.queue_free()

    for slot in 3:
        var index := int(GameState.battle_team[slot]) if slot < GameState.battle_team.size() else -1
        var card := _panel()
        card.custom_minimum_size = Vector2(0, 120)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        slots_box.add_child(card)

        var box := VBoxContainer.new()
        box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        box.offset_left = 10
        box.offset_top = 8
        box.offset_right = -10
        box.offset_bottom = -8
        card.add_child(box)

        box.add_child(_label("SLOT %d" % (slot + 1), 13))

        if index >= 0 and index < GameState.monsters.size():
            var monster: Dictionary = GameState.monsters[index]
            var data: Dictionary = MonsterDatabase.get_monster(str(monster.get("id", "")))
            box.add_child(_label(str(monster.get("nickname", "Monster")), 16))
            box.add_child(_label(
                "Lv.%d • %s • HP %d • ATK %d" % [
                    int(monster.get("level", 1)),
                    data.get("element", "Unknown"),
                    int(monster.get("hp", 0)),
                    int(monster.get("attack", 0))
                ],
                11
            ))
            var remove := _button("Remove", 90)
            remove.pressed.connect(_remove_slot.bind(slot))
            box.add_child(remove)
        else:
            box.add_child(_label("Empty", 16))
            box.add_child(_label("Choose a monster below.", 11))

func _refresh_monsters() -> void:
    if not monster_list:
        return
    for child in monster_list.get_children():
        child.queue_free()

    var selected := GameState.valid_battle_team()
    for i in GameState.monsters.size():
        var monster: Dictionary = GameState.monsters[i]
        var data: Dictionary = MonsterDatabase.get_monster(str(monster.get("id", "")))

        var card := _panel()
        card.custom_minimum_size = Vector2(0, 76)
        monster_list.add_child(card)

        var row := HBoxContainer.new()
        row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        row.offset_left = 10
        row.offset_top = 8
        row.offset_right = -10
        row.offset_bottom = -8
        card.add_child(row)

        var avatar: MonsterAvatar = preload("res://scripts/monster_avatar.gd").new()
        avatar.setup(str(monster.get("id", "")), str(data.get("element", "Nature")), str(data.get("rarity", "Common")))
        avatar.custom_minimum_size = Vector2(58, 58)
        row.add_child(avatar)

        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        info.add_child(_label(str(monster.get("nickname", "Monster")), 15))
        info.add_child(_label(
            "Lv.%d • Rank %d • %s • HP %d • ATK %d" % [
                int(monster.get("level", 1)),
                int(monster.get("rank", 1)),
                data.get("element", "Unknown"),
                int(monster.get("hp", 0)),
                int(monster.get("attack", 0))
            ],
            11
        ))

        if selected.has(i):
            info.add_child(_label("Already in team.", 10))
        else:
            for slot in 3:
                if int(GameState.battle_team[slot]) == -1:
                    var add := _button("Add to Slot %d" % (slot + 1), 115)
                    add.pressed.connect(_add_to_slot.bind(slot, i))
                    row.add_child(add)
                    break

func _add_to_slot(slot: int, monster_index: int) -> void:
    if GameState.set_battle_slot(slot, monster_index):
        _show_status("Added %s to team." % GameState.monsters[monster_index].get("nickname", "Monster"))

func _remove_slot(slot: int) -> void:
    GameState.clear_battle_slot(slot)

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
    button.custom_minimum_size = Vector2(width, 38)
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
