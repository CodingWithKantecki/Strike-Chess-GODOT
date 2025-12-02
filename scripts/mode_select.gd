extends Control

# Mode Select Screen - "CHOOSE YOUR BATTLE" with falling pieces

@onready var title: Label = $Title
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var falling_pieces_container: Node2D = $FallingPieces

# Description panel elements
@onready var mode_name_label: Label = $BottomContainer/DescriptionPanel/VBox/ModeName
@onready var mode_subtitle_label: Label = $BottomContainer/DescriptionPanel/VBox/ModeSubtitle
@onready var description_label: Label = $BottomContainer/DescriptionPanel/VBox/Description
@onready var features_label: Label = $BottomContainer/DescriptionPanel/VBox/Features

# Card panels for selection highlight
@onready var tutorial_card: Panel = $CardsContainer/TutorialCard
@onready var campaign_card: Panel = $CardsContainer/CampaignCard
@onready var sandbox_card: Panel = $CardsContainer/SandboxCard
@onready var multiplayer_card: Panel = $CardsContainer/MultiplayerCard

# Scene fade
var scene_fade_duration: float = 0.5
var scene_fade_elapsed: float = 0.0

# Title glitch effect
var title_glitch_active: bool = true
var title_glitch_timer: float = 0.0
var title_glitch_duration: float = 1.2
var original_title: String = "CHOOSE YOUR BATTLE"

# Description glitch effect
var desc_glitch_active: bool = false
var desc_glitch_timer: float = 0.0
var desc_glitch_duration: float = 1.2
var target_mode_name: String = ""
var target_subtitle: String = ""
var target_description: String = ""
var target_features: String = ""

# Currently selected mode
var selected_mode: String = "campaign"

# Piece textures and falling pieces
var piece_textures: Dictionary = {}
var white_pieces = ["W_Pawn", "W_Knight", "W_Bishop", "W_Rook", "W_Queen", "W_King"]
var black_pieces = ["B_Pawn", "B_Knight", "B_Bishop", "B_Rook", "B_Queen", "B_King"]
var falling_pieces: Array = []
var NUM_COLUMNS: int = 6

# Falling piece settings (same as main menu)
const PIECE_SCALE: float = 12.0
const FALL_SPEED: float = 45.0
const ROTATION_SPEED_MAX: float = 0.08
const MIN_PIECE_DISTANCE: float = 180.0

# Mode data
var mode_data = {
	"tutorial": {
		"name": "TUTORIAL",
		"subtitle": "Learn the Basics",
		"description": "New to Strike Chess? Start your training\nhere! Learn the basics of chess combined\nwith our unique tactical system.\nPerfect for beginners or as a refresher.",
		"features": "- Master chess fundamentals\n- Learn special abilities\n- Practice against AI",
		"color": Color(0, 0.8, 1, 1)
	},
	"campaign": {
		"name": "CAMPAIGN",
		"subtitle": "Story Mode",
		"description": "Lead your forces through an epic campaign!\nBattle through 25+ challenging missions,\nface powerful boss enemies, and unlock\nnew abilities as you progress.",
		"features": "- 25+ missions\n- Boss battles\n- Unlock content",
		"color": Color(1, 0.84, 0, 1)
	},
	"sandbox": {
		"name": "SANDBOX",
		"subtitle": "Free Play",
		"description": "Unleash your creativity with unlimited\nresources! Test strategies, experiment\nwith different tactics, and play chess\nwithout restrictions.",
		"features": "- Unlimited power\n- Experiment freely\n- No limits",
		"color": Color(0.6, 1, 0.6, 1)
	},
	"multiplayer": {
		"name": "MULTIPLAYER",
		"subtitle": "Coming Soon",
		"description": "Online multiplayer is coming soon!\nYou'll be able to challenge friends,\nclimb the ranked ladder, and compete\non global leaderboards. Stay tuned!",
		"features": "- Battle friends online\n- Ranked matches\n- Global leaderboard",
		"color": Color(0.5, 0.35, 0.7, 1)
	}
}

# StyleBoxFlat for cards
var style_normal: StyleBoxFlat
var style_selected: StyleBoxFlat

func _ready():
	# Start with black fade overlay
	fade_overlay.color = Color(0, 0, 0, 1)

	# Initialize title glitch
	title_glitch_timer = 0.0
	title_glitch_active = true

	# Create style boxes
	style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style_normal.set_border_width_all(3)
	style_normal.border_color = Color(0.3, 0.3, 0.35, 1)

	style_selected = StyleBoxFlat.new()
	style_selected.bg_color = Color(0.15, 0.15, 0.2, 1)
	style_selected.set_border_width_all(4)
	style_selected.border_color = Color(1, 0.84, 0, 1)

	# Load pieces and initialize falling pieces
	load_piece_textures()
	initialize_falling_pieces()

	# Set initial selection
	update_selection("campaign")

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
	# Scene fade in
	if scene_fade_elapsed < scene_fade_duration:
		scene_fade_elapsed += delta
		var progress = min(scene_fade_elapsed / scene_fade_duration, 1.0)
		fade_overlay.color.a = 1.0 - progress

	# Title glitch effect
	if title_glitch_active:
		title_glitch_timer += delta
		var progress = min(title_glitch_timer / title_glitch_duration, 1.0)
		title.text = scramble_text(original_title, progress)

		if progress >= 1.0:
			title_glitch_active = false
			title.text = original_title

	# Description glitch effect
	if desc_glitch_active:
		desc_glitch_timer += delta
		var progress = min(desc_glitch_timer / desc_glitch_duration, 1.0)

		mode_name_label.text = scramble_text(target_mode_name, progress)
		mode_subtitle_label.text = scramble_text(target_subtitle, progress)
		description_label.text = scramble_text(target_description, progress)
		features_label.text = scramble_text(target_features, progress)

		if progress >= 1.0:
			desc_glitch_active = false
			mode_name_label.text = target_mode_name
			mode_subtitle_label.text = target_subtitle
			description_label.text = target_description
			features_label.text = target_features

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

	piece["vy"] = FALL_SPEED
	piece["rotation_speed"] = randf_range(-ROTATION_SPEED_MAX, ROTATION_SPEED_MAX)

	# Change piece type
	var piece_pool = white_pieces if piece["is_white"] else black_pieces
	var new_piece = piece_pool[randi() % piece_pool.size()]
	if piece_textures.has(new_piece):
		sprite.texture = piece_textures[new_piece]

func scramble_text(text: String, progress: float) -> String:
	if progress >= 1.0:
		return text

	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@$%&!?[]{}/<>"
	var result = ""

	# Use time to control character flip rate
	var time_slot = int(Time.get_ticks_msec() / 30)  # Change character every 30ms

	for i in range(text.length()):
		var char = text[i]
		if char == " " or char == "\n":
			result += char
		else:
			var char_progress = progress * 1.5 - (float(i) / text.length()) * 0.3

			if char_progress >= 1.0:
				result += char
			elif char_progress <= 0:
				# Use deterministic random based on position and time
				var char_index = (time_slot + i * 7) % chars.length()
				result += chars[char_index]
			else:
				if randf() < char_progress * 0.9:
					result += char
				else:
					var char_index = (time_slot + i * 7) % chars.length()
					result += chars[char_index]

	return result

func update_selection(mode: String):
	var is_new_selection = (mode != selected_mode)
	selected_mode = mode

	# Update card styles
	tutorial_card.add_theme_stylebox_override("panel", style_selected if mode == "tutorial" else style_normal)
	campaign_card.add_theme_stylebox_override("panel", style_selected if mode == "campaign" else style_normal)
	sandbox_card.add_theme_stylebox_override("panel", style_selected if mode == "sandbox" else style_normal)
	multiplayer_card.add_theme_stylebox_override("panel", style_selected if mode == "multiplayer" else style_normal)

	# Update selected card border color to match mode
	if mode_data.has(mode):
		var data = mode_data[mode]
		style_selected.border_color = data["color"]
		mode_name_label.add_theme_color_override("font_color", data["color"])

		# Store target text for glitch effect
		target_mode_name = data["name"]
		target_subtitle = data["subtitle"]
		target_description = data["description"]
		target_features = data["features"]

		# Trigger glitch effect if this is a new selection
		if is_new_selection:
			desc_glitch_active = true
			desc_glitch_timer = 0.0
		else:
			# First load - set text directly
			mode_name_label.text = target_mode_name
			mode_subtitle_label.text = target_subtitle
			description_label.text = target_description
			features_label.text = target_features

func _on_card_selected(mode: String):
	AudioManager.play_click_sound()
	update_selection(mode)

func _on_start_pressed():
	if selected_mode == "multiplayer":
		# Coming soon - don't start
		return

	AudioManager.play_click_sound()
	# Fade out and go to game
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	tween.tween_callback(_go_to_game)

func _go_to_game():
	# Navigate based on selected mode
	match selected_mode:
		"campaign":
			GameState.current_mode = "campaign"
			get_tree().change_scene_to_file("res://scenes/campaign_map.tscn")
		"tutorial":
			GameState.current_mode = "tutorial"
			get_tree().change_scene_to_file("res://scenes/game.tscn")
		"sandbox":
			# Go to ELO selection screen
			get_tree().change_scene_to_file("res://scenes/sandbox_settings.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_pressed():
	AudioManager.play_click_sound()
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	tween.tween_callback(_go_to_main_menu)

func _go_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
