extends CanvasLayer
class_name PowerupMenu

# Powerup Menu UI - matching pygame powerup_renderer.py
# Tiered powerup selection panel with visual feedback

signal powerup_selected(powerup_key: String)
signal menu_closed

var powerup_system: PowerupSystem
var current_player: String = "white"
var is_open: bool = false

# UI elements
var panel: Panel
var title_label: Label
var points_label: Label
var tier_containers: Dictionary = {}  # tier_name -> VBoxContainer
var powerup_buttons: Dictionary = {}  # powerup_key -> Button
var close_button: Button
var description_label: RichTextLabel

# Tier colors (matching pygame)
var tier_colors: Dictionary = {
	"basic": Color(0.2, 0.6, 0.2),      # Green
	"mid": Color(0.2, 0.4, 0.8),        # Blue
	"high": Color(0.6, 0.2, 0.8),       # Purple
	"ultimate": Color(0.9, 0.6, 0.1)    # Gold
}

# Tier labels
var tier_labels: Dictionary = {
	"basic": "BASIC (5-10 pts)",
	"mid": "MID TIER (12-20 pts)",
	"high": "HIGH TIER (25-40 pts)",
	"ultimate": "ULTIMATE (50-60 pts)"
}

func _ready():
	visible = false
	_create_ui()

func _create_ui():
	"""Create the powerup menu UI."""
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(350, 600)
	panel.anchors_preset = Control.PRESET_CENTER_RIGHT
	panel.position = Vector2(-380, -300)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.95)
	style.border_color = Color(0.0, 0.7, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	# Title
	title_label = Label.new()
	title_label.text = "TACTICAL POWERUPS"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, 10)
	title_label.size = Vector2(350, 30)
	panel.add_child(title_label)

	# Points display
	points_label = Label.new()
	points_label.text = "Points: 0"
	points_label.add_theme_font_size_override("font_size", 20)
	points_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_label.position = Vector2(0, 40)
	points_label.size = Vector2(350, 25)
	panel.add_child(points_label)

	# Scroll container for tiers
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 75)
	scroll.size = Vector2(330, 420)
	panel.add_child(scroll)

	var content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(310, 0)
	scroll.add_child(content)

	# Create tier sections
	for tier in ["basic", "mid", "high", "ultimate"]:
		_create_tier_section(content, tier)

	# Description panel at bottom
	description_label = RichTextLabel.new()
	description_label.bbcode_enabled = true
	description_label.fit_content = true
	description_label.position = Vector2(10, 505)
	description_label.size = Vector2(330, 50)
	description_label.add_theme_color_override("default_color", Color(0.8, 0.8, 0.8))
	description_label.add_theme_font_size_override("normal_font_size", 14)
	panel.add_child(description_label)

	# Close button
	close_button = Button.new()
	close_button.text = "Close [TAB]"
	close_button.position = Vector2(125, 560)
	close_button.size = Vector2(100, 30)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

	add_child(panel)

func _create_tier_section(parent: Control, tier: String):
	"""Create a section for a powerup tier."""
	var section = VBoxContainer.new()

	# Tier header
	var header = Label.new()
	header.text = tier_labels[tier]
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", tier_colors[tier])
	section.add_child(header)

	# Container for powerup buttons
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	section.add_child(container)
	tier_containers[tier] = container

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	section.add_child(spacer)

	parent.add_child(section)

func setup(system: PowerupSystem):
	"""Setup with powerup system reference."""
	powerup_system = system
	_create_powerup_buttons()

func _create_powerup_buttons():
	"""Create buttons for all powerups."""
	if not powerup_system:
		return

	# Clear existing buttons
	for key in powerup_buttons:
		powerup_buttons[key].queue_free()
	powerup_buttons.clear()

	# Create buttons for each powerup
	for key in powerup_system.get_powerup_list():
		var data = powerup_system.get_powerup_data(key)
		var tier = data.get("tier", "basic")

		if not tier_containers.has(tier):
			continue

		var button = _create_powerup_button(key, data)
		tier_containers[tier].add_child(button)
		powerup_buttons[key] = button

func _create_powerup_button(key: String, data: Dictionary) -> Button:
	"""Create a single powerup button."""
	var button = Button.new()
	button.custom_minimum_size = Vector2(300, 40)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Button text: [COST] NAME
	var cost = data.get("cost", 0)
	var name = data.get("name", key.to_upper())
	button.text = "[%d] %s" % [cost, name]

	# Style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.15, 0.2)
	normal_style.border_color = tier_colors[data.get("tier", "basic")]
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.15, 0.2, 0.3)
	button.add_theme_stylebox_override("hover", hover_style)

	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = Color(0.05, 0.05, 0.08)
	disabled_style.border_color = Color(0.2, 0.2, 0.2)
	button.add_theme_stylebox_override("disabled", disabled_style)

	# Connect signals
	button.pressed.connect(_on_powerup_pressed.bind(key))
	button.mouse_entered.connect(_on_powerup_hover.bind(key))

	return button

func _on_powerup_pressed(key: String):
	"""Handle powerup button pressed."""
	if powerup_system and powerup_system.can_afford_powerup(current_player, key):
		emit_signal("powerup_selected", key)
		close()

func _on_powerup_hover(key: String):
	"""Show description on hover."""
	if powerup_system:
		var data = powerup_system.get_powerup_data(key)
		var desc = data.get("description", "")
		var cost = data.get("cost", 0)
		description_label.text = "[b]%s[/b] (%d pts)\n%s" % [data.get("name", key), cost, desc]

func _on_close_pressed():
	"""Close the menu."""
	close()

func open(player: String):
	"""Open the menu for a player."""
	current_player = player
	is_open = true
	visible = true
	_refresh_buttons()

func close():
	"""Close the menu."""
	is_open = false
	visible = false
	emit_signal("menu_closed")

func toggle(player: String):
	"""Toggle menu open/closed."""
	if is_open:
		close()
	else:
		open(player)

func _refresh_buttons():
	"""Update button states based on affordability."""
	if not powerup_system:
		return

	var player_points = powerup_system.get_points(current_player)
	points_label.text = "Points: %d" % player_points

	for key in powerup_buttons:
		var button = powerup_buttons[key]
		var can_afford = powerup_system.can_afford_powerup(current_player, key)
		button.disabled = not can_afford

		# Update text color
		if can_afford:
			button.add_theme_color_override("font_color", Color.WHITE)
		else:
			button.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB:
			if is_open:
				close()
		elif event.keycode == KEY_ESCAPE and is_open:
			close()
			get_viewport().set_input_as_handled()

func _process(_delta):
	if is_open and powerup_system:
		# Keep points display updated
		var player_points = powerup_system.get_points(current_player)
		points_label.text = "Points: %d" % player_points

		# Refresh button states periodically
		_refresh_buttons()
