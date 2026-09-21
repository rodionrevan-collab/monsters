extends Control

var player_team: Array[Dictionary] = []
var enemy_team: Array[Dictionary] = []
var player_hp: Array[int] = []
var enemy_hp: Array[int] = []
var active_player: int = 0
var target_enemy: int = 0

var skill_cooldowns: Array[Array] = []
var player_list: VBoxContainer
var enemy_list: VBoxContainer
var battle_log: Label
var turn_label: Label
var action_box: HBoxContainer

var battle_over: bool = false
var player_turn: bool = true
var stage: int = 1

func _ready() -> void:
    stage = clampi(GameState.selected_stage, 1, 30)
    _setup_teams()
    _build_ui()
    _refresh_ui()
    _log("Choose a target, then use one of the four skills.")

func _setup_teams() -> void:
    var selected: Array = GameState.valid_battle_team()
    if selected.is_empty():
        for i in mini(3, GameState.monsters.size()):
            selected.append(i)
        for slot in selected.size():
            GameState.set_battle_slot(slot, int(selected[slot]))

    for i in 3:
        var monster_index := int(selected[i]) if i < selected.size() else -1
        if monster_index >= 0 and monster_index < GameState.monsters.size():
            var m: Dictionary = GameState.monsters[monster_index]
            var data: Dictionary = MonsterDatabase.get_monster(str(m.get("id", "")))
            player_team.append({
                "id": str(m.get("id", "")),
                "name": str(m.get("nickname", "Monster")),
                "element": str(data.get("element", "Unknown")),
                "hp": int(m.get("hp", 100)),
                "max_hp": int(m.get("hp", 100)),
                "attack": int(m.get("attack", 25)),
                "monster_index": monster_index
            })
            player_hp.append(int(m.get("hp", 100)))
        else:
            player_team.append({
                "id": "",
                "name": "Empty Slot",
                "element": "-",
                "hp": 0,
                "max_hp": 0,
                "attack": 0,
                "monster_index": -1
            })
            player_hp.append(0)
        skill_cooldowns.append([0, 0, 0, 0])

    if GameState.battle_mode == "arena":
        var opponents := GameState.arena_opponents()
        var opponent: Dictionary = opponents[clampi(GameState.selected_arena_opponent, 0, opponents.size() - 1)]
        for unit in opponent.get("team", []):
            enemy_team.append({
                "name": str(unit.get("name", "Opponent")),
                "element": str(unit.get("element", "Nature")),
                "hp": int(unit.get("hp", 100)),
                "max_hp": int(unit.get("hp", 100)),
                "attack": int(unit.get("attack", 25))
            })
    else:
        var scale := 1.0 + float(stage - 1) * 0.08
        enemy_team = [
            {"name": "Stonefang", "element": "Nature", "hp": int(260 * scale), "max_hp": int(260 * scale), "attack": int(45 * scale)},
            {"name": "Ashbeetle", "element": "Fire", "hp": int(210 * scale), "max_hp": int(210 * scale), "attack": int(52 * scale)},
            {"name": "Mistfin", "element": "Water", "hp": int(230 * scale), "max_hp": int(230 * scale), "attack": int(48 * scale)}
        ]
    for enemy in enemy_team:
        enemy_hp.append(int(enemy["hp"]))
    while enemy_team.size() < 3:
        enemy_team.append({"name": "Empty Opponent", "element": "-", "hp": 0, "max_hp": 0, "attack": 0})
        enemy_hp.append(0)

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#0a101d")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := VBoxContainer.new()
    root.position = Vector2(24, 18)
    root.size = Vector2(1232, 684)
    root.add_theme_constant_override("separation", 10)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 54)
    root.add_child(header)

    var title := Label.new()
    title.text = ("ARENA • " + str(GameState.arena_opponents()[GameState.selected_arena_opponent].get("name", "Opponent"))) if GameState.battle_mode == "arena" else "STAGE %02d • WILD ARENA" % stage
    title.add_theme_font_size_override("font_size", 25)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)

    turn_label = Label.new()
    turn_label.add_theme_font_size_override("font_size", 16)
    header.add_child(turn_label)

    var arena := HBoxContainer.new()
    arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
    arena.add_theme_constant_override("separation", 16)
    root.add_child(arena)

    var player_panel := _panel()
    player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    arena.add_child(player_panel)

    var player_root := VBoxContainer.new()
    player_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    player_root.offset_left = 14
    player_root.offset_top = 12
    player_root.offset_right = -14
    player_root.offset_bottom = -12
    player_root.add_theme_constant_override("separation", 7)
    player_panel.add_child(player_root)

    var player_title := Label.new()
    player_title.text = "YOUR TEAM"
    player_title.add_theme_font_size_override("font_size", 20)
    player_root.add_child(player_title)

    player_list = VBoxContainer.new()
    player_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    player_list.add_theme_constant_override("separation", 7)
    player_root.add_child(player_list)

    var enemy_panel := _panel()
    enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    arena.add_child(enemy_panel)

    var enemy_root := VBoxContainer.new()
    enemy_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    enemy_root.offset_left = 14
    enemy_root.offset_top = 12
    enemy_root.offset_right = -14
    enemy_root.offset_bottom = -12
    enemy_root.add_theme_constant_override("separation", 7)
    enemy_panel.add_child(enemy_root)

    var enemy_title := Label.new()
    enemy_title.text = "ENEMY TEAM • CLICK A TARGET"
    enemy_title.add_theme_font_size_override("font_size", 20)
    enemy_root.add_child(enemy_title)

    enemy_list = VBoxContainer.new()
    enemy_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    enemy_list.add_theme_constant_override("separation", 7)
    enemy_root.add_child(enemy_list)

    var log_panel := _panel()
    log_panel.custom_minimum_size = Vector2(0, 78)
    root.add_child(log_panel)

    battle_log = Label.new()
    battle_log.position = Vector2(12, 10)
    battle_log.size = Vector2(1200, 58)
    battle_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    battle_log.modulate = Color("#86d8ff")
    log_panel.add_child(battle_log)

    action_box = HBoxContainer.new()
    action_box.custom_minimum_size = Vector2(0, 58)
    action_box.add_theme_constant_override("separation", 7)
    root.add_child(action_box)
    _refresh_actions()

    var bottom := HBoxContainer.new()
    bottom.custom_minimum_size = Vector2(0, 42)
    root.add_child(bottom)

    var back := Button.new()
    back.text = "Return to Campaign"
    back.custom_minimum_size = Vector2(190, 40)
    back.pressed.connect(_return_to_campaign)
    bottom.add_child(back)

func _refresh_actions() -> void:
    if not action_box:
        return
    for child in action_box.get_children():
        child.queue_free()

    if player_team.is_empty():
        return

    var skills: Array[Dictionary] = MonsterDatabase.get_skills(str(player_team[active_player].get("id", "")))
    var cooldowns: Array = skill_cooldowns[active_player]

    for i in skills.size():
        var skill: Dictionary = skills[i]
        var button := Button.new()
        var remaining := int(cooldowns[i])
        if remaining > 0:
            button.text = "%s\nCD %d" % [str(skill.get("name", "Skill")), remaining]
            button.disabled = true
        else:
            button.text = "%s\nx%.1f" % [str(skill.get("name", "Skill")), float(skill.get("power", 1.0))]
        button.custom_minimum_size = Vector2(185, 48)
        button.pressed.connect(_use_skill.bind(i))
        action_box.add_child(button)

func _refresh_ui() -> void:
    if player_list:
        for child in player_list.get_children():
            child.queue_free()
        for i in player_team.size():
            player_list.add_child(_player_row(i))

    if enemy_list:
        for child in enemy_list.get_children():
            child.queue_free()
        for i in enemy_team.size():
            enemy_list.add_child(_enemy_row(i))

    if turn_label:
        if battle_over:
            turn_label.text = "BATTLE COMPLETE"
        else:
            turn_label.text = "TURN • %s • TARGET %s" % [
                str(player_team[active_player].get("name", "Monster")),
                str(enemy_team[target_enemy].get("name", "Enemy"))
            ]

    _refresh_actions()

func _player_row(index: int) -> PanelContainer:
    var unit: Dictionary = player_team[index]
    var panel := _panel()
    panel.custom_minimum_size = Vector2(0, 94)

    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.offset_left = 10
    root.offset_top = 8
    root.offset_right = -10
    root.offset_bottom = -8
    root.add_theme_constant_override("separation", 2)
    panel.add_child(root)

    var title := Label.new()
    title.text = ("%s  • ACTIVE" if index == active_player and not battle_over else "%s") % str(unit.get("name", "Unit"))
    title.add_theme_font_size_override("font_size", 16)
    root.add_child(title)

    var detail := Label.new()
    detail.text = "%s • ATK %d" % [str(unit.get("element", "-")), int(unit.get("attack", 0))]
    detail.modulate = Color("#a9bad1")
    root.add_child(detail)

    var bar := ProgressBar.new()
    bar.max_value = max(1, int(unit.get("max_hp", 1)))
    bar.value = player_hp[index]
    bar.show_percentage = false
    bar.custom_minimum_size = Vector2(0, 18)
    root.add_child(bar)

    var hp := Label.new()
    hp.text = "HP %d / %d" % [player_hp[index], int(unit.get("max_hp", 0))]
    hp.add_theme_font_size_override("font_size", 11)
    root.add_child(hp)

    return panel

func _enemy_row(index: int) -> PanelContainer:
    var unit: Dictionary = enemy_team[index]
    var panel := _panel()
    panel.custom_minimum_size = Vector2(0, 94)

    var root := HBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.offset_left = 10
    root.offset_top = 8
    root.offset_right = -10
    root.offset_bottom = -8
    panel.add_child(root)

    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(info)

    var title := Label.new()
    title.text = ("%s  • TARGET" if index == target_enemy and enemy_hp[index] > 0 else "%s") % str(unit.get("name", "Enemy"))
    title.add_theme_font_size_override("font_size", 16)
    info.add_child(title)

    var detail := Label.new()
    detail.text = "%s • ATK %d" % [str(unit.get("element", "-")), int(unit.get("attack", 0))]
    detail.modulate = Color("#a9bad1")
    info.add_child(detail)

    var bar := ProgressBar.new()
    bar.max_value = max(1, int(unit.get("max_hp", 1)))
    bar.value = enemy_hp[index]
    bar.show_percentage = false
    bar.custom_minimum_size = Vector2(0, 18)
    info.add_child(bar)

    var hp := Label.new()
    hp.text = "HP %d / %d" % [enemy_hp[index], int(unit.get("max_hp", 0))]
    hp.add_theme_font_size_override("font_size", 11)
    info.add_child(hp)

    var target := Button.new()
    target.text = "TARGET" if index == target_enemy else "SELECT"
    target.custom_minimum_size = Vector2(92, 70)
    target.disabled = enemy_hp[index] <= 0 or battle_over
    target.pressed.connect(_select_target.bind(index))
    root.add_child(target)

    return panel

func _select_target(index: int) -> void:
    if battle_over or not player_turn or enemy_hp[index] <= 0:
        return
    target_enemy = index
    _log("Target selected: %s." % enemy_team[index]["name"])
    _refresh_ui()

func _use_skill(index: int) -> void:
    if battle_over or not player_turn:
        return

    var target := _first_alive_enemy()
    if target_enemy >= 0 and target_enemy < enemy_hp.size() and enemy_hp[target_enemy] > 0:
        target = target_enemy
    if target == -1:
        _finish_battle(true)
        return

    var skills: Array[Dictionary] = MonsterDatabase.get_skills(str(player_team[active_player].get("id", "")))
    if index < 0 or index >= skills.size():
        return

    var skill: Dictionary = skills[index]
    var cooldown := int(skill.get("cooldown", 0))
    if int(skill_cooldown(active_player, index)) > 0:
        return

    skill_cooldowns[active_player][index] = cooldown
    var kind := str(skill.get("kind", "damage"))
    if kind == "heal_self":
        var heal := int(float(player_team[active_player]["max_hp"]) * float(skill.get("power", 0.9)) * 0.45)
        player_hp[active_player] = mini(player_team[active_player]["max_hp"], player_hp[active_player] + heal)
        _log("%s used %s and recovered %d HP." % [player_team[active_player]["name"], skill["name"], heal])
    else:
        var base_damage := int(player_team[active_player]["attack"])
        var damage := int(float(base_damage) * float(skill.get("power", 1.0)))
        var attacker_element := str(player_team[active_player]["element"])
        var defender_element := str(enemy_team[target]["element"])
        var multiplier := MonsterDatabase.effectiveness(attacker_element, defender_element)
        damage = int(float(damage) * multiplier)
        enemy_hp[target] = maxi(0, enemy_hp[target] - damage)
        _log("%s used %s on %s for %d damage." % [
            player_team[active_player]["name"],
            skill["name"],
            enemy_team[target]["name"],
            damage
        ])
        if multiplier > 1.0:
            _log("Elemental advantage!")
        elif multiplier < 1.0:
            _log("The attack was resisted.")

    _refresh_ui()

    if _all_enemies_defeated():
        _finish_battle(true)
        return

    player_turn = false
    await get_tree().create_timer(0.5).timeout
    _enemy_turn()

func skill_cooldown(unit_index: int, skill_index: int) -> int:
    if unit_index < 0 or unit_index >= skill_cooldowns.size():
        return 0
    if skill_index < 0 or skill_index >= skill_cooldowns[unit_index].size():
        return 0
    return int(skill_cooldowns[unit_index][skill_index])

func _tick_cooldowns() -> void:
    for unit_cooldowns in skill_cooldowns:
        for i in unit_cooldowns.size():
            unit_cooldowns[i] = maxi(0, int(unit_cooldowns[i]) - 1)

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

    _tick_cooldowns()
    active_player = _first_alive_player()
    target_enemy = _first_alive_enemy()
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

    if GameState.battle_mode == "arena":
        GameState.complete_arena(victory)
        if victory:
            _log("ARENA VICTORY! +100 trophies and rewards.")
        else:
            _log("ARENA DEFEAT. -50 trophies.")
    elif victory:
        var defeated := 0
        for hp in player_hp:
            if hp <= 0:
                defeated += 1
        var stars := 1
        if defeated == 0:
            stars = 3
        elif defeated == 1:
            stars = 2

        var reward := GameState.complete_stage(stage, stars)
        _log("VICTORY! Stage %d • %d★ • +%d gold, +%d food, +%d XP." % [
            stage,
            stars,
            int(reward.get("gold", 0)),
            int(reward.get("food", 0)),
            int(reward.get("xp", 0))
        ])
    else:
        _log("DEFEAT. Train your monsters and try again.")
    _refresh_ui()

func _return_to_campaign() -> void:
    GameState.save_game()
    GameState.battle_mode = "campaign"
    GameState.save_game()
    get_tree().change_scene_to_file("res://scenes/Campaign.tscn")

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
