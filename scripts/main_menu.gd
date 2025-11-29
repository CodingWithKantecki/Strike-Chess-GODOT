extends Control

# Main Menu - Exact replica of pygame version
# City parallax background with falling chess pieces

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

# Falling pieces data
var falling_pieces: Array = []
var NUM_COLS = 6
var NUM_ROWS = 4

# Parallax scroll speed (matching pygame)
var parallax_offset: float = 0.0
var PARALLAX_SPEED: float = 0.5

func _ready():
	# Start with black fade overlay
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)

	load_piece_textures()
	initialize_falling_pieces()

func load_piece_textures():
	for piece_name in white_pieces + black_pieces:
		var path = "res://assets/pieces/" + piece_name + ".png"
		var texture = load(path)
		if texture:
			piece_textures[piece_name] = texture

func initialize_falling_pieces():
	var screen_size = get_viewport_rect().size
	var col_spacing = (screen_size.x - 200) / (NUM_COLS - 1)
	var row_spacing = (screen_size.y + 400) / NUM_ROWS

	for row in range(NUM_ROWS):
		for col in range(NUM_COLS):
			# Create sprite for this piece
			var sprite = Sprite2D.new()
			falling_pieces_container.add_child(sprite)

			# Choose piece type (alternating colors)
			var piece_pool = white_pieces if (row + col) % 2 == 0 else black_pieces
			var piece_name = piece_pool[randi() % piece_pool.size()]

			if piece_textures.has(piece_name):
				sprite.texture = piece_textures[piece_name]

			# Scale the piece up (8x for big falling pieces like pygame)
			sprite.scale = Vector2(8.0, 8.0)

			# Use nearest neighbor filtering for crisp pixel art
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

			# Calculate position
			var x_pos = 100 + col * col_spacing + randf_range(-30, 30)
			x_pos = clamp(x_pos, 100, screen_size.x - 100)
			var y_base = -300 + row * row_spacing
			var y_pos = y_base + randf_range(-150, 150)

			sprite.position = Vector2(x_pos, y_pos)

			# Store piece data (matching pygame parameters)
			falling_pieces.append({
				"sprite": sprite,
				"column_x": 100 + col * col_spacing,
				"vy": randf_range(0.45, 0.55),  # Matching pygame speed
				"rotation_speed": randf_range(-0.3, 0.3),  # Matching pygame rotation
				"piece_name": piece_name,
				"is_white": (row + col) % 2 == 0
			})

func _process(delta):
	# Scene fade in from black
	if fade_overlay and scene_fade_elapsed < scene_fade_duration:
		scene_fade_elapsed += delta
		var progress = min(scene_fade_elapsed / scene_fade_duration, 1.0)
		fade_overlay.color.a = 1.0 - progress

	# Update parallax scroll
	parallax_offset += PARALLAX_SPEED
	if parallax_bg:
		parallax_bg.scroll_offset.x = -parallax_offset

	# Update falling pieces
	var screen_size = get_viewport_rect().size

	for piece_data in falling_pieces:
		var sprite: Sprite2D = piece_data["sprite"]

		# Move down (matching pygame speed)
		sprite.position.y += piece_data["vy"] * 60 * delta

		# Rotate smoothly
		sprite.rotation += piece_data["rotation_speed"] * delta

		# Reset when off screen
		if sprite.position.y > screen_size.y + 150:
			sprite.position.x = piece_data["column_x"] + randf_range(-30, 30)
			sprite.position.y = randf_range(-400, -150)
			piece_data["vy"] = randf_range(0.45, 0.55)

			# Randomly change piece type (same color)
			var piece_pool = white_pieces if piece_data["is_white"] else black_pieces
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
