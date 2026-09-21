extends Node2D

var selected_a := -1
var selected_b := -1
var monster_list: VBoxContainer
var breeding_status: Label
var incubation_status: Label
var resource_label: Label
var log_label: Label
var dev_check: CheckButton

func _ready() -> void:
    _build_ui()
    GameState.state_changed.connect(_refresh_ui)
    GameState.log_message.connect(_show_log)
    _refresh_ui()
    _show_log("Welcome to Monster Islands.")

func _process(_delta: float) -> void:
    _refresh_timers()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#101827")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := HBoxContainer.new()
    root.position = Vector2(24, 24)
    root.size = Vector2(1232, 672)
    root.add_theme_constant_override("separation", 18)
    add_child(root)

    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(270, 0)
    left.add_theme_constant_override("separation", 10)
    root.add_child(left)

    var title := Label.new()
    title.text = "MONSTER ISLANDS"
    title.add_theme_font_size_override("font_size", 28)
    left.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Collection • Breeding • Growth"
    subtitle.modulate = Color("#9fb0c8")
    left.add_child(subtitle)

    resource_label = Label.new()
    resource_label.add_theme_font_size_override("font_size", 18)
    resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    left.add_child(resource_label)

    var habitat_panel := Label.new()
    habitat_panel.text = "YOUR ISLAND"
    habitat_panel.add_theme_font_size_override("font_size", 18)
    left.add_child(habitat_panel)

    var island_info := Label.new()
    island_info.text = "Habitat 1 — Meadow\nHabitat 2 — Cinder\n\nLater: farms, temples,\nmonster towers and more islands."
    island_info.modulate = Color("#b9c5d6")
    left.add_child(island_info)

    dev_check = CheckButton.new()
    dev_check.text = "Developer Mode"
    dev_check.toggled.connect(_toggle_dev)
    left.add_child(dev_check)

    var center_panel := VBoxContainer.new()
    center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center_panel.add_theme_constant_override("separation", 10)
    root.add_child(center_panel)

    var list_title := Label.new()
    list_title.text = "MONSTERS"
    list_title.add_theme_font_size_override("font_size", 22)
    center_panel.add_child(list_title)

    monster_list = VBoxContainer.new()
    monster_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    center_panel.add_child(monster_list)

    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(330, 0)
    right.add_theme_constant_override("separation", 10)
    root.add_child(right)

    var breed_title := Label.new()
    breed_title.text = "BREEDING LAB"
    breed_title.add_theme_font_size_override("font_size", 22)
    right.add_child(breed_title)

    var hint := Label.new()
    hint.text = "Select two different monsters, then breed them."
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.modulate = Color("#b9c5d6")
    right.add_child(hint)

    var breed_button := Button.new()
    breed_button.text = "Start Breeding"
    breed_button.custom_minimum_size = Vector2(0, 42)
    breed_button.pressed.connect(_start_breeding)
    right.add_child(breed_button)

    breeding_status = Label.new()
    breeding_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    right.add_child(breeding_status)

    var claim_breed := Button.new()
    claim_breed.text = "Claim Egg"
    claim_breed.pressed.connect(_claim_breed)
    right.add_child(claim_breed)

    incubation_status = Label.new()
    incubation_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    right.add_child(incubation_status)

    var hatch := Button.new()
    hatch.text = "Hatch Monster"
    hatch.pressed.connect(_hatch)
    right.add_child(hatch)

    var log_title := Label.new()
    log_title.text = "ACTIVITY"
    log_title.add_theme_font_size_override("font_size", 18)
    right.add_child(log_title)

    log_label = Label.new()
    log_label.custom_minimum_size = Vector2(0, 90)
    log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    log_label.modulate = Color("#8fd3ff")
    right.add_child(log_label)

func _refresh_ui() -> void:
    if resource_label:
        resource_label.text = "Gold: %d\nGems: %d\nFood: %d" % [GameState.gold, GameState.gems, GameState.food]
    if dev_check:
        dev_check.set_pressed_no_signal(GameState.developer_mode)
    if not monster_list:
        return
    for child in monster_list.get_children():
        child.queue_free()
    for i in GameState.monsters.size():
        var monster: Dictionary = GameState.monsters[i]
        var data := MonsterDatabase.get_monster(str(monster["id"]))
        var row := HBoxContainer.new()
        row.custom_minimum_size = Vector2(0, 72)
        monster_list.add_child(row)

        var info := Label.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        info.text = "%s\nLv.%d • %s • HP %d • ATK %d" % [
            monster["nickname"],
            monster["level"],
            data.get("element", "Unknown"),
            monster["hp"],
            monster["attack"]
        ]
        info.add_theme_font_size_override("font_size", 16)
        row.add_child(info)

        var select := Button.new()
        select.text = "A" if selected_a != i else "A ✓"
        select.pressed.connect(func(): _select_a(i))
        row.add_child(select)

        var select_b := Button.new()
        select_b.text = "B" if selected_b != i else "B ✓"
        select_b.pressed.connect(func(): _select_b(i))
        row.add_child(select_b)

        var feed := Button.new()
        feed.text = "Feed"
        feed.pressed.connect(func(): _feed(i))
        row.add_child(feed)
    _refresh_timers()

func _feed(index: int) -> void:
    GameState.feed_monster(index, 1)

func _select_a(index: int) -> void:
    selected_a = index
    _refresh_ui()

func _select_b(index: int) -> void:
    selected_b = index
    _refresh_ui()

func _start_breeding() -> void:
    if selected_a == -1 or selected_b == -1:
        _show_log("Choose two monsters first.")
        return
    GameState.start_breeding(selected_a, selected_b)

func _claim_breed() -> void:
    if not GameState.claim_breeding():
        _show_log("The breeding result is not ready yet.")

func _hatch() -> void:
    if not GameState.claim_incubation():
        _show_log("The egg is not ready yet.")

func _refresh_timers() -> void:
    if breeding_status:
        if GameState.breeding.is_empty():
            breeding_status.text = "Breeding: empty"
        else:
            breeding_status.text = "Breeding: %s" % _remaining_text(int(GameState.breeding["ready_at"]))
    if incubation_status:
        if GameState.incubating.is_empty():
            incubation_status.text = "Incubator: empty"
        else:
            var data := MonsterDatabase.get_monster(str(GameState.incubating["monster_id"]))
            incubation_status.text = "Egg: %s\n%s" % [data.get("name", "Unknown"), _remaining_text(int(GameState.incubating["ready_at"]))]

func _remaining_text(target: int) -> String:
    if GameState.developer_mode:
        return "READY (developer mode)"
    var left := maxi(0, target - int(Time.get_unix_time_from_system()))
    return "%02d:%02d remaining" % [left / 60, left % 60]

func _toggle_dev(enabled: bool) -> void:
    if enabled:
        GameState.grant_dev_resources()
        _show_log("Developer Mode enabled: resources and timers are unlocked.")
    else:
        GameState.developer_mode = false
        GameState.save_game()
        GameState.state_changed.emit()
        _show_log("Developer Mode disabled.")

func _show_log(message: String) -> void:
    if log_label:
        log_label.text = message
