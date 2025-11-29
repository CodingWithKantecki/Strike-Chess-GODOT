extends CanvasLayer
class_name AnimatedDialogue

# Animated Dialogue Box - matching pygame animated_dialogue.py
# Features: Expanding box animation, typewriter text effect

signal dialogue_complete
signal line_complete

enum State { IDLE, EXPANDING, TYPEWRITING, COMPLETE }

@onready var panel: Panel = $DialoguePanel
@onready var text_label: RichTextLabel = $DialoguePanel/TextLabel
@onready var speaker_label: Label = $DialoguePanel/SpeakerLabel
@onready var continue_hint: Label = $DialoguePanel/ContinueHint

var current_state: State = State.IDLE
var dialogue_queue: Array = []
var current_line: String = ""
var current_speaker: String = ""
var displayed_text: String = ""
var char_index: int = 0

# Timing
var expand_duration: float = 0.6  # 600ms like pygame
var expand_timer: float = 0.0
var typewriter_speed: float = 30.0  # Characters per second
var typewriter_timer: float = 0.0

# Box dimensions
var box_start_height: float = 2.0
var box_target_height: float = 140.0
var box_width: float = 800.0

# Colors
var border_color: Color = Color(0, 0.588, 0.784)  # Cyan (0, 150, 200)
var bg_color: Color = Color(0.039, 0.059, 0.098)  # Dark navy (10, 15, 25)

# Typewriter sound
var typewriter_sound: AudioStream

func _ready():
	visible = false
	panel.visible = false

	# Load typewriter sound if available
	if ResourceLoader.exists("res://assets/typesound.wav"):
		typewriter_sound = load("res://assets/typesound.wav")

	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)

func show_dialogue(lines: Array, speaker: String = ""):
	"""Show dialogue with given lines."""
	dialogue_queue = lines.duplicate()
	current_speaker = speaker
	if speaker_label:
		speaker_label.text = speaker
	_start_next_line()

func _start_next_line():
	"""Start showing the next line in the queue."""
	if dialogue_queue.size() == 0:
		_finish_dialogue()
		return

	current_line = dialogue_queue.pop_front()

	# Parse speaker from line if in format "SPEAKER: text"
	if ": " in current_line:
		var parts = current_line.split(": ", true, 1)
		if parts.size() == 2 and parts[0] == parts[0].to_upper():
			current_speaker = parts[0]
			current_line = parts[1]
			if speaker_label:
				speaker_label.text = current_speaker

	displayed_text = ""
	char_index = 0

	# Start expansion animation
	visible = true
	panel.visible = true
	current_state = State.EXPANDING
	expand_timer = 0.0
	panel.custom_minimum_size.y = box_start_height

	if text_label:
		text_label.text = ""
	if continue_hint:
		continue_hint.visible = false

func _process(delta):
	match current_state:
		State.EXPANDING:
			_update_expansion(delta)
		State.TYPEWRITING:
			_update_typewriter(delta)
		State.COMPLETE:
			_update_complete(delta)

func _update_expansion(delta):
	expand_timer += delta
	var progress = min(expand_timer / expand_duration, 1.0)

	# Ease-out cubic easing like pygame
	var eased_progress = 1.0 - pow(1.0 - progress, 3)

	# Interpolate height
	var current_height = lerp(box_start_height, box_target_height, eased_progress)
	panel.custom_minimum_size.y = current_height

	if progress >= 1.0:
		# Start typewriter
		current_state = State.TYPEWRITING
		typewriter_timer = 0.0

func _update_typewriter(delta):
	typewriter_timer += delta

	var chars_to_show = int(typewriter_timer * typewriter_speed)
	if chars_to_show > char_index and char_index < current_line.length():
		# Show new characters
		while char_index < chars_to_show and char_index < current_line.length():
			displayed_text += current_line[char_index]
			char_index += 1

			# Play typewriter sound (skip spaces)
			if current_line[char_index - 1] != " " and typewriter_sound:
				AudioManager.play_sound_effect(typewriter_sound, 0.16)

		if text_label:
			text_label.text = displayed_text

	# Check if complete
	if char_index >= current_line.length():
		current_state = State.COMPLETE
		emit_signal("line_complete")
		if continue_hint:
			continue_hint.visible = true

func _update_complete(_delta):
	# Blink continue hint
	if continue_hint:
		var blink = int(Time.get_ticks_msec() / 500) % 2 == 0
		continue_hint.modulate.a = 1.0 if blink else 0.5

func _input(event):
	if not visible:
		return

	if event is InputEventMouseButton and event.pressed:
		_handle_click()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_handle_click()

func _handle_click():
	match current_state:
		State.EXPANDING:
			# Skip to fully expanded
			expand_timer = expand_duration
		State.TYPEWRITING:
			# Skip to full text
			displayed_text = current_line
			char_index = current_line.length()
			if text_label:
				text_label.text = displayed_text
			current_state = State.COMPLETE
			if continue_hint:
				continue_hint.visible = true
		State.COMPLETE:
			# Move to next line
			_start_next_line()

func _finish_dialogue():
	"""Close the dialogue box."""
	current_state = State.IDLE
	visible = false
	panel.visible = false
	emit_signal("dialogue_complete")

func skip_all():
	"""Skip all remaining dialogue."""
	dialogue_queue.clear()
	_finish_dialogue()

func is_active() -> bool:
	"""Check if dialogue is currently showing."""
	return visible and current_state != State.IDLE
