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

# ELO settings
var current_elo: int = 1000
const MIN_ELO = 600
const MAX_ELO = 2000

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

	update_display()

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
