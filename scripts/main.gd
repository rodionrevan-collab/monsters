extends Node2D

var selected_a: int = -1
var selected_b: int = -1

var resource_label: Label
var xp_label: Label
var building_grid: GridContainer
var monster_list: VBoxContainer
var breeding_status: Label
var incubation_status: Label
var activity_label: Label
var dev_check: CheckButton
var island_level_label: Label

func _ready() -> void:
    _build_ui()
    GameState.state_changed.connect(_refresh_ui)
    GameState.log_message.connect(_show_log)
    _refresh_ui()
    _show_log("Welcome to Monster Islands.")

func _process(_delta: float) -> void:
    if is_instance_valid(breeding_status) or is_instance_valid(incubation_status):
        _refresh_timers()

func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("#0b1220")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var root := VBoxContainer.new()
    root.position = Vector2(18, 16)
    root.size = Vector2(1244, 688)
    root.add_theme_constant_override("separation", 12)
    add_child(root)

    var header := _make_panel()
    header.custom_minimum_size = Vector2(0, 72)
    root.add_child(header)

    var header_row := HBoxContainer.new()
    header_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    header_row.offset_left = 18
    header_row.offset_right = -18
    header.add_child(header_row)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_row.add_child(title_box)

    var title := _make_label("MONSTER ISLANDS", 28)
    title_box.add_child(title)
    var subtitle := _make_label("Collect • Breed • Grow • Battle", 14)
    subtitle.modulate = Color("#9fb0c8")
    title_box.add_child(subtitle)

    resource_label = _make_label("", 18)
    resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    resource_label.custom_minimum_size = Vector2(430, 0)
    header_row.add_child(resource_label)

    dev_check = CheckButton.new()
    dev_check.text = "DEV"
    dev_check.tooltip_text = "Unlock resources and finish timers instantly."
    dev_check.toggled.connect(_toggle_dev)
    header_row.add_child(dev_check)

    var campaign := _make_button("Campaign", 125)
    campaign.pressed.connect(_open_campaign)
    header_row.add_child(campaign)

    var adventure := _make_button("Quick Battle", 125)
    adventure.pressed.connect(_open_adventure)
    header_row.add_child(adventure)

    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 12)
    root.add_child(body)

    var island_panel := _make_panel()
    island_panel.custom_minimum_size = Vector2(610, 0)
    body.add_child(island_panel)

    var island_root := VBoxContainer.new()
    island_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    island_root.offset_left = 16
    island_root.offset_top = 14
    island_root.offset_right = -16
    island_root.offset_bottom = -14
    island_root.add_theme_constant_override("separation", 10)
    island_panel.add_child(island_root)

    var island_header := HBoxContainer.new()
    island_root.add_child(island_header)
    var island_title := _make_label("YOUR ISLAND", 22)
    island_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    island_header.add_child(island_title)
    island_level_label = _make_label("", 14)
    island_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    island_header.add_child(island_level_label)

    var island_desc := _make_label("Build habitats and farms, then collect their production.", 13)
    island_desc.modulate = Color("#9fb0c8")
    island_root.add_child(island_desc)

    var island_canvas := _make_panel()
    island_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
    island_root.add_child(island_canvas)

    var island_art := ColorRect.new()
    island_art.color = Color("#163b31")
    island_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    island_canvas.add_child(island_art)

    var island_title2 := _make_label("GREEN ISLE", 20)
    island_title2.position = Vector2(20, 16)
    island_art.add_child(island_title2)

    var island_hint := _make_label("Habitat district", 13)
    island_hint.position = Vector2(20, 48)
    island_hint.modulate = Color("#b8d8ca")
    island_art.add_child(island_hint)

    building_grid = GridContainer.new()
    building_grid.columns = 2
    building_grid.position = Vector2(18, 88)
    building_grid.size = Vector2(550, 270)
    building_grid.add_theme_constant_override("h_separation", 10)
    building_grid.add_theme_constant_override("v_separation", 10)
    island_art.add_child(building_grid)

    var island_bottom := HBoxContainer.new()
    island_root.add_child(island_bottom)

    var collect := _make_button("Collect Production", 180)
    collect.pressed.connect(_collect_production)
    island_bottom.add_child(collect)

    var farm := _make_button("Build Farm — 1500", 180)
    farm.pressed.connect(_build_farm)
    island_bottom.add_child(farm)

    var island_note := _make_label("More island slots unlock as progression expands.", 12)
    island_note.modulate = Color("#8aa99c")
    island_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    island_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    island_bottom.add_child(island_note)

    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_theme_constant_override("separation", 12)
    body.add_child(right)

    var monsters_panel := _make_panel()
    monsters_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(monsters_panel)

    var monsters_root := VBoxContainer.new()
    monsters_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    monsters_root.offset_left = 14
    monsters_root.offset_top = 14
    monsters_root.offset_right = -14
    monsters_root.offset_bottom = -14
    monsters_root.add_theme_constant_override("separation", 8)
    monsters_panel.add_child(monsters_root)

    var monsters_header := HBoxContainer.new()
    monsters_root.add_child(monsters_header)

    var monsters_title := _make_label("MONSTER COLLECTION", 21)
    monsters_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    monsters_header.add_child(monsters_title)

    xp_label = _make_label("", 13)
    xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    monsters_header.add_child(xp_label)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    monsters_root.add_child(scroll)

    monster_list = VBoxContainer.new()
    monster_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    monster_list.add_theme_constant_override("separation", 7)
    scroll.add_child(monster_list)

    var breed_panel := _make_panel()
    breed_panel.custom_minimum_size = Vector2(0, 178)
    right.add_child(breed_panel)

    var breed_root := VBoxContainer.new()
    breed_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    breed_root.offset_left = 14
    breed_root.offset_top = 12
    breed_root.offset_right = -14
    breed_root.offset_bottom = -12
    breed_root.add_theme_constant_override("separation", 7)
    breed_panel.add_child(breed_root)

    var breed_title := _make_label("BREEDING LAB", 20)
    breed_root.add_child(breed_title)

    var breed_hint := _make_label("Choose parents with A and B.", 12)
    breed_hint.modulate = Color("#9fb0c8")
    breed_root.add_child(breed_hint)

    var breed_actions := HBoxContainer.new()
    breed_root.add_child(breed_actions)

    var breed_button := _make_button("Breed — 250 Gold", 170)
    breed_button.pressed.connect(_start_breeding)
    breed_actions.add_child(breed_button)

    var claim_button := _make_button("Claim Egg", 120)
    claim_button.pressed.connect(_claim_breed)
    breed_actions.add_child(claim_button)

    var hatch_button := _make_button("Hatch", 100)
    hatch_button.pressed.connect(_hatch)
    breed_actions.add_child(hatch_button)

    breeding_status = _make_label("", 12)
    breed_root.add_child(breeding_status)

    incubation_status = _make_label("", 12)
    breed_root.add_child(incubation_status)

    activity_label = _make_label("", 12)
    activity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var footer := _make_panel()
    footer.custom_minimum_size = Vector2(0, 50)
    root.add_child(footer)

    var footer_row := HBoxContainer.new()
    footer_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    footer_row.offset_left = 14
    footer_row.offset_right = -14
    footer.add_child(footer_row)

    var activity_title := _make_label("ACTIVITY", 13)
    activity_title.custom_minimum_size = Vector2(90, 0)
    footer_row.add_child(activity_title)
    activity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    activity_label.modulate = Color("#82d5ff")
    footer_row.add_child(activity_label)

func _make_panel() -> PanelContainer:
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

func _make_label(text: String, size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", size)
    return label

func _make_button(text: String, width: int) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(width, 36)
    return button

func _refresh_ui() -> void:
    if resource_label:
        resource_label.text = "Gold %d    Gems %d    Food %d" % [GameState.gold, GameState.gems, GameState.food]
    if xp_label:
        xp_label.text = "Island XP %d" % GameState.xp
    if island_level_label:
        island_level_label.text = "Level %d" % GameState.level
    if dev_check:
        dev_check.set_pressed_no_signal(GameState.developer_mode)
    _refresh_buildings()
    _refresh_monsters()
    _refresh_timers()

func _refresh_buildings() -> void:
    if not building_grid:
        return
    for child in building_grid.get_children():
        child.queue_free()

    for i in GameState.buildings.size():
        var building: Dictionary = GameState.buildings[i]
        var card := _make_panel()
        card.custom_minimum_size = Vector2(265, 120)
        building_grid.add_child(card)

        var root := VBoxContainer.new()
        root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        root.offset_left = 10
        root.offset_top = 8
        root.offset_right = -10
        root.offset_bottom = -8
        root.add_theme_constant_override("separation", 4)
        card.add_child(root)

        var name_row := HBoxContainer.new()
        root.add_child(name_row)

        var name_label := _make_label(str(building.get("name", "Building")), 16)
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name_row.add_child(name_label)

        var level_label := _make_label("Lv.%d" % int(building.get("level", 1)), 13)
        name_row.add_child(level_label)

        var type := str(building.get("type", ""))
        if type == "habitat":
            var income := int(building.get("gold_per_minute", 0))
            var cap := int(building.get("capacity", 2))
            root.add_child(_make_label("Nature/Element habitat • %d capacity" % cap, 11))
            root.add_child(_make_label("%d gold / min" % income, 13))
        else:
            var income_food := int(building.get("food_per_minute", 0))
            root.add_child(_make_label("Food production", 11))
            root.add_child(_make_label("%d food / min" % income_food, 13))

        var upgrade := _make_button("Upgrade — %d Gold" % GameState.building_upgrade_cost(i), 200)
        upgrade.pressed.connect(_upgrade_building.bind(i))
        root.add_child(upgrade)

func _refresh_monsters() -> void:
    if not monster_list:
        return
    for child in monster_list.get_children():
        child.queue_free()

    for i in GameState.monsters.size():
        var monster: Dictionary = GameState.monsters[i]
        var data: Dictionary = MonsterDatabase.get_monster(str(monster.get("id", "")))
        var card := _make_panel()
        card.custom_minimum_size = Vector2(0, 76)
        monster_list.add_child(card)

        var row := HBoxContainer.new()
        row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        row.offset_left = 10
        row.offset_top = 8
        row.offset_right = -10
        row.offset_bottom = -8
        card.add_child(row)

        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)

        var title := _make_label(str(monster.get("nickname", "Monster")), 15)
        info.add_child(title)

        var details := _make_label(
            "Lv.%d • %s • HP %d • ATK %d" % [
                int(monster.get("level", 1)),
                str(data.get("element", "Unknown")),
                int(monster.get("hp", 0)),
                int(monster.get("attack", 0))
            ],
            11
        )
        details.modulate = Color("#a9bad1")
        info.add_child(details)

        var select_a := _make_button("A" if selected_a != i else "A ✓", 42)
        select_a.pressed.connect(_select_a.bind(i))
        row.add_child(select_a)

        var select_b := _make_button("B" if selected_b != i else "B ✓", 42)
        select_b.pressed.connect(_select_b.bind(i))
        row.add_child(select_b)

        var feed := _make_button("Feed", 70)
        feed.pressed.connect(_feed.bind(i))
        row.add_child(feed)

func _refresh_timers() -> void:
    if breeding_status:
        if GameState.breeding.is_empty():
            breeding_status.text = "Breeding: empty"
        else:
            breeding_status.text = "Breeding: %s" % _remaining_text(int(GameState.breeding.get("ready_at", 0)))
    if incubation_status:
        if GameState.incubating.is_empty():
            incubation_status.text = "Incubator: empty"
        else:
            var data: Dictionary = MonsterDatabase.get_monster(str(GameState.incubating.get("monster_id", "")))
            incubation_status.text = "Egg: %s • %s" % [
                str(data.get("name", "Unknown")),
                _remaining_text(int(GameState.incubating.get("ready_at", 0)))
            ]

func _remaining_text(target: int) -> String:
    if GameState.developer_mode:
        return "READY"
    var left := maxi(0, target - int(Time.get_unix_time_from_system()))
    return "%02d:%02d" % [left / 60, left % 60]

func _feed(index: int) -> void:
    GameState.feed_monster(index, 1)

func _select_a(index: int) -> void:
    selected_a = index
    _refresh_monsters()

func _select_b(index: int) -> void:
    selected_b = index
    _refresh_monsters()

func _start_breeding() -> void:
    if selected_a == -1 or selected_b == -1:
        _show_log("Choose two monsters first.")
        return
    if selected_a == selected_b:
        _show_log("Choose two different monsters.")
        return
    GameState.start_breeding(selected_a, selected_b)

func _claim_breed() -> void:
    if not GameState.claim_breeding():
        _show_log("The breeding result is not ready yet.")

func _hatch() -> void:
    if not GameState.claim_incubation():
        _show_log("The egg is not ready yet.")

func _collect_production() -> void:
    GameState.collect_production()

func _build_farm() -> void:
    GameState.build_farm()

func _upgrade_building(index: int) -> void:
    GameState.upgrade_building(index)

func _open_campaign() -> void:
    get_tree().change_scene_to_file("res://scenes/Campaign.tscn")

func _open_adventure() -> void:
    GameState.selected_stage = 1
    get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _toggle_dev(enabled: bool) -> void:
    if enabled:
        GameState.grant_dev_resources()
        _show_log("Developer Mode enabled.")
    else:
        GameState.developer_mode = false
        GameState.save_game()
        GameState.state_changed.emit()
        _show_log("Developer Mode disabled.")

func _show_log(message: String) -> void:
    if activity_label:
        activity_label.text = message
