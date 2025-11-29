extends CanvasLayer
class_name LoadoutSelector

# Loadout Selector - Pre-battle powerup customization
# Matches pygame loadout_selector.py

signal loadout_confirmed(selected_powerups: Array)
signal loadout_cancelled

var is_open: bool = false
var max_slots: int = 5
var selected_powerups: Array = []
var available_powerups: Array = []

# UI elements
var panel: Panel
var title_label: Label
var slots_container: HBoxContainer
var available_container: GridContainer
var confirm_button: Button
var cancel_button: Button
var description_label: RichTextLabel

# Slot buttons
var slot_buttons: Array = []
# Available powerup buttons
var powerup_buttons: Dictionary = {}

# Powerup data reference
var powerup_data: Dictionary = {
	"shield": {"name": "SHIELD", "icon": "shield", "tier": "basic"},
	"gun": {"name": "GUN", "icon": "gun", "tier": "basic"},
	"airstrike": {"name": "AIRSTRIKE", "icon": "airstrike", "tier": "basic"},
	"smoke": {"name": "SMOKE", "icon": "smoke", "tier": "mid"},
	"paratroopers": {"name": "PARATROOPERS", "icon": "paratroopers", "tier": "mid"},
	"recon": {"name": "RECON DRONE", "icon": "recon", "tier": "mid"},
	"medic": {"name": "MEDIC", "icon": "medic", "tier": "mid"},
	"nuke": {"name": "TACTICAL NUKE", "icon": "nuke", "tier": "mid"},
	"teleport": {"name": "TELEPORTER", "icon": "teleport", "tier": "high"},
	"freeze": {"name": "TIME FREEZE", "icon": "freeze", "tier": "high"},
	"forcefield": {"name": "FORCEFIELD", "icon": "forcefield", "tier": "high"},
	"mind_control": {"name": "MIND CONTROL", "icon": "mind_control", "tier": "high"},
	"laser": {"name": "ORBITAL LASER", "icon": "laser", "tier": "ultimate"},
	"chopper": {"name": "CHOPPER GUNNER", "icon": "chopper", "tier": "ultimate"}
}

# Tier colors
var tier_colors: Dictionary = {
	"basic": Color(0.2, 0.6, 0.2),
	"mid": Color(0.2, 0.4, 0.8),
	"high": Color(0.6, 0.2, 0.8),
	"ultimate": Color(0.9, 0.6, 0.1)
}

func _ready():
	visible = false
	_create_ui()

func _create_ui():
	"""Create the loadout selector UI."""
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(700, 500)
	panel.anchors_preset = Control.PRESET_CENTER

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.98)
	style.border_color = Color(0.0, 0.7, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)

	# Title
	title_label = Label.new()
	title_label.text = "SELECT YOUR LOADOUT"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, 15)
	title_label.size = Vector2(700, 40)
	panel.add_child(title_label)

	# Slots label
	var slots_label = Label.new()
	slots_label.text = "Your Loadout:"
	slots_label.add_theme_font_size_override("font_size", 18)
	slots_label.add_theme_color_override("font_color", Color.WHITE)
	slots_label.position = Vector2(20, 60)
	panel.add_child(slots_label)

	# Slots container
	slots_container = HBoxContainer.new()
	slots_container.position = Vector2(20, 90)
	slots_container.add_theme_constant_override("separation", 10)
	panel.add_child(slots_container)

	# Create slot buttons
	for i in range(max_slots):
		var slot = _create_slot_button(i)
		slots_container.add_child(slot)
		slot_buttons.append(slot)

	# Available powerups label
	var available_label = Label.new()
	available_label.text = "Available Powerups (click to add):"
	available_label.add_theme_font_size_override("font_size", 18)
	available_label.add_theme_color_override("font_color", Color.WHITE)
	available_label.position = Vector2(20, 170)
	panel.add_child(available_label)

	# Available powerups grid
	available_container = GridContainer.new()
	available_container.columns = 5
	available_container.position = Vector2(20, 200)
	available_container.add_theme_constant_override("h_separation", 10)
	available_container.add_theme_constant_override("v_separation", 10)
	panel.add_child(available_container)

	# Create powerup buttons
	for key in powerup_data:
		var btn = _create_powerup_button(key)
		available_container.add_child(btn)
		powerup_buttons[key] = btn

	# Description panel
	description_label = RichTextLabel.new()
	description_label.bbcode_enabled = true
	description_label.position = Vector2(20, 380)
	description_label.size = Vector2(660, 60)
	description_label.add_theme_color_override("default_color", Color(0.8, 0.8, 0.8))
	description_label.add_theme_font_size_override("normal_font_size", 16)
	panel.add_child(description_label)

	# Confirm button
	confirm_button = Button.new()
	confirm_button.text = "CONFIRM LOADOUT"
	confirm_button.position = Vector2(180, 450)
	confirm_button.size = Vector2(150, 40)
	confirm_button.pressed.connect(_on_confirm_pressed)
	panel.add_child(confirm_button)

	# Cancel button
	cancel_button = Button.new()
	cancel_button.text = "CANCEL"
	cancel_button.position = Vector2(370, 450)
	cancel_button.size = Vector2(150, 40)
	cancel_button.pressed.connect(_on_cancel_pressed)
	panel.add_child(cancel_button)

	add_child(panel)

func _create_slot_button(index: int) -> Button:
	"""Create a loadout slot button."""
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	btn.text = "Empty"

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.12, 0.15)
	style_normal.border_color = Color(0.3, 0.3, 0.3)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(5)
	btn.add_theme_stylebox_override("normal", style_normal)

	btn.pressed.connect(_on_slot_pressed.bind(index))

	return btn

func _create_powerup_button(key: String) -> Button:
	"""Create a powerup selection button."""
	var data = powerup_data[key]
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(120, 50)
	btn.text = data["name"]
	btn.add_theme_font_size_override("font_size", 12)

	var tier = data.get("tier", "basic")
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.2)
	style.border_color = tier_colors[tier]
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.15, 0.2, 0.28)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.pressed.connect(_on_powerup_pressed.bind(key))
	btn.mouse_entered.connect(_on_powerup_hover.bind(key))

	return btn

func open(unlocked_powerups: Array = []):
	"""Open the loadout selector."""
	available_powerups = unlocked_powerups if unlocked_powerups.size() > 0 else powerup_data.keys()
	selected_powerups.clear()
	is_open = true
	visible = true
	_refresh_ui()

func close():
	"""Close the loadout selector."""
	is_open = false
	visible = false

func _on_powerup_pressed(key: String):
	"""Handle clicking a powerup to add to loadout."""
	if key not in available_powerups:
		return

	if selected_powerups.size() >= max_slots:
		return

	if key in selected_powerups:
		# Already selected
		return

	selected_powerups.append(key)
	_refresh_ui()

func _on_slot_pressed(index: int):
	"""Handle clicking a slot to remove powerup."""
	if index < selected_powerups.size():
		selected_powerups.remove_at(index)
		_refresh_ui()

func _on_powerup_hover(key: String):
	"""Show powerup description on hover."""
	var data = powerup_data.get(key, {})
	var name = data.get("name", key)
	var tier = data.get("tier", "basic")
	description_label.text = "[b]%s[/b] (%s tier)\nSelect this powerup for your loadout." % [name, tier.to_upper()]

func _on_confirm_pressed():
	"""Confirm the loadout selection."""
	emit_signal("loadout_confirmed", selected_powerups)
	close()

func _on_cancel_pressed():
	"""Cancel loadout selection."""
	emit_signal("loadout_cancelled")
	close()

func _refresh_ui():
	"""Update the UI to reflect current selection."""
	# Update slot buttons
	for i in range(max_slots):
		var btn = slot_buttons[i]
		if i < selected_powerups.size():
			var key = selected_powerups[i]
			var data = powerup_data.get(key, {})
			btn.text = data.get("name", key)

			var tier = data.get("tier", "basic")
			var style = btn.get_theme_stylebox("normal").duplicate()
			style.border_color = tier_colors[tier]
			btn.add_theme_stylebox_override("normal", style)
		else:
			btn.text = "Empty"
			var style = btn.get_theme_stylebox("normal").duplicate()
			style.border_color = Color(0.3, 0.3, 0.3)
			btn.add_theme_stylebox_override("normal", style)

	# Update available powerup buttons
	for key in powerup_buttons:
		var btn = powerup_buttons[key]
		var is_available = key in available_powerups
		var is_selected = key in selected_powerups

		btn.disabled = not is_available or is_selected

		if is_selected:
			btn.modulate = Color(0.5, 0.5, 0.5)
		else:
			btn.modulate = Color.WHITE

func _input(event):
	if not is_open:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_cancel_pressed()

func get_selected_loadout() -> Array:
	"""Get the current selected loadout."""
	return selected_powerups.duplicate()

func set_default_loadout():
	"""Set a default loadout."""
	selected_powerups = ["shield", "gun", "airstrike"]
	_refresh_ui()
