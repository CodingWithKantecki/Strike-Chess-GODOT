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

# Currently selected mode
var selected_mode: String = "campaign"

# Piece textures and falling pieces
var piece_textures: Dictionary = {}
var white_pieces = ["W_Pawn", "W_Knight", "W_Bishop", "W_Rook", "W_Queen", "W_King"]
var black_pieces = ["B_Pawn", "B_Knight", "B_Bishop", "B_Rook", "B_Queen", "B_King"]
var falling_pieces: Array = []
var NUM_COLS = 6
var NUM_ROWS = 4

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
	var col_spacing = (screen_size.x - 200) / (NUM_COLS - 1)
	var row_spacing = (screen_size.y + 400) / NUM_ROWS

	for row in range(NUM_ROWS):
		for col in range(NUM_COLS):
			var sprite = Sprite2D.new()
			falling_pieces_container.add_child(sprite)

			var piece_pool = white_pieces if (row + col) % 2 == 0 else black_pieces
			var piece_name = piece_pool[randi() % piece_pool.size()]

			if piece_textures.has(piece_name):
				sprite.texture = piece_textures[piece_name]

			sprite.scale = Vector2(8.0, 8.0)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

			var x_pos = 100 + col * col_spacing + randf_range(-30, 30)
			x_pos = clamp(x_pos, 100, screen_size.x - 100)
			var y_base = -300 + row * row_spacing
			var y_pos = y_base + randf_range(-150, 150)

			sprite.position = Vector2(x_pos, y_pos)

			falling_pieces.append({
				"sprite": sprite,
				"column_x": 100 + col * col_spacing,
				"vy": randf_range(0.45, 0.55),
				"rotation_speed": randf_range(-0.3, 0.3),
				"piece_name": piece_name,
				"is_white": (row + col) % 2 == 0
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
		title.text = scramble_title(original_title, progress)

		if progress >= 1.0:
			title_glitch_active = false
			title.text = original_title

	# Update falling pieces
	var screen_size = get_viewport_rect().size
	for piece_data in falling_pieces:
		var sprite: Sprite2D = piece_data["sprite"]
		sprite.position.y += piece_data["vy"] * 60 * delta
		sprite.rotation += piece_data["rotation_speed"] * delta

		if sprite.position.y > screen_size.y + 150:
			sprite.position.x = piece_data["column_x"] + randf_range(-30, 30)
			sprite.position.y = randf_range(-400, -150)
			piece_data["vy"] = randf_range(0.45, 0.55)

			var piece_pool = white_pieces if piece_data["is_white"] else black_pieces
			var new_piece = piece_pool[randi() % piece_pool.size()]
			if piece_textures.has(new_piece):
				sprite.texture = piece_textures[new_piece]

func scramble_title(text: String, progress: float) -> String:
	if progress >= 1.0:
		return text

	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@$%&!?[]{}/<>"
	var result = ""

	for i in range(text.length()):
		var char = text[i]
		if char == " ":
			result += " "
		else:
			var char_progress = progress * 1.5 - (float(i) / text.length()) * 0.3

			if char_progress >= 1.0:
				result += char
			elif char_progress <= 0:
				result += chars[randi() % chars.length()]
			else:
				if randf() < char_progress * 0.8:
					result += char
				else:
					result += chars[randi() % chars.length()]

	return result

func update_selection(mode: String):
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

		# Update description panel
		mode_name_label.text = data["name"]
		mode_name_label.add_theme_color_override("font_color", data["color"])
		mode_subtitle_label.text = data["subtitle"]
		description_label.text = data["description"]
		features_label.text = data["features"]

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
