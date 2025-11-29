extends Node
class_name AssetSystem

# Asset System - Tactical cards matching pygame asset_system.py
# 6 asset types distributed on rounds 3, 6, 9, 12, 15, 18, 21...

signal asset_received(player: String, asset_type: int)
signal asset_used(player: String, asset_type: int, target: Variant)
signal asset_effect_applied(effect_type: int, target: Vector2i)

# Asset types matching pygame
enum AssetType {
	FLASHBANG,      # Stuns one enemy piece for 1 round
	ARMOR_PLATES,   # Blocks next capture (5 rounds)
	FIGHTER_JET,    # Destroys target within 3 squares of spotter
	SMOKE_GRENADE,  # 2x2 smoke area blocking LOS (1 round)
	DECOY,          # Creates fake duplicate for one move
	UAV_RECON       # Reveals enemy move or asset use
}

# Status effects
enum StatusEffect {
	STUNNED,    # Can't move this round
	ARMORED,    # Blocks next capture
	SMOKED,     # Hidden from LOS
	REVEALED    # Move is visible to opponent
}

# Asset distribution schedule (matching pygame asset_system.py lines 186-194)
var distribution_schedule: Dictionary = {
	3: AssetType.FLASHBANG,
	6: AssetType.ARMOR_PLATES,
	9: AssetType.FIGHTER_JET,
	12: AssetType.SMOKE_GRENADE,
	15: AssetType.DECOY,
	18: AssetType.UAV_RECON
}

# Player hands (max 2 assets each)
const MAX_HAND_SIZE = 2
var white_hand: Array = []  # Array of AssetType
var black_hand: Array = []

# Pending asset uses (applied during resolution)
var pending_uses: Array = []  # [{player, asset_type, target}]

# Active status effects on pieces
var status_effects: Dictionary = {}  # {pos: {effect: StatusEffect, duration: int, owner: String}}

# Asset data
var asset_data: Dictionary = {
	AssetType.FLASHBANG: {
		"name": "FLASHBANG",
		"description": "Stun enemy piece for 1 round",
		"range": 3,
		"target_type": "enemy_piece",
		"duration": 1
	},
	AssetType.ARMOR_PLATES: {
		"name": "ARMOR PLATES",
		"description": "Block next capture (5 rounds)",
		"range": 0,
		"target_type": "friendly_piece",
		"duration": 5
	},
	AssetType.FIGHTER_JET: {
		"name": "FIGHTER JET",
		"description": "Destroy target within 3 squares",
		"range": 3,
		"target_type": "enemy_piece",
		"duration": 0
	},
	AssetType.SMOKE_GRENADE: {
		"name": "SMOKE GRENADE",
		"description": "2x2 smoke blocking LOS (1 round)",
		"range": 3,
		"target_type": "square",
		"duration": 1
	},
	AssetType.DECOY: {
		"name": "DECOY",
		"description": "Create fake duplicate",
		"range": 0,
		"target_type": "self",
		"duration": 1
	},
	AssetType.UAV_RECON: {
		"name": "UAV RECON",
		"description": "Reveal enemy move or asset",
		"range": 0,
		"target_type": "none",
		"duration": 0
	}
}

func _ready():
	pass

func check_distribution(round_number: int):
	"""Check if assets should be distributed this round."""
	# Rounds 3, 6, 9, 12, 15, 18, 21... (every 3 rounds starting at 3)
	if round_number >= 3 and round_number % 3 == 0:
		var schedule_round = ((round_number - 3) % 18) + 3  # Cycle through 3-18
		if distribution_schedule.has(schedule_round):
			var asset_type = distribution_schedule[schedule_round]
			distribute_asset(asset_type)

func distribute_asset(asset_type: AssetType):
	"""Give asset to both players."""
	# Add to white's hand (respecting max)
	if white_hand.size() < MAX_HAND_SIZE:
		white_hand.append(asset_type)
		emit_signal("asset_received", "white", asset_type)

	# Add to black's hand (respecting max)
	if black_hand.size() < MAX_HAND_SIZE:
		black_hand.append(asset_type)
		emit_signal("asset_received", "black", asset_type)

func use_asset(player: String, asset_index: int, target: Variant) -> bool:
	"""Queue asset use for resolution phase."""
	var hand = white_hand if player == "white" else black_hand

	if asset_index < 0 or asset_index >= hand.size():
		return false

	var asset_type = hand[asset_index]

	# Remove from hand
	hand.remove_at(asset_index)

	# Queue for resolution
	pending_uses.append({
		"player": player,
		"asset_type": asset_type,
		"target": target
	})

	emit_signal("asset_used", player, asset_type, target)
	return true

func apply_pending_effects(board: ChessBoard):
	"""Apply all pending asset effects (called during RESOLUTION phase)."""
	for use in pending_uses:
		_apply_asset_effect(use["player"], use["asset_type"], use["target"], board)

	pending_uses.clear()

func _apply_asset_effect(player: String, asset_type: AssetType, target: Variant, board: ChessBoard):
	"""Apply a single asset effect."""
	match asset_type:
		AssetType.FLASHBANG:
			if target is Vector2i:
				# Stun the piece at target
				status_effects[target] = {
					"effect": StatusEffect.STUNNED,
					"duration": 1,
					"owner": player
				}
				emit_signal("asset_effect_applied", StatusEffect.STUNNED, target)

		AssetType.ARMOR_PLATES:
			if target is Vector2i:
				# Add armor to friendly piece
				status_effects[target] = {
					"effect": StatusEffect.ARMORED,
					"duration": 5,
					"owner": player
				}
				emit_signal("asset_effect_applied", StatusEffect.ARMORED, target)

		AssetType.FIGHTER_JET:
			if target is Vector2i:
				# Destroy target piece (except King)
				var piece = board.get_piece_at(target)
				if piece != "" and piece[1] != "K":
					board.remove_piece_at(target)
					emit_signal("asset_effect_applied", -1, target)  # Destruction effect

		AssetType.SMOKE_GRENADE:
			if target is Vector2i:
				# Create 2x2 smoke area
				for dx in [0, 1]:
					for dy in [0, 1]:
						var smoke_pos = target + Vector2i(dx, dy)
						if smoke_pos.x < 8 and smoke_pos.y < 8:
							status_effects[smoke_pos] = {
								"effect": StatusEffect.SMOKED,
								"duration": 1,
								"owner": player
							}
				emit_signal("asset_effect_applied", StatusEffect.SMOKED, target)

		AssetType.DECOY:
			# Decoy effect - handled separately in movement
			pass

		AssetType.UAV_RECON:
			# Reveal opponent's move (handled in UI)
			var opponent = "black" if player == "white" else "white"
			emit_signal("asset_effect_applied", StatusEffect.REVEALED, Vector2i(-1, -1))

func update_status_effects():
	"""Decrement durations and remove expired effects."""
	var to_remove = []
	for pos in status_effects:
		status_effects[pos]["duration"] -= 1
		if status_effects[pos]["duration"] <= 0:
			to_remove.append(pos)

	for pos in to_remove:
		status_effects.erase(pos)

func is_stunned(pos: Vector2i) -> bool:
	"""Check if piece at position is stunned."""
	if status_effects.has(pos):
		return status_effects[pos]["effect"] == StatusEffect.STUNNED
	return false

func is_armored(pos: Vector2i) -> bool:
	"""Check if piece at position has armor."""
	if status_effects.has(pos):
		return status_effects[pos]["effect"] == StatusEffect.ARMORED
	return false

func is_in_smoke(pos: Vector2i) -> bool:
	"""Check if position is in smoke."""
	if status_effects.has(pos):
		return status_effects[pos]["effect"] == StatusEffect.SMOKED
	return false

func consume_armor(pos: Vector2i):
	"""Remove armor when it blocks a capture."""
	if is_armored(pos):
		status_effects.erase(pos)

func get_hand(player: String) -> Array:
	"""Get player's current hand."""
	return white_hand if player == "white" else black_hand

func get_asset_name(asset_type: AssetType) -> String:
	"""Get display name for asset type."""
	if asset_data.has(asset_type):
		return asset_data[asset_type]["name"]
	return "Unknown"

func get_asset_description(asset_type: AssetType) -> String:
	"""Get description for asset type."""
	if asset_data.has(asset_type):
		return asset_data[asset_type]["description"]
	return ""

func apply_discard_rule():
	"""Enforce max 2 cards rule at end of round."""
	while white_hand.size() > MAX_HAND_SIZE:
		white_hand.pop_back()
	while black_hand.size() > MAX_HAND_SIZE:
		black_hand.pop_back()

func reset():
	"""Reset all asset state."""
	white_hand.clear()
	black_hand.clear()
	pending_uses.clear()
	status_effects.clear()
