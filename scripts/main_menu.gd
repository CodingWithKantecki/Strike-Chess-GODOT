extends Control

# Main Menu - Soft falling chess pieces background

@onready var parallax_bg: ParallaxBackground = $ParallaxBackground
@onready var falling_pieces_container: Node2D = $FallingPieces
@onready var fade_overlay: ColorRect = $FadeOverlay

# Scene fade
var scene_fade_duration: float = 1.0
var scene_fade_elapsed: float = 0.0

# Piece textures
var piece_textures: Dictionary = {}
var white_pieces = ["W_Pawn", "W_Knight", "W_Bishop", "W_Rook", "W_Queen", "W_King"]
var black_pieces = ["B_Pawn", "B_Knight", "B_Bishop", "B_Rook", "B_Queen", "B_King"]

# Falling pieces
var falling_pieces: Array = []
var NUM_COLUMNS: int = 6  # Number of columns for pieces to fall in

# Settings
const PIECE_SCALE: float = 12.0
const FALL_SPEED: float = 45.0  # Consistent speed
const ROTATION_SPEED_MAX: float = 0.08
const MIN_PIECE_DISTANCE: float = 180.0  # Minimum distance between pieces

# Random glitch effect
var glitch_time: float = 0.0
const GLITCH_CHANCE: float = 0.001  # Chance per frame for a piece to start glitching
const GLITCH_DURATION: float = 0.3  # How long a glitch lasts

# Parallax scroll speed
var parallax_offset: float = 0.0
var PARALLAX_SPEED: float = 0.5

func _ready():
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)

	load_piece_textures()
	call_deferred("initialize_falling_pieces")

func load_piece_textures():
	for piece_name in white_pieces + black_pieces:
		var path = "res://assets/pieces/" + piece_name + ".png"
		var texture = load(path)
		if texture:
			piece_textures[piece_name] = texture

func initialize_falling_pieces():
	var screen_size = get_viewport_rect().size
	if screen_size.x <= 0 or screen_size.y <= 0:
		screen_size = Vector2(1445, 940)

	var col_width = screen_size.x / NUM_COLUMNS
	var pieces_per_col = 2
	var vertical_spacing = (screen_size.y + 400) / pieces_per_col

	# Create pieces evenly spaced in columns
	for col in range(NUM_COLUMNS):
		for i in range(pieces_per_col):
			var piece_pool = white_pieces if (col + i) % 2 == 0 else black_pieces
			var piece_name = piece_pool[randi() % piece_pool.size()]

			var sprite = Sprite2D.new()
			if piece_textures.has(piece_name):
				sprite.texture = piece_textures[piece_name]
			sprite.scale = Vector2(PIECE_SCALE, PIECE_SCALE)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

			# Center in column with small random offset
			var x_pos = col_width * (col + 0.5) + randf_range(-20, 20)

			# Evenly space vertically with offset so columns aren't aligned
			var col_offset = (col % 2) * (vertical_spacing * 0.5)
			var y_pos = -200 + (i * vertical_spacing) + col_offset + randf_range(-30, 30)

			sprite.position = Vector2(x_pos, y_pos)
			sprite.rotation = randf_range(-0.3, 0.3)

			falling_pieces_container.add_child(sprite)

			falling_pieces.append({
				"sprite": sprite,
				"column": col,
				"vy": FALL_SPEED,  # Same speed for all - consistent rain
				"rotation_speed": randf_range(-ROTATION_SPEED_MAX, ROTATION_SPEED_MAX),
				"is_white": (col + i) % 2 == 0,
				"glitch_timer": 0.0,
				"glitch_offset": Vector2.ZERO
			})

func _process(delta):
	# Scene fade in
	if fade_overlay and scene_fade_elapsed < scene_fade_duration:
		scene_fade_elapsed += delta
		fade_overlay.color.a = 1.0 - min(scene_fade_elapsed / scene_fade_duration, 1.0)

	# Parallax scroll
	parallax_offset += PARALLAX_SPEED
	if parallax_bg:
		parallax_bg.scroll_offset.x = -parallax_offset

	# Update glitch time
	glitch_time += delta

	var screen_size = get_viewport_rect().size
	var col_width = screen_size.x / NUM_COLUMNS

	# Prevent pieces from overlapping - push apart if too close
	for i in range(falling_pieces.size()):
		var piece_a = falling_pieces[i]
		var sprite_a: Sprite2D = piece_a["sprite"]

		for j in range(i + 1, falling_pieces.size()):
			var piece_b = falling_pieces[j]
			var sprite_b: Sprite2D = piece_b["sprite"]

			var diff = sprite_b.position - sprite_a.position
			var dist = diff.length()

			if dist < MIN_PIECE_DISTANCE and dist > 0:
				# Push apart - mostly vertically
				var push = (MIN_PIECE_DISTANCE - dist) * 0.5
				var push_dir = diff.normalized()
				sprite_a.position -= push_dir * push
				sprite_b.position += push_dir * push

	# Update each piece
	for piece in falling_pieces:
		var sprite: Sprite2D = piece["sprite"]

		# Fall down at constant speed
		sprite.position.y += piece["vy"] * delta

		# Rotate slowly
		sprite.rotation += piece["rotation_speed"] * delta

		# Keep in column bounds
		var col = piece["column"]
		var col_center = col_width * (col + 0.5)
		var col_min = col_center - col_width * 0.4
		var col_max = col_center + col_width * 0.4
		sprite.position.x = clamp(sprite.position.x, col_min, col_max)

		# Random glitch effect
		if piece["glitch_timer"] > 0:
			piece["glitch_timer"] -= delta
			apply_glitch_effect(piece, sprite)
			if piece["glitch_timer"] <= 0:
				reset_glitch_effect(piece, sprite)
		elif randf() < GLITCH_CHANCE:
			# Start a new glitch
			piece["glitch_timer"] = GLITCH_DURATION

		# Recycle when off bottom
		if sprite.position.y > screen_size.y + 150:
			recycle_piece(piece, screen_size, col_width)

func recycle_piece(piece: Dictionary, screen_size: Vector2, col_width: float):
	var sprite: Sprite2D = piece["sprite"]
	var col = piece["column"]

	# Reset well above screen in its column
	sprite.position.x = col_width * (col + 0.5) + randf_range(-20, 20)
	sprite.position.y = randf_range(-300, -150)
	sprite.rotation = randf_range(-0.3, 0.3)

	piece["vy"] = FALL_SPEED  # Same speed - consistent rain
	piece["rotation_speed"] = randf_range(-ROTATION_SPEED_MAX, ROTATION_SPEED_MAX)

	# Change piece type
	var piece_pool = white_pieces if piece["is_white"] else black_pieces
	var new_piece = piece_pool[randi() % piece_pool.size()]
	if piece_textures.has(new_piece):
		sprite.texture = piece_textures[new_piece]

# Button handlers matching pygame menu
func _on_play_pressed():
	AudioManager.play_click_sound()
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _on_tutorial_pressed():
	# TODO: Implement tutorial
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_credits_pressed():
	AudioManager.play_click_sound()
	get_tree().change_scene_to_file("res://scenes/credits_screen.tscn")

func _on_card_viewer_pressed():
	AudioManager.play_click_sound()
	get_tree().change_scene_to_file("res://scenes/card_viewer.tscn")

func apply_glitch_effect(piece: Dictionary, sprite: Sprite2D):
	"""Apply subtle digital glitch effect to hovered piece."""
	# Gentle position jitter
	var jitter_x = randf_range(-3, 3) if randf() > 0.85 else 0
	var jitter_y = randf_range(-2, 2) if randf() > 0.9 else 0
	piece["glitch_offset"] = Vector2(jitter_x, jitter_y)

	# Apply offset
	sprite.offset = piece["glitch_offset"]

	# Subtle color glitch
	var glitch_intensity = sin(glitch_time * 12.0) * 0.5 + 0.5
	if randf() > 0.95:
		# Rare color flash - more muted
		var colors = [
			Color(1, 0.7, 0.85, 1),   # Soft pink
			Color(0.7, 1, 1, 1),       # Soft cyan
			Color(1, 1, 0.8, 1),       # Soft yellow
		]
		sprite.modulate = colors[randi() % colors.size()]
	elif randf() > 0.85:
		# Subtle brightness shift
		var brightness = 1.0 + glitch_intensity * 0.3
		sprite.modulate = Color(brightness, brightness, brightness, 1)
	else:
		# Very subtle color shift
		sprite.modulate = Color(1.0 + glitch_intensity * 0.08, 1.0, 1.0 + glitch_intensity * 0.05, 1)

	# Rare scale glitch
	if randf() > 0.97:
		var scale_glitch = PIECE_SCALE * randf_range(0.95, 1.08)
		sprite.scale = Vector2(scale_glitch, scale_glitch)
	else:
		sprite.scale = Vector2(PIECE_SCALE, PIECE_SCALE)

func reset_glitch_effect(piece: Dictionary, sprite: Sprite2D):
	"""Reset piece to normal after glitch."""
	piece["glitch_offset"] = Vector2.ZERO
	sprite.offset = Vector2.ZERO
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.scale = Vector2(PIECE_SCALE, PIECE_SCALE)
