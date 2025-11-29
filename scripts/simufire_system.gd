extends Node
class_name SimuFireSystem

# SimuFire - Simultaneous Turn Chess System
# Both players plan their moves secretly, then both execute at once
# Matches pygame simufire.py mechanic

signal planning_started(phase: int)
signal planning_complete
signal moves_resolved
signal collision_occurred(pos: Vector2i, white_piece: String, black_piece: String)

enum Phase { PLANNING_WHITE, PLANNING_BLACK, RESOLUTION }

var current_phase: Phase = Phase.PLANNING_WHITE
var white_planned_move: Dictionary = {}  # {from: Vector2i, to: Vector2i}
var black_planned_move: Dictionary = {}
var is_active: bool = false

# Resolution timing
var resolution_delay: float = 0.5  # Seconds between move animations
var resolution_timer: float = 0.0
var resolution_step: int = 0

# Collision rules
enum CollisionResult { WHITE_WINS, BLACK_WINS, BOTH_DESTROYED, BOUNCE_BACK }

# Piece strength for collisions (higher wins)
var piece_strength: Dictionary = {
	"P": 1,   # Pawn
	"N": 3,   # Knight
	"B": 3,   # Bishop
	"R": 5,   # Rook
	"Q": 9,   # Queen
	"K": 100  # King (always wins unless vs King)
}

func _ready():
	pass

func start_simufire():
	"""Start a SimuFire turn."""
	is_active = true
	current_phase = Phase.PLANNING_WHITE
	white_planned_move = {}
	black_planned_move = {}
	resolution_step = 0

	emit_signal("planning_started", 0)

func plan_move(color: String, from: Vector2i, to: Vector2i) -> bool:
	"""Plan a move for the given color."""
	if not is_active:
		return false

	var move = {"from": from, "to": to}

	if color == "white" and current_phase == Phase.PLANNING_WHITE:
		white_planned_move = move
		current_phase = Phase.PLANNING_BLACK
		emit_signal("planning_started", 1)
		return true
	elif color == "black" and current_phase == Phase.PLANNING_BLACK:
		black_planned_move = move
		emit_signal("planning_complete")
		_start_resolution()
		return true

	return false

func _start_resolution():
	"""Begin resolving the simultaneous moves."""
	current_phase = Phase.RESOLUTION
	resolution_step = 0
	resolution_timer = 0.0

func _process(delta):
	if not is_active or current_phase != Phase.RESOLUTION:
		return

	resolution_timer += delta

	if resolution_timer >= resolution_delay:
		resolution_timer = 0.0
		_resolve_next_step()

func _resolve_next_step():
	"""Process the next step of move resolution."""
	resolution_step += 1

	match resolution_step:
		1:
			# Check for collisions
			_check_collisions()
		2:
			# Execute moves
			_execute_moves()
		3:
			# Finish resolution
			_finish_resolution()

func _check_collisions():
	"""Check if the planned moves result in collisions."""
	if white_planned_move.size() == 0 or black_planned_move.size() == 0:
		return

	var white_to = white_planned_move["to"]
	var black_to = black_planned_move["to"]

	# Head-on collision: Both moving to same square
	if white_to == black_to:
		_resolve_collision_at(white_to)
		return

	# Swap collision: Each moving to where the other was
	var white_from = white_planned_move["from"]
	var black_from = black_planned_move["from"]

	if white_to == black_from and black_to == white_from:
		_resolve_swap_collision()
		return

func _resolve_collision_at(pos: Vector2i):
	"""Resolve a collision where both pieces are moving to the same square."""
	var white_piece = _get_piece_type_from_move(white_planned_move)
	var black_piece = _get_piece_type_from_move(black_planned_move)

	var white_str = piece_strength.get(white_piece, 1)
	var black_str = piece_strength.get(black_piece, 1)

	var result: CollisionResult

	if white_str > black_str:
		result = CollisionResult.WHITE_WINS
	elif black_str > white_str:
		result = CollisionResult.BLACK_WINS
	else:
		# Equal strength - both destroyed (unless kings)
		if white_piece == "K" or black_piece == "K":
			result = CollisionResult.BOUNCE_BACK
		else:
			result = CollisionResult.BOTH_DESTROYED

	_apply_collision_result(result, pos)
	emit_signal("collision_occurred", pos, "w" + white_piece, "b" + black_piece)

func _resolve_swap_collision():
	"""Resolve a collision where pieces are swapping positions."""
	# This is a pass-through collision - compare strength
	var white_piece = _get_piece_type_from_move(white_planned_move)
	var black_piece = _get_piece_type_from_move(black_planned_move)

	var white_str = piece_strength.get(white_piece, 1)
	var black_str = piece_strength.get(black_piece, 1)

	if white_str > black_str:
		# White captures black in transit
		black_planned_move = {}  # Cancel black's move
	elif black_str > white_str:
		# Black captures white in transit
		white_planned_move = {}  # Cancel white's move
	else:
		# Both bounce back
		white_planned_move = {}
		black_planned_move = {}

func _get_piece_type_from_move(move: Dictionary) -> String:
	"""Get piece type from planned move (needs board reference)."""
	# This would normally query the board
	# For now, return a placeholder
	return "P"

func _apply_collision_result(result: CollisionResult, pos: Vector2i):
	"""Apply the result of a collision."""
	match result:
		CollisionResult.WHITE_WINS:
			black_planned_move = {}  # Black's move cancelled, piece removed
		CollisionResult.BLACK_WINS:
			white_planned_move = {}  # White's move cancelled, piece removed
		CollisionResult.BOTH_DESTROYED:
			# Both moves happen but both pieces destroyed at destination
			pass
		CollisionResult.BOUNCE_BACK:
			# Both moves cancelled
			white_planned_move = {}
			black_planned_move = {}

func _execute_moves():
	"""Execute the planned moves after collision resolution."""
	# This would communicate with the chess board to actually move pieces
	pass

func _finish_resolution():
	"""Complete the SimuFire turn."""
	is_active = false
	current_phase = Phase.PLANNING_WHITE
	emit_signal("moves_resolved")

func get_white_planned_move() -> Dictionary:
	return white_planned_move

func get_black_planned_move() -> Dictionary:
	return black_planned_move

func is_simufire_active() -> bool:
	return is_active

func get_current_phase() -> Phase:
	return current_phase

func cancel():
	"""Cancel the current SimuFire turn."""
	is_active = false
	current_phase = Phase.PLANNING_WHITE
	white_planned_move = {}
	black_planned_move = {}
