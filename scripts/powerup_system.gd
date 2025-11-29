extends Node
class_name PowerupSystem

# Complete 14 Powerup System - matching pygame powerups.py

signal powerup_activated(powerup_name: String, player: String, target: Variant)
signal points_changed(player: String, points: int)
signal powerup_targeting(powerup_name: String)
signal targeting_cancelled

# Player points
var points: Dictionary = {"white": 0, "black": 0}

# Piece point values for captures
var piece_values: Dictionary = {
	"P": 1,  # Pawn
	"N": 3,  # Knight
	"B": 3,  # Bishop
	"R": 5,  # Rook
	"Q": 9,  # Queen
	"K": 0   # King (game ends on capture)
}

# All 14 powerups with costs and descriptions (matching pygame)
var powerups: Dictionary = {
	# BASIC TIER (5-10 pts)
	"shield": {
		"cost": 5,
		"name": "SHIELD",
		"description": "Protect a piece for 3 turns",
		"tier": "basic",
		"target_type": "friendly_piece",
		"duration": 3
	},
	"gun": {
		"cost": 7,
		"name": "GUN",
		"description": "Destroy enemy piece in line of sight",
		"tier": "basic",
		"target_type": "enemy_piece"
	},
	"airstrike": {
		"cost": 10,
		"name": "AIRSTRIKE",
		"description": "3x3 area bombardment",
		"tier": "basic",
		"target_type": "square",
		"area": 3
	},
	# MID TIER (12-20 pts)
	"smoke": {
		"cost": 12,
		"name": "SMOKE",
		"description": "Hide pieces for 5 turns",
		"tier": "mid",
		"target_type": "friendly_piece",
		"duration": 5
	},
	"paratroopers": {
		"cost": 15,
		"name": "PARATROOPERS",
		"description": "Drop 3 tactical pawns",
		"tier": "mid",
		"target_type": "empty_squares",
		"count": 3
	},
	"recon": {
		"cost": 15,
		"name": "RECON DRONE",
		"description": "Reveal opponent's next 3 moves",
		"tier": "mid",
		"target_type": "none"
	},
	"medic": {
		"cost": 18,
		"name": "MEDIC",
		"description": "Resurrect captured piece on back row",
		"tier": "mid",
		"target_type": "resurrection"
	},
	"nuke": {
		"cost": 20,
		"name": "TACTICAL NUKE",
		"description": "5x5 area destruction (Kings spared)",
		"tier": "mid",
		"target_type": "square",
		"area": 5
	},
	# HIGH TIER (25-40 pts)
	"teleport": {
		"cost": 25,
		"name": "TELEPORTER",
		"description": "Move any piece to empty square",
		"tier": "high",
		"target_type": "teleport"
	},
	"freeze": {
		"cost": 30,
		"name": "TIME FREEZE",
		"description": "Skip enemy's next turn",
		"tier": "high",
		"target_type": "none"
	},
	"forcefield": {
		"cost": 35,
		"name": "FORCEFIELD",
		"description": "3x3 barrier for 5 turns",
		"tier": "high",
		"target_type": "square",
		"area": 3,
		"duration": 5
	},
	"mind_control": {
		"cost": 40,
		"name": "MIND CONTROL",
		"description": "Control enemy piece for 3 turns",
		"tier": "high",
		"target_type": "enemy_piece",
		"duration": 3
	},
	# ULTIMATE TIER (50-60 pts)
	"laser": {
		"cost": 50,
		"name": "ORBITAL LASER",
		"description": "Destroy all pieces in a line",
		"tier": "ultimate",
		"target_type": "line"
	},
	"chopper": {
		"cost": 60,
		"name": "CHOPPER GUNNER",
		"description": "First-person helicopter minigun",
		"tier": "ultimate",
		"target_type": "special"
	}
}

# Active effects tracking
var shielded_pieces: Dictionary = {}  # {pos: {color, turns_remaining}}
var smoked_pieces: Dictionary = {}     # {pos: {color, turns_remaining}}
var forcefields: Array = []            # [{center, turns_remaining, owner}]
var mind_controlled: Dictionary = {}   # {pos: {original_owner, controller, turns_remaining}}
var frozen_turns: Dictionary = {"white": 0, "black": 0}

# Currently active targeting
var active_powerup: String = ""
var targeting_player: String = ""

# Freeplay mode (unlimited points)
var freeplay_mode: bool = false

# Captured pieces for medic resurrection
var captured_white: Array = []
var captured_black: Array = []

func _ready():
	pass

func set_freeplay_mode(enabled: bool):
	"""Enable/disable freeplay mode (unlimited points)."""
	freeplay_mode = enabled
	if enabled:
		points["white"] = 999
		points["black"] = 999

func add_points_for_capture(captured_piece: String, capturing_player: String) -> int:
	"""Add points when a piece is captured."""
	if captured_piece.length() >= 2:
		var piece_type = captured_piece[1]
		if piece_values.has(piece_type):
			var value = piece_values[piece_type]
			points[capturing_player] += value
			emit_signal("points_changed", capturing_player, points[capturing_player])

			# Track captured piece for medic
			var opponent = "black" if capturing_player == "white" else "white"
			if opponent == "white":
				captured_white.append(captured_piece)
			else:
				captured_black.append(captured_piece)

			return value
	return 0

func can_afford_powerup(player: String, powerup_key: String) -> bool:
	"""Check if player can afford a powerup."""
	if freeplay_mode:
		return true
	if powerups.has(powerup_key):
		return points[player] >= powerups[powerup_key]["cost"]
	return false

func start_powerup_targeting(player: String, powerup_key: String) -> bool:
	"""Start targeting for a powerup."""
	if not can_afford_powerup(player, powerup_key):
		return false

	active_powerup = powerup_key
	targeting_player = player
	emit_signal("powerup_targeting", powerup_key)
	return true

func cancel_targeting():
	"""Cancel current powerup targeting."""
	active_powerup = ""
	targeting_player = ""
	emit_signal("targeting_cancelled")

func use_powerup(player: String, powerup_key: String, target: Variant = null) -> bool:
	"""Use a powerup with optional target."""
	if not can_afford_powerup(player, powerup_key):
		return false

	# Deduct cost (unless freeplay)
	if not freeplay_mode:
		points[player] -= powerups[powerup_key]["cost"]
		emit_signal("points_changed", player, points[player])

	# Apply effect based on powerup type
	_apply_powerup_effect(player, powerup_key, target)

	emit_signal("powerup_activated", powerup_key, player, target)
	active_powerup = ""
	targeting_player = ""
	return true

func _apply_powerup_effect(player: String, powerup_key: String, target: Variant):
	"""Apply the effect of a powerup."""
	var powerup = powerups[powerup_key]

	match powerup_key:
		"shield":
			if target is Vector2i:
				shielded_pieces[target] = {
					"color": player,
					"turns_remaining": powerup["duration"]
				}

		"freeze":
			var opponent = "black" if player == "white" else "white"
			frozen_turns[opponent] = 1

		"forcefield":
			if target is Vector2i:
				forcefields.append({
					"center": target,
					"turns_remaining": powerup["duration"],
					"owner": player
				})

		"smoke":
			if target is Vector2i:
				smoked_pieces[target] = {
					"color": player,
					"turns_remaining": powerup["duration"]
				}

		"mind_control":
			if target is Vector2i:
				var opponent = "black" if player == "white" else "white"
				mind_controlled[target] = {
					"original_owner": opponent,
					"controller": player,
					"turns_remaining": powerup["duration"]
				}

func update_turn_effects(current_player: String):
	"""Update all turn-based effects at the start of a turn."""
	# Update shielded pieces
	var to_remove_shields = []
	for pos in shielded_pieces:
		shielded_pieces[pos]["turns_remaining"] -= 1
		if shielded_pieces[pos]["turns_remaining"] <= 0:
			to_remove_shields.append(pos)
	for pos in to_remove_shields:
		shielded_pieces.erase(pos)

	# Update smoked pieces
	var to_remove_smoke = []
	for pos in smoked_pieces:
		smoked_pieces[pos]["turns_remaining"] -= 1
		if smoked_pieces[pos]["turns_remaining"] <= 0:
			to_remove_smoke.append(pos)
	for pos in to_remove_smoke:
		smoked_pieces.erase(pos)

	# Update forcefields
	var to_remove_fields = []
	for i in range(forcefields.size()):
		forcefields[i]["turns_remaining"] -= 1
		if forcefields[i]["turns_remaining"] <= 0:
			to_remove_fields.append(i)
	for i in range(to_remove_fields.size() - 1, -1, -1):
		forcefields.remove_at(to_remove_fields[i])

	# Update mind controlled pieces
	var to_remove_mind = []
	for pos in mind_controlled:
		mind_controlled[pos]["turns_remaining"] -= 1
		if mind_controlled[pos]["turns_remaining"] <= 0:
			to_remove_mind.append(pos)
	for pos in to_remove_mind:
		mind_controlled.erase(pos)

func is_turn_frozen(player: String) -> bool:
	"""Check if player's turn is frozen."""
	if frozen_turns[player] > 0:
		frozen_turns[player] -= 1
		return true
	return false

func is_shielded(pos: Vector2i) -> bool:
	"""Check if a position has a shield."""
	return shielded_pieces.has(pos)

func is_smoked(pos: Vector2i) -> bool:
	"""Check if a position is in smoke."""
	return smoked_pieces.has(pos)

func is_in_forcefield(pos: Vector2i, player_color: String) -> bool:
	"""Check if a position is blocked by enemy forcefield."""
	for field in forcefields:
		if field["owner"] != player_color:
			var center = field["center"]
			if abs(pos.x - center.x) <= 1 and abs(pos.y - center.y) <= 1:
				return true
	return false

func get_controlled_color(pos: Vector2i) -> String:
	"""Get who controls a piece (for mind control)."""
	if mind_controlled.has(pos):
		return mind_controlled[pos]["controller"]
	return ""

func move_shield(from_pos: Vector2i, to_pos: Vector2i):
	"""Move a shield when its piece moves."""
	if shielded_pieces.has(from_pos):
		var shield_data = shielded_pieces[from_pos]
		shielded_pieces.erase(from_pos)
		shielded_pieces[to_pos] = shield_data

func remove_shield(pos: Vector2i):
	"""Remove shield at position."""
	shielded_pieces.erase(pos)

func get_points(player: String) -> int:
	"""Get current points for player."""
	return points.get(player, 0)

func get_powerup_list() -> Array:
	"""Get list of all powerup keys."""
	return powerups.keys()

func get_powerup_data(key: String) -> Dictionary:
	"""Get data for a specific powerup."""
	return powerups.get(key, {})

func get_affordable_powerups(player: String) -> Array:
	"""Get list of powerups the player can afford."""
	var affordable = []
	for key in powerups:
		if can_afford_powerup(player, key):
			affordable.append(key)
	return affordable

func get_active_powerup() -> String:
	"""Get currently active powerup for targeting."""
	return active_powerup

func get_targeting_player() -> String:
	"""Get player currently targeting with powerup."""
	return targeting_player

func reset():
	"""Reset all powerup state."""
	points = {"white": 0, "black": 0}
	shielded_pieces.clear()
	smoked_pieces.clear()
	forcefields.clear()
	mind_controlled.clear()
	frozen_turns = {"white": 0, "black": 0}
	captured_white.clear()
	captured_black.clear()
	active_powerup = ""
	targeting_player = ""
	freeplay_mode = false
