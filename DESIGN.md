# Monster Islands — development plan

## Core loop

Collect monsters -> place them in habitats -> produce food -> feed and level monsters -> breed new species -> hatch eggs -> build stronger teams -> complete battles and quests -> unlock new islands.

## Phase 1 — Foundation

- Island/home screen
- Resources: gold, gems, food
- Monster collection and monster data
- Feeding and leveling
- Breeding and incubation timers
- Local save/load
- Developer Mode

## Phase 2 — Island economy

- Buildable habitats with capacity and elements
- Food farms
- Gold generation from habitats
- Building upgrade levels
- Construction timers and gem speedups
- Decoration/building placement
- Multiple islands unlocked by player level

## Phase 3 — Monster progression

- Monster book with discovery state
- Rarity tiers
- Elements and elemental interactions
- Skills and passive traits
- Evolution/rank-up system
- Equipment/relic slots as an optional late-game layer

## Phase 4 — Battles

- 3-monster teams
- Turn order based on speed
- Basic attack and four skill slots
- Cooldowns and status effects
- Elemental advantages
- PvE campaign with staged opponents
- Rewards: gold, food, gems, eggs and upgrade items

## Phase 5 — Meta progression

- Quests
- Daily rewards
- Chests
- Achievement system
- Campaign map
- Special islands and limited-time activities

## Phase 6 — Multiplayer

- Player profile
- Arena matchmaking
- Defensive team
- Seasonal ranking
- Battle replay/result summary

For a first release, multiplayer can be simulated/server-backed later; the offline core should remain playable.

## Originality rule

Use original monster names, designs, artwork, UI and lore. Reproduce the genre's gameplay structure, not another game's branded assets, characters or exact presentation.

## Current test route

1. Launch the Godot project.
2. Confirm two starter monsters appear.
3. Feed either monster and verify XP/level/stat changes.
4. Select A and B.
5. Start breeding.
6. Enable Developer Mode to bypass timers during development.
7. Claim egg, hatch monster, and verify collection count increases.
8. Restart the game and verify local save data persists.


## Breeding & hatching expansion

- Two simultaneous breeding slots
- Probability-based breeding recipes
- Egg collection inventory
- Three simultaneous incubators
- Eggs can be loaded into any free incubator
- Incubation time depends on the resulting monster
- Legacy single breeding/incubation saves migrate into the new slots


## Islands & territory

- Green Isle is the starter island with Nature and Fire habitats.
- Azure Atoll unlocks at island level 8 for 10000 gold.
- Azure Atoll starts with Water and Air habitats.
- Each island stores its own buildings, habitats and production timers.
- Monster collection remains shared across islands.
- Island territory has its own building-slot limit and expansion cost.
- Island switching persists the previous island before loading the next one.


## Economy & Live Progression

- Building Shop for the active island
- Purchaseable Nature, Fire, Water and Air habitats
- Food Farm and Gold Mine production buildings
- Building requirements by player level and island slots
- Quest system tied to actual gameplay actions
- Quest rewards: gold, food and gems
- Daily reward with a seven-day streak
- Quest progress and daily streak persist in the save file


## Battle & long-term meta expansion

- Custom saved 3-monster battle team
- Team management screen
- Three-star campaign scoring
- Best stage score persists and is shown on the campaign map
- Achievements with independent rewards
- Shop, quests and daily rewards share the same persistent progression state


## Arena

- Offline arena ladder against original AI teams
- Trophy rating with win/loss changes
- Arena win/loss statistics
- Arena rewards: gold, food and gems
- Shared custom 3-monster Battle Team
- PvP/network layer can be connected later without changing the team UI
