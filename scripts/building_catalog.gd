extends RefCounted
class_name BuildingCatalog

static func all_items() -> Dictionary:
    return {
        "nature_habitat": {
            "name": "Nature Habitat",
            "type": "habitat",
            "element": "Nature",
            "cost": 2500,
            "capacity": 2,
            "gold_per_minute": 35,
            "level": 1,
            "description": "Home for Nature monsters."
        },
        "fire_habitat": {
            "name": "Fire Habitat",
            "type": "habitat",
            "element": "Fire",
            "cost": 3000,
            "capacity": 2,
            "gold_per_minute": 40,
            "level": 2,
            "description": "A hot home for Fire monsters."
        },
        "water_habitat": {
            "name": "Water Habitat",
            "type": "habitat",
            "element": "Water",
            "cost": 3500,
            "capacity": 2,
            "gold_per_minute": 45,
            "level": 2,
            "description": "A cool habitat for Water monsters."
        },
        "air_habitat": {
            "name": "Air Habitat",
            "type": "habitat",
            "element": "Air",
            "cost": 4000,
            "capacity": 2,
            "gold_per_minute": 50,
            "level": 3,
            "description": "A high-altitude home for Air monsters."
        },
        "sunberry_farm": {
            "name": "Sunberry Farm",
            "type": "farm",
            "element": "",
            "cost": 1500,
            "capacity": 0,
            "food_per_minute": 45,
            "level": 1,
            "description": "Produces food over time."
        },
        "gold_mine": {
            "name": "Gold Mine",
            "type": "gold_mine",
            "element": "",
            "cost": 5000,
            "capacity": 0,
            "gold_per_minute": 80,
            "level": 3,
            "description": "Produces gold without needing a monster."
        }
    }

static func get_item(item_id: String) -> Dictionary:
    return all_items().get(item_id, {})
