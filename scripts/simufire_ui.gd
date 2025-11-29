extends CanvasLayer
class_name SimuFireUI

# SimuFire UI Overlay - Timer, Countdown, Phase Display
# Matches pygame game.py draw_simufire_overlay()

signal countdown_sound_requested(number: int)

var chess_board: ChessBoard
var asset_system: AssetSystem

# UI Elements
var timer_label: Label
var phase_label: Label
var round_label: Label
var countdown_label: Label
var white_status_label: Label
var black_status_label: Label
var instruction_label: Label

# Asset hand displays
var white_hand_container: HBoxContainer
var black_hand_container: HBoxContainer

# Countdown animation
var last_countdown_number: int = -1
var countdown_scale: float = 1.0

# Colors
const TIMER_COLOR = Color(1.0, 1.0, 1.0)
const TIMER_LOW_COLOR = Color(1.0, 0.3, 0.3)
const LOCKED_COLOR = Color(0.3, 1.0, 0.3)
const WAITING_COLOR = Color(1.0, 0.8, 0.2)
const COUNTDOWN_COLOR = Color(1.0, 0.9, 0.2)

func _ready():
	_create_ui()

func setup(board: ChessBoard, assets: AssetSystem = null):
	"""Setup with references to game systems."""
	chess_board = board
	asset_system = assets

	if chess_board:
		chess_board.timer_updated.connect(_on_timer_updated)
		chess_board.phase_changed.connect(_on_phase_changed)
		chess_board.move_locked.connect(_on_move_locked)
		chess_board.countdown_tick.connect(_on_countdown_tick)

func _create_ui():
	"""Create all UI elements."""
	# Timer display (top center)
	timer_label = Label.new()
	timer_label.text = "30"
	timer_label.add_theme_font_size_override("font_size", 72)
	timer_label.add_theme_color_override("font_color", TIMER_COLOR)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.anchors_preset = Control.PRESET_TOP_WIDE
	timer_label.position = Vector2(0, 20)
	add_child(timer_label)

	# Phase label
	phase_label = Label.new()
	phase_label.text = "PLANNING PHASE"
	phase_label.add_theme_font_size_override("font_size", 24)
	phase_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.anchors_preset = Control.PRESET_TOP_WIDE
	phase_label.position = Vector2(0, 100)
	add_child(phase_label)

	# Round label
	round_label = Label.new()
	round_label.text = "Round 1"
	round_label.add_theme_font_size_override("font_size", 20)
	round_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	round_label.position = Vector2(20, 20)
	add_child(round_label)

	# White status
	white_status_label = Label.new()
	white_status_label.text = "WHITE: Planning..."
	white_status_label.add_theme_font_size_override("font_size", 20)
	white_status_label.add_theme_color_override("font_color", WAITING_COLOR)
	white_status_label.position = Vector2(20, 200)
	add_child(white_status_label)

	# Black status
	black_status_label = Label.new()
	black_status_label.text = "BLACK: Planning..."
	black_status_label.add_theme_font_size_override("font_size", 20)
	black_status_label.add_theme_color_override("font_color", WAITING_COLOR)
	black_status_label.position = Vector2(20, 230)
	add_child(black_status_label)

	# Instructions
	instruction_label = Label.new()
	instruction_label.text = "Both players: Select piece, then click destination to lock move"
	instruction_label.add_theme_font_size_override("font_size", 16)
	instruction_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	instruction_label.position = Vector2(0, -50)
	add_child(instruction_label)

	# Countdown label (large center, initially hidden)
	countdown_label = Label.new()
	countdown_label.text = ""
	countdown_label.add_theme_font_size_override("font_size", 200)
	countdown_label.add_theme_color_override("font_color", COUNTDOWN_COLOR)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.anchors_preset = Control.PRESET_CENTER
	countdown_label.visible = false
	add_child(countdown_label)

	# White hand container (left side)
	white_hand_container = HBoxContainer.new()
	white_hand_container.position = Vector2(20, 300)
	add_child(white_hand_container)

	# Black hand container (right side)
	black_hand_container = HBoxContainer.new()
	black_hand_container.position = Vector2(1100, 300)
	add_child(black_hand_container)

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
		timer_label.add_theme_color_override("font_color", TIMER_COLOR)
		timer_label.modulate.a = 1.0

func _on_phase_changed(phase: int):
	"""Update phase display."""
	match phase:
		ChessBoard.SimuFirePhase.PLANNING:
			phase_label.text = "PLANNING PHASE"
			countdown_label.visible = false
			instruction_label.text = "Both players: Select piece, then click destination to lock move"
			_reset_status_labels()

		ChessBoard.SimuFirePhase.COUNTDOWN:
			phase_label.text = "GET READY!"
			countdown_label.visible = true
			instruction_label.text = "Moves locked - executing in..."

		ChessBoard.SimuFirePhase.RESOLUTION:
			phase_label.text = "RESOLUTION"
			countdown_label.visible = false
			instruction_label.text = "Moves executing..."

		ChessBoard.SimuFirePhase.END:
			phase_label.text = "ROUND COMPLETE"
			instruction_label.text = "Starting next round..."

	if chess_board:
		round_label.text = "Round " + str(chess_board.round_number)

func _on_move_locked(color: String):
	"""Update when a player locks their move."""
	if color == "white":
		white_status_label.text = "WHITE: LOCKED!"
		white_status_label.add_theme_color_override("font_color", LOCKED_COLOR)
	else:
		black_status_label.text = "BLACK: LOCKED!"
		black_status_label.add_theme_color_override("font_color", LOCKED_COLOR)

func _on_countdown_tick(number: int):
	"""Handle countdown tick."""
	if number != last_countdown_number:
		last_countdown_number = number
		countdown_scale = 2.0  # Start large

		if number > 0:
			countdown_label.text = str(number)
			emit_signal("countdown_sound_requested", number)
		else:
			countdown_label.text = "GO!"
			emit_signal("countdown_sound_requested", 0)

func _reset_status_labels():
	"""Reset status labels for new round."""
	white_status_label.text = "WHITE: Planning..."
	white_status_label.add_theme_color_override("font_color", WAITING_COLOR)
	black_status_label.text = "BLACK: Planning..."
	black_status_label.add_theme_color_override("font_color", WAITING_COLOR)
	last_countdown_number = -1

func _process(delta):
	# Animate countdown scale
	if countdown_label.visible and countdown_scale > 1.0:
		countdown_scale = max(1.0, countdown_scale - delta * 3.0)
		countdown_label.scale = Vector2(countdown_scale, countdown_scale)

	# Update hand displays
	_update_hand_displays()

func _update_hand_displays():
	"""Update asset card displays."""
	if not asset_system:
		return

	# Clear existing
	for child in white_hand_container.get_children():
		child.queue_free()
	for child in black_hand_container.get_children():
		child.queue_free()

	# Add white's cards
	for asset_type in asset_system.get_hand("white"):
		var card = _create_card(asset_type, "white")
		white_hand_container.add_child(card)

	# Add black's cards
	for asset_type in asset_system.get_hand("black"):
		var card = _create_card(asset_type, "black")
		black_hand_container.add_child(card)

func _create_card(asset_type: int, player: String) -> Control:
	"""Create a card display for an asset."""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(100, 140)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_color = Color(0.0, 0.7, 1.0) if player == "white" else Color(1.0, 0.3, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	card.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = asset_system.get_asset_name(asset_type)
	label.add_theme_font_size_override("font_size", 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(5, 100)
	label.size = Vector2(90, 30)
	card.add_child(label)

	return card

func show_collision_effect(pos: Vector2, collision_type: String):
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
