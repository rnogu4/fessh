class_name Difficulty
extends RefCounted

## IMPORTANT CAVEAT: there is no formula that maps search depth/randomness
## to a specific Elo rating for a custom ruleset like Fessh -- Elo numbers
## are calibrated against a huge pool of real games in standard chess, and
## none of that data applies here. These presets are starting points to
## playtest and retune, not calibrated targets. Treat "~500" and "~750" as
## relative labels (level 3 noticeably stronger than 1/2), not guarantees.

static func profile_for_level(level: int) -> Dictionary:
	match level:
		1:
			return {
				"depth": 2,
				"randomness_margin": 2.0,
				"blunder_chance": 0.10,
				"powerups_enabled": false,
			}
		2:
			return {
				"depth": 3,
				"randomness_margin": 1.5,
				"blunder_chance": 0.07,
				"powerups_enabled": true,
			}
		3:
			return {
				"depth": 3,
				"randomness_margin": 1.0,
				"blunder_chance": 0.03,
				"powerups_enabled": true,
			}
		_:
			return profile_for_level(1)
