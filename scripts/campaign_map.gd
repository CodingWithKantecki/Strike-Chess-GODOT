extends Control

# Campaign Map - Military tactical map with tank navigation
# Exact replica of pygame campaign_map.py

@onready var map_container: Node2D = $MapContainer
@onready var tank_sprite: Node2D = $TankContainer/Tank
@onready var tank_hull: Sprite2D = $TankContainer/Tank/Hull
@onready var tank_turret: Sprite2D = $TankContainer/Tank/Turret
@onready var mission_nodes_container: Node2D = $MapContainer/MissionNodes
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var left_panel: Panel = $LeftPanel
@onready var right_panel: Panel = $RightPanel

# Intel panel labels
@onready var zone_title_label: Label = $LeftPanel/VBox/ZoneTitle
@onready var zone_subtitle_label: Label = $LeftPanel/VBox/ZoneSubtitle
@onready var enemies_label: Label = $LeftPanel/VBox/Enemies
@onready var special_label: Label = $LeftPanel/VBox/Special
@onready var boss_label: Label = $LeftPanel/VBox/Boss
@onready var description_label: Label = $LeftPanel/VBox/Description

# Minimap elements
@onready var minimap_rect: TextureRect = $RightPanel/VBox/Minimap
@onready var minimap_tank: ColorRect = $RightPanel/VBox/Minimap/TankIndicator

# Scene fade
var scene_fade_duration: float = 0.5
var scene_fade_elapsed: float = 0.0

# Map dimensions - matching pygame
var border_width: int = 220  # Match panel width (both panels equal)
var map_width: int = 1005
var map_height: int = 4700
var map_offset_x: int = 220

# Scrolling
var scroll_y: float = 0.0
var target_scroll_y: float = 0.0
var max_scroll: float = 0.0

# Tank navigation - matching pygame exactly
var tank_x: float = 0.0
var tank_y: float = 0.0
var tank_angle: float = 0.0  # Hull rotation in degrees
var turret_angle: float = 0.0
var tank_speed: float = 3.0
var tank_current_speed: float = 0.0
var tank_acceleration: float = 0.08
var tank_deceleration: float = 0.15
var turret_rotation_speed: float = 3.5

# Tank physics - velocity separate from facing direction
var tank_velocity_x: float = 0.0
var tank_velocity_y: float = 0.0
var drift_factor: float = 0.012

var tank_size: int = 48  # Smaller tank size
var tank_interaction_radius: float = 300.0

# Mission nodes
var mission_nodes: Array = []
var selected_node: int = -1
var current_zone: int = 0

# Zone boundaries
var zone_boundaries: Array = []

# Map images
var map_textures: Array = []

# Mission path points for dotted line
var mission_path: Array = []

# Animation timer for dotted path
var animation_timer: float = 0.0

# Walkable path boundary from recorded path
var walkable_path: Array = []
var path_check_radius: float = 60.0  # How close tank must be to path points (larger for tolerance)

# Chapter data
var chapter_data: Array = [
	{"name": "Pawn's Front", "difficulty": 1},
	{"name": "Bishop's Walk", "difficulty": 2},
	{"name": "Gambit Gorge", "difficulty": 3},
	{"name": "Rookspire", "difficulty": 4},
	{"name": "Knight's Frost", "difficulty": 5},
	{"name": "King's Hold", "difficulty": 6},
	{"name": "Isle of Check", "difficulty": 7},
	{"name": "Ironworks", "difficulty": 8},
	{"name": "Knightlight City", "difficulty": 9}
]

# Zone notification
var zone_notification_active: bool = false
var zone_notification_text: String = ""
var zone_notification_progress: float = 0.0
var last_notified_zone: int = -1

# Intel panel glitch effect
var intel_glitch_active: bool = false
var intel_glitch_timer: float = 0.0
var intel_glitch_duration: float = 0.8
var intel_target_texts: Dictionary = {}  # Final text values to scramble to

# Pixel font
var pixel_font: Font

func _ready():
	pixel_font = load("res://assets/fonts/editundo.ttf")

	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)

	var viewport_size = get_viewport_rect().size
	var panel_width = 220  # Both panels are equal width
	# Extend map slightly under panels to prevent any gaps
	map_width = int(viewport_size.x) - (panel_width * 2) + 10
	map_offset_x = panel_width - 5

	load_map_images()
	load_walkable_path()
	setup_missions()
	create_mission_path()
	init_tank_position()
	update_intel_panel(0)

	# Scale tank sprites smaller
	if tank_hull:
		tank_hull.scale = Vector2(1.875, 1.875)
	if tank_turret:
		tank_turret.scale = Vector2(1.875, 1.875)

func load_map_images():
	var image_names = [
		"res://assets/pieces/new_1map.png",
		"res://assets/pieces/new_2map.png",
		"res://assets/pieces/new_3map.png",
		"res://assets/pieces/new_4map.png",
		"res://assets/pieces/new_5map.png",
		"res://assets/pieces/new_6map.png",
		"res://assets/pieces/new_7map.png",
		"res://assets/pieces/new_8map.png",
		"res://assets/pieces/new_9map.png"
	]

	var total_height: float = 0.0
	zone_boundaries = []

	for i in range(image_names.size()):
		var texture = load(image_names[i])
		if texture:
			map_textures.append(texture)
			var scale_factor = float(map_width) / texture.get_width()
			var scaled_height = texture.get_height() * scale_factor
			total_height += scaled_height
			if i < image_names.size() - 1:
				zone_boundaries.append({"y": total_height, "zone_above": i + 1, "zone_below": i + 2})

	map_height = int(total_height)
	max_scroll = max(0, map_height - get_viewport_rect().size.y)
	create_map_sprites()

func load_walkable_path():
	"""Load the recorded walkable path from JSON file."""
	var file = FileAccess.open("res://assets/campaign_path_recording.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			var data = json.get_data()
			# The JSON has structure {"path": [[x,y], ...]}
			if data is Dictionary and data.has("path"):
				walkable_path = data["path"]
				print("Loaded walkable path with ", walkable_path.size(), " points")
			elif data is Array:
				walkable_path = data
				print("Loaded walkable path with ", walkable_path.size(), " points")
		else:
			print("Failed to parse path JSON: ", json.get_error_message())
	else:
		print("Could not load campaign_path_recording.json")

func is_position_walkable(x: float, y: float) -> bool:
	"""Check if a position is near the recorded walkable path."""
	if walkable_path.size() == 0:
		return true  # No path loaded, allow movement everywhere

	# Check every Nth point for performance (path has ~3500 points)
	var check_interval = 5
	for i in range(0, walkable_path.size(), check_interval):
		var point = walkable_path[i]
		var px = point[0]
		var py = point[1]
		var dist = sqrt(pow(x - px, 2) + pow(y - py, 2))
		if dist < path_check_radius:
			return true

	return false

func create_map_sprites():
	if not map_container:
		return

	var current_y: float = 0.0
	for i in range(map_textures.size()):
		var sprite = Sprite2D.new()
		sprite.texture = map_textures[i]
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var scale_factor = float(map_width) / map_textures[i].get_width()
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position = Vector2(0, current_y)
		map_container.add_child(sprite)
		current_y += map_textures[i].get_height() * scale_factor

func setup_missions():
	mission_nodes.clear()
	var zone_height = map_height / 9.0
	var map_center_x = map_width / 2.0
	var x_offsets = [0, -80, 80, -60, 60, 0, -70, 70, 0]

	for i in range(9):
		var node = {
			"index": i,
			"name": chapter_data[i]["name"],
			"x": map_center_x + x_offsets[i],
			"y": zone_height * (i + 0.5),
			"difficulty": chapter_data[i]["difficulty"],
			"unlocked": StoryMode.unlocked_chapters[i] if i < StoryMode.unlocked_chapters.size() else false,
			"completed": is_chapter_completed(i),
			"hover": false,
			"pulse": 0.0,
			"scale": 1.0
		}
		mission_nodes.append(node)

func is_chapter_completed(chapter_index: int) -> bool:
	var chapter_id = "chapter_" + str(chapter_index + 1)
	for battle in StoryMode.completed_battles:
		if battle.begins_with(chapter_id):
			return true
	return false

func create_mission_path():
	"""Create smooth curved paths between missions like pygame."""
	mission_path.clear()

	for i in range(mission_nodes.size() - 1):
		var start = mission_nodes[i]
		var end_node = mission_nodes[i + 1]

		# Create bezier curve segments
		var segments = 40
		var control1_x = start["x"] + randf_range(-100, 100)
		var control1_y = start["y"] - (start["y"] - end_node["y"]) * 0.3
		var control2_x = end_node["x"] + randf_range(-100, 100)
		var control2_y = end_node["y"] + (start["y"] - end_node["y"]) * 0.3

		for j in range(segments):
			var t = float(j) / segments
			var t2 = t * t
			var t3 = t2 * t

			# Cubic bezier formula
			var x = pow(1-t, 3) * start["x"] + 3*pow(1-t, 2)*t * control1_x + 3*(1-t)*t2 * control2_x + t3 * end_node["x"]
			var y = pow(1-t, 3) * start["y"] + 3*pow(1-t, 2)*t * control1_y + 3*(1-t)*t2 * control2_y + t3 * end_node["y"]

			mission_path.append({
				"x": x,
				"y": y,
				"segment": i,
				"progress": t
			})

func init_tank_position():
	if mission_nodes.size() > 0:
		var spawn_node = mission_nodes[0]
		var offset_distance = 200  # Start 200 pixels above first node

		if mission_nodes.size() > 1:
			var next_node = mission_nodes[1]
			var dx = spawn_node["x"] - next_node["x"]
			var dy = spawn_node["y"] - next_node["y"]
			var dist = sqrt(dx*dx + dy*dy)
			if dist > 0:
				dx /= dist
				dy /= dist
				tank_x = spawn_node["x"] + dx * offset_distance
				tank_y = spawn_node["y"] + dy * offset_distance
				tank_angle = rad_to_deg(atan2(spawn_node["y"] - tank_y, spawn_node["x"] - tank_x))
				turret_angle = tank_angle
			else:
				tank_x = spawn_node["x"]
				tank_y = spawn_node["y"] - offset_distance
				tank_angle = 90
				turret_angle = tank_angle
		else:
			tank_x = spawn_node["x"]
			tank_y = spawn_node["y"] - offset_distance
			tank_angle = 90
			turret_angle = tank_angle

func _process(delta):
	animation_timer += delta * 1000  # Convert to milliseconds

	# Scene fade in
	if scene_fade_elapsed < scene_fade_duration:
		scene_fade_elapsed += delta
		var progress = min(scene_fade_elapsed / scene_fade_duration, 1.0)
		if fade_overlay:
			fade_overlay.color.a = 1.0 - progress

	handle_tank_input(delta)
	update_camera()

	if map_container:
		map_container.position.y = -scroll_y
		map_container.position.x = map_offset_x

	update_tank_visual()
	check_zone_change()
	update_node_proximity()
	update_minimap()
	update_intel_glitch(delta)
	queue_redraw()

func handle_tank_input(delta):
	"""Handle WASD as screen-direction controls like pygame."""
	var move_up = Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W)
	var move_down = Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S)
	var move_left = Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var move_right = Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)

	var move_x: float = 0.0
	var move_y: float = 0.0

	if move_right:
		move_x += 1
	if move_left:
		move_x -= 1
	if move_down:
		move_y += 1
	if move_up:
		move_y -= 1

	if move_x != 0 or move_y != 0:
		# Accelerate
		tank_current_speed = min(tank_speed, tank_current_speed + tank_acceleration)

		# Normalize diagonal movement
		var length = sqrt(move_x * move_x + move_y * move_y)
		if length > 0:
			move_x = move_x / length
			move_y = move_y / length

		# Calculate desired velocity
		var desired_vel_x = move_x * tank_current_speed
		var desired_vel_y = move_y * tank_current_speed

		# Normal mode: velocity matches desired direction
		tank_velocity_x = desired_vel_x
		tank_velocity_y = desired_vel_y

		# Update position
		var new_x = tank_x + tank_velocity_x * 60 * delta
		var new_y = tank_y + tank_velocity_y * 60 * delta

		# Clamp to map bounds
		new_x = clamp(new_x, 50, map_width - 50)
		new_y = clamp(new_y, 50, map_height - 50)

		# Check if new position is on walkable path
		if is_position_walkable(new_x, new_y):
			tank_x = new_x
			tank_y = new_y
		else:
			# Try sliding along X or Y axis only
			if is_position_walkable(new_x, tank_y):
				tank_x = new_x
			elif is_position_walkable(tank_x, new_y):
				tank_y = new_y
			# Otherwise don't move - blocked by boundary

		# Update hull angle to face movement direction
		# Tank sprite faces UP at 0 degrees rotation in Godot
		# atan2 returns: up=-90, right=0, down=90, left=180
		# We want: up=0, right=90, down=180, left=270
		# So we ADD 90 to convert
		var target_angle = rad_to_deg(atan2(move_y, move_x)) + 90

		# Smooth rotation toward target
		var angle_diff = target_angle - tank_angle
		while angle_diff > 180:
			angle_diff -= 360
		while angle_diff < -180:
			angle_diff += 360

		var rotation_speed = 8.0
		if abs(angle_diff) < rotation_speed:
			tank_angle = target_angle
		else:
			if angle_diff > 0:
				tank_angle += rotation_speed
			else:
				tank_angle -= rotation_speed

		tank_angle = fmod(tank_angle + 360, 360)
	else:
		# Decelerate
		tank_current_speed = max(0, tank_current_speed - tank_deceleration)
		tank_velocity_x *= 0.85
		tank_velocity_y *= 0.85

		# Continue moving with remaining velocity
		if abs(tank_velocity_x) > 0.1 or abs(tank_velocity_y) > 0.1:
			var new_x = tank_x + tank_velocity_x * 60 * delta
			var new_y = tank_y + tank_velocity_y * 60 * delta
			new_x = clamp(new_x, 50, map_width - 50)
			new_y = clamp(new_y, 50, map_height - 50)
			if is_position_walkable(new_x, new_y):
				tank_x = new_x
				tank_y = new_y

	# Turret follows hull with lag
	var turret_diff = tank_angle - turret_angle
	while turret_diff > 180:
		turret_diff -= 360
	while turret_diff < -180:
		turret_diff += 360
	turret_angle += sign(turret_diff) * min(abs(turret_diff), turret_rotation_speed)

	# Space/Enter - Interact
	if Input.is_action_just_pressed("ui_accept"):
		interact_with_node()

	# Escape - Back
	if Input.is_action_just_pressed("ui_cancel"):
		go_back()

func update_camera():
	var screen_height = get_viewport_rect().size.y
	var target_y = tank_y - screen_height / 2.0
	target_scroll_y = clamp(target_y, 0, max_scroll)
	scroll_y = lerp(scroll_y, target_scroll_y, 0.1)

func update_tank_visual():
	if tank_sprite:
		var screen_pos_x = map_offset_x + tank_x
		var screen_pos_y = tank_y - scroll_y
		tank_sprite.position = Vector2(screen_pos_x, screen_pos_y)

	if tank_hull:
		tank_hull.rotation = deg_to_rad(tank_angle)

	if tank_turret:
		tank_turret.rotation = deg_to_rad(turret_angle)

func check_zone_change():
	var new_zone = get_current_zone()
	if new_zone != current_zone:
		current_zone = new_zone
		update_intel_panel(current_zone)
		if new_zone != last_notified_zone:
			show_zone_notification(new_zone)
			last_notified_zone = new_zone

func get_current_zone() -> int:
	for i in range(zone_boundaries.size()):
		if tank_y < zone_boundaries[i]["y"]:
			return i
	return zone_boundaries.size()

func show_zone_notification(zone_index: int):
	if zone_index >= 0 and zone_index < chapter_data.size():
		zone_notification_active = true
		zone_notification_text = "ENTERING: " + chapter_data[zone_index]["name"].to_upper()
		zone_notification_progress = 0.0

func update_intel_panel(zone_index: int):
	if zone_index < 0 or zone_index >= 9:
		return

	var intel = StoryMode.get_enemy_intel_for_chapter(zone_index)
	var chapter = chapter_data[zone_index]

	# Store target texts and start glitch effect
	intel_target_texts = {
		"title": "CHAPTER " + str(zone_index + 1),
		"subtitle": chapter["name"].to_upper(),
		"enemies": "ENEMIES: " + intel.get("enemies", "Unknown"),
		"special": "SPECIAL: " + intel.get("special", "None"),
		"boss": "BOSS: " + intel.get("boss", "Unknown"),
		"description": intel.get("description", "")
	}

	# Start glitch effect
	intel_glitch_active = true
	intel_glitch_timer = 0.0

func update_intel_glitch(delta: float):
	"""Update digital glitch effect on intel panel text."""
	if not intel_glitch_active:
		return

	intel_glitch_timer += delta
	var progress = min(intel_glitch_timer / intel_glitch_duration, 1.0)

	# Update each label with scrambled text
	if zone_title_label and intel_target_texts.has("title"):
		zone_title_label.text = scramble_text(intel_target_texts["title"], progress)
	if zone_subtitle_label and intel_target_texts.has("subtitle"):
		zone_subtitle_label.text = scramble_text(intel_target_texts["subtitle"], progress)
	if enemies_label and intel_target_texts.has("enemies"):
		enemies_label.text = scramble_text(intel_target_texts["enemies"], progress)
	if special_label and intel_target_texts.has("special"):
		special_label.text = scramble_text(intel_target_texts["special"], progress)
	if boss_label and intel_target_texts.has("boss"):
		boss_label.text = scramble_text(intel_target_texts["boss"], progress)
	if description_label and intel_target_texts.has("description"):
		description_label.text = scramble_text(intel_target_texts["description"], progress)

	# End glitch when complete
	if progress >= 1.0:
		intel_glitch_active = false

func scramble_text(text: String, progress: float) -> String:
	"""Scramble text with digital glitch effect - characters resolve over time."""
	if progress >= 1.0:
		return text

	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@$%&!?[]{}/<>_-+=*"
	var result = ""

	for i in range(text.length()):
		var char = text[i]
		if char == " " or char == ":" or char == ".":
			result += char
		else:
			# Each character resolves based on its position
			var char_progress = progress * 1.5 - (float(i) / max(text.length(), 1)) * 0.4

			if char_progress >= 1.0:
				result += char
			elif char_progress <= 0:
				result += chars[randi() % chars.length()]
			else:
				# Random chance to show correct character
				if randf() < char_progress * 0.85:
					result += char
				else:
					result += chars[randi() % chars.length()]

	return result

func update_node_proximity():
	selected_node = -1
	for i in range(mission_nodes.size()):
		var node = mission_nodes[i]
		var dist = sqrt(pow(tank_x - node["x"], 2) + pow(tank_y - node["y"], 2))
		if dist < tank_interaction_radius:
			if node["unlocked"]:
				selected_node = i
				node["hover"] = true
			break
		else:
			node["hover"] = false

func interact_with_node():
	if selected_node >= 0 and selected_node < mission_nodes.size():
		var node = mission_nodes[selected_node]
		if node["unlocked"]:
			start_mission(selected_node)

func start_mission(chapter_index: int):
	AudioManager.play_click_sound()
	StoryMode.select_chapter(chapter_index)
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/game.tscn"))

func go_back():
	AudioManager.play_click_sound()
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/mode_select.tscn"))

func update_minimap():
	if minimap_tank and minimap_rect:
		var minimap_size = minimap_rect.size
		var tank_percent_x = tank_x / map_width
		var tank_percent_y = tank_y / map_height
		minimap_tank.position = Vector2(
			tank_percent_x * minimap_size.x - minimap_tank.size.x / 2,
			tank_percent_y * minimap_size.y - minimap_tank.size.y / 2
		)

func _draw():
	# Draw zone notification (on top of everything via CanvasItem)
	if zone_notification_active:
		zone_notification_progress += 0.02
		if zone_notification_progress > 3.0:
			zone_notification_active = false
		else:
			var bar_height = 60
			var bar_y = 100
			var alpha = 1.0 if zone_notification_progress < 2.5 else (3.0 - zone_notification_progress) * 2
			draw_rect(Rect2(0, bar_y, get_viewport_rect().size.x, bar_height), Color(0, 0, 0, 0.8 * alpha))
			if pixel_font:
				var text_pos = Vector2(get_viewport_rect().size.x / 2 - 150, bar_y + 35)
				draw_string(pixel_font, text_pos, zone_notification_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1, 0.84, 0, alpha))

	# Draw deploy prompt
	if selected_node >= 0:
		draw_deploy_prompt()

# NOTE: Mission paths, nodes, and walkable boundary are drawn by DrawOverlay (campaign_draw_overlay.gd)

func draw_deploy_prompt():
	if selected_node < 0:
		return

	var node = mission_nodes[selected_node]
	var screen_x = map_offset_x + node["x"]
	var screen_y = node["y"] - scroll_y

	if screen_y < -100 or screen_y > get_viewport_rect().size.y + 100:
		return

	# Background box
	var prompt_y = screen_y - 100
	draw_rect(Rect2(screen_x - 130, prompt_y - 25, 260, 55), Color(0, 0, 0, 0.9))
	draw_rect(Rect2(screen_x - 128, prompt_y - 23, 256, 51), Color(0.3, 0.3, 0.35, 1), false, 2.0)

	if pixel_font:
		# Mission name
		draw_string(pixel_font, Vector2(screen_x - 100, prompt_y - 5), node["name"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 1))
		# Deploy prompt
		draw_string(pixel_font, Vector2(screen_x - 100, prompt_y + 15), "PRESS ENTER TO DEPLOY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.84, 0, 1))
