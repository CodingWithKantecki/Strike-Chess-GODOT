extends Control

# Main Game Controller - SimuFire Chess
# Matches pygame game.py - Simultaneous turn system

@onready var chess_board: ChessBoard = $ChessBoard
@onready var game_over_panel: Panel = $UI/GameOverPanel
@onready var winner_label: Label = $UI/GameOverPanel/VBox/WinnerLabel

# SimuFire UI
var simufire_ui: SimuFireUI
var asset_system: AssetSystem

# Points tracking
var white_points: int = 0
var black_points: int = 0

# Piece point values (matching pygame)
var piece_values: Dictionary = {
	"P": 1,
	"N": 3,
	"B": 3,
	"R": 5,
	"Q": 9,
	"K": 0  # King capture ends game
}

func _ready():
	# Setup SimuFire UI
	simufire_ui = SimuFireUI.new()
	add_child(simufire_ui)

	# Setup Asset System
	asset_system = AssetSystem.new()
	add_child(asset_system)

	# Connect to chess board
	simufire_ui.setup(chess_board, asset_system)

	# Connect signals
	chess_board.game_over.connect(_on_game_over)
	chess_board.piece_moved.connect(_on_piece_moved)
	chess_board.phase_changed.connect(_on_phase_changed)
	chess_board.collision_occurred.connect(_on_collision)
	chess_board.moves_resolved.connect(_on_moves_resolved)

	simufire_ui.countdown_sound_requested.connect(_on_countdown_sound)

	game_over_panel.visible = false

func _on_phase_changed(phase: int):
	"""Handle phase changes."""
	match phase:
		ChessBoard.SimuFirePhase.RESOLUTION:
			# Apply asset effects before moves resolve
			asset_system.apply_pending_effects(chess_board)

		ChessBoard.SimuFirePhase.END:
			# Check for asset distribution
			asset_system.check_distribution(chess_board.round_number)
			# Update status effects
			asset_system.update_status_effects()
			# Apply discard rule
			asset_system.apply_discard_rule()

func _on_piece_moved(from: Vector2i, to: Vector2i, was_capture: bool):
	"""Handle piece movement."""
	if was_capture:
		AudioManager.play_capture_sound()
		_add_capture_points()
	else:
		AudioManager.play_move_sound()

func _add_capture_points():
	"""Add points for captured piece."""
	var captured = chess_board.get_last_captured_piece()
	if captured == "":
		return

	var piece_type = captured[1]
	var capturing_color = "black" if captured[0] == "w" else "white"
	var points = piece_values.get(piece_type, 0)

	if capturing_color == "white":
		white_points += points
	else:
		black_points += points

func _on_collision(pos: Vector2i, collision_type: String):
	"""Handle collision effects."""
	var screen_pos = chess_board.board_to_screen(pos)
	simufire_ui.show_collision_effect(screen_pos, collision_type)

	# Play bonk sound
	AudioManager.play_click_sound()  # Placeholder for bonk sound

func _on_moves_resolved():
	"""Handle after moves are resolved."""
	pass

func _on_countdown_sound(number: int):
	"""Play countdown sound."""
	AudioManager.play_click_sound()  # Placeholder for countdown beep

func _on_game_over(winner: String):
	"""Handle game over."""
	game_over_panel.visible = true
	if winner == "draw":
		winner_label.text = "Stalemate - Draw!"
	else:
		winner_label.text = winner.capitalize() + " Wins!"

func _on_back_button_pressed():
	AudioManager.play_click_sound()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_play_again_pressed():
	AudioManager.play_click_sound()
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	AudioManager.play_click_sound()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func get_white_points() -> int:
	return white_points

func get_black_points() -> int:
	return black_points
