extends Node2D

# This overlay draws mission paths, nodes, and boundary on top of the map
# It gets data from the parent CampaignMap script

var campaign_map: Control
var sign_texture: Texture2D
var sign_sprites: Array = []

var zone_names = [
	"Pawn's Front",
	"Bishop's Walk",
	"Gambit Gorge",
	"Rookspire",
	"Knight's Frost",
	"King's Hold",
	"Isle of Check",
	"Ironworks",
	"Knightlight City"
]

func _ready():
	campaign_map = get_parent()

	# Load sign texture
	sign_texture = load("res://assets/pieces/sign.png")

	# Create sign sprites at zone boundaries
	create_zone_signs()

func _process(_delta):
	queue_redraw()

	# Update sign positions based on scroll
	if campaign_map:
		for sign_data in sign_sprites:
			var sprite: Sprite2D = sign_data["sprite"]
			sprite.position.y = sign_data["map_y"] - campaign_map.scroll_y

func _draw():
	if not campaign_map:
		return

	# Draw walkable path boundary (blue pixelated dots)
	draw_walkable_boundary()

	# Draw mission nodes (circles with chapter numbers)
	draw_mission_nodes()

	# Draw zone sign text
	draw_zone_signs()

func draw_walkable_boundary():
	"""Draw the walkable path as chunky pixelated blue squares."""
	if campaign_map.walkable_path.size() < 2:
		return

	var screen_height = get_viewport_rect().size.y
	var dot_color = Color(0, 0.5, 0.9, 0.85)  # Blue pixels
	var dot_color_dark = Color(0, 0.3, 0.6, 0.7)  # Darker blue for depth

	# Larger pixel size for 8-bit look
	var pixel_size = 6

	# Draw every Nth point for chunky pixel effect
	var draw_interval = 12
	for i in range(0, campaign_map.walkable_path.size(), draw_interval):
		var point = campaign_map.walkable_path[i]
		var screen_y = point[1] - campaign_map.scroll_y

		# Skip if off screen
		if screen_y < -50 or screen_y > screen_height + 50:
			continue

		var screen_x = point[0] + campaign_map.map_offset_x

		# Snap to pixel grid for true 8-bit look
		screen_x = floor(screen_x / pixel_size) * pixel_size
		screen_y = floor(screen_y / pixel_size) * pixel_size

		# Draw shadow pixel (offset)
		draw_rect(Rect2(screen_x + 2, screen_y + 2, pixel_size, pixel_size), Color(0, 0, 0, 0.4))

		# Draw dark border pixel
		draw_rect(Rect2(screen_x - 1, screen_y - 1, pixel_size + 2, pixel_size + 2), dot_color_dark)

		# Draw main blue pixel square
		draw_rect(Rect2(screen_x, screen_y, pixel_size, pixel_size), dot_color)

func draw_mission_paths():
	"""Draw 8-bit style dotted paths between mission nodes."""
	var dot_size = 4  # Size of each dot

	for i in range(campaign_map.mission_path.size() - 1):
		var point = campaign_map.mission_path[i]

		var screen_y = point["y"] - campaign_map.scroll_y

		# Skip if off screen
		var screen_height = get_viewport_rect().size.y
		if screen_y < -50 or screen_y > screen_height + 50:
			continue

		# Only draw every 6th point for dotted effect, animated
		var anim_offset = int(campaign_map.animation_timer * 0.015) % 6
		if (i + anim_offset) % 6 != 0:
			continue

		var segment = point["segment"]
		if segment >= campaign_map.mission_nodes.size() - 1:
			continue

		var color: Color
		if campaign_map.mission_nodes[segment]["completed"]:
			color = Color(0.3, 0.7, 0.3, 1)  # Green
		elif campaign_map.mission_nodes[segment]["unlocked"]:
			var pulse = abs(sin(campaign_map.animation_timer * 0.003))
			color = Color(0.9, 0.75 + pulse * 0.15, 0.1, 1)  # Yellow pulse
		else:
			color = Color(0.4, 0.4, 0.4, 1)  # Gray

		var screen_x = point["x"] + campaign_map.map_offset_x

		# Draw small square dot (8-bit style)
		draw_rect(Rect2(screen_x - dot_size/2, screen_y - dot_size/2, dot_size, dot_size), color)

func draw_mission_nodes():
	"""Draw 8-bit style mission nodes."""
	for i in range(campaign_map.mission_nodes.size()):
		var node = campaign_map.mission_nodes[i]
		var tank_dist = sqrt(pow(campaign_map.tank_x - node["x"], 2) + pow(campaign_map.tank_y - node["y"], 2))
		var tank_near_node = tank_dist < campaign_map.tank_interaction_radius

		var x = node["x"] + campaign_map.map_offset_x
		var y = node["y"] - campaign_map.scroll_y

		# Skip if off screen
		var screen_height = get_viewport_rect().size.y
		if y < -100 or y > screen_height + 100:
			continue

		# Smaller 8-bit style size
		var base_size = 24
		var size = base_size
		if tank_near_node and node["unlocked"]:
			size = base_size + 8  # Slight grow when near

		# Colors based on status
		var outer_color: Color
		var inner_color: Color
		var text_color: Color

		if node["completed"]:
			outer_color = Color(0.2, 0.5, 0.2, 1)
			inner_color = Color(0.3, 0.7, 0.3, 1)
			text_color = Color(1, 1, 1, 1)
		elif node["unlocked"]:
			outer_color = Color(0.7, 0.6, 0.1, 1)
			inner_color = Color(0.9, 0.8, 0.2, 1)
			text_color = Color(0, 0, 0, 1)
		else:
			outer_color = Color(0.25, 0.25, 0.25, 1)
			inner_color = Color(0.35, 0.35, 0.35, 1)
			text_color = Color(0.5, 0.5, 0.5, 1)

		# 8-bit style: Draw as rounded rectangle/square
		var half = size / 2

		# Shadow
		draw_rect(Rect2(x - half + 2, y - half + 2, size, size), Color(0, 0, 0, 0.4))

		# Outer border
		draw_rect(Rect2(x - half - 2, y - half - 2, size + 4, size + 4), outer_color)

		# Inner fill
		draw_rect(Rect2(x - half, y - half, size, size), inner_color)

		# Draw chapter number
		if campaign_map.pixel_font:
			var chapter_text = str(node["index"] + 1)
			draw_string(campaign_map.pixel_font, Vector2(x - 6, y + 6), chapter_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, text_color)

		# Draw lock icon if locked (simple X)
		if not node["unlocked"]:
			draw_line(Vector2(x - 6, y - 6), Vector2(x + 6, y + 6), Color(0.1, 0.1, 0.1, 1), 3)
			draw_line(Vector2(x + 6, y - 6), Vector2(x - 6, y + 6), Color(0.1, 0.1, 0.1, 1), 3)

		# Selection indicator when near
		if tank_near_node and node["unlocked"]:
			# Pulsing border
			var pulse = abs(sin(campaign_map.animation_timer * 0.003))
			var highlight_color = Color(1, 1, 1, 0.5 + pulse * 0.5)
			draw_rect(Rect2(x - half - 5, y - half - 5, size + 10, size + 10), highlight_color, false, 2)

func create_zone_signs():
	"""Create sign sprites for each zone."""
	if not sign_texture or not campaign_map:
		return

	# Wait for campaign_map to be ready
	await get_tree().process_frame

	var zone_height = campaign_map.map_height / 9.0

	for i in range(9):
		var sprite = Sprite2D.new()
		sprite.texture = sign_texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(0.12, 0.12)  # Much smaller scale
		sprite.centered = true

		# Position at start of each zone, offset to side of path
		var sign_x = campaign_map.map_width / 2.0 - 150  # Offset to left of center
		var sign_y = zone_height * i + 200  # Offset from zone start

		sprite.position = Vector2(sign_x + campaign_map.map_offset_x, sign_y)
		add_child(sprite)
		sign_sprites.append({"sprite": sprite, "map_y": sign_y, "zone": i})

func draw_zone_signs():
	"""Draw zone name text next to signs."""
	if not campaign_map.pixel_font:
		return

	var screen_height = get_viewport_rect().size.y

	for sign_data in sign_sprites:
		var screen_y = sign_data["map_y"] - campaign_map.scroll_y
		var zone_index = sign_data["zone"]

		# Skip if off screen
		if screen_y < -100 or screen_y > screen_height + 100:
			continue

		# Position text next to the sign (to the right)
		var sign_x = campaign_map.map_width / 2.0 - 150 + campaign_map.map_offset_x

		# Draw text box background
		draw_rect(Rect2(sign_x + 30, screen_y - 20, 120, 40), Color(0, 0, 0, 0.7))

		# "Welcome to" text
		draw_string(campaign_map.pixel_font, Vector2(sign_x + 35, screen_y - 5), "Welcome to", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.8, 0.8, 1))
		# Zone name
		draw_string(campaign_map.pixel_font, Vector2(sign_x + 35, screen_y + 12), zone_names[zone_index], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.84, 0, 1))
