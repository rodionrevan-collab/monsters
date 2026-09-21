extends Node

signal state_changed
signal log_message(message: String)

const SAVE_PATH := "user://monster_islands_save.json"
const MAX_PRODUCTION_SECONDS := 8 * 60 * 60
const MAX_MONSTER_LEVEL := 50
const MAX_MONSTER_RANK := 5

var gold: int = 5000
var gems: int = 50
var food: int = 1000
var level: int = 1
var xp: int = 0
var developer_mode: bool = false
var selected_stage: int = 1
var campaign_stage: int = 1
var completed_stages: Array = []
var selected_monster: int = 0

var monsters: Array[Dictionary] = []
var habitats: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var breeding: Dictionary = {}
var incubating: Dictionary = {}
var breeding_slots: Array = []
var egg_inventory: Array = []
var incubators: Array = []
var islands: Array = []
var selected_island: int = 0
const MAX_BREEDING_SLOTS := 2
const MAX_INCUBATORS := 3

func _ready() -> void:
    load_game()
    if monsters.is_empty():
        _create_new_game()
        save_game()
    elif buildings.is_empty():
        _create_buildings_from_legacy()
    _migrate_island_system()
    _load_active_island()
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
    breeding_slots = [{}, {}]
    egg_inventory = []
    incubators = [{}, {}, {}]
    islands = []
    selected_island = 0

func _create_initial_islands(now: int) -> void:
    islands = [
        {
            "id": 1,
            "name": "Green Isle",
            "theme": "Nature",
            "unlocked": true,
            "territory_level": 1,
            "max_slots": 4,
            "habitats": [
                {"id": "green_meadow", "name": "Meadow Habitat", "element": "Nature", "capacity": 2, "monsters": [0], "building_id": "green_meadow_habitat"},
                {"id": "green_cinder", "name": "Cinder Habitat", "element": "Fire", "capacity": 2, "monsters": [1], "building_id": "green_cinder_habitat"}
            ],
            "buildings": [
                {"id": "green_meadow_habitat", "type": "habitat", "name": "Meadow Habitat", "element": "Nature", "level": 1, "capacity": 2, "gold_per_minute": 30, "last_tick": now},
                {"id": "green_cinder_habitat", "type": "habitat", "name": "Cinder Habitat", "element": "Fire", "level": 1, "capacity": 2, "gold_per_minute": 30, "last_tick": now},
                {"id": "green_food_farm_1", "type": "farm", "name": "Sunberry Farm", "element": "", "level": 1, "capacity": 0, "food_per_minute": 45, "last_tick": now}
            ]
        },
        {
            "id": 2,
            "name": "Azure Atoll",
            "theme": "Water/Air",
            "unlocked": false,
            "territory_level": 1,
            "max_slots": 4,
            "habitats": [
                {"id": "azure_water", "name": "Tide Habitat", "element": "Water", "capacity": 2, "monsters": [], "building_id": "azure_water_habitat"},
                {"id": "azure_air", "name": "Cloud Habitat", "element": "Air", "capacity": 2, "monsters": [], "building_id": "azure_air_habitat"}
            ],
            "buildings": [
                {"id": "azure_water_habitat", "type": "habitat", "name": "Tide Habitat", "element": "Water", "level": 1, "capacity": 2, "gold_per_minute": 40, "last_tick": now},
                {"id": "azure_air_habitat", "type": "habitat", "name": "Cloud Habitat", "element": "Air", "level": 1, "capacity": 2, "gold_per_minute": 40, "last_tick": now},
                {"id": "azure_food_farm_1", "type": "farm", "name": "Blueberry Farm", "element": "", "level": 1, "capacity": 0, "food_per_minute": 60, "last_tick": now}
            ]
        }
    ]

func _migrate_island_system() -> void:
    if not islands.is_empty():
        return
    var now := int(Time.get_unix_time_from_system())
    var legacy_habitats: Array = habitats
    var legacy_buildings: Array = buildings
    _create_initial_islands(now)
    if not legacy_habitats.is_empty():
        islands[0]["habitats"] = legacy_habitats.duplicate(true)
        for i in islands[0]["habitats"].size():
            var h: Dictionary = islands[0]["habitats"][i]
            h["building_id"] = "green_meadow_habitat" if i == 0 else "green_cinder_habitat"
            islands[0]["habitats"][i] = h
    if not legacy_buildings.is_empty():
        islands[0]["buildings"] = legacy_buildings.duplicate(true)
        for building in islands[0]["buildings"]:
            var old_id := str(building.get("id", ""))
            if old_id == "meadow_habitat":
                building["id"] = "green_meadow_habitat"
            elif old_id == "cinder_habitat":
                building["id"] = "green_cinder_habitat"
            elif old_id.begins_with("food_farm_"):
                building["id"] = "green_" + old_id
    selected_island = 0
    save_game()

func _save_active_island() -> void:
    if islands.is_empty():
        return
    islands[selected_island]["habitats"] = habitats.duplicate(true)
    islands[selected_island]["buildings"] = buildings.duplicate(true)

func _load_active_island() -> void:
    if islands.is_empty():
        return
    selected_island = clampi(selected_island, 0, islands.size() - 1)
    habitats = islands[selected_island].get("habitats", []).duplicate(true)
    buildings = islands[selected_island].get("buildings", []).duplicate(true)

func current_island_name() -> String:
    if islands.is_empty():
        return "Green Isle"
    return str(islands[selected_island].get("name", "Island"))

func current_island_theme() -> String:
    if islands.is_empty():
        return "Nature"
    return str(islands[selected_island].get("theme", "Nature"))

func island_building_slots_used(index: int = selected_island) -> int:
    if index < 0 or index >= islands.size():
        return 0
    return islands[index].get("buildings", []).size()

func island_building_slots_max(index: int = selected_island) -> int:
    if index < 0 or index >= islands.size():
        return 0
    return int(islands[index].get("max_slots", 4))

func island_expansion_cost(index: int = selected_island) -> int:
    if index < 0 or index >= islands.size():
        return 999999999
    var territory_level := int(islands[index].get("territory_level", 1))
    return 3000 * territory_level

func can_expand_island(index: int = selected_island) -> bool:
    if index < 0 or index >= islands.size() or not is_island_unlocked(index):
        return false
    return island_building_slots_max(index) < 10 and (developer_mode or gold >= island_expansion_cost(index))

func expand_island(index: int = selected_island) -> bool:
    if not can_expand_island(index):
        return false
    var cost := island_expansion_cost(index)
    if not developer_mode:
        gold -= cost
    islands[index]["territory_level"] = int(islands[index].get("territory_level", 1)) + 1
    islands[index]["max_slots"] = int(islands[index].get("max_slots", 4)) + 2
    if index == selected_island:
        _load_active_island()
    _emit_state()
    save_game()
    log_message.emit("%s territory expanded!" % islands[index].get("name", "Island"))
    return true


func is_island_unlocked(index: int) -> bool:
    return index >= 0 and index < islands.size() and bool(islands[index].get("unlocked", false))

func island_unlock_cost(index: int) -> int:
    if index == 1:
        return 10000
    return 999999999

func can_unlock_island(index: int) -> bool:
    if index < 0 or index >= islands.size() or is_island_unlocked(index):
        return false
    if index == 1:
        return level >= 8 and (developer_mode or gold >= island_unlock_cost(index))
    return false

func unlock_island(index: int) -> bool:
    if not can_unlock_island(index):
        if index == 1 and level < 8:
            log_message.emit("Reach island level 8 to unlock Azure Atoll.")
        elif index == 1:
            log_message.emit("Need 10000 gold to unlock Azure Atoll.")
        return false
    if not developer_mode:
        gold -= island_unlock_cost(index)
    islands[index]["unlocked"] = true
    _emit_state()
    save_game()
    log_message.emit("%s unlocked!" % islands[index].get("name", "New Island"))
    return true

func switch_island(index: int) -> bool:
    if index < 0 or index >= islands.size() or not is_island_unlocked(index):
        return false
    _save_active_island()
    selected_island = index
    _load_active_island()
    save_game()
    _emit_state()
    log_message.emit("Travelled to %s." % current_island_name())
    return true

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
        "rank": 1,
        "hp": int(data.get("base_hp", 100)),
        "attack": int(data.get("base_attack", 25))
    }

func habitat_for_monster(monster_index: int) -> int:
    for i in habitats.size():
        var occupied: Array = habitats[i].get("monsters", [])
        if occupied.has(monster_index):
            return i
    return -1

func habitat_capacity(habitat_index: int) -> int:
    if habitat_index < 0 or habitat_index >= habitats.size():
        return 0
    var habitat: Dictionary = habitats[habitat_index]
    for building in buildings:
        if str(building.get("id", "")) == _habitat_building_id(habitat_index):
            return int(building.get("capacity", habitat.get("capacity", 2)))
    return int(habitat.get("capacity", 2))

func _habitat_building_id(habitat_index: int) -> String:
    if habitat_index < 0 or habitat_index >= habitats.size():
        return ""
    return str(habitats[habitat_index].get("building_id", ""))

func can_assign_monster(monster_index: int, habitat_index: int) -> bool:
    if monster_index < 0 or monster_index >= monsters.size():
        return false
    if habitat_index < 0 or habitat_index >= habitats.size():
        return false
    var monster_data: Dictionary = MonsterDatabase.get_monster(str(monsters[monster_index].get("id", "")))
    var habitat_element := str(habitats[habitat_index].get("element", ""))
    if habitat_element != str(monster_data.get("element", "")):
        return false
    var occupied: Array = habitats[habitat_index].get("monsters", [])
    var current_habitat := habitat_for_monster(monster_index)
    if current_habitat == habitat_index:
        return true
    if occupied.size() >= habitat_capacity(habitat_index):
        return false
    return true

func assign_monster_to_habitat(monster_index: int, habitat_index: int) -> bool:
    if not can_assign_monster(monster_index, habitat_index):
        return false

    for habitat in habitats:
        var list: Array = habitat.get("monsters", [])
        list.erase(monster_index)
        habitat["monsters"] = list

    var target: Dictionary = habitats[habitat_index]
    var target_list: Array = target.get("monsters", [])
    if not target_list.has(monster_index):
        target_list.append(monster_index)
    target["monsters"] = target_list
    habitats[habitat_index] = target
    _save_active_island()

    _emit_state()
    save_game()
    log_message.emit("%s moved to %s." % [
        monsters[monster_index].get("nickname", "Monster"),
        target.get("name", "Habitat")
    ])
    return true

func remove_monster_from_habitat(monster_index: int) -> bool:
    var old_habitat := habitat_for_monster(monster_index)
    if old_habitat == -1:
        return false
    var target: Dictionary = habitats[old_habitat]
    var list: Array = target.get("monsters", [])
    list.erase(monster_index)
    target["monsters"] = list
    habitats[old_habitat] = target
    _save_active_island()
    _emit_state()
    save_game()
    return true

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
        if building.get("type", "") == "habitat":
            var habitat_index := -1
            for h in habitats.size():
                if str(habitats[h].get("building_id", "")) == str(building.get("id", "")):
                    habitat_index = h
                    break
            var occupant_count := 0
            if habitat_index >= 0:
                var occupied: Array = habitats[habitat_index].get("monsters", [])
                occupant_count = occupied.size()
            gold_rate *= float(occupant_count)
        if gold_rate > 0.0:
            gold += int(minutes * gold_rate)
            changed = true
        if food_rate > 0.0:
            food += int(minutes * food_rate)
            changed = true
        building["last_tick"] = now
        buildings[i] = building
    if changed:
        _save_active_island()
        save_game()
        if notify:
            _emit_state()

func collect_production() -> void:
    _update_production(true)
    log_message.emit("Island production collected.")

func feed_monster(index: int, amount: int = 1) -> bool:
    if index < 0 or index >= monsters.size():
        return false
    var monster: Dictionary = monsters[index]
    var level_now := int(monster.get("level", 1))
    if level_now >= MAX_MONSTER_LEVEL:
        log_message.emit("%s is already level %d." % [monster["nickname"], MAX_MONSTER_LEVEL])
        return false

    var total_cost := feeding_cost(monster, amount)
    if not developer_mode and food < total_cost:
        log_message.emit("Need %d food." % total_cost)
        return false
    if not developer_mode:
        food -= total_cost

    monster["xp"] = int(monster.get("xp", 0)) + feeding_xp(monster, amount)
    while int(monster["xp"]) >= xp_to_next_level(int(monster["level"])) and int(monster["level"]) < MAX_MONSTER_LEVEL:
        monster["xp"] = int(monster["xp"]) - xp_to_next_level(int(monster["level"]))
        monster["level"] = int(monster["level"]) + 1
        _recalculate_stats(monster)
        xp += 10
        log_message.emit("%s reached level %d." % [monster["nickname"], monster["level"]])

    if int(monster["level"]) >= MAX_MONSTER_LEVEL:
        monster["xp"] = 0

    monsters[index] = monster
    _emit_state()
    save_game()
    return true

func feeding_cost(monster: Dictionary, amount: int = 1) -> int:
    var lv := int(monster.get("level", 1))
    return amount * (10 + lv * 5)

func feeding_xp(monster: Dictionary, amount: int = 1) -> int:
    var lv := int(monster.get("level", 1))
    return amount * (25 + lv * 10)

func xp_to_next_level(monster_level: int) -> int:
    return 100 + monster_level * 75

func rank_upgrade_cost(monster: Dictionary) -> Dictionary:
    var rank := int(monster.get("rank", 1))
    return {
        "gold": rank * 1000,
        "food": rank * 500
    }

func rank_level_requirement(rank: int) -> int:
    return 5 + rank * 5

func can_rank_up(index: int) -> bool:
    if index < 0 or index >= monsters.size():
        return false
    var monster: Dictionary = monsters[index]
    var rank := int(monster.get("rank", 1))
    if rank >= MAX_MONSTER_RANK:
        return false
    return int(monster.get("level", 1)) >= rank_level_requirement(rank)

func rank_up_monster(index: int) -> bool:
    if not can_rank_up(index):
        if index >= 0 and index < monsters.size():
            var current_rank := int(monsters[index].get("rank", 1))
            log_message.emit("Monster needs level %d for its next rank." % rank_level_requirement(current_rank))
        else:
            log_message.emit("Monster cannot rank up.")
        return false
    var monster: Dictionary = monsters[index]
    var cost := rank_upgrade_cost(monster)
    if not developer_mode and (gold < int(cost["gold"]) or food < int(cost["food"])):
        log_message.emit("Need %d gold and %d food to rank up." % [cost["gold"], cost["food"]])
        return false
    if not developer_mode:
        gold -= int(cost["gold"])
        food -= int(cost["food"])
    monster["rank"] = int(monster.get("rank", 1)) + 1
    _recalculate_stats(monster)
    monsters[index] = monster
    log_message.emit("%s reached rank %d." % [monster["nickname"], monster["rank"]])
    _emit_state()
    save_game()
    return true

func _recalculate_stats(monster: Dictionary) -> void:
    var data: Dictionary = MonsterDatabase.get_monster(str(monster["id"]))
    var lv := int(monster["level"])
    var rank := int(monster.get("rank", 1))
    var growth := float(data.get("growth", 1.18))
    var rank_multiplier := 1.0 + float(rank - 1) * 0.15
    monster["hp"] = int(float(data.get("base_hp", 100)) * pow(growth, lv - 1) * rank_multiplier)
    monster["attack"] = int(float(data.get("base_attack", 25)) * pow(growth, lv - 1) * rank_multiplier)

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
    _save_active_island()
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
    _save_active_island()
    log_message.emit("New Sunberry Farm built.")
    _emit_state()
    save_game()
    return true

func can_breed() -> bool:
    if monsters.size() < 2:
        return false
    for slot in breeding_slots:
        if slot.is_empty():
            return true
    return false

func free_breeding_slot() -> int:
    for i in breeding_slots.size():
        if breeding_slots[i].is_empty():
            return i
    return -1

func start_breeding(a: int, b: int) -> bool:
    if a == b or a < 0 or b < 0 or a >= monsters.size() or b >= monsters.size():
        return false
    var slot_index := free_breeding_slot()
    if slot_index == -1:
        log_message.emit("Both breeding slots are busy.")
        return false
    if not developer_mode and gold < 250:
        log_message.emit("Need 250 gold to start breeding.")
        return false
    if not developer_mode:
        gold -= 250

    var parent_a: String = str(monsters[a].get("id", ""))
    var parent_b: String = str(monsters[b].get("id", ""))
    var duration := 20 + ((int(monsters[a].get("level", 1)) + int(monsters[b].get("level", 1))) / 5)
    var slot := {
        "a": a,
        "b": b,
        "parent_a": parent_a,
        "parent_b": parent_b,
        "ready_at": int(Time.get_unix_time_from_system()) + duration
    }
    breeding_slots[slot_index] = slot
    _sync_legacy_breeding()
    log_message.emit("Breeding slot %d started." % (slot_index + 1))
    _emit_state()
    save_game()
    return true

func breeding_time_left(slot_index: int) -> int:
    if slot_index < 0 or slot_index >= breeding_slots.size() or breeding_slots[slot_index].is_empty():
        return 0
    return maxi(0, int(breeding_slots[slot_index].get("ready_at", 0)) - int(Time.get_unix_time_from_system()))

func claim_breeding(slot_index: int = -1) -> bool:
    var chosen := slot_index
    if chosen == -1:
        for i in breeding_slots.size():
            if not breeding_slots[i].is_empty() and breeding_time_left(i) <= 0:
                chosen = i
                break
    if chosen < 0 or chosen >= breeding_slots.size() or breeding_slots[chosen].is_empty():
        return false
    if not developer_mode and breeding_time_left(chosen) > 0:
        return false

    var slot: Dictionary = breeding_slots[chosen]
    var parent_a := str(slot.get("parent_a", ""))
    var parent_b := str(slot.get("parent_b", ""))
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var child_id := MonsterDatabase.choose_breeding_result(parent_a, parent_b, rng)
    egg_inventory.append({
        "monster_id": child_id,
        "created_at": int(Time.get_unix_time_from_system()),
        "parents": [parent_a, parent_b]
    })
    breeding_slots[chosen] = {}
    _sync_legacy_breeding()
    log_message.emit("Egg added to collection: %s." % MonsterDatabase.get_monster(child_id).get("name", child_id))
    _emit_state()
    save_game()
    return true

func incubator_free_slot() -> int:
    for i in incubators.size():
        if incubators[i].is_empty():
            return i
    return -1

func load_egg_to_incubator(egg_index: int, incubator_index: int) -> bool:
    if egg_index < 0 or egg_index >= egg_inventory.size():
        return false
    if incubator_index < 0 or incubator_index >= incubators.size():
        return false
    if not incubators[incubator_index].is_empty():
        return false

    var egg: Dictionary = egg_inventory[egg_index]
    var hatch_seconds := 15
    var monster_id := str(egg.get("monster_id", ""))
    var data: Dictionary = MonsterDatabase.get_monster(monster_id)
    hatch_seconds += int(data.get("breed_time", 15))
    incubators[incubator_index] = {
        "monster_id": monster_id,
        "parents": egg.get("parents", []),
        "ready_at": int(Time.get_unix_time_from_system()) + hatch_seconds
    }
    egg_inventory.remove_at(egg_index)
    _sync_legacy_incubating()
    log_message.emit("%s loaded into incubator %d." % [data.get("name", monster_id), incubator_index + 1])
    _emit_state()
    save_game()
    return true

func incubation_time_left(slot_index: int) -> int:
    if slot_index < 0 or slot_index >= incubators.size() or incubators[slot_index].is_empty():
        return 0
    return maxi(0, int(incubators[slot_index].get("ready_at", 0)) - int(Time.get_unix_time_from_system()))

func claim_incubation(slot_index: int = -1) -> bool:
    var chosen := slot_index
    if chosen == -1:
        for i in incubators.size():
            if not incubators[i].is_empty() and incubation_time_left(i) <= 0:
                chosen = i
                break
    if chosen < 0 or chosen >= incubators.size() or incubators[chosen].is_empty():
        return false
    if not developer_mode and incubation_time_left(chosen) > 0:
        return false

    var id := str(incubators[chosen].get("monster_id", ""))
    var data: Dictionary = MonsterDatabase.get_monster(id)
    monsters.append(_make_monster(id, "%s %d" % [data.get("name", id), monsters.size() + 1]))
    incubators[chosen] = {}
    _sync_legacy_incubating()
    log_message.emit("%s hatched!" % data.get("name", id))
    _emit_state()
    save_game()
    return true

func _sync_legacy_breeding() -> void:
    breeding = {}
    for slot in breeding_slots:
        if not slot.is_empty():
            breeding = slot.duplicate(true)
            break

func _sync_legacy_incubating() -> void:
    incubating = {}
    for slot in incubators:
        if not slot.is_empty():
            incubating = slot.duplicate(true)
            break

func _migrate_legacy_timers() -> void:
    if breeding_slots.is_empty():
        breeding_slots = [{}, {}]
    if incubators.is_empty():
        incubators = [{}, {}, {}]
    if not breeding.is_empty() and breeding_slots[0].is_empty():
        breeding_slots[0] = {
            "a": int(breeding.get("a", 0)),
            "b": int(breeding.get("b", 1)),
            "parent_a": str(breeding.get("parent_a", monsters[int(breeding.get("a", 0))].get("id", ""))) if not monsters.is_empty() else "",
            "parent_b": str(breeding.get("parent_b", monsters[int(breeding.get("b", 1))].get("id", ""))) if monsters.size() > 1 else "",
            "ready_at": int(breeding.get("ready_at", 0))
        }
    if not incubating.is_empty() and incubators[0].is_empty():
        incubators[0] = incubating.duplicate(true)
    _sync_legacy_breeding()
    _sync_legacy_incubating()


func is_stage_unlocked(stage: int) -> bool:
    return stage <= campaign_stage

func stage_reward(stage: int) -> Dictionary:
    var reward_gold := 500 + stage * 125
    var reward_food := 180 + stage * 40
    var reward_xp := 40 + stage * 10
    return {"gold": reward_gold, "food": reward_food, "xp": reward_xp}

func complete_stage(stage: int) -> Dictionary:
    if stage < 1 or stage > 30:
        return {}
    var reward := stage_reward(stage)
    if not completed_stages.has(stage):
        completed_stages.append(stage)
        gold += int(reward.get("gold", 0))
        food += int(reward.get("food", 0))
        xp += int(reward.get("xp", 0))
        campaign_stage = maxi(campaign_stage, stage + 1)
        if xp >= campaign_level_xp():
            level += 1
        log_message.emit("Stage %d complete! +%d gold, +%d food, +%d XP." % [stage, reward["gold"], reward["food"], reward["xp"]])
        _emit_state()
        save_game()
    return reward

func campaign_level_xp() -> int:
    return 100 + level * 100

func grant_dev_resources() -> void:
    developer_mode = true
    gold = 999999
    gems = 9999
    food = 999999
    campaign_stage = 30
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
        "selected_stage": selected_stage,
        "selected_monster": selected_monster,
        "selected_island": selected_island,
        "islands": islands,
        "campaign_stage": campaign_stage,
        "completed_stages": completed_stages,
        "monsters": monsters,
        "habitats": habitats,
        "buildings": buildings,
        "breeding": breeding,
        "incubating": incubating,
        "breeding_slots": breeding_slots,
        "egg_inventory": egg_inventory,
        "incubators": incubators
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
        selected_stage = int(parsed.get("selected_stage", selected_stage))
        selected_monster = int(parsed.get("selected_monster", selected_monster))
        selected_island = int(parsed.get("selected_island", selected_island))
        islands = parsed.get("islands", [])
        campaign_stage = int(parsed.get("campaign_stage", campaign_stage))
        completed_stages = parsed.get("completed_stages", [])
        monsters = parsed.get("monsters", [])
        habitats = parsed.get("habitats", [])
        buildings = parsed.get("buildings", [])
        breeding = parsed.get("breeding", {})
        incubating = parsed.get("incubating", {})
        breeding_slots = parsed.get("breeding_slots", [])
        egg_inventory = parsed.get("egg_inventory", [])
        incubators = parsed.get("incubators", [])
        if monsters.is_empty():
            selected_monster = 0
        else:
            selected_monster = clampi(selected_monster, 0, monsters.size() - 1)
        if breeding_slots.is_empty():
            breeding_slots = [{}, {}]
        if incubators.is_empty():
            incubators = [{}, {}, {}]
        for i in monsters.size():
            var saved_monster: Dictionary = monsters[i]
            if not saved_monster.has("rank"):
                saved_monster["rank"] = 1
            monsters[i] = saved_monster
        _migrate_legacy_timers()
