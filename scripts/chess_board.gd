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
signal border_hit()  # Emitted when dragging piece hits board edge

# SimuFire Phases (matching pygame board.py lines 25-31)
enum SimuFirePhase { PLANNING, COUNTDOWN, RESOLUTION, VICTORY, END }

# Board configuration - matches pygame exactly
const BOARD_SIZE = 8
const SQUARE_SIZE = 81  # Square size in pixels (648 / 8)
const BOARD_OFFSET = Vector2(398, 146)  # Top-left of playable area (362+36, 110+36)
# Pawns use larger scale, other pieces 15% smaller
const PAWN_SCALE = 3.85  # 10% larger than before
const PIECE_SCALE = 2.975  # 15% smaller than pawns (3.5 * 0.85)
const QUEEN_SCALE = 2.543  # 15% smaller than other pieces
const KING_SCALE = 2.436  # 18% smaller than other pieces
const PIECE_Y_OFFSET = -25  # Move pawns up to center them visually in squares
const NON_PAWN_Y_ADJUST = 5  # Move non-pawns down 5 pixels relative to pawns
const QUEEN_Y_ADJUST = 11  # Queen needs extra 6 pixels down (5 + 6)
const KING_Y_ADJUST = 13  # King needs extra 8 pixels down (5 + 8)

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
var pulse_time: float = 0.0  # For pulsing move highlights

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

# Drag and drop state with physics
var is_dragging: bool = false
var drag_piece_pos: Vector2i = Vector2i(-1, -1)  # Board position of dragged piece
var drag_sprite: Sprite2D = null  # The sprite being dragged
var drag_target_pos: Vector2 = Vector2.ZERO  # Where the mouse is (target for physics)
var drag_current_pos: Vector2 = Vector2.ZERO  # Current visual position (lags behind)
var drag_original_pos: Vector2 = Vector2.ZERO  # Original screen position to return to
var drag_color: String = ""  # Color of the piece being dragged

# Physics constants for drag feel
const DRAG_SMOOTHING = 0.10  # How quickly piece follows mouse (0-1, lower = more lag)
const DRAG_LIFT_SCALE = 1.15  # Scale up piece slightly when lifted

# Board boundaries for drag constraint
# Board texture is at (362, 110) with size 720x720
const DRAG_BOARD_LEFT = 389.0    # Left edge
const DRAG_BOARD_TOP = 110.0     # Top edge
const DRAG_BOARD_RIGHT = 1055.0  # Right edge
const DRAG_BOARD_BOTTOM = 767.0  # Bottom edge

# Border hit tracking
var last_hit_borders: Array = []  # Which borders were hit last frame
var border_hit_sound: AudioStreamPlayer

# Hover state
var hovered_square: Vector2i = Vector2i(-1, -1)  # Currently hovered square
var last_hover_sound_square: Vector2i = Vector2i(-1, -1)  # Last square that played hover sound
var hover_sound: AudioStreamPlayer
const HOVER_LIFT = -10.0  # Pixels to lift piece when hovered (matches pygame)

func _ready():
	load_piece_textures()
	initialize_board()
	create_piece_sprites()
	setup_border_hit_sound()
	start_new_round()

func setup_border_hit_sound():
	"""Setup the border hit sound player."""
	border_hit_sound = AudioStreamPlayer.new()
	add_child(border_hit_sound)
	var sound = load("res://assets/sounds/borderhit.wav")
	if sound:
		border_hit_sound.stream = sound
		border_hit_sound.volume_db = -16  # Quieter (0.15 volume ~ -16db)

	# Setup hover sound
	hover_sound = AudioStreamPlayer.new()
	add_child(hover_sound)
	var hover_snd = load("res://assets/sounds/hoverclick.wav")
	if hover_snd:
		hover_sound.stream = hover_snd
		hover_sound.volume_db = -6  # 0.5 volume ~ -6db

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
	sprite.centered = true  # Ensure sprite is centered at position
	var base_pos = board_to_screen(pos)
	# Determine scale based on piece type
	var piece_type = piece[1]
	var scale: float
	if piece_type == "P":
		scale = PAWN_SCALE
	elif piece_type == "Q":
		scale = QUEEN_SCALE
	elif piece_type == "K":
		scale = KING_SCALE
	else:
		scale = PIECE_SCALE
	# Non-pawns are positioned lower, kings/queens have custom offsets
	var y_adjust = 0
	if piece_type == "P":
		y_adjust = 0
	elif piece_type == "K":
		y_adjust = KING_Y_ADJUST
	elif piece_type == "Q":
		y_adjust = QUEEN_Y_ADJUST
	else:
		y_adjust = NON_PAWN_Y_ADJUST
	sprite.position = base_pos + Vector2(0, y_adjust)
	sprite.scale = Vector2(scale, scale)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	piece_sprites[pos] = sprite

func board_to_screen(pos: Vector2i) -> Vector2:
	return BOARD_OFFSET + Vector2(pos.x * SQUARE_SIZE + SQUARE_SIZE/2,
								   pos.y * SQUARE_SIZE + SQUARE_SIZE/2 + PIECE_Y_OFFSET)

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
	pulse_time += delta

	if current_phase == SimuFirePhase.RESOLUTION:
		update_animation(delta)

	# Update drag physics
	if is_dragging and drag_sprite:
		update_drag_physics(delta)

	# Update hover state (only during planning, not while dragging)
	if current_phase == SimuFirePhase.PLANNING and not is_dragging:
		update_hover()

	queue_redraw()

func update_hover():
	"""Update piece hover state - lift and play sound on new hovers."""
	var mouse_pos = get_global_mouse_position()
	var new_hover = screen_to_board(mouse_pos)

	# Check if hovering over a valid piece
	if new_hover != Vector2i(-1, -1):
		var piece = board[new_hover.y][new_hover.x]
		if piece != "":
			# Hovering over a piece
			if new_hover != hovered_square:
				# New piece hovered - update position and play sound if different
				var old_hovered = hovered_square
				hovered_square = new_hover

				# Reset old hovered piece position
				if old_hovered != Vector2i(-1, -1) and piece_sprites.has(old_hovered):
					_reset_piece_position(old_hovered)

				# Lift new hovered piece
				if piece_sprites.has(new_hover):
					_lift_piece(new_hover)

				# Play sound if this is a new hover (not the same as last sound)
				if new_hover != last_hover_sound_square:
					if hover_sound:
						hover_sound.play()
					last_hover_sound_square = new_hover
		else:
			# Hovering over empty square
			_clear_hover()
	else:
		# Not on board
		_clear_hover()

func _clear_hover():
	"""Clear any current hover state."""
	if hovered_square != Vector2i(-1, -1):
		if piece_sprites.has(hovered_square):
			_reset_piece_position(hovered_square)
		hovered_square = Vector2i(-1, -1)
		last_hover_sound_square = Vector2i(-1, -1)

func _lift_piece(pos: Vector2i):
	"""Lift a piece visually for hover effect."""
	if piece_sprites.has(pos):
		var sprite = piece_sprites[pos]
		var base_pos = board_to_screen(pos)
		var piece = board[pos.y][pos.x]
		var piece_type = piece[1]
		var y_adjust = 0
		if piece_type == "P":
			y_adjust = 0
		elif piece_type == "K":
			y_adjust = KING_Y_ADJUST
		elif piece_type == "Q":
			y_adjust = QUEEN_Y_ADJUST
		else:
			y_adjust = NON_PAWN_Y_ADJUST
		sprite.position = base_pos + Vector2(0, y_adjust + HOVER_LIFT)

func _reset_piece_position(pos: Vector2i):
	"""Reset a piece to its normal position."""
	if piece_sprites.has(pos):
		var sprite = piece_sprites[pos]
		var base_pos = board_to_screen(pos)
		var piece = board[pos.y][pos.x]
		if piece != "":
			var piece_type = piece[1]
			var y_adjust = 0
			if piece_type == "P":
				y_adjust = 0
			elif piece_type == "K":
				y_adjust = KING_Y_ADJUST
			elif piece_type == "Q":
				y_adjust = QUEEN_Y_ADJUST
			else:
				y_adjust = NON_PAWN_Y_ADJUST
			sprite.position = base_pos + Vector2(0, y_adjust)

func update_drag_physics(_delta: float):
	"""Update dragged piece position with physics-like feel."""
	# Simple lerp toward target - creates a smooth, weighted feel
	drag_current_pos = drag_current_pos.lerp(drag_target_pos, DRAG_SMOOTHING)

	# Check which borders we're hitting and constrain position
	var current_hit_borders: Array = []
	var constrained_pos = drag_current_pos

	# Check and constrain each border
	if drag_current_pos.x <= DRAG_BOARD_LEFT:
		current_hit_borders.append("left")
		constrained_pos.x = DRAG_BOARD_LEFT
	if drag_current_pos.x >= DRAG_BOARD_RIGHT:
		current_hit_borders.append("right")
		constrained_pos.x = DRAG_BOARD_RIGHT
	if drag_current_pos.y <= DRAG_BOARD_TOP:
		current_hit_borders.append("top")
		constrained_pos.y = DRAG_BOARD_TOP
	if drag_current_pos.y >= DRAG_BOARD_BOTTOM:
		current_hit_borders.append("bottom")
		constrained_pos.y = DRAG_BOARD_BOTTOM

	# Check for NEW border hits (not in previous frame)
	var new_hits: Array = []
	for border in current_hit_borders:
		if border not in last_hit_borders:
			new_hits.append(border)

	# Trigger effects on new border hits
	if new_hits.size() > 0:
		emit_signal("border_hit")  # Let game.gd handle screen shake
		if border_hit_sound:
			border_hit_sound.play()

	# Update tracking
	last_hit_borders = current_hit_borders

	# Apply constrained position
	drag_current_pos = constrained_pos
	drag_sprite.position = drag_current_pos

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

	# Mouse button events
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag(event.position)
		else:
			end_drag(event.position)

	# Mouse motion while dragging
	if event is InputEventMouseMotion and is_dragging:
		# Use global mouse position (works correctly with Node2D in Control)
		drag_target_pos = get_global_mouse_position()

func start_drag(screen_pos: Vector2):
	"""Start dragging a piece if clicked on one."""
	# Clear hover state when starting drag
	_clear_hover()

	var board_pos = screen_to_board(screen_pos)
	if board_pos == Vector2i(-1, -1):
		return

	var piece = board[board_pos.y][board_pos.x]
	var color = get_piece_color(piece)

	# Check if this is a valid piece to drag
	var can_drag = false
	if color == "white" and not white_locked:
		can_drag = true
		white_selected = board_pos
		white_valid_moves = get_valid_moves(board_pos)
		drag_color = "white"
	elif color == "black" and not black_locked:
		can_drag = true
		black_selected = board_pos
		black_valid_moves = get_valid_moves(board_pos)
		drag_color = "black"

	if can_drag and piece_sprites.has(board_pos):
		is_dragging = true
		drag_piece_pos = board_pos
		drag_sprite = piece_sprites[board_pos]
		drag_original_pos = drag_sprite.position
		drag_current_pos = drag_sprite.position
		drag_target_pos = get_global_mouse_position()  # Use mouse position

		# Lift the piece (scale up and bring to front)
		var base_scale = get_piece_scale(piece)
		drag_sprite.scale = Vector2(base_scale * DRAG_LIFT_SCALE, base_scale * DRAG_LIFT_SCALE)
		drag_sprite.z_index = 100

		emit_signal("piece_selected", board_pos)
		queue_redraw()

func end_drag(screen_pos: Vector2):
	"""End dragging and try to make a move."""
	if not is_dragging:
		return

	var drop_pos = screen_to_board(screen_pos)
	var move_made = false

	# Check if this is a valid move
	if drop_pos != Vector2i(-1, -1) and drop_pos != drag_piece_pos:
		if drag_color == "white" and drop_pos in white_valid_moves:
			plan_move("white", drag_piece_pos, drop_pos)
			move_made = true
		elif drag_color == "black" and drop_pos in black_valid_moves:
			plan_move("black", drag_piece_pos, drop_pos)
			move_made = true

	# Return piece to original position if no valid move
	if not move_made and drag_sprite:
		# Animate back with physics
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(drag_sprite, "position", drag_original_pos, 0.3)

	# Reset drag state
	if drag_sprite:
		var piece = board[drag_piece_pos.y][drag_piece_pos.x]
		var base_scale = get_piece_scale(piece)
		drag_sprite.scale = Vector2(base_scale, base_scale)
		drag_sprite.z_index = 0

	is_dragging = false
	drag_sprite = null
	drag_piece_pos = Vector2i(-1, -1)
	drag_color = ""
	last_hit_borders = []  # Reset border tracking
	queue_redraw()

func get_piece_scale(piece: String) -> float:
	"""Get the appropriate scale for a piece type."""
	if piece == "":
		return PIECE_SCALE
	var piece_type = piece[1]
	if piece_type == "P":
		return PAWN_SCALE
	elif piece_type == "Q":
		return QUEEN_SCALE
	elif piece_type == "K":
		return KING_SCALE
	return PIECE_SCALE

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
	# Board squares are drawn by BoardTexture in the scene
	# Only draw selection highlights and move indicators here

	# During planning, show selections and valid moves
	if current_phase == SimuFirePhase.PLANNING:
		# White selection
		if white_selected != Vector2i(-1, -1) and not white_locked:
			var rect = Rect2(BOARD_OFFSET + Vector2(white_selected.x * SQUARE_SIZE, white_selected.y * SQUARE_SIZE),
							Vector2(SQUARE_SIZE, SQUARE_SIZE))
			draw_rect(rect, WHITE_PLAN_COLOR)

			for move in white_valid_moves:
				var is_capture = board[move.y][move.x] != ""
				draw_pulsing_move_highlight(move, is_capture)

		# Black selection
		if black_selected != Vector2i(-1, -1) and not black_locked:
			var rect = Rect2(BOARD_OFFSET + Vector2(black_selected.x * SQUARE_SIZE, black_selected.y * SQUARE_SIZE),
							Vector2(SQUARE_SIZE, SQUARE_SIZE))
			draw_rect(rect, BLACK_PLAN_COLOR)

			for move in black_valid_moves:
				var is_capture = board[move.y][move.x] != ""
				draw_pulsing_move_highlight(move, is_capture)

		# Show locked plans
		if white_locked and white_plan.size() > 0:
			_draw_planned_move(white_plan, LOCKED_COLOR)
		if black_locked and black_plan.size() > 0:
			_draw_planned_move(black_plan, LOCKED_COLOR)

	# During countdown, show both planned moves with flashing effect
	if current_phase == SimuFirePhase.COUNTDOWN:
		var flash = (sin(pulse_time * 8.0) + 1.0) / 2.0  # Fast flash
		if white_plan.size() > 0:
			_draw_move_path(white_plan, Color(0.2, 0.5, 1.0, 0.8))
			# Flash opponent's move (black) with red warning
			_draw_flashing_threat(black_plan, flash)
		if black_plan.size() > 0:
			_draw_move_path(black_plan, Color(1.0, 0.3, 0.3, 0.8))
			# Flash opponent's move (white) with blue warning
			_draw_flashing_threat(white_plan, flash)

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

func _draw_flashing_threat(plan: Dictionary, flash: float):
	"""Draw flashing warning on opponent's planned move destination."""
	if not plan.has("to"):
		return

	var to = plan["to"]
	var base_pos = BOARD_OFFSET + Vector2(to.x * SQUARE_SIZE, to.y * SQUARE_SIZE)

	# Flashing red/orange warning
	var warning_color = Color(1.0, 0.2, 0.1, flash * 0.5)
	var rect = Rect2(base_pos, Vector2(SQUARE_SIZE, SQUARE_SIZE))
	draw_rect(rect, warning_color)

	# Pulsing border
	var border_alpha = 0.6 + flash * 0.4
	var border_color = Color(1.0, 0.3, 0.0, border_alpha)
	var border_width = 4.0
	# Top
	draw_rect(Rect2(base_pos, Vector2(SQUARE_SIZE, border_width)), border_color)
	# Bottom
	draw_rect(Rect2(base_pos + Vector2(0, SQUARE_SIZE - border_width), Vector2(SQUARE_SIZE, border_width)), border_color)
	# Left
	draw_rect(Rect2(base_pos, Vector2(border_width, SQUARE_SIZE)), border_color)
	# Right
	draw_rect(Rect2(base_pos + Vector2(SQUARE_SIZE - border_width, 0), Vector2(border_width, SQUARE_SIZE)), border_color)

func draw_pulsing_move_highlight(move: Vector2i, _is_capture: bool):
	"""Draw 8-bit style single pulsing dot in center of square."""
	var base_pos = BOARD_OFFSET + Vector2(move.x * SQUARE_SIZE, move.y * SQUARE_SIZE)
	var center = base_pos + Vector2(SQUARE_SIZE / 2, SQUARE_SIZE / 2)

	# Pulse parameters
	var pulse_speed = 4.0
	var pulse = (sin(pulse_time * pulse_speed) + 1.0) / 2.0  # 0 to 1

	# Pulsing size
	var dot_size = 16 + pulse * 8  # Pulses between 16 and 24
	var border_size = dot_size + 6

	# Colors
	var border_alpha = 0.6 + pulse * 0.3
	var dot_alpha = 0.7 + pulse * 0.25
	var border_color = Color(0.75, 0.75, 0.75, border_alpha)  # Light grey border
	var dot_color = Color(0.3, 0.3, 0.3, dot_alpha)  # Dark grey dot

	# Draw light grey border
	draw_rect(Rect2(center - Vector2(border_size/2, border_size/2), Vector2(border_size, border_size)), border_color)
	# Draw dark grey center dot
	draw_rect(Rect2(center - Vector2(dot_size/2, dot_size/2), Vector2(dot_size, dot_size)), dot_color)

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
