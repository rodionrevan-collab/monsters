extends Node

signal state_changed
signal log_message(message: String)

const SAVE_PATH := "user://monster_islands_save.json"
const MAX_PRODUCTION_SECONDS := 8 * 60 * 60

var gold: int = 5000
var gems: int = 50
var food: int = 1000
var level: int = 1
var xp: int = 0
var developer_mode: bool = false

var monsters: Array[Dictionary] = []
var habitats: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var breeding: Dictionary = {}
var incubating: Dictionary = {}

func _ready() -> void:
    load_game()
    if monsters.is_empty():
        _create_new_game()
        save_game()
    elif buildings.is_empty():
        _create_buildings_from_legacy()
    _update_production(false)

func _create_new_game() -> void:
    var now := int(Time.get_unix_time_from_system())
    monsters = [
        _make_monster("sproutling", "Sproutling A"),
        _make_monster("embercub", "Embercub A")
    ]
    habitats = [
        {"id": 1, "name": "Meadow Habitat", "element": "Nature", "capacity": 2, "monsters": [0]},
        {"id": 2, "name": "Cinder Habitat", "element": "Fire", "capacity": 2, "monsters": [1]}
    ]
    buildings = [
        {"id": "meadow_habitat", "type": "habitat", "name": "Meadow Habitat", "element": "Nature", "level": 1, "capacity": 2, "gold_per_minute": 30, "last_tick": now},
        {"id": "cinder_habitat", "type": "habitat", "name": "Cinder Habitat", "element": "Fire", "level": 1, "capacity": 2, "gold_per_minute": 30, "last_tick": now},
        {"id": "food_farm_1", "type": "farm", "name": "Sunberry Farm", "element": "", "level": 1, "capacity": 0, "food_per_minute": 45, "last_tick": now}
    ]
    breeding = {}
    incubating = {}

func _create_buildings_from_legacy() -> void:
    var now := int(Time.get_unix_time_from_system())
    buildings = [
        {"id": "meadow_habitat", "type": "habitat", "name": "Meadow Habitat", "element": "Nature", "level": 1, "capacity": 2, "gold_per_minute": 30, "last_tick": now},
        {"id": "cinder_habitat", "type": "habitat", "name": "Cinder Habitat", "element": "Fire", "level": 1, "capacity": 2, "gold_per_minute": 30, "last_tick": now},
        {"id": "food_farm_1", "type": "farm", "name": "Sunberry Farm", "element": "", "level": 1, "capacity": 0, "food_per_minute": 45, "last_tick": now}
    ]
    save_game()

func _make_monster(monster_id: String, nickname: String) -> Dictionary:
    var data: Dictionary = MonsterDatabase.get_monster(monster_id)
    return {
        "id": monster_id,
        "nickname": nickname,
        "level": 1,
        "xp": 0,
        "hp": int(data.get("base_hp", 100)),
        "attack": int(data.get("base_attack", 25))
    }

func _update_production(notify: bool = true) -> void:
    var now := int(Time.get_unix_time_from_system())
    var changed := false
    for i in buildings.size():
        var building: Dictionary = buildings[i]
        var last_tick := int(building.get("last_tick", now))
        var elapsed := mini(MAX_PRODUCTION_SECONDS, maxi(0, now - last_tick))
        if elapsed <= 0:
            continue
        var minutes := float(elapsed) / 60.0
        var gold_rate := float(building.get("gold_per_minute", 0))
        var food_rate := float(building.get("food_per_minute", 0))
        if gold_rate > 0.0:
            gold += int(minutes * gold_rate)
            changed = true
        if food_rate > 0.0:
            food += int(minutes * food_rate)
            changed = true
        building["last_tick"] = now
        buildings[i] = building
    if changed:
        save_game()
        if notify:
            _emit_state()

func collect_production() -> void:
    _update_production(true)
    log_message.emit("Island production collected.")

func feed_monster(index: int, amount: int = 1) -> bool:
    if index < 0 or index >= monsters.size():
        return false
    var total_cost := amount * 10
    if not developer_mode and food < total_cost:
        log_message.emit("Not enough food.")
        return false
    if not developer_mode:
        food -= total_cost
    var monster: Dictionary = monsters[index]
    monster["xp"] = int(monster.get("xp", 0)) + amount * 25
    while int(monster["xp"]) >= xp_to_next_level(int(monster["level"])):
        monster["xp"] = int(monster["xp"]) - xp_to_next_level(int(monster["level"]))
        monster["level"] = int(monster["level"]) + 1
        _recalculate_stats(monster)
        xp += 10
        log_message.emit("%s reached level %d." % [monster["nickname"], monster["level"]])
    monsters[index] = monster
    _emit_state()
    save_game()
    return true

func xp_to_next_level(monster_level: int) -> int:
    return 100 + monster_level * 75

func _recalculate_stats(monster: Dictionary) -> void:
    var data: Dictionary = MonsterDatabase.get_monster(str(monster["id"]))
    var lv := int(monster["level"])
    var growth := float(data.get("growth", 1.18))
    monster["hp"] = int(float(data.get("base_hp", 100)) * pow(growth, lv - 1))
    monster["attack"] = int(float(data.get("base_attack", 25)) * pow(growth, lv - 1))

func building_upgrade_cost(index: int) -> int:
    if index < 0 or index >= buildings.size():
        return 999999999
    var lv := int(buildings[index].get("level", 1))
    return 500 * lv * lv

func upgrade_building(index: int) -> bool:
    _update_production(false)
    if index < 0 or index >= buildings.size():
        return false
    var cost := building_upgrade_cost(index)
    if not developer_mode and gold < cost:
        log_message.emit("Need %d gold to upgrade." % cost)
        return false
    if not developer_mode:
        gold -= cost
    var building: Dictionary = buildings[index]
    building["level"] = int(building.get("level", 1)) + 1
    if building.get("type", "") == "habitat":
        building["capacity"] = int(building.get("capacity", 2)) + 1
        building["gold_per_minute"] = int(building.get("gold_per_minute", 30)) + 15
    elif building.get("type", "") == "farm":
        building["food_per_minute"] = int(building.get("food_per_minute", 45)) + 25
    buildings[index] = building
    log_message.emit("%s upgraded to level %d." % [building["name"], building["level"]])
    _emit_state()
    save_game()
    return true

func can_build_farm() -> bool:
    return buildings.size() < 6

func build_farm() -> bool:
    if not can_build_farm():
        log_message.emit("The island has no free construction slots yet.")
        return false
    var cost := 1500
    if not developer_mode and gold < cost:
        log_message.emit("Need 1500 gold to build a new farm.")
        return false
    if not developer_mode:
        gold -= cost
    var now := int(Time.get_unix_time_from_system())
    var number := 1
    for building in buildings:
        if building.get("type", "") == "farm":
            number += 1
    buildings.append({
        "id": "food_farm_%d" % number,
        "type": "farm",
        "name": "Sunberry Farm %d" % number,
        "element": "",
        "level": 1,
        "capacity": 0,
        "food_per_minute": 45,
        "last_tick": now
    })
    log_message.emit("New Sunberry Farm built.")
    _emit_state()
    save_game()
    return true

func can_breed() -> bool:
    return breeding.is_empty() and monsters.size() >= 2

func start_breeding(a: int, b: int) -> bool:
    if not can_breed():
        return false
    if a == b or a < 0 or b < 0 or a >= monsters.size() or b >= monsters.size():
        return false
    if not developer_mode and gold < 250:
        log_message.emit("Need 250 gold to start breeding.")
        return false
    if not developer_mode:
        gold -= 250
    var duration := 20
    breeding = {
        "a": a,
        "b": b,
        "ready_at": int(Time.get_unix_time_from_system()) + duration
    }
    log_message.emit("Breeding started. The egg will be ready soon.")
    _emit_state()
    save_game()
    return true

func claim_breeding() -> bool:
    if breeding.is_empty():
        return false
    if not developer_mode and Time.get_unix_time_from_system() < int(breeding["ready_at"]):
        return false
    var a: Dictionary = monsters[int(breeding["a"])]
    var b: Dictionary = monsters[int(breeding["b"])]
    var child_id := _breed_result(str(a["id"]), str(b["id"]))
    incubating = {
        "monster_id": child_id,
        "ready_at": int(Time.get_unix_time_from_system()) + 15
    }
    breeding = {}
    log_message.emit("A new egg was created: %s." % MonsterDatabase.get_monster(child_id).get("name", child_id))
    _emit_state()
    save_game()
    return true

func claim_incubation() -> bool:
    if incubating.is_empty():
        return false
    if not developer_mode and Time.get_unix_time_from_system() < int(incubating["ready_at"]):
        return false
    var id := str(incubating["monster_id"])
    var data: Dictionary = MonsterDatabase.get_monster(id)
    monsters.append(_make_monster(id, "%s %d" % [data.get("name", id), monsters.size() + 1]))
    incubating = {}
    log_message.emit("Monster hatched!")
    _emit_state()
    save_game()
    return true

func _breed_result(a: String, b: String) -> String:
    if (a == "sproutling" and b == "embercub") or (a == "embercub" and b == "sproutling"):
        return "tidehorn"
    if a == b and a == "sproutling":
        return "mossback"
    if a == b and a == "embercub":
        return "stormwing"
    var fallback := ["tidehorn", "stormwing"]
    return fallback[(monsters.size() + int(Time.get_unix_time_from_system())) % fallback.size()]

func grant_dev_resources() -> void:
    developer_mode = true
    gold = 999999
    gems = 9999
    food = 999999
    _emit_state()
    save_game()

func _emit_state() -> void:
    state_changed.emit()

func save_game() -> void:
    var data := {
        "gold": gold,
        "gems": gems,
        "food": food,
        "level": level,
        "xp": xp,
        "developer_mode": developer_mode,
        "monsters": monsters,
        "habitats": habitats,
        "buildings": buildings,
        "breeding": breeding,
        "incubating": incubating
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        gold = int(parsed.get("gold", gold))
        gems = int(parsed.get("gems", gems))
        food = int(parsed.get("food", food))
        level = int(parsed.get("level", level))
        xp = int(parsed.get("xp", xp))
        developer_mode = bool(parsed.get("developer_mode", false))
        monsters = parsed.get("monsters", [])
        habitats = parsed.get("habitats", [])
        buildings = parsed.get("buildings", [])
        breeding = parsed.get("breeding", {})
        incubating = parsed.get("incubating", {})
