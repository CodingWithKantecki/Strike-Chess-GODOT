extends Node2D
class_name ChessBoard

# SimuFire Chess Board - Simultaneous Turn System
# Matches pygame board.py EXACTLY

signal piece_selected(pos: Vector2i)
signal piece_moved(from: Vector2i, to: Vector2i, was_capture: bool)
signal turn_changed(color: String)
signal game_over(winner: String)
signal phase_changed(phase: int)
signal timer_updated(seconds: float)
signal move_locked(color: String)
signal countdown_tick(number: int)
signal moves_resolved
signal collision_occurred(pos: Vector2i, type: String)

# SimuFire Phases (matching pygame board.py lines 25-31)
enum SimuFirePhase { PLANNING, COUNTDOWN, RESOLUTION, VICTORY, END }

# Board configuration
const BOARD_SIZE = 8
const SQUARE_SIZE = 81
const BOARD_OFFSET = Vector2(362, 110)
const PIECE_SCALE = 3.0

# Colors
const LIGHT_SQUARE = Color(0.941, 0.851, 0.710)
const DARK_SQUARE = Color(0.710, 0.533, 0.388)
const HIGHLIGHT_COLOR = Color(0.73, 0.79, 0.17, 0.6)
const VALID_MOVE_COLOR = Color(0.2, 0.8, 0.2, 0.5)
const CAPTURE_COLOR = Color(0.8, 0.2, 0.2, 0.5)
const WHITE_PLAN_COLOR = Color(0.2, 0.5, 1.0, 0.6)  # Blue for white's plan
const BLACK_PLAN_COLOR = Color(1.0, 0.3, 0.3, 0.6)  # Red for black's plan
const LOCKED_COLOR = Color(0.0, 1.0, 0.0, 0.3)  # Green when locked

# Timing (matching pygame - 30 seconds total, transition at 25)
const PLANNING_DURATION = 25.0  # Seconds for planning phase
const COUNTDOWN_DURATION = 4.0   # 3-2-1-GO
const ANIMATION_DURATION = 0.5   # Move animation time

# Game state
var board: Array = []
var current_phase: SimuFirePhase = SimuFirePhase.PLANNING
var round_number: int = 1

# SimuFire state
var round_start_time: float = 0.0
var countdown_start_time: float = 0.0
var animation_start_time: float = 0.0

# Both players' planned moves
var white_plan: Dictionary = {}  # {from: Vector2i, to: Vector2i}
var black_plan: Dictionary = {}
var white_locked: bool = false
var black_locked: bool = false

# Current selection (per player during planning)
var white_selected: Vector2i = Vector2i(-1, -1)
var black_selected: Vector2i = Vector2i(-1, -1)
var white_valid_moves: Array = []
var black_valid_moves: Array = []

# Animation state
var animating_moves: Array = []  # [{piece, from, to, sprite}]
var animation_progress: float = 0.0

# Collision results
var collision_results: Array = []  # Store collision info for display

# Piece data
var piece_textures: Dictionary = {}
var piece_sprites: Dictionary = {}

# Status effects (for assets)
var status_effects: Dictionary = {}  # {pos: {effect: type, duration: int}}

# Last captured piece for points
var last_captured_piece: String = ""

# En passant and castling
var en_passant_target: Vector2i = Vector2i(-1, -1)
var castling_rights: Dictionary = {
	"white_king": true, "white_queen": true,
	"black_king": true, "black_queen": true
}

func _ready():
	load_piece_textures()
	initialize_board()
	create_piece_sprites()
	start_new_round()

func load_piece_textures():
	var pieces = {
		"wP": "W_Pawn", "wN": "W_Knight", "wB": "W_Bishop",
		"wR": "W_Rook", "wQ": "W_Queen", "wK": "W_King",
		"bP": "B_Pawn", "bN": "B_Knight", "bB": "B_Bishop",
		"bR": "B_Rook", "bQ": "B_Queen", "bK": "B_King"
	}
	for code in pieces:
		var path = "res://assets/pieces/" + pieces[code] + ".png"
		var texture = load(path)
		if texture:
			piece_textures[code] = texture

func initialize_board():
	board = [
		["bR", "bN", "bB", "bQ", "bK", "bB", "bN", "bR"],
		["bP", "bP", "bP", "bP", "bP", "bP", "bP", "bP"],
		["", "", "", "", "", "", "", ""],
		["", "", "", "", "", "", "", ""],
		["", "", "", "", "", "", "", ""],
		["", "", "", "", "", "", "", ""],
		["wP", "wP", "wP", "wP", "wP", "wP", "wP", "wP"],
		["wR", "wN", "wB", "wQ", "wK", "wB", "wN", "wR"]
	]

func create_piece_sprites():
	for sprite in piece_sprites.values():
		sprite.queue_free()
	piece_sprites.clear()

	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var piece = board[row][col]
			if piece != "":
				create_sprite_at(Vector2i(col, row), piece)

func create_sprite_at(pos: Vector2i, piece: String):
	if not piece_textures.has(piece):
		return
	var sprite = Sprite2D.new()
	sprite.texture = piece_textures[piece]
	sprite.position = board_to_screen(pos)
	sprite.scale = Vector2(PIECE_SCALE, PIECE_SCALE)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	piece_sprites[pos] = sprite

func board_to_screen(pos: Vector2i) -> Vector2:
	return BOARD_OFFSET + Vector2(pos.x * SQUARE_SIZE + SQUARE_SIZE/2,
								   pos.y * SQUARE_SIZE + SQUARE_SIZE/2)

func screen_to_board(screen_pos: Vector2) -> Vector2i:
	var local_pos = screen_pos - BOARD_OFFSET
	var col = int(local_pos.x / SQUARE_SIZE)
	var row = int(local_pos.y / SQUARE_SIZE)
	if col >= 0 and col < 8 and row >= 0 and row < 8:
		return Vector2i(col, row)
	return Vector2i(-1, -1)

# ==================== SIMUFIRE SYSTEM ====================

func start_new_round():
	"""Start a new SimuFire round."""
	round_start_time = Time.get_unix_time_from_system()
	current_phase = SimuFirePhase.PLANNING

	# Reset plans
	white_plan = {}
	black_plan = {}
	white_locked = false
	black_locked = false
	white_selected = Vector2i(-1, -1)
	black_selected = Vector2i(-1, -1)
	white_valid_moves = []
	black_valid_moves = []
	collision_results = []

	emit_signal("phase_changed", current_phase)

func _process(delta):
	update_simufire()

	if current_phase == SimuFirePhase.RESOLUTION:
		update_animation(delta)

	queue_redraw()

func update_simufire():
	"""Update SimuFire state machine - matching pygame board.py update_simufire()"""
	match current_phase:
		SimuFirePhase.PLANNING:
			var elapsed = Time.get_unix_time_from_system() - round_start_time
			var remaining = max(0, 30.0 - elapsed)
			emit_signal("timer_updated", remaining)

			# Check if both players locked OR time expired (25 seconds)
			if (white_locked and black_locked) or elapsed >= PLANNING_DURATION:
				# Transition to countdown
				current_phase = SimuFirePhase.COUNTDOWN
				countdown_start_time = Time.get_unix_time_from_system()
				emit_signal("phase_changed", current_phase)

		SimuFirePhase.COUNTDOWN:
			var elapsed = Time.get_unix_time_from_system() - countdown_start_time
			var countdown_num = 3 - int(elapsed)

			if countdown_num >= 0:
				emit_signal("countdown_tick", countdown_num)

			# After 4 seconds (3-2-1-GO), start resolution
			if elapsed >= COUNTDOWN_DURATION:
				current_phase = SimuFirePhase.RESOLUTION
				emit_signal("phase_changed", current_phase)
				resolve_simultaneous_moves()

		SimuFirePhase.RESOLUTION:
			# Handled by animation system
			pass

		SimuFirePhase.VICTORY:
			# Check handled after resolution
			pass

		SimuFirePhase.END:
			end_round()

func plan_move(color: String, from: Vector2i, to: Vector2i) -> bool:
	"""Plan a move for a player - matching pygame board.py plan_move()"""
	if current_phase != SimuFirePhase.PLANNING:
		return false

	# Can't change plan once locked
	if color == "white" and white_locked:
		return false
	if color == "black" and black_locked:
		return false

	var plan = {"from": from, "to": to}

	if color == "white":
		white_plan = plan
		white_locked = true
		white_selected = Vector2i(-1, -1)
		white_valid_moves = []
		emit_signal("move_locked", "white")
	else:
		black_plan = plan
		black_locked = true
		black_selected = Vector2i(-1, -1)
		black_valid_moves = []
		emit_signal("move_locked", "black")

	return true

func resolve_simultaneous_moves():
	"""Resolve both moves simultaneously - matching pygame board.py resolve_simultaneous_moves()"""
	collision_results = []
	animating_moves = []

	var white_from = white_plan.get("from", Vector2i(-1, -1))
	var white_to = white_plan.get("to", Vector2i(-1, -1))
	var black_from = black_plan.get("from", Vector2i(-1, -1))
	var black_to = black_plan.get("to", Vector2i(-1, -1))

	var white_piece = "" if white_from == Vector2i(-1, -1) else board[white_from.y][white_from.x]
	var black_piece = "" if black_from == Vector2i(-1, -1) else board[black_from.y][black_from.x]

	# Check for COLLISION - both targeting same square
	if white_to != Vector2i(-1, -1) and white_to == black_to:
		# BONK! Both pieces bounce back
		collision_results.append({"type": "bonk", "pos": white_to, "white": white_piece, "black": black_piece})
		emit_signal("collision_occurred", white_to, "bonk")
		# No moves happen - pieces stay in place
		_finish_resolution()
		return

	# Check for SWAP - pieces crossing paths
	if white_to == black_from and black_to == white_from:
		# Swap collision - compare piece strength
		var white_strength = get_piece_strength(white_piece)
		var black_strength = get_piece_strength(black_piece)

		if white_strength > black_strength:
			# White captures black mid-swap
			_setup_move_animation(white_from, white_to, white_piece)
			_capture_piece(black_from, black_piece)
		elif black_strength > white_strength:
			# Black captures white mid-swap
			_setup_move_animation(black_from, black_to, black_piece)
			_capture_piece(white_from, white_piece)
		else:
			# Equal strength - both bounce back (bonk)
			collision_results.append({"type": "swap_bonk", "pos": white_to})

		_start_animation()
		return

	# Normal simultaneous moves
	if white_to != Vector2i(-1, -1) and white_piece != "":
		var captured = board[white_to.y][white_to.x]
		_setup_move_animation(white_from, white_to, white_piece)
		if captured != "":
			_capture_piece(white_to, captured)
			# Check for king capture - GAME OVER
			if captured[1] == "K":
				emit_signal("game_over", "white")

	if black_to != Vector2i(-1, -1) and black_piece != "":
		var captured = board[black_to.y][black_to.x]
		_setup_move_animation(black_from, black_to, black_piece)
		if captured != "":
			_capture_piece(black_to, captured)
			# Check for king capture - GAME OVER
			if captured[1] == "K":
				emit_signal("game_over", "black")

	_start_animation()

func get_piece_strength(piece: String) -> int:
	"""Get piece strength for collision resolution."""
	if piece == "":
		return 0
	match piece[1]:
		"P": return 1
		"N": return 3
		"B": return 3
		"R": return 5
		"Q": return 9
		"K": return 100
	return 0

func _setup_move_animation(from: Vector2i, to: Vector2i, piece: String):
	"""Setup animation data for a move."""
	if piece_sprites.has(from):
		animating_moves.append({
			"piece": piece,
			"from": from,
			"to": to,
			"sprite": piece_sprites[from]
		})

func _capture_piece(pos: Vector2i, piece: String):
	"""Handle piece capture."""
	last_captured_piece = piece
	if piece_sprites.has(pos):
		piece_sprites[pos].queue_free()
		piece_sprites.erase(pos)

func _start_animation():
	"""Start move animation."""
	animation_start_time = Time.get_unix_time_from_system()
	animation_progress = 0.0

func update_animation(delta):
	"""Update move animations."""
	if animating_moves.size() == 0:
		_finish_resolution()
		return

	var elapsed = Time.get_unix_time_from_system() - animation_start_time
	animation_progress = min(elapsed / ANIMATION_DURATION, 1.0)

	# Animate all moves
	for move_data in animating_moves:
		var sprite = move_data["sprite"]
		if sprite and is_instance_valid(sprite):
			var start_pos = board_to_screen(move_data["from"])
			var end_pos = board_to_screen(move_data["to"])
			sprite.position = start_pos.lerp(end_pos, animation_progress)

	# Animation complete
	if animation_progress >= 1.0:
		_complete_animations()

func _complete_animations():
	"""Complete move animations and update board."""
	for move_data in animating_moves:
		var from = move_data["from"]
		var to = move_data["to"]
		var piece = move_data["piece"]
		var sprite = move_data["sprite"]

		# Update board array
		board[from.y][from.x] = ""
		board[to.y][to.x] = piece

		# Update sprite dictionary
		piece_sprites.erase(from)
		if sprite and is_instance_valid(sprite):
			piece_sprites[to] = sprite
			sprite.position = board_to_screen(to)

		# Handle pawn promotion
		if piece[1] == "P" and (to.y == 0 or to.y == 7):
			var color = piece[0]
			board[to.y][to.x] = color + "Q"
			if piece_sprites.has(to):
				piece_sprites[to].texture = piece_textures[color + "Q"]

		emit_signal("piece_moved", from, to, last_captured_piece != "")

	animating_moves = []
	emit_signal("moves_resolved")
	_finish_resolution()

func _finish_resolution():
	"""Finish resolution phase."""
	current_phase = SimuFirePhase.END
	emit_signal("phase_changed", current_phase)

func end_round():
	"""End the current round and start new one."""
	round_number += 1

	# Update status effects (decrement durations)
	var to_remove = []
	for pos in status_effects:
		status_effects[pos]["duration"] -= 1
		if status_effects[pos]["duration"] <= 0:
			to_remove.append(pos)
	for pos in to_remove:
		status_effects.erase(pos)

	# Start new round
	start_new_round()

# ==================== INPUT HANDLING ====================

func _input(event):
	if current_phase != SimuFirePhase.PLANNING:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click(event.position)

func handle_click(screen_pos: Vector2):
	"""Handle click during planning phase."""
	var board_pos = screen_to_board(screen_pos)
	if board_pos == Vector2i(-1, -1):
		return

	# Determine which player is clicking based on piece color at position
	# In local multiplayer, we need some way to determine whose turn it is
	# For now, check if clicking on white or black piece

	var piece = board[board_pos.y][board_pos.x]
	var color = get_piece_color(piece)

	# Handle white player
	if not white_locked:
		if white_selected != Vector2i(-1, -1):
			# Already selected, try to plan move
			if board_pos in white_valid_moves:
				plan_move("white", white_selected, board_pos)
				return

		# Select white piece
		if color == "white":
			white_selected = board_pos
			white_valid_moves = get_valid_moves(board_pos)
			emit_signal("piece_selected", board_pos)
			return
		else:
			white_selected = Vector2i(-1, -1)
			white_valid_moves = []

	# Handle black player (same click can work for both in hotseat)
	if not black_locked:
		if black_selected != Vector2i(-1, -1):
			if board_pos in black_valid_moves:
				plan_move("black", black_selected, board_pos)
				return

		if color == "black":
			black_selected = board_pos
			black_valid_moves = get_valid_moves(board_pos)
			emit_signal("piece_selected", board_pos)
			return
		else:
			black_selected = Vector2i(-1, -1)
			black_valid_moves = []

# ==================== DRAWING ====================

func _draw():
	# Draw board squares
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var color = LIGHT_SQUARE if (row + col) % 2 == 0 else DARK_SQUARE
			var rect = Rect2(BOARD_OFFSET + Vector2(col * SQUARE_SIZE, row * SQUARE_SIZE),
							Vector2(SQUARE_SIZE, SQUARE_SIZE))
			draw_rect(rect, color)

	# During planning, show selections and valid moves
	if current_phase == SimuFirePhase.PLANNING:
		# White selection
		if white_selected != Vector2i(-1, -1) and not white_locked:
			var rect = Rect2(BOARD_OFFSET + Vector2(white_selected.x * SQUARE_SIZE, white_selected.y * SQUARE_SIZE),
							Vector2(SQUARE_SIZE, SQUARE_SIZE))
			draw_rect(rect, WHITE_PLAN_COLOR)

			for move in white_valid_moves:
				var move_rect = Rect2(BOARD_OFFSET + Vector2(move.x * SQUARE_SIZE, move.y * SQUARE_SIZE),
								Vector2(SQUARE_SIZE, SQUARE_SIZE))
				var move_color = CAPTURE_COLOR if board[move.y][move.x] != "" else VALID_MOVE_COLOR
				draw_rect(move_rect, move_color)

		# Black selection
		if black_selected != Vector2i(-1, -1) and not black_locked:
			var rect = Rect2(BOARD_OFFSET + Vector2(black_selected.x * SQUARE_SIZE, black_selected.y * SQUARE_SIZE),
							Vector2(SQUARE_SIZE, SQUARE_SIZE))
			draw_rect(rect, BLACK_PLAN_COLOR)

			for move in black_valid_moves:
				var move_rect = Rect2(BOARD_OFFSET + Vector2(move.x * SQUARE_SIZE, move.y * SQUARE_SIZE),
								Vector2(SQUARE_SIZE, SQUARE_SIZE))
				var move_color = CAPTURE_COLOR if board[move.y][move.x] != "" else VALID_MOVE_COLOR
				draw_rect(move_rect, move_color)

		# Show locked plans
		if white_locked and white_plan.size() > 0:
			_draw_planned_move(white_plan, LOCKED_COLOR)
		if black_locked and black_plan.size() > 0:
			_draw_planned_move(black_plan, LOCKED_COLOR)

	# During countdown, show both planned moves with arrows
	if current_phase == SimuFirePhase.COUNTDOWN:
		if white_plan.size() > 0:
			_draw_move_path(white_plan, Color(0.2, 0.5, 1.0, 0.8))
		if black_plan.size() > 0:
			_draw_move_path(black_plan, Color(1.0, 0.3, 0.3, 0.8))

func _draw_planned_move(plan: Dictionary, color: Color):
	"""Draw a planned move indicator."""
	if plan.has("from") and plan.has("to"):
		var from_rect = Rect2(BOARD_OFFSET + Vector2(plan["from"].x * SQUARE_SIZE, plan["from"].y * SQUARE_SIZE),
						Vector2(SQUARE_SIZE, SQUARE_SIZE))
		var to_rect = Rect2(BOARD_OFFSET + Vector2(plan["to"].x * SQUARE_SIZE, plan["to"].y * SQUARE_SIZE),
						Vector2(SQUARE_SIZE, SQUARE_SIZE))
		draw_rect(from_rect, color)
		draw_rect(to_rect, color)

func _draw_move_path(plan: Dictionary, color: Color):
	"""Draw arrow showing move path."""
	if plan.has("from") and plan.has("to"):
		var from_pos = board_to_screen(plan["from"])
		var to_pos = board_to_screen(plan["to"])
		draw_line(from_pos, to_pos, color, 4.0)

		# Draw arrowhead
		var dir = (to_pos - from_pos).normalized()
		var perp = Vector2(-dir.y, dir.x)
		var arrow_size = 15.0
		var arrow_tip = to_pos
		var arrow_left = to_pos - dir * arrow_size + perp * arrow_size * 0.5
		var arrow_right = to_pos - dir * arrow_size - perp * arrow_size * 0.5
		draw_polygon([arrow_tip, arrow_left, arrow_right], [color])

# ==================== CHESS LOGIC ====================

func get_piece_color(piece: String) -> String:
	if piece == "":
		return ""
	return "white" if piece[0] == "w" else "black"

func get_valid_moves(pos: Vector2i) -> Array:
	var piece = board[pos.y][pos.x]
	if piece == "":
		return []

	var moves = []
	var piece_type = piece[1]
	var color = get_piece_color(piece)

	match piece_type:
		"P": moves = get_pawn_moves(pos, color)
		"N": moves = get_knight_moves(pos, color)
		"B": moves = get_bishop_moves(pos, color)
		"R": moves = get_rook_moves(pos, color)
		"Q": moves = get_queen_moves(pos, color)
		"K": moves = get_king_moves(pos, color)

	# Filter moves that would leave king in check
	var legal_moves = []
	for move in moves:
		if not would_be_in_check(pos, move, color):
			legal_moves.append(move)

	return legal_moves

func get_pawn_moves(pos: Vector2i, color: String) -> Array:
	var moves = []
	var direction = -1 if color == "white" else 1
	var start_row = 6 if color == "white" else 1

	var forward = Vector2i(pos.x, pos.y + direction)
	if is_valid_pos(forward) and board[forward.y][forward.x] == "":
		moves.append(forward)
		if pos.y == start_row:
			var double = Vector2i(pos.x, pos.y + direction * 2)
			if board[double.y][double.x] == "":
				moves.append(double)

	for dx in [-1, 1]:
		var capture = Vector2i(pos.x + dx, pos.y + direction)
		if is_valid_pos(capture):
			var target = board[capture.y][capture.x]
			if target != "" and get_piece_color(target) != color:
				moves.append(capture)
			elif capture == en_passant_target:
				moves.append(capture)

	return moves

func get_knight_moves(pos: Vector2i, color: String) -> Array:
	var moves = []
	var offsets = [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
		Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)
	]
	for offset in offsets:
		var target = pos + offset
		if is_valid_pos(target):
			var piece = board[target.y][target.x]
			if piece == "" or get_piece_color(piece) != color:
				moves.append(target)
	return moves

func get_bishop_moves(pos: Vector2i, color: String) -> Array:
	return get_sliding_moves(pos, color, [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)])

func get_rook_moves(pos: Vector2i, color: String) -> Array:
	return get_sliding_moves(pos, color, [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)])

func get_queen_moves(pos: Vector2i, color: String) -> Array:
	return get_bishop_moves(pos, color) + get_rook_moves(pos, color)

func get_sliding_moves(pos: Vector2i, color: String, directions: Array) -> Array:
	var moves = []
	for dir in directions:
		var current = pos + dir
		while is_valid_pos(current):
			var piece = board[current.y][current.x]
			if piece == "":
				moves.append(current)
			elif get_piece_color(piece) != color:
				moves.append(current)
				break
			else:
				break
			current += dir
	return moves

func get_king_moves(pos: Vector2i, color: String) -> Array:
	var moves = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var target = pos + Vector2i(dx, dy)
			if is_valid_pos(target):
				var piece = board[target.y][target.x]
				if piece == "" or get_piece_color(piece) != color:
					moves.append(target)

	# Castling
	var row = 7 if color == "white" else 0
	if pos == Vector2i(4, row) and not is_in_check(color):
		var key = "white_king" if color == "white" else "black_king"
		if castling_rights[key]:
			if board[row][5] == "" and board[row][6] == "":
				if not is_square_attacked(Vector2i(5, row), color) and not is_square_attacked(Vector2i(6, row), color):
					moves.append(Vector2i(6, row))
		key = "white_queen" if color == "white" else "black_queen"
		if castling_rights[key]:
			if board[row][1] == "" and board[row][2] == "" and board[row][3] == "":
				if not is_square_attacked(Vector2i(2, row), color) and not is_square_attacked(Vector2i(3, row), color):
					moves.append(Vector2i(2, row))

	return moves

func is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8

func find_king(color: String) -> Vector2i:
	var king = "wK" if color == "white" else "bK"
	for row in range(8):
		for col in range(8):
			if board[row][col] == king:
				return Vector2i(col, row)
	return Vector2i(-1, -1)

func is_in_check(color: String) -> bool:
	var king_pos = find_king(color)
	return is_square_attacked(king_pos, color)

func is_square_attacked(pos: Vector2i, defending_color: String) -> bool:
	var attacking_color = "black" if defending_color == "white" else "white"
	for row in range(8):
		for col in range(8):
			var piece = board[row][col]
			if piece != "" and get_piece_color(piece) == attacking_color:
				var attacks = get_attack_squares(Vector2i(col, row), piece)
				if pos in attacks:
					return true
	return false

func get_attack_squares(pos: Vector2i, piece: String) -> Array:
	var color = get_piece_color(piece)
	match piece[1]:
		"P":
			var direction = -1 if color == "white" else 1
			return [Vector2i(pos.x - 1, pos.y + direction), Vector2i(pos.x + 1, pos.y + direction)]
		"N": return get_knight_moves(pos, color)
		"B": return get_bishop_moves(pos, color)
		"R": return get_rook_moves(pos, color)
		"Q": return get_queen_moves(pos, color)
		"K":
			var moves = []
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx != 0 or dy != 0:
						moves.append(pos + Vector2i(dx, dy))
			return moves
	return []

func would_be_in_check(from: Vector2i, to: Vector2i, color: String) -> bool:
	var moving_piece = board[from.y][from.x]
	var captured_piece = board[to.y][to.x]
	board[to.y][to.x] = moving_piece
	board[from.y][from.x] = ""
	var in_check = is_in_check(color)
	board[from.y][from.x] = moving_piece
	board[to.y][to.x] = captured_piece
	return in_check

# ==================== PUBLIC API ====================

func get_current_turn() -> String:
	# In SimuFire, both players act simultaneously
	return "both"

func get_board_array() -> Array:
	return board.duplicate(true)

func get_piece_at(pos: Vector2i) -> String:
	if is_valid_pos(pos):
		return board[pos.y][pos.x]
	return ""

func get_last_captured_piece() -> String:
	return last_captured_piece

func get_simufire_timer() -> float:
	var elapsed = Time.get_unix_time_from_system() - round_start_time
	return max(0, 30.0 - elapsed)

func get_current_phase() -> SimuFirePhase:
	return current_phase

func is_white_locked() -> bool:
	return white_locked

func is_black_locked() -> bool:
	return black_locked

func remove_piece_at(pos: Vector2i):
	"""Remove piece at position (for powerups)."""
	if is_valid_pos(pos):
		board[pos.y][pos.x] = ""
		if piece_sprites.has(pos):
			piece_sprites[pos].queue_free()
			piece_sprites.erase(pos)

func skip_turn():
	"""Not applicable in SimuFire - both players act together."""
	pass

func execute_move(from: Vector2i, to: Vector2i):
	"""Execute a move directly (for AI)."""
	# In SimuFire, AI would use plan_move instead
	pass
