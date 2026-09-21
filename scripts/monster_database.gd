extends RefCounted
class_name MonsterDatabase

static func all_monsters() -> Dictionary:
    return {
        "sproutling": {
            "name": "Sproutling", "rarity": "Common", "element": "Nature",
            "base_hp": 120, "base_attack": 32, "growth": 1.18, "breed_time": 12
        },
        "embercub": {
            "name": "Embercub", "rarity": "Common", "element": "Fire",
            "base_hp": 105, "base_attack": 38, "growth": 1.20, "breed_time": 12
        },
        "tidehorn": {
            "name": "Tidehorn", "rarity": "Rare", "element": "Water",
            "base_hp": 155, "base_attack": 41, "growth": 1.23, "breed_time": 30
        },
        "stormwing": {
            "name": "Stormwing", "rarity": "Rare", "element": "Air",
            "base_hp": 145, "base_attack": 47, "growth": 1.25, "breed_time": 30
        },
        "mossback": {
            "name": "Mossback", "rarity": "Epic", "element": "Nature",
            "base_hp": 240, "base_attack": 62, "growth": 1.29, "breed_time": 60
        },
        "flaretoad": {
            "name": "Flaretoad", "rarity": "Rare", "element": "Fire",
            "base_hp": 180, "base_attack": 55, "growth": 1.24, "breed_time": 40
        },
        "reefclaw": {
            "name": "Reefclaw", "rarity": "Rare", "element": "Water",
            "base_hp": 190, "base_attack": 52, "growth": 1.24, "breed_time": 40
        },
        "cloudram": {
            "name": "Cloudram", "rarity": "Epic", "element": "Air",
            "base_hp": 210, "base_attack": 66, "growth": 1.28, "breed_time": 55
        },
        "thornhide": {
            "name": "Thornhide", "rarity": "Epic", "element": "Nature",
            "base_hp": 280, "base_attack": 60, "growth": 1.30, "breed_time": 65
        },
        "voltica": {
            "name": "Voltica", "rarity": "Epic", "element": "Fire",
            "base_hp": 230, "base_attack": 78, "growth": 1.31, "breed_time": 65
        }
    }

static func get_monster(monster_id: String) -> Dictionary:
    return all_monsters().get(monster_id, {})

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
