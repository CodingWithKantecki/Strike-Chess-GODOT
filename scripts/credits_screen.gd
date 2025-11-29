extends Control

# Credits Screen - Full credits display with cool animations

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var credits_container: VBoxContainer = $CreditsContainer

var scroll_speed: float = 40.0
var credits_data: Array = [
	{"type": "header", "text": "STRIKE CHESS"},
	{"type": "subtitle", "text": "Tactical Chess Combat"},
	{"type": "spacer"},
	{"type": "section", "text": "CREATED BY"},
	{"type": "name", "text": "CodingWithKantecki"},
	{"type": "spacer"},
	{"type": "section", "text": "PROGRAMMING"},
	{"type": "name", "text": "CodingWithKantecki"},
	{"type": "spacer"},
	{"type": "section", "text": "GAME DESIGN"},
	{"type": "name", "text": "CodingWithKantecki"},
	{"type": "spacer"},
	{"type": "section", "text": "ART & ASSETS"},
	{"type": "name", "text": "Pixel Art Chess Pieces"},
	{"type": "name", "text": "EditUndo Font"},
	{"type": "spacer"},
	{"type": "section", "text": "SOUND DESIGN"},
	{"type": "name", "text": "Sound Effects & Music"},
	{"type": "spacer"},
	{"type": "section", "text": "SPECIAL THANKS"},
	{"type": "name", "text": "Godot Engine Team"},
	{"type": "name", "text": "The Chess Community"},
	{"type": "name", "text": "All Players & Supporters"},
	{"type": "spacer"},
	{"type": "spacer"},
	{"type": "section", "text": "POWERED BY"},
	{"type": "name", "text": "Godot Engine 4"},
	{"type": "spacer"},
	{"type": "spacer"},
	{"type": "footer", "text": "Thank you for playing!"},
]

var pixel_font: Font
var scroll_offset: float = 0.0
var total_height: float = 0.0
var fade_in_complete: bool = false

# Glitch effect
var glitch_active: bool = true
var glitch_timer: float = 0.0
var glitch_duration: float = 1.0

func _ready():
	pixel_font = load("res://assets/fonts/editundo.ttf")

	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)

	build_credits()

	# Position credits below screen
	var screen_height = get_viewport_rect().size.y
	scroll_offset = screen_height + 50

func build_credits():
	"""Build credit labels dynamically."""
	for credit in credits_data:
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", pixel_font)

		match credit["type"]:
			"header":
				label.text = credit["text"]
				label.add_theme_font_size_override("font_size", 64)
				label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))  # Gold
			"subtitle":
				label.text = credit["text"]
				label.add_theme_font_size_override("font_size", 28)
				label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
			"section":
				label.text = credit["text"]
				label.add_theme_font_size_override("font_size", 24)
				label.add_theme_color_override("font_color", Color(0.4, 0.8, 1, 1))  # Cyan
			"name":
				label.text = credit["text"]
				label.add_theme_font_size_override("font_size", 32)
				label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			"footer":
				label.text = credit["text"]
				label.add_theme_font_size_override("font_size", 36)
				label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
			"spacer":
				label.text = " "
				label.add_theme_font_size_override("font_size", 40)

		credits_container.add_child(label)

func _process(delta):
	# Fade in
	if not fade_in_complete:
		if fade_overlay:
			fade_overlay.color.a = max(0, fade_overlay.color.a - delta * 2)
			if fade_overlay.color.a <= 0:
				fade_in_complete = true

	# Glitch effect on header
	if glitch_active:
		glitch_timer += delta
		var progress = min(glitch_timer / glitch_duration, 1.0)

		if credits_container.get_child_count() > 0:
			var header = credits_container.get_child(0)
			header.text = scramble_text("STRIKE CHESS", progress)

		if progress >= 1.0:
			glitch_active = false
			if credits_container.get_child_count() > 0:
				credits_container.get_child(0).text = "STRIKE CHESS"

	# Scroll credits upward
	scroll_offset -= scroll_speed * delta
	credits_container.position.y = scroll_offset

	# Check if credits are done (scrolled past top)
	var container_height = credits_container.size.y
	if scroll_offset < -container_height - 100:
		_return_to_menu()

func scramble_text(text: String, progress: float) -> String:
	if progress >= 1.0:
		return text

	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@$%&!?"
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

func _input(event):
	# Skip credits on any key/click
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_return_to_menu()
	elif event is InputEventMouseButton and event.pressed:
		# Speed up scrolling on click
		scroll_speed = 200.0

func _return_to_menu():
	AudioManager.play_click_sound()
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
