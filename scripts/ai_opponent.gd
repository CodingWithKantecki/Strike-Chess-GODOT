extends Node
class_name AIOpponent

# AI Opponent using minimax with alpha-beta pruning
# Matches pygame difficulty levels (400-1800 Elo)

signal thinking_started
signal thinking_complete(move: Dictionary)

var is_thinking: bool = false
var current_board: Array = []
var ai_color: String = "black"
var difficulty_elo: int = 1000

# Difficulty mappings (matching pygame)
var campaign_difficulties: Dictionary = {
	"recruit": 400,
	"rookie": 500,
	"soldier": 700,
	"veteran": 900,
	"elite": 1100,
	"commander": 1300,
	"champion": 1500,
	"master": 1700,
	"nexus": 1800
}

var sandbox_difficulties: Dictionary = {
	"beginner": 600,
	"easy": 800,
	"medium": 1000,
	"hard": 1400,
	"expert": 1600,
	"master": 1700,
	"grandmaster": 1800
}

# Piece values for evaluation
var piece_values: Dictionary = {
	"P": 100,   # Pawn
	"N": 320,   # Knight
	"B": 330,   # Bishop
	"R": 500,   # Rook
	"Q": 900,   # Queen
	"K": 20000  # King (high but not infinite)
}

# Position bonuses for pieces (center control)
var pawn_table: Array = [
	[0,  0,  0,  0,  0,  0,  0,  0],
	[50, 50, 50, 50, 50, 50, 50, 50],
	[10, 10, 20, 30, 30, 20, 10, 10],
	[5,  5, 10, 25, 25, 10,  5,  5],
	[0,  0,  0, 20, 20,  0,  0,  0],
	[5, -5,-10,  0,  0,-10, -5,  5],
	[5, 10, 10,-20,-20, 10, 10,  5],
	[0,  0,  0,  0,  0,  0,  0,  0]
]

var knight_table: Array = [
	[-50,-40,-30,-30,-30,-30,-40,-50],
	[-40,-20,  0,  0,  0,  0,-20,-40],
	[-30,  0, 10, 15, 15, 10,  0,-30],
	[-30,  5, 15, 20, 20, 15,  5,-30],
	[-30,  0, 15, 20, 20, 15,  0,-30],
	[-30,  5, 10, 15, 15, 10,  5,-30],
	[-40,-20,  0,  5,  5,  0,-20,-40],
	[-50,-40,-30,-30,-30,-30,-40,-50]
]

var bishop_table: Array = [
	[-20,-10,-10,-10,-10,-10,-10,-20],
	[-10,  0,  0,  0,  0,  0,  0,-10],
	[-10,  0,  5, 10, 10,  5,  0,-10],
	[-10,  5,  5, 10, 10,  5,  5,-10],
	[-10,  0, 10, 10, 10, 10,  0,-10],
	[-10, 10, 10, 10, 10, 10, 10,-10],
	[-10,  5,  0,  0,  0,  0,  5,-10],
	[-20,-10,-10,-10,-10,-10,-10,-20]
]

var rook_table: Array = [
	[0,  0,  0,  0,  0,  0,  0,  0],
	[5, 10, 10, 10, 10, 10, 10,  5],
	[-5,  0,  0,  0,  0,  0,  0, -5],
	[-5,  0,  0,  0,  0,  0,  0, -5],
	[-5,  0,  0,  0,  0,  0,  0, -5],
	[-5,  0,  0,  0,  0,  0,  0, -5],
	[-5,  0,  0,  0,  0,  0,  0, -5],
	[0,  0,  0,  5,  5,  0,  0,  0]
]

var queen_table: Array = [
	[-20,-10,-10, -5, -5,-10,-10,-20],
	[-10,  0,  0,  0,  0,  0,  0,-10],
	[-10,  0,  5,  5,  5,  5,  0,-10],
	[-5,  0,  5,  5,  5,  5,  0, -5],
	[0,  0,  5,  5,  5,  5,  0, -5],
	[-10,  5,  5,  5,  5,  5,  0,-10],
	[-10,  0,  5,  0,  0,  0,  0,-10],
	[-20,-10,-10, -5, -5,-10,-10,-20]
]

var king_table: Array = [
	[-30,-40,-40,-50,-50,-40,-40,-30],
	[-30,-40,-40,-50,-50,-40,-40,-30],
	[-30,-40,-40,-50,-50,-40,-40,-30],
	[-30,-40,-40,-50,-50,-40,-40,-30],
	[-20,-30,-30,-40,-40,-30,-30,-20],
	[-10,-20,-20,-20,-20,-20,-20,-10],
	[20, 20,  0,  0,  0,  0, 20, 20],
	[20, 30, 10,  0,  0, 10, 30, 20]
]

func set_difficulty(difficulty_name: String, is_campaign: bool = false):
	"""Set AI difficulty by name."""
	if is_campaign and campaign_difficulties.has(difficulty_name):
		difficulty_elo = campaign_difficulties[difficulty_name]
	elif sandbox_difficulties.has(difficulty_name):
		difficulty_elo = sandbox_difficulties[difficulty_name]
	else:
		difficulty_elo = 1000  # Default

func get_search_depth() -> int:
	"""Get search depth based on Elo rating."""
	if difficulty_elo < 600:
		return 1
	elif difficulty_elo < 1000:
		return 2
	elif difficulty_elo < 1400:
		return 3
	elif difficulty_elo < 1700:
		return 4
	else:
		return 5

func start_thinking(board: Array, color: String = "black"):
	"""Start AI thinking process."""
	if is_thinking:
		return

	is_thinking = true
	current_board = deep_copy_board(board)
	ai_color = color
	emit_signal("thinking_started")

	# Use call_deferred to not block the main thread
	call_deferred("_calculate_move")

func _calculate_move():
	"""Calculate the best move using minimax."""
	var depth = get_search_depth()
	var best_move = find_best_move(current_board, ai_color, depth)

	is_thinking = false
	emit_signal("thinking_complete", best_move)

func find_best_move(board: Array, color: String, depth: int) -> Dictionary:
	"""Find the best move using minimax with alpha-beta pruning."""
	var all_moves = get_all_moves(board, color)

	if all_moves.size() == 0:
		return {}

	# Add randomness for lower difficulties
	var random_factor = get_random_factor()

	var best_move = {}
	var best_score = -INF
	var alpha = -INF
	var beta = INF

	for move in all_moves:
		var new_board = make_move_on_copy(board, move)
		var score = -minimax(new_board, depth - 1, -beta, -alpha, get_opponent(color))

		# Add random noise for lower difficulties
		score += randf_range(-random_factor, random_factor)

		if score > best_score:
			best_score = score
			best_move = move

		alpha = max(alpha, score)

	return best_move

func minimax(board: Array, depth: int, alpha: float, beta: float, color: String) -> float:
	"""Minimax algorithm with alpha-beta pruning."""
	if depth == 0:
		return evaluate_board(board, color)

	var all_moves = get_all_moves(board, color)

	if all_moves.size() == 0:
		# No legal moves - checkmate or stalemate
		if is_in_check(board, color):
			return -INF  # Checkmate
		return 0  # Stalemate

	var max_score = -INF

	for move in all_moves:
		var new_board = make_move_on_copy(board, move)
		var score = -minimax(new_board, depth - 1, -beta, -alpha, get_opponent(color))
		max_score = max(max_score, score)
		alpha = max(alpha, score)

		if alpha >= beta:
			break  # Beta cutoff

	return max_score

func evaluate_board(board: Array, perspective_color: String) -> float:
	"""Evaluate board position from perspective of given color."""
	var score = 0.0

	for row in range(8):
		for col in range(8):
			var piece = board[row][col]
			if piece == "":
				continue

			var piece_color = "white" if piece[0] == "w" else "black"
			var piece_type = piece[1]
			var piece_score = piece_values.get(piece_type, 0)

			# Add positional bonus
			piece_score += get_position_bonus(piece_type, row, col, piece_color)

			if piece_color == perspective_color:
				score += piece_score
			else:
				score -= piece_score

	return score

func get_position_bonus(piece_type: String, row: int, col: int, color: String) -> int:
	"""Get positional bonus for a piece."""
	var table_row = row if color == "black" else 7 - row

	match piece_type:
		"P": return pawn_table[table_row][col]
		"N": return knight_table[table_row][col]
		"B": return bishop_table[table_row][col]
		"R": return rook_table[table_row][col]
		"Q": return queen_table[table_row][col]
		"K": return king_table[table_row][col]

	return 0

func get_random_factor() -> float:
	"""Get random factor for move selection based on difficulty."""
	if difficulty_elo < 600:
		return 200.0  # Very random
	elif difficulty_elo < 1000:
		return 100.0
	elif difficulty_elo < 1400:
		return 50.0
	elif difficulty_elo < 1700:
		return 20.0
	else:
		return 5.0  # Almost no randomness

func get_all_moves(board: Array, color: String) -> Array:
	"""Get all legal moves for a color."""
	var moves = []

	for row in range(8):
		for col in range(8):
			var piece = board[row][col]
			if piece == "":
				continue

			var piece_color = "white" if piece[0] == "w" else "black"
			if piece_color != color:
				continue

			var piece_moves = get_piece_moves(board, Vector2i(col, row), piece)
			for move_to in piece_moves:
				# Check if move is legal (doesn't leave king in check)
				var test_board = make_move_on_copy(board, {"from": Vector2i(col, row), "to": move_to})
				if not is_in_check(test_board, color):
					moves.append({"from": Vector2i(col, row), "to": move_to})

	return moves

func get_piece_moves(board: Array, pos: Vector2i, piece: String) -> Array:
	"""Get all possible moves for a piece (not checking for check)."""
	var moves = []
	var color = "white" if piece[0] == "w" else "black"
	var piece_type = piece[1]

	match piece_type:
		"P": moves = get_pawn_moves(board, pos, color)
		"N": moves = get_knight_moves(board, pos, color)
		"B": moves = get_bishop_moves(board, pos, color)
		"R": moves = get_rook_moves(board, pos, color)
		"Q": moves = get_queen_moves(board, pos, color)
		"K": moves = get_king_moves(board, pos, color)

	return moves

func get_pawn_moves(board: Array, pos: Vector2i, color: String) -> Array:
	var moves = []
	var direction = -1 if color == "white" else 1
	var start_row = 6 if color == "white" else 1

	# Forward move
	var forward = Vector2i(pos.x, pos.y + direction)
	if is_valid_pos(forward) and board[forward.y][forward.x] == "":
		moves.append(forward)
		# Double move from start
		if pos.y == start_row:
			var double = Vector2i(pos.x, pos.y + direction * 2)
			if board[double.y][double.x] == "":
				moves.append(double)

	# Captures
	for dx in [-1, 1]:
		var capture = Vector2i(pos.x + dx, pos.y + direction)
		if is_valid_pos(capture):
			var target = board[capture.y][capture.x]
			if target != "":
				var target_color = "white" if target[0] == "w" else "black"
				if target_color != color:
					moves.append(capture)

	return moves

func get_knight_moves(board: Array, pos: Vector2i, color: String) -> Array:
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

func get_bishop_moves(board: Array, pos: Vector2i, color: String) -> Array:
	return get_sliding_moves(board, pos, color, [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)])

func get_rook_moves(board: Array, pos: Vector2i, color: String) -> Array:
	return get_sliding_moves(board, pos, color, [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)])

func get_queen_moves(board: Array, pos: Vector2i, color: String) -> Array:
	return get_bishop_moves(board, pos, color) + get_rook_moves(board, pos, color)

func get_king_moves(board: Array, pos: Vector2i, color: String) -> Array:
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
	return moves

func get_sliding_moves(board: Array, pos: Vector2i, color: String, directions: Array) -> Array:
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

func is_in_check(board: Array, color: String) -> bool:
	"""Check if the king of given color is in check."""
	var king_pos = find_king(board, color)
	if king_pos == Vector2i(-1, -1):
		return false

	var opponent = get_opponent(color)

	# Check all opponent pieces
	for row in range(8):
		for col in range(8):
			var piece = board[row][col]
			if piece == "" or get_piece_color(piece) != opponent:
				continue

			var piece_moves = get_piece_moves(board, Vector2i(col, row), piece)
			if king_pos in piece_moves:
				return true

	return false

func find_king(board: Array, color: String) -> Vector2i:
	"""Find the king position for given color."""
	var king_piece = "wK" if color == "white" else "bK"
	for row in range(8):
		for col in range(8):
			if board[row][col] == king_piece:
				return Vector2i(col, row)
	return Vector2i(-1, -1)

func make_move_on_copy(board: Array, move: Dictionary) -> Array:
	"""Make a move on a copy of the board."""
	var new_board = deep_copy_board(board)
	var from = move["from"]
	var to = move["to"]

	new_board[to.y][to.x] = new_board[from.y][from.x]
	new_board[from.y][from.x] = ""

	return new_board

func deep_copy_board(board: Array) -> Array:
	"""Create a deep copy of the board."""
	var new_board = []
	for row in board:
		new_board.append(row.duplicate())
	return new_board

func get_piece_color(piece: String) -> String:
	if piece == "":
		return ""
	return "white" if piece[0] == "w" else "black"

func get_opponent(color: String) -> String:
	return "black" if color == "white" else "white"

func is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8
