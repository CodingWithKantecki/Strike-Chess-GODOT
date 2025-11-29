extends Control

# Press Continue Scene - Matches pygame PostIntroCutscene
# Black background with binary streams, military data, logo, and blinking text

@onready var logo: TextureRect = $Logo
@onready var press_label: Label = $PressLabel
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var effects_container: Control = $EffectsContainer

# Scene fade in
var scene_fade_duration: float = 1.0
var scene_fade_elapsed: float = 0.0

# Binary stream labels
var binary_labels: Array = []
var NUM_STREAMS = 8

# Military data labels
var military_labels: Array = []
var NUM_DATA = 5

# Blink timer for press label (smoother)
var blink_timer: float = 0.0

# Logo fade
var logo_fade_start: float = 0.0
var logo_fade_duration: float = 2.0
var logo_alpha: float = 0.0

# Ready to accept input
var can_continue: bool = false
var transitioning: bool = false

func _ready():
	# Start with black fade overlay - ensure it's fully black
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.modulate.a = 1.0

	# Start logo invisible
	logo.modulate.a = 0.0
	press_label.modulate.a = 0.0
	logo_fade_start = 0.0

	# Initialize effects using Label nodes
	initialize_binary_streams()
	initialize_military_data()

func initialize_binary_streams():
	var screen_size = get_viewport_rect().size
	var font = load("res://assets/fonts/editundo.ttf")

	for i in range(NUM_STREAMS):
		var label = Label.new()
		effects_container.add_child(label)

		# Generate binary text
		var binary_text = ""
		for j in range(randi_range(8, 16)):
			binary_text += str(randi() % 2)

		label.text = binary_text
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 32)

		var opacity = randf_range(0.08, 0.20)
		label.add_theme_color_override("font_color", Color(0, 0.8, 0, opacity))

		label.position = Vector2(
			randf_range(50, screen_size.x - 200),
			randf_range(-100, screen_size.y)
		)

		binary_labels.append({
			"label": label,
			"speed": randf_range(0.3, 0.8),
			"direction": 1 if randi() % 2 == 0 else -1,
			"opacity": opacity
		})

func initialize_military_data():
	var screen_size = get_viewport_rect().size
	var font = load("res://assets/fonts/editundo.ttf")

	for i in range(NUM_DATA):
		var label = Label.new()
		effects_container.add_child(label)

		label.text = _generate_military_text()
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 28)

		var opacity = randf_range(0.10, 0.25)
		label.add_theme_color_override("font_color", Color(0, 0.8, 0, opacity))

		label.position = Vector2(
			randf_range(50, screen_size.x - 250),
			randf_range(50, screen_size.y - 50)
		)

		military_labels.append({
			"label": label,
			"speed": randf_range(0.2, 0.5),
			"opacity": opacity
		})

func _process(delta):
	var screen_size = get_viewport_rect().size

	# Scene fade in from black (keep overlay on top)
	if scene_fade_elapsed < scene_fade_duration:
		scene_fade_elapsed += delta
		var progress = min(scene_fade_elapsed / scene_fade_duration, 1.0)
		fade_overlay.color.a = 1.0 - progress
	elif not transitioning:
		fade_overlay.color.a = 0.0

	# Update logo fade-in
	logo_fade_start += delta
	if logo_fade_start < logo_fade_duration:
		logo_alpha = logo_fade_start / logo_fade_duration
	else:
		logo_alpha = 1.0
		can_continue = true

	logo.modulate.a = logo_alpha

	# Update binary streams
	for stream_data in binary_labels:
		var label: Label = stream_data["label"]
		label.position.y += stream_data["speed"] * stream_data["direction"] * 60 * delta

		# Wrap around
		if stream_data["direction"] == 1 and label.position.y > screen_size.y + 50:
			label.position.y = -50
			label.position.x = randf_range(50, screen_size.x - 200)
			label.text = _generate_binary_string()
		elif stream_data["direction"] == -1 and label.position.y < -50:
			label.position.y = screen_size.y + 50
			label.position.x = randf_range(50, screen_size.x - 200)
			label.text = _generate_binary_string()
		# Randomly regenerate text occasionally (like pygame)
		if randi() % 60 == 0:
			label.text = _generate_binary_string()

	# Update military data (scroll up slowly)
	for data in military_labels:
		var label: Label = data["label"]
		label.position.y -= data["speed"] * 60 * delta
		if label.position.y < -30:
			label.position.y = screen_size.y + 30
			label.position.x = randf_range(50, screen_size.x - 250)
			label.text = _generate_military_text()
		# Randomly regenerate text occasionally (like pygame)
		if randi() % 100 == 0:
			label.text = _generate_military_text()

	# Smooth blink for press label using sine wave (not harsh on/off)
	if can_continue:
		blink_timer += delta * 3.0  # Slower blink
		var alpha = (sin(blink_timer) + 1.0) / 2.0  # Oscillates 0 to 1
		alpha = 0.3 + alpha * 0.7  # Range from 0.3 to 1.0 (never fully invisible)
		press_label.modulate.a = alpha

func _generate_binary_string() -> String:
	var result = ""
	for i in range(randi_range(8, 16)):
		result += str(randi() % 2)
	return result

func _generate_military_text() -> String:
	var templates = [
		"LAT: %.4fN", "LON: %.4fW", "ALT: %dm", "SPD: %dkts", "HDG: %d deg",
		"TACTICAL: ENGAGED", "MISSION: CHECKMATE", "STATUS: ACTIVE", "TARGET: ACQUIRED", "ETA: %ds"
	]
	var template = templates[randi() % templates.size()]
	if template.contains("%.4f"):
		return template % randf_range(0, 90)
	elif template.contains("%d"):
		return template % randi_range(100, 9999)
	return template

func _input(event):
	if not can_continue or transitioning:
		return

	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			transitioning = true
			AudioManager.play_click_sound()
			# Fade out before transitioning
			var tween = create_tween()
			tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
			tween.tween_callback(_go_to_main_menu)

func _go_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
