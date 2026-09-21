extends Node

signal state_changed
signal log_message(message: String)

const SAVE_PATH := "user://monster_islands_save.json"

var gold: int = 5000
var gems: int = 50
var food: int = 1000
var level: int = 1
var xp: int = 0
var developer_mode: bool = false

var monsters: Array[Dictionary] = []
var habitats: Array[Dictionary] = []
var breeding: Dictionary = {}
var incubating: Dictionary = {}

func _ready() -> void:
    load_game()
    if monsters.is_empty():
        _create_new_game()
        save_game()

func _create_new_game() -> void:
    monsters = [
        _make_monster("sproutling", "Sproutling A"),
        _make_monster("embercub", "Embercub A")
    ]
    habitats = [
        {"id": 1, "name": "Meadow Habitat", "capacity": 2, "monsters": [0]},
        {"id": 2, "name": "Cinder Habitat", "capacity": 2, "monsters": [1]}
    ]
    breeding = {}
    incubating = {}

func _make_monster(monster_id: String, nickname: String) -> Dictionary:
    var data := MonsterDatabase.get_monster(monster_id)
    return {
        "id": monster_id,
        "nickname": nickname,
        "level": 1,
        "xp": 0,
        "hp": int(data.get("base_hp", 100)),
        "attack": int(data.get("base_attack", 25))
    }

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
        log_message.emit("%s reached level %d." % [monster["nickname"], monster["level"]])
    monsters[index] = monster
    _emit_state()
    save_game()
    return true

func xp_to_next_level(monster_level: int) -> int:
    return 100 + monster_level * 75

func _recalculate_stats(monster: Dictionary) -> void:
    var data := MonsterDatabase.get_monster(str(monster["id"]))
    var lv := int(monster["level"])
    var growth := float(data.get("growth", 1.18))
    monster["hp"] = int(float(data.get("base_hp", 100)) * pow(growth, lv - 1))
    monster["attack"] = int(float(data.get("base_attack", 25)) * pow(growth, lv - 1))

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
        "ready_at": Time.get_unix_time_from_system() + duration
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
        "ready_at": Time.get_unix_time_from_system() + 15
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
    var data := MonsterDatabase.get_monster(id)
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
        breeding = parsed.get("breeding", {})
        incubating = parsed.get("incubating", {})
