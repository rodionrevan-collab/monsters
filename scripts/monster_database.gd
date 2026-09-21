extends RefCounted
class_name MonsterDatabase

static func all_monsters() -> Dictionary:
    return {
        "sproutling": {
            "name": "Sproutling", "rarity": "Common", "element": "Nature",
            "base_hp": 120, "base_attack": 32, "growth": 1.18, "breed_time": 12,
            "lore": "A young forest spirit that grows stronger near living things."
        },
        "embercub": {
            "name": "Embercub", "rarity": "Common", "element": "Fire",
            "base_hp": 105, "base_attack": 38, "growth": 1.20, "breed_time": 12,
            "lore": "A small flame beast with a surprisingly fierce roar."
        },
        "tidehorn": {
            "name": "Tidehorn", "rarity": "Rare", "element": "Water",
            "base_hp": 155, "base_attack": 41, "growth": 1.23, "breed_time": 30,
            "lore": "A horned swimmer that can pull waves behind its charge."
        },
        "stormwing": {
            "name": "Stormwing", "rarity": "Rare", "element": "Air",
            "base_hp": 145, "base_attack": 47, "growth": 1.25, "breed_time": 30,
            "lore": "A swift flier that rides thunderclouds above the islands."
        },
        "mossback": {
            "name": "Mossback", "rarity": "Epic", "element": "Nature",
            "base_hp": 240, "base_attack": 62, "growth": 1.29, "breed_time": 60,
            "lore": "An ancient woodland guardian covered in living moss."
        },
        "flaretoad": {
            "name": "Flaretoad", "rarity": "Rare", "element": "Fire",
            "base_hp": 180, "base_attack": 55, "growth": 1.24, "breed_time": 40,
            "lore": "A hot-tempered amphibian that spits burning sparks."
        },
        "reefclaw": {
            "name": "Reefclaw", "rarity": "Rare", "element": "Water",
            "base_hp": 190, "base_attack": 52, "growth": 1.24, "breed_time": 40,
            "lore": "A reef hunter with a shell hard enough to deflect attacks."
        },
        "cloudram": {
            "name": "Cloudram", "rarity": "Epic", "element": "Air",
            "base_hp": 210, "base_attack": 66, "growth": 1.28, "breed_time": 55,
            "lore": "A sky ram whose horns crackle with static."
        },
        "thornhide": {
            "name": "Thornhide", "rarity": "Epic", "element": "Nature",
            "base_hp": 280, "base_attack": 60, "growth": 1.30, "breed_time": 65,
            "lore": "A heavy guardian that turns its body into a wall of thorns."
        },
        "voltica": {
            "name": "Voltica", "rarity": "Epic", "element": "Fire",
            "base_hp": 230, "base_attack": 78, "growth": 1.31, "breed_time": 65,
            "lore": "A rare fire predator that stores electricity in its mane."
        }
    }

static func get_monster(monster_id: String) -> Dictionary:
    return all_monsters().get(monster_id, {})

static func get_skills(monster_id: String) -> Array[Dictionary]:
    var data: Dictionary = get_monster(monster_id)
    var element := str(data.get("element", "Neutral"))
    return [
        {"name": "Quick Strike", "power": 1.0, "element": element, "cooldown": 0, "kind": "damage"},
        {"name": "Heavy Blow", "power": 1.45, "element": element, "cooldown": 1, "kind": "damage"},
        {"name": "Element Surge", "power": 1.9, "element": element, "cooldown": 2, "kind": "damage"},
        {"name": "Guardian Pulse", "power": 0.9, "element": element, "cooldown": 3, "kind": "heal_self"}
    ]

static func effectiveness(attacking_element: String, defending_element: String) -> float:
    if attacking_element == "Fire" and defending_element == "Nature":
        return 1.5
    if attacking_element == "Nature" and defending_element == "Water":
        return 1.5
    if attacking_element == "Water" and defending_element == "Fire":
        return 1.5
    if attacking_element == "Nature" and defending_element == "Fire":
        return 0.75
    if attacking_element == "Water" and defending_element == "Nature":
        return 0.75
    if attacking_element == "Fire" and defending_element == "Water":
        return 0.75
    return 1.0
