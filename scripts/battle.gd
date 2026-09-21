extends Control

var player_team: Array[Dictionary] = []
var enemy_team: Array[Dictionary] = []
var player_hp: Array[int] = []
var enemy_hp: Array[int] = []
var active_player: int = 0
var selected_attack: int = 0

var player_list: VBoxContainer
var enemy_list: VBoxContainer
var battle_log: Label
var turn_label: Label
var action_box: HBoxContainer
var reward_box: VBoxContainer

var battle_over: bool = false
var player_turn: bool = true

func _ready() -> void:
    _setup_teams()
    _build_ui()
    _refresh_ui()
    _log("Battle started. Choose an attack.")

func _setup_teams() -> void:
    var count := mini(3, GameState.monsters.size())
    for i in count:
        var m: Dictionary = GameState.monsters[i]
        var data: Dictionary = MonsterDatabase.get_monster(str(m.get("id", "")))
        player_team.append({
            "name": str(m.get("nickname", "Monster")),
            "element": str(data.get("element", "Unknown")),
            "hp": int(m.get("hp", 100)),
            "max_hp": int(m.get("hp", 100)),
            "attack": int(m.get("attack", 25))
        })
        player_hp.append(int(m.get("hp", 100)))

    while player_team.size() < 3:
        player_team.append({
            "name": "Empty Slot",
            "element": "-",
            "hp": 0,
            "max_hp": 0,
            "attack": 0
        })
        player_hp.append(0)

    enemy_team = [
        {"name": "Stonefang", "element": "Earth", "hp": 260, "max_hp": 260, "attack": 45},
        {"name": "Ashbeetle", "element": "Fire", "hp": 210, "max_hp": 210, "attack": 52},
        {"name": "Mistfin", "element": "Water", "hp": 230, "max_hp": 230, "attack": 48}
    ]
    for enemy in enemy_team:
        enemy_hp.append(int(enemy["hp"]))

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#0a101d")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := VBoxContainer.new()
    root.position = Vector2(28, 24)
    root.size = Vector2(1224, 672)
    root.add_theme_constant_override("separation", 12)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 56)
    root.add_child(header)

    var title := Label.new()
    title.text = "ADVENTURE • WILD ARENA"
    title.add_theme_font_size_override("font_size", 25)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)

    turn_label = Label.new()
    turn_label.add_theme_font_size_override("font_size", 16)
    header.add_child(turn_label)

    var arena := HBoxContainer.new()
    arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
    arena.add_theme_constant_override("separation", 20)
    root.add_child(arena)

    var player_panel := _panel()
    player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    arena.add_child(player_panel)

    var player_root := VBoxContainer.new()
    player_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    player_root.offset_left = 16
    player_root.offset_top = 14
    player_root.offset_right = -16
    player_root.offset_bottom = -14
    player_root.add_theme_constant_override("separation", 8)
    player_panel.add_child(player_root)

    var pt := Label.new()
    pt.text = "YOUR TEAM"
    pt.add_theme_font_size_override("font_size", 20)
    player_root.add_child(pt)

    player_list = VBoxContainer.new()
    player_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    player_list.add_theme_constant_override("separation", 8)
    player_root.add_child(player_list)

    var enemy_panel := _panel()
    enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    arena.add_child(enemy_panel)

    var enemy_root := VBoxContainer.new()
    enemy_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    enemy_root.offset_left = 16
    enemy_root.offset_top = 14
    enemy_root.offset_right = -16
    enemy_root.offset_bottom = -14
    enemy_root.add_theme_constant_override("separation", 8)
    enemy_panel.add_child(enemy_root)

    var et := Label.new()
    et.text = "ENEMY TEAM"
    et.add_theme_font_size_override("font_size", 20)
    enemy_root.add_child(et)

    enemy_list = VBoxContainer.new()
    enemy_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    enemy_list.add_theme_constant_override("separation", 8)
    enemy_root.add_child(enemy_list)

    var log_panel := _panel()
    log_panel.custom_minimum_size = Vector2(0, 110)
    root.add_child(log_panel)

    battle_log = Label.new()
    battle_log.position = Vector2(14, 12)
    battle_log.size = Vector2(1196, 86)
    battle_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    battle_log.modulate = Color("#86d8ff")
    log_panel.add_child(battle_log)

    action_box = HBoxContainer.new()
    action_box.custom_minimum_size = Vector2(0, 52)
    action_box.add_theme_constant_override("separation", 8)
    root.add_child(action_box)
    _build_actions()

    var bottom := HBoxContainer.new()
    bottom.custom_minimum_size = Vector2(0, 42)
    root.add_child(bottom)

    reward_box = VBoxContainer.new()
    reward_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bottom.add_child(reward_box)

    var back := Button.new()
    back.text = "Return to Island"
    back.custom_minimum_size = Vector2(170, 40)
    back.pressed.connect(_return_to_island)
    bottom.add_child(back)

func _build_actions() -> void:
    for child in action_box.get_children():
        child.queue_free()
    var attacks := [
        ["Basic Attack", 1.0],
        ["Power Strike", 1.6],
        ["Element Burst", 2.0]
    ]
    for i in attacks.size():
        var button := Button.new()
        button.text = "%s x%.1f" % [attacks[i][0], float(attacks[i][1])]
        button.custom_minimum_size = Vector2(190, 44)
        button.pressed.connect(_use_attack.bind(i))
        action_box.add_child(button)

func _refresh_ui() -> void:
    if player_list:
        for child in player_list.get_children():
            child.queue_free()
        for i in player_team.size():
            var row := _unit_row(player_team[i], player_hp[i], player_team[i]["max_hp"], i == active_player and not battle_over)
            player_list.add_child(row)

    if enemy_list:
        for child in enemy_list.get_children():
            child.queue_free()
        for i in enemy_team.size():
            var row := _unit_row(enemy_team[i], enemy_hp[i], enemy_team[i]["max_hp"], false)
            enemy_list.add_child(row)

    if turn_label:
        if battle_over:
            turn_label.text = "BATTLE COMPLETE"
        else:
            turn_label.text = "Turn • %s" % player_team[active_player]["name"]

func _unit_row(unit: Dictionary, hp: int, max_hp: int, active: bool) -> PanelContainer:
    var panel := _panel()
    panel.custom_minimum_size = Vector2(0, 92)
    var row := VBoxContainer.new()
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    row.offset_left = 10
    row.offset_top = 8
    row.offset_right = -10
    row.offset_bottom = -8
    row.add_theme_constant_override("separation", 2)
    panel.add_child(row)

    var title := Label.new()
    title.text = ("%s  <ACTIVE>" if active else "%s") % str(unit.get("name", "Unit"))
    title.add_theme_font_size_override("font_size", 16)
    row.add_child(title)

    var element := Label.new()
    element.text = "%s • ATK %d" % [str(unit.get("element", "-")), int(unit.get("attack", 0))]
    element.modulate = Color("#a9bad1")
    row.add_child(element)

    var bar := ProgressBar.new()
    bar.max_value = max_hp
    bar.value = hp
    bar.show_percentage = false
    bar.custom_minimum_size = Vector2(0, 20)
    row.add_child(bar)

    var hp_label := Label.new()
    hp_label.text = "HP %d / %d" % [hp, max_hp]
    hp_label.add_theme_font_size_override("font_size", 11)
    row.add_child(hp_label)
    return panel

func _use_attack(index: int) -> void:
    if battle_over or not player_turn:
        return

    var target := _first_alive_enemy()
    if target == -1:
        _finish_battle(true)
        return

    var multiplier := [1.0, 1.6, 2.0][index]
    var base_damage := int(player_team[active_player]["attack"])
    var damage := int(float(base_damage) * multiplier)

    if index == 2:
        damage += 20

    enemy_hp[target] = maxi(0, enemy_hp[target] - damage)
    _log("%s used %s for %d damage." % [
        player_team[active_player]["name"],
        ["Basic Attack", "Power Strike", "Element Burst"][index],
        damage
    ])
    _refresh_ui()

    if _all_enemies_defeated():
        _finish_battle(true)
        return

    player_turn = false
    await get_tree().create_timer(0.55).timeout
    _enemy_turn()

func _enemy_turn() -> void:
    if battle_over:
        return

    var target := _first_alive_player()
    if target == -1:
        _finish_battle(false)
        return

    var enemy_index := _first_alive_enemy()
    if enemy_index == -1:
        _finish_battle(true)
        return

    var enemy: Dictionary = enemy_team[enemy_index]
    var damage := int(enemy["attack"])
    player_hp[target] = maxi(0, player_hp[target] - damage)
    _log("%s attacked %s for %d damage." % [enemy["name"], player_team[target]["name"], damage])

    if player_hp[target] <= 0:
        _log("%s was defeated." % player_team[target]["name"])
        active_player = _first_alive_player()

    _refresh_ui()

    if _all_players_defeated():
        _finish_battle(false)
        return

    active_player = _first_alive_player()
    player_turn = true
    _refresh_ui()

func _first_alive_player() -> int:
    for i in player_hp.size():
        if player_hp[i] > 0:
            return i
    return -1

func _first_alive_enemy() -> int:
    for i in enemy_hp.size():
        if enemy_hp[i] > 0:
            return i
    return -1

func _all_players_defeated() -> bool:
    return _first_alive_player() == -1

func _all_enemies_defeated() -> bool:
    return _first_alive_enemy() == -1

func _finish_battle(victory: bool) -> void:
    if battle_over:
        return
    battle_over = true
    player_turn = false
    if victory:
        var gold_reward := 600
        var food_reward := 250
        GameState.gold += gold_reward
        GameState.food += food_reward
        GameState.xp += 50
        _log("VICTORY! Rewards: %d gold, %d food, 50 island XP." % [gold_reward, food_reward])
    else:
        _log("DEFEAT. Train your monsters and try again.")
    _refresh_ui()

func _return_to_island() -> void:
    GameState.save_game()
    get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _log(message: String) -> void:
    if battle_log:
        battle_log.text = message

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
