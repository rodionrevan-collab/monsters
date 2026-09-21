extends RefCounted
class_name MonsterDatabase

static func all_monsters() -> Dictionary:
    return {
        "sproutling": {
            "name": "Sproutling",
            "rarity": "Common",
            "element": "Nature",
            "base_hp": 120,
            "base_attack": 32,
            "growth": 1.18,
            "breed_time": 12
        },
        "embercub": {
            "name": "Embercub",
            "rarity": "Common",
            "element": "Fire",
            "base_hp": 105,
            "base_attack": 38,
            "growth": 1.20,
            "breed_time": 12
        },
        "tidehorn": {
            "name": "Tidehorn",
            "rarity": "Rare",
            "element": "Water",
            "base_hp": 155,
            "base_attack": 41,
            "growth": 1.23,
            "breed_time": 30
        },
        "stormwing": {
            "name": "Stormwing",
            "rarity": "Rare",
            "element": "Air",
            "base_hp": 145,
            "base_attack": 47,
            "growth": 1.25,
            "breed_time": 30
        },
        "mossback": {
            "name": "Mossback",
            "rarity": "Epic",
            "element": "Nature",
            "base_hp": 240,
            "base_attack": 62,
            "growth": 1.29,
            "breed_time": 60
        }
    }

static func get_monster(monster_id: String) -> Dictionary:
    return all_monsters().get(monster_id, {})
