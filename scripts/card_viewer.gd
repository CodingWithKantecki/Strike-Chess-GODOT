extends Control

# Card Viewer - Display powerup cards with navigation

@onready var card_display: TextureRect = $CardDisplay
@onready var card_name_label: Label = $CardName
@onready var card_counter_label: Label = $CardCounter
@onready var left_arrow: Polygon2D = $LeftArrow
@onready var right_arrow: Polygon2D = $RightArrow
@onready var hint_label: Label = $HintLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

# Card data
var cards: Array = [
	{"file": "smokecard.png", "name": "SMOKE GRENADE"},
	{"file": "decoycard.png", "name": "DECOY"},
	{"file": "reconcard.png", "name": "UAV RECON"},
	{"file": "sheildcard.png", "name": "ARMOR PLATES"},
	{"file": "jetcard.png", "name": "FIGHTER JET"},
	{"file": "flashcard.png", "name": "FLASHBANG"}
]

var current_index: int = 0
var card_textures: Array = []

# Animation
var arrow_pulse: float = 0.0

# Glitch effect
var glitch_active: bool = false
var glitch_timer: float = 0.0
var glitch_duration: float = 0.5
var target_name: String = ""

func _ready():
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)

	# Load all card textures
	for card in cards:
		var path = "res://assets/pieces/" + card["file"]
		var texture = load(path)
		card_textures.append(texture)

	# Display first card
	show_card(0)

func _process(delta):
	# Fade in
	if fade_overlay and fade_overlay.color.a > 0:
		fade_overlay.color.a = max(0, fade_overlay.color.a - delta * 3)

	# Arrow pulse animation
	arrow_pulse += delta * 3
	var pulse = 0.7 + sin(arrow_pulse) * 0.3
	if left_arrow:
		left_arrow.modulate.a = pulse
	if right_arrow:
		right_arrow.modulate.a = pulse

	# Glitch effect on card name
	if glitch_active:
		glitch_timer += delta
		var progress = min(glitch_timer / glitch_duration, 1.0)
		card_name_label.text = scramble_text(target_name, progress)

		if progress >= 1.0:
			glitch_active = false
			card_name_label.text = target_name

func show_card(index: int):
	"""Display the card at the given index."""
	current_index = index

	if index >= 0 and index < card_textures.size():
		var texture = card_textures[index]
		if texture and card_display:
			card_display.texture = texture

	# Update labels
	if card_counter_label:
		card_counter_label.text = str(index + 1) + " / " + str(cards.size())

	# Start glitch effect for name
	target_name = cards[index]["name"]
	glitch_active = true
	glitch_timer = 0.0

func next_card():
	"""Go to next card."""
	AudioManager.play_click_sound()
	var new_index = (current_index + 1) % cards.size()
	show_card(new_index)

func prev_card():
	"""Go to previous card."""
	AudioManager.play_click_sound()
	var new_index = (current_index - 1 + cards.size()) % cards.size()
	show_card(new_index)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_return_to_menu()
			KEY_LEFT, KEY_A:
				prev_card()
			KEY_RIGHT, KEY_D:
				next_card()

	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var screen_width = get_viewport_rect().size.x
		var click_x = event.position.x

		# Left third - previous
		if click_x < screen_width / 3:
			prev_card()
		# Right third - next
		elif click_x > screen_width * 2 / 3:
			next_card()
		# Middle - return to menu
		else:
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

func _return_to_menu():
	AudioManager.play_click_sound()
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
