extends CanvasLayer
class_name ChopperGunner

# Chopper Gunner - Ultimate 60pt powerup
# First-person helicopter minigun view for attacking the chess board
# Matches pygame chopper_gunner.py

signal chopper_started
signal chopper_ended
signal target_hit(position: Vector2i, piece_destroyed: bool)
signal ammo_changed(current: int, max_ammo: int)

enum State { INACTIVE, FLYING_IN, ACTIVE, FLYING_OUT }

var current_state: State = State.INACTIVE
var owner_color: String = "white"
var board_ref: Node = null  # Reference to chess board

# Gameplay settings
var max_ammo: int = 30
var current_ammo: int = 30
var fire_rate: float = 0.15  # Seconds between shots
var fire_cooldown: float = 0.0
var duration: float = 15.0  # Total time in chopper
var time_remaining: float = 0.0

# Visual settings
var crosshair_pos: Vector2 = Vector2.ZERO
var crosshair_speed: float = 400.0
var screen_shake: float = 0.0
var muzzle_flash_timer: float = 0.0

# Camera shake for firing
var shake_intensity: float = 5.0
var shake_decay: float = 10.0

# UI elements
var background: ColorRect
var crosshair: Control
var hud_container: Control
var ammo_label: Label
var time_label: Label
var instruction_label: Label

# Effects
var bullet_trails: Array = []
var impact_effects: Array = []

# Sounds
var helicopter_loop: AudioStream
var minigun_fire: AudioStream
var impact_sound: AudioStream

func _ready():
	visible = false
	_create_ui()
	_load_sounds()

func _load_sounds():
	"""Load chopper sound effects."""
	if ResourceLoader.exists("res://assets/helicopta.wav"):
		helicopter_loop = load("res://assets/helicopta.wav")
	if ResourceLoader.exists("res://assets/gunfire.wav"):
		minigun_fire = load("res://assets/gunfire.wav")
	if ResourceLoader.exists("res://assets/impact.wav"):
		impact_sound = load("res://assets/impact.wav")

func _create_ui():
	"""Create the chopper gunner UI."""
	# Dark overlay with slight green tint (night vision style)
	background = ColorRect.new()
	background.color = Color(0.0, 0.05, 0.0, 0.3)
	background.anchors_preset = Control.PRESET_FULL_RECT
	add_child(background)

	# Crosshair
	crosshair = Control.new()
	crosshair.custom_minimum_size = Vector2(60, 60)
	add_child(crosshair)
	crosshair.draw.connect(_draw_crosshair)

	# HUD container
	hud_container = Control.new()
	hud_container.anchors_preset = Control.PRESET_FULL_RECT
	add_child(hud_container)

	# Ammo display
	ammo_label = Label.new()
	ammo_label.text = "AMMO: 30/30"
	ammo_label.add_theme_font_size_override("font_size", 28)
	ammo_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	ammo_label.position = Vector2(50, 50)
	hud_container.add_child(ammo_label)

	# Time remaining
	time_label = Label.new()
	time_label.text = "TIME: 15.0"
	time_label.add_theme_font_size_override("font_size", 28)
	time_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	time_label.position = Vector2(50, 90)
	hud_container.add_child(time_label)

	# Instructions
	instruction_label = Label.new()
	instruction_label.text = "WASD/Mouse to aim | CLICK/SPACE to fire | ESC to exit"
	instruction_label.add_theme_font_size_override("font_size", 20)
	instruction_label.add_theme_color_override("font_color", Color(0.0, 0.8, 0.0))
	instruction_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
	instruction_label.position.y = -60
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_container.add_child(instruction_label)

	# Scan lines overlay for retro effect
	var scanlines = ColorRect.new()
	scanlines.anchors_preset = Control.PRESET_FULL_RECT
	scanlines.color = Color(0, 0, 0, 0)  # Will be shader-based ideally
	add_child(scanlines)

func _draw_crosshair():
	"""Draw the targeting crosshair."""
	var center = Vector2(30, 30)
	var color = Color(0.0, 1.0, 0.0, 0.9) if current_ammo > 0 else Color(1.0, 0.0, 0.0, 0.9)

	# Outer circle
	crosshair.draw_arc(center, 25, 0, TAU, 32, color, 2.0)

	# Inner circle
	crosshair.draw_arc(center, 8, 0, TAU, 16, color, 2.0)

	# Crosshair lines
	crosshair.draw_line(center + Vector2(-30, 0), center + Vector2(-10, 0), color, 2.0)
	crosshair.draw_line(center + Vector2(30, 0), center + Vector2(10, 0), color, 2.0)
	crosshair.draw_line(center + Vector2(0, -30), center + Vector2(0, -10), color, 2.0)
	crosshair.draw_line(center + Vector2(0, 30), center + Vector2(0, 10), color, 2.0)

	# Muzzle flash effect
	if muzzle_flash_timer > 0:
		crosshair.draw_circle(center, 15, Color(1.0, 0.9, 0.3, muzzle_flash_timer * 2))

func start(color: String, board: Node):
	"""Start the chopper gunner sequence."""
	owner_color = color
	board_ref = board
	current_ammo = max_ammo
	time_remaining = duration
	fire_cooldown = 0.0

	var viewport_size = get_viewport().get_visible_rect().size
	crosshair_pos = viewport_size / 2

	current_state = State.FLYING_IN
	visible = true

	# Play helicopter sound
	if helicopter_loop:
		AudioManager.play_music(helicopter_loop)

	emit_signal("chopper_started")

	# Fly-in animation
	var tween = create_tween()
	tween.tween_property(background, "color:a", 0.3, 1.0)
	tween.tween_callback(func():
		current_state = State.ACTIVE
	)

func stop():
	"""End the chopper gunner sequence."""
	if current_state == State.INACTIVE:
		return

	current_state = State.FLYING_OUT

	# Fly-out animation
	var tween = create_tween()
	tween.tween_property(background, "color:a", 0.0, 0.5)
	tween.tween_callback(func():
		current_state = State.INACTIVE
		visible = false
		emit_signal("chopper_ended")
	)

func _process(delta):
	if current_state == State.INACTIVE:
		return

	if current_state == State.ACTIVE:
		# Update time
		time_remaining -= delta
		if time_remaining <= 0:
			stop()
			return

		# Update fire cooldown
		fire_cooldown = max(0, fire_cooldown - delta)

		# Update muzzle flash
		muzzle_flash_timer = max(0, muzzle_flash_timer - delta * 10)

		# Handle input for aiming
		var move_dir = Vector2.ZERO
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			move_dir.x -= 1
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
			move_dir.x += 1
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			move_dir.y -= 1
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			move_dir.y += 1

		crosshair_pos += move_dir * crosshair_speed * delta

		# Clamp to screen
		var viewport_size = get_viewport().get_visible_rect().size
		crosshair_pos.x = clamp(crosshair_pos.x, 50, viewport_size.x - 50)
		crosshair_pos.y = clamp(crosshair_pos.y, 50, viewport_size.y - 50)

		# Update screen shake
		if screen_shake > 0:
			screen_shake = max(0, screen_shake - shake_decay * delta)
			var shake_offset = Vector2(
				randf_range(-screen_shake, screen_shake),
				randf_range(-screen_shake, screen_shake)
			)
			hud_container.position = shake_offset

	# Update crosshair position
	crosshair.position = crosshair_pos - Vector2(30, 30)
	crosshair.queue_redraw()

	# Update HUD
	ammo_label.text = "AMMO: %d/%d" % [current_ammo, max_ammo]
	time_label.text = "TIME: %.1f" % time_remaining

	# Color code ammo
	if current_ammo <= 5:
		ammo_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	elif current_ammo <= 10:
		ammo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	else:
		ammo_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))

	# Update bullet trails
	for i in range(bullet_trails.size() - 1, -1, -1):
		var trail = bullet_trails[i]
		trail["life"] -= delta
		if trail["life"] <= 0:
			bullet_trails.remove_at(i)

func _input(event):
	if current_state != State.ACTIVE:
		return

	# Mouse movement
	if event is InputEventMouseMotion:
		crosshair_pos = event.position

	# Firing
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fire()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			fire()
		elif event.keycode == KEY_ESCAPE:
			stop()

func fire():
	"""Fire the minigun."""
	if fire_cooldown > 0 or current_ammo <= 0:
		return

	current_ammo -= 1
	fire_cooldown = fire_rate
	muzzle_flash_timer = 1.0
	screen_shake = shake_intensity

	emit_signal("ammo_changed", current_ammo, max_ammo)

	# Play sound
	if minigun_fire:
		AudioManager.play_sound_effect(minigun_fire, 0.4)

	# Create bullet trail
	bullet_trails.append({
		"start": Vector2(crosshair_pos.x, 0),
		"end": crosshair_pos,
		"life": 0.1
	})

	# Check if hitting the board
	if board_ref:
		var board_pos = _screen_to_board(crosshair_pos)
		if board_pos.x >= 0 and board_pos.x < 8 and board_pos.y >= 0 and board_pos.y < 8:
			_hit_board_position(board_pos)

func _screen_to_board(screen_pos: Vector2) -> Vector2i:
	"""Convert screen position to board coordinates."""
	# This depends on the board's position and scale
	# Assuming board is centered and has known dimensions
	var viewport_size = get_viewport().get_visible_rect().size
	var board_size = 512  # Standard board size
	var board_offset = (viewport_size - Vector2(board_size, board_size)) / 2

	var board_pos = screen_pos - board_offset
	var col = int(board_pos.x / (board_size / 8))
	var row = int(board_pos.y / (board_size / 8))

	return Vector2i(col, row)

func _hit_board_position(pos: Vector2i):
	"""Process a hit on a board position."""
	if not board_ref:
		return

	# Check if there's a piece at this position
	var piece_destroyed = false

	if board_ref.has_method("get_piece_at"):
		var piece = board_ref.get_piece_at(pos)
		if piece != "":
			var piece_color = "white" if piece[0] == "w" else "black"

			# Can't hit own pieces
			if piece_color == owner_color:
				emit_signal("target_hit", pos, false)
				return

			# Can't destroy kings
			if piece[1] == "K":
				emit_signal("target_hit", pos, false)
				_create_impact_effect(pos, false)
				return

			# Check for shield
			if board_ref.has_method("is_shielded") and board_ref.is_shielded(pos):
				# Shield absorbs hit
				if board_ref.has_method("remove_shield"):
					board_ref.remove_shield(pos)
				emit_signal("target_hit", pos, false)
				_create_impact_effect(pos, false)
				return

			# Destroy the piece!
			if board_ref.has_method("remove_piece_at"):
				board_ref.remove_piece_at(pos)
				piece_destroyed = true

	emit_signal("target_hit", pos, piece_destroyed)
	_create_impact_effect(pos, piece_destroyed)

	# Play impact sound
	if impact_sound:
		AudioManager.play_sound_effect(impact_sound, 0.3)

func _create_impact_effect(pos: Vector2i, destroyed: bool):
	"""Create visual effect at impact point."""
	# Convert board pos back to screen for effect
	var viewport_size = get_viewport().get_visible_rect().size
	var board_size = 512
	var board_offset = (viewport_size - Vector2(board_size, board_size)) / 2
	var cell_size = board_size / 8

	var screen_pos = board_offset + Vector2(pos.x * cell_size + cell_size / 2, pos.y * cell_size + cell_size / 2)

	impact_effects.append({
		"pos": screen_pos,
		"destroyed": destroyed,
		"life": 0.3
	})

func get_remaining_time() -> float:
	return time_remaining

func get_ammo() -> int:
	return current_ammo

func is_active() -> bool:
	return current_state == State.ACTIVE
