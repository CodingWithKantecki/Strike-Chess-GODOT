extends Control

# Main Game Controller - SimuFire Chess
# Matches pygame game.py - Simultaneous turn system

@onready var chess_board: ChessBoard = $ChessBoard
@onready var game_over_panel: Panel = $GameOverPanel
@onready var winner_label: Label = $GameOverPanel/VBox/WinnerLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

# Top bar UI
@onready var white_status: Label = $TopBar/WhiteStatus
@onready var black_status: Label = $TopBar/BlackStatus
@onready var round_label: Label = $TopBar/RoundLabel
@onready var timer_label: Label = $Timer
@onready var instruction_label: Label = $InstructionLabel
@onready var countdown_label: Label = $CountdownLabel
@onready var tension_overlay: Control = $TensionOverlay

# Right sidebar
@onready var notifications_content: Label = $RightSidebar/NotificationsPanel/Content
@onready var card_container: HBoxContainer = $RightSidebar/StrikeDeckPanel/CardContainer
@onready var card_count_label: Label = $RightSidebar/StrikeDeckPanel/CardCount

# Parallax container
@onready var parallax_container: Control = $ParallaxContainer

# Asset system
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

# Colors for status
const PLANNING_COLOR = Color(1.0, 0.84, 0.0)  # Gold
const LOCKED_COLOR = Color(0.3, 1.0, 0.3)  # Green
const WAITING_COLOR = Color(0.8, 0.8, 0.8)
const TIMER_LOW_COLOR = Color(1.0, 0.3, 0.3)

# Countdown animation
var last_countdown_number: int = -1
var countdown_scale: float = 1.0

# Scene fade
var scene_fade_duration: float = 0.5
var scene_fade_elapsed: float = 0.0

# Parallax layers
var parallax_layers: Array = []
var parallax_speed: float = 15.0

# Screen shake (whole screen, like pygame)
var shake_active: bool = false
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_start_time: float = 0.0
var base_position: Vector2 = Vector2.ZERO


func _ready():
	# Start with black fade overlay
	fade_overlay.color = Color(0, 0, 0, 1)

	# Setup Asset System
	asset_system = AssetSystem.new()
	add_child(asset_system)

	# Connect signals
	if chess_board:
		chess_board.game_over.connect(_on_game_over)
		chess_board.piece_moved.connect(_on_piece_moved)
		chess_board.phase_changed.connect(_on_phase_changed)
		chess_board.collision_occurred.connect(_on_collision)
		chess_board.moves_resolved.connect(_on_moves_resolved)
		chess_board.timer_updated.connect(_on_timer_updated)
		chess_board.move_locked.connect(_on_move_locked)
		chess_board.countdown_tick.connect(_on_countdown_tick)
		chess_board.border_hit.connect(_on_border_hit)

	game_over_panel.visible = false
	countdown_label.visible = false

	# Setup parallax background
	_setup_parallax()

	# Initial UI state
	_reset_status_labels()

func _setup_parallax():
	"""Setup city parallax background layers."""
	var layer_paths = [
		"res://assets/parallax/WCP_1.png",
		"res://assets/parallax/WCP_2.png",
		"res://assets/parallax/WCP_3.png",
		"res://assets/parallax/WCP_4.png",
		"res://assets/parallax/WCP_5.png"
	]

	for i in range(layer_paths.size()):
		var texture = load(layer_paths[i])
		if texture:
			var sprite = TextureRect.new()
			sprite.texture = texture
			sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			sprite.anchors_preset = Control.PRESET_FULL_RECT
			sprite.anchor_right = 1.0
			sprite.anchor_bottom = 1.0
			sprite.modulate.a = 0.6 - (i * 0.05)  # Fade layers progressively
			parallax_container.add_child(sprite)
			parallax_layers.append({
				"sprite": sprite,
				"speed": (5 - i) * 0.2,  # Back layers move slower
				"offset": 0.0
			})

func _process(delta):
	# Scene fade in
	if scene_fade_elapsed < scene_fade_duration:
		scene_fade_elapsed += delta
		var progress = min(scene_fade_elapsed / scene_fade_duration, 1.0)
		fade_overlay.color.a = 1.0 - progress

	# Animate countdown scale
	if countdown_label.visible and countdown_scale > 1.0:
		countdown_scale = max(1.0, countdown_scale - delta * 3.0)
		countdown_label.scale = Vector2(countdown_scale, countdown_scale)
		countdown_label.pivot_offset = countdown_label.size / 2

	# Animate parallax (subtle horizontal drift)
	for layer in parallax_layers:
		layer["offset"] += layer["speed"] * delta
		# Subtle movement effect
		var sprite = layer["sprite"] as TextureRect
		if sprite:
			sprite.position.x = sin(layer["offset"] * 0.1) * 5

	# Update screen shake (whole screen)
	_update_screen_shake()

func _on_timer_updated(seconds: float):
	"""Update timer display."""
	timer_label.text = str(int(seconds))

	# Color based on time remaining
	if seconds <= 5:
		timer_label.add_theme_color_override("font_color", TIMER_LOW_COLOR)
		# Pulse effect
		var pulse = abs(sin(Time.get_ticks_msec() * 0.01)) * 0.3 + 0.7
		timer_label.modulate.a = pulse
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)
		timer_label.modulate.a = 1.0

func _on_phase_changed(phase: int):
	"""Handle phase changes."""
	match phase:
		ChessBoard.SimuFirePhase.PLANNING:
			countdown_label.visible = false
			if tension_overlay:
				tension_overlay.set_countdown_active(false)
			instruction_label.text = "DRAG TO MOVE - CLICK TO SELECT"
			_reset_status_labels()

		ChessBoard.SimuFirePhase.COUNTDOWN:
			countdown_label.visible = true
			if tension_overlay:
				tension_overlay.set_countdown_active(true)
			instruction_label.text = "MOVES LOCKED - EXECUTING IN..."

		ChessBoard.SimuFirePhase.RESOLUTION:
			countdown_label.visible = false
			if tension_overlay:
				tension_overlay.set_countdown_active(false)
			instruction_label.text = "MOVES EXECUTING..."
			# Apply asset effects before moves resolve
			asset_system.apply_pending_effects(chess_board)

		ChessBoard.SimuFirePhase.END:
			if tension_overlay:
				tension_overlay.set_countdown_active(false)
			instruction_label.text = "ROUND COMPLETE"
			# Check for asset distribution
			asset_system.check_distribution(chess_board.round_number)
			# Update status effects
			asset_system.update_status_effects()
			# Apply discard rule
			asset_system.apply_discard_rule()

	# Update round label
	if chess_board:
		round_label.text = "ROUND " + str(chess_board.round_number)

	# Update notification about next asset
	_update_notifications()

func _on_move_locked(color: String):
	"""Update when a player locks their move."""
	if color == "white":
		white_status.text = "WHITE: LOCKED!"
		white_status.add_theme_color_override("font_color", LOCKED_COLOR)
	else:
		black_status.text = "BLACK: LOCKED!"
		black_status.add_theme_color_override("font_color", LOCKED_COLOR)

func _on_countdown_tick(number: int):
	"""Handle countdown tick."""
	if number != last_countdown_number:
		last_countdown_number = number
		countdown_scale = 2.0  # Start large

		if number > 0:
			countdown_label.text = str(number)
			AudioManager.play_click_sound()
		else:
			countdown_label.text = "GO!"
			AudioManager.play_click_sound()

func _reset_status_labels():
	"""Reset status labels for new round."""
	white_status.text = "WHITE: PLANNING"
	white_status.add_theme_color_override("font_color", PLANNING_COLOR)
	black_status.text = "BLACK: PLANNING"
	black_status.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	last_countdown_number = -1

func _update_notifications():
	"""Update notification panel with next asset info."""
	var next_round = asset_system.get_next_distribution_round(chess_board.round_number if chess_board else 1)
	if next_round > 0:
		notifications_content.text = "NEXT ASSET: ROUND " + str(next_round)
	else:
		notifications_content.text = "NO UPCOMING ASSETS"

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
	_show_collision_effect(screen_pos, collision_type)
	AudioManager.play_click_sound()

func _show_collision_effect(pos: Vector2, collision_type: String):
	"""Show visual effect for collision."""
	var effect_label = Label.new()

	match collision_type:
		"bonk":
			effect_label.text = "BONK!"
			effect_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
		"swap_bonk":
			effect_label.text = "BLOCKED!"
			effect_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	effect_label.add_theme_font_size_override("font_size", 48)
	effect_label.position = pos
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(effect_label)

	# Animate and remove
	var tween = create_tween()
	tween.tween_property(effect_label, "position:y", pos.y - 50, 0.5)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(effect_label.queue_free)

func _on_moves_resolved():
	"""Handle after moves are resolved."""
	pass

func _on_game_over(winner: String):
	"""Handle game over."""
	game_over_panel.visible = true
	if winner == "draw":
		winner_label.text = "STALEMATE!"
	else:
		winner_label.text = winner.to_upper() + " WINS!"

func _on_back_button_pressed():
	AudioManager.play_click_sound()
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	tween.tween_callback(_go_to_menu)

func _go_to_menu():
	match GameState.current_mode:
		"campaign":
			get_tree().change_scene_to_file("res://scenes/campaign_map.tscn")
		"sandbox":
			get_tree().change_scene_to_file("res://scenes/sandbox_settings.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_play_again_pressed():
	AudioManager.play_click_sound()
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	AudioManager.play_click_sound()
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func get_white_points() -> int:
	return white_points

func get_black_points() -> int:
	return black_points

# ==================== SCREEN SHAKE ====================

func _on_border_hit():
	"""Handle border hit from chess board - trigger whole screen shake."""
	start_screen_shake(3.0, 0.1)  # intensity 3, duration 100ms (matching pygame)

func start_screen_shake(intensity: float, duration: float):
	"""Start a screen shake effect on the whole game."""
	shake_active = true
	shake_intensity = intensity
	shake_duration = duration
	shake_start_time = Time.get_unix_time_from_system()

func _update_screen_shake():
	"""Update screen shake - applies to whole Control node."""
	if not shake_active:
		position = base_position
		return

	var elapsed = Time.get_unix_time_from_system() - shake_start_time
	if elapsed >= shake_duration:
		shake_active = false
		position = base_position
		return

	# Calculate shake with decay (matching pygame powerups.py)
	var progress = elapsed / shake_duration
	var current_intensity = shake_intensity * (1.0 - progress)

	# Random shake offset
	var offset_x = randf_range(-current_intensity, current_intensity)
	var offset_y = randf_range(-current_intensity, current_intensity)

	position = base_position + Vector2(offset_x, offset_y)
