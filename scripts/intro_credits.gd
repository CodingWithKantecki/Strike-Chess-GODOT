extends Control

# Intro Credits Scene - Shows "CodingWithKantecki" for 3.1 seconds
# Matches pygame IntroScreen class with proper fade timing

@onready var credits_label: Label = $CreditsLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

# Timing (matches pygame: 800ms fade in, 1500ms display, 800ms fade out = 3100ms)
var fade_in_duration: float = 0.8
var display_duration: float = 1.5
var fade_out_duration: float = 0.8
var total_duration: float = 3.1

var elapsed: float = 0.0
var transitioning: bool = false

func _ready():
	# Start with black overlay covering everything
	fade_overlay.color = Color(0, 0, 0, 1)
	credits_label.modulate.a = 0.0

func _process(delta):
	if transitioning:
		return

	elapsed += delta

	# Phase 1: Fade in (0 to 0.8s) - fade overlay from black to transparent
	if elapsed < fade_in_duration:
		var progress = elapsed / fade_in_duration
		fade_overlay.color.a = 1.0 - progress
		credits_label.modulate.a = progress

	# Phase 2: Display (0.8s to 2.3s) - fully visible
	elif elapsed < fade_in_duration + display_duration:
		fade_overlay.color.a = 0.0
		credits_label.modulate.a = 1.0

	# Phase 3: Fade out (2.3s to 3.1s) - fade to black
	elif elapsed < total_duration:
		var fade_elapsed = elapsed - fade_in_duration - display_duration
		var progress = fade_elapsed / fade_out_duration
		fade_overlay.color.a = progress
		credits_label.modulate.a = 1.0 - progress

	# Transition to next scene
	else:
		transitioning = true
		fade_overlay.color.a = 1.0
		credits_label.modulate.a = 0.0
		# Small delay before scene change for clean transition
		await get_tree().create_timer(0.1).timeout
		get_tree().change_scene_to_file("res://scenes/press_continue.tscn")

func _input(event):
	# Allow skipping with any key/click
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed and not transitioning:
			transitioning = true
			# Quick fade to black then transition
			var tween = create_tween()
			tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
			tween.parallel().tween_property(credits_label, "modulate:a", 0.0, 0.3)
			tween.tween_callback(_go_to_next_scene)

func _go_to_next_scene():
	get_tree().change_scene_to_file("res://scenes/press_continue.tscn")
