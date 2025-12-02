extends Control

# Sandbox Settings - ELO Selection Screen
# Matches pygame sandbox difficulty menu

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var elo_label: Label = $CenterContainer/VBox/EloDisplay
@onready var difficulty_label: Label = $CenterContainer/VBox/DifficultyLabel
@onready var elo_slider: HSlider = $CenterContainer/VBox/SliderContainer/EloSlider
@onready var slider_fill: ColorRect = $CenterContainer/VBox/SliderContainer/SliderFill
@onready var min_label: Label = $CenterContainer/VBox/SliderContainer/MinLabel
@onready var max_label: Label = $CenterContainer/VBox/SliderContainer/MaxLabel
@onready var falling_pieces_container: Node2D = $FallingPieces

# ELO settings
var current_elo: int = 1000
const MIN_ELO = 600
const MAX_ELO = 2000

# Falling pieces (same as main menu)
var piece_textures: Dictionary = {}
var white_pieces = ["W_Pawn", "W_Knight", "W_Bishop", "W_Rook", "W_Queen", "W_King"]
var black_pieces = ["B_Pawn", "B_Knight", "B_Bishop", "B_Rook", "B_Queen", "B_King"]
var falling_pieces: Array = []
var NUM_COLUMNS: int = 6

const PIECE_SCALE: float = 12.0
const FALL_SPEED: float = 45.0
const ROTATION_SPEED_MAX: float = 0.08
const MIN_PIECE_DISTANCE: float = 180.0

# Difficulty tiers with colors
var difficulty_tiers = [
	{"max_elo": 700, "name": "Beginner - Makes frequent mistakes", "color": Color(0.2, 0.8, 0.2)},
	{"max_elo": 900, "name": "Easy - Some tactical errors", "color": Color(0.4, 0.8, 0.2)},
	{"max_elo": 1200, "name": "Medium - Balanced opponent", "color": Color(0.8, 0.8, 0.2)},
	{"max_elo": 1500, "name": "Hard - Strong strategy", "color": Color(0.8, 0.6, 0.2)},
	{"max_elo": 1700, "name": "Expert - Very challenging", "color": Color(0.8, 0.4, 0.2)},
	{"max_elo": 1900, "name": "Master - Very strong play", "color": Color(0.8, 0.2, 0.2)},
	{"max_elo": 2001, "name": "Grandmaster - Maximum difficulty", "color": Color(1.0, 0.0, 0.0)}
]

# Glitch effect
var glitch_active: bool = true
var glitch_timer: float = 0.0
var glitch_duration: float = 0.8

func _ready():
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)

	# Setup slider
	if elo_slider:
		elo_slider.min_value = MIN_ELO
		elo_slider.max_value = MAX_ELO
		elo_slider.step = 100
		elo_slider.value = current_elo
		elo_slider.value_changed.connect(_on_elo_changed)

	# Load pieces and initialize falling pieces
	load_piece_textures()
	call_deferred("initialize_falling_pieces")

	update_display()

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
				"vy": FALL_SPEED,
				"rotation_speed": randf_range(-ROTATION_SPEED_MAX, ROTATION_SPEED_MAX),
				"is_white": (col + i) % 2 == 0
			})

func _process(delta):
	# Fade in
	if fade_overlay and fade_overlay.color.a > 0:
		fade_overlay.color.a = max(0, fade_overlay.color.a - delta * 3)

	# Glitch effect on title
	if glitch_active:
		glitch_timer += delta
		var progress = min(glitch_timer / glitch_duration, 1.0)

		if progress >= 1.0:
			glitch_active = false

	# Update falling pieces
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

		# Recycle when off bottom
		if sprite.position.y > screen_size.y + 150:
			recycle_piece(piece, screen_size, col_width)

func recycle_piece(piece: Dictionary, screen_size: Vector2, col_width: float):
	var sprite: Sprite2D = piece["sprite"]
	var col = piece["column"]

	sprite.position.x = col_width * (col + 0.5) + randf_range(-20, 20)
	sprite.position.y = randf_range(-300, -150)
	sprite.rotation = randf_range(-0.3, 0.3)

	piece["vy"] = FALL_SPEED
	piece["rotation_speed"] = randf_range(-ROTATION_SPEED_MAX, ROTATION_SPEED_MAX)

	var piece_pool = white_pieces if piece["is_white"] else black_pieces
	var new_piece = piece_pool[randi() % piece_pool.size()]
	if piece_textures.has(new_piece):
		sprite.texture = piece_textures[new_piece]

func _on_elo_changed(value: float):
	current_elo = int(value)
	update_display()
	AudioManager.play_click_sound()

func update_display():
	"""Update all display elements based on current ELO."""
	# Update ELO display
	if elo_label:
		elo_label.text = str(current_elo) + " ELO"

	# Find current difficulty tier
	var tier = difficulty_tiers[0]
	for t in difficulty_tiers:
		if current_elo < t["max_elo"]:
			tier = t
			break

	# Update difficulty label
	if difficulty_label:
		difficulty_label.text = tier["name"]
		difficulty_label.add_theme_color_override("font_color", tier["color"])

	# Update ELO label color
	if elo_label:
		elo_label.add_theme_color_override("font_color", tier["color"])

	# Update slider fill
	if slider_fill:
		var fill_ratio = float(current_elo - MIN_ELO) / float(MAX_ELO - MIN_ELO)
		slider_fill.size.x = fill_ratio * 600  # Slider width
		slider_fill.color = tier["color"]

func _on_start_pressed():
	AudioManager.play_click_sound()

	# Store ELO in global singleton
	GameState.sandbox_elo = current_elo

	# Fade out and start game
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	tween.tween_callback(_start_game)

func _start_game():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_pressed():
	AudioManager.play_click_sound()
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/mode_select.tscn"))

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_back_pressed()
