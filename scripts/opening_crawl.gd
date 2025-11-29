extends CanvasLayer
class_name OpeningCrawl

# Opening Crawl - Star Wars style text scroll
# Matches pygame opening_crawl.py

signal crawl_complete

enum State { IDLE, FADE_IN, HOLD, FADE_OUT, TRANSITIONING }

@onready var background: ColorRect = $Background
@onready var text_container: Control = $TextContainer

var current_state: State = State.IDLE
var crawl_lines: Array = []
var current_paragraph_index: int = 0
var paragraphs: Array = []

# Timing (matching pygame)
var fade_in_time: float = 1.0
var hold_time: float = 4.5
var fade_out_time: float = 0.8
var state_timer: float = 0.0

# Visual
var text_labels: Array = []
var line_height: int = 60
var title_scale: float = 2.8
var normal_scale: float = 2.0

# Skip hint
var skip_label: Label

func _ready():
	visible = false
	_setup_skip_hint()

func _setup_skip_hint():
	skip_label = Label.new()
	skip_label.text = "Press SPACE to skip"
	skip_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	skip_label.offset_bottom = -20
	add_child(skip_label)

func show_crawl(lines: Array):
	"""Start the opening crawl with given lines."""
	crawl_lines = lines
	_parse_paragraphs()

	if paragraphs.size() == 0:
		emit_signal("crawl_complete")
		return

	visible = true
	current_paragraph_index = 0
	_show_paragraph(0)

func _parse_paragraphs():
	"""Group lines by empty lines to create paragraphs."""
	paragraphs = []
	var current_paragraph = []

	for line in crawl_lines:
		if line == "":
			if current_paragraph.size() > 0:
				paragraphs.append(current_paragraph)
				current_paragraph = []
		else:
			current_paragraph.append(line)

	# Don't forget the last paragraph
	if current_paragraph.size() > 0:
		paragraphs.append(current_paragraph)

func _show_paragraph(index: int):
	"""Show a single paragraph with fade animation."""
	if index >= paragraphs.size():
		_finish_crawl()
		return

	# Clear existing labels
	for label in text_labels:
		label.queue_free()
	text_labels.clear()

	var paragraph = paragraphs[index]
	var viewport_size = get_viewport().get_visible_rect().size

	# Calculate total height for centering
	var total_height = paragraph.size() * line_height
	var start_y = (viewport_size.y - total_height) / 2

	# Create labels for each line
	for i in range(paragraph.size()):
		var label = Label.new()
		label.text = paragraph[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# Check if this is the title (STRIKE CHESS)
		var is_title = paragraph[i] == "STRIKE CHESS"
		if is_title:
			label.add_theme_font_size_override("font_size", int(24 * title_scale))
			label.add_theme_color_override("font_color", Color.WHITE)
		else:
			label.add_theme_font_size_override("font_size", int(24 * normal_scale))
			label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))

		# Position
		label.anchors_preset = Control.PRESET_TOP_WIDE
		label.position.y = start_y + i * line_height

		# Start invisible
		label.modulate.a = 0.0

		text_container.add_child(label)
		text_labels.append(label)

	# Start fade in
	current_state = State.FADE_IN
	state_timer = 0.0

func _process(delta):
	if not visible:
		return

	state_timer += delta

	match current_state:
		State.FADE_IN:
			var alpha = min(state_timer / fade_in_time, 1.0)
			_set_labels_alpha(alpha)
			if state_timer >= fade_in_time:
				current_state = State.HOLD
				state_timer = 0.0

		State.HOLD:
			if state_timer >= hold_time:
				current_state = State.FADE_OUT
				state_timer = 0.0

		State.FADE_OUT:
			var alpha = 1.0 - min(state_timer / fade_out_time, 1.0)
			_set_labels_alpha(alpha)
			if state_timer >= fade_out_time:
				current_state = State.TRANSITIONING
				state_timer = 0.0
				current_paragraph_index += 1
				_show_paragraph(current_paragraph_index)

func _set_labels_alpha(alpha: float):
	"""Set alpha for all text labels."""
	for label in text_labels:
		label.modulate.a = alpha

func _input(event):
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			skip()

func skip():
	"""Skip the entire crawl."""
	_finish_crawl()

func _finish_crawl():
	"""Complete the crawl and hide."""
	visible = false
	current_state = State.IDLE

	# Clear labels
	for label in text_labels:
		label.queue_free()
	text_labels.clear()

	emit_signal("crawl_complete")

func is_active() -> bool:
	"""Check if crawl is currently playing."""
	return visible and current_state != State.IDLE
