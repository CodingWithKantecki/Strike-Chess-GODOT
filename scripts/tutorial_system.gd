extends CanvasLayer
class_name TutorialSystem

# Tutorial System - matching pygame tutorial_system.py
# Provides interactive tutorials for game mechanics

signal tutorial_started(tutorial_name: String)
signal tutorial_step_changed(step: int)
signal tutorial_complete(tutorial_name: String)
signal highlight_requested(positions: Array)
signal highlight_cleared

enum TutorialState { INACTIVE, ACTIVE, WAITING_INPUT, PAUSED }

var current_state: TutorialState = TutorialState.INACTIVE
var current_tutorial: String = ""
var current_step: int = 0
var tutorials: Dictionary = {}

# UI elements
var instruction_panel: Panel
var instruction_label: RichTextLabel
var hint_label: Label
var skip_button: Button
var next_button: Button
var highlight_rects: Array = []

# Timing
var auto_advance_timer: float = 0.0
var auto_advance_delay: float = 0.0

func _ready():
	visible = false
	_setup_tutorials()
	_create_ui()

func _setup_tutorials():
	"""Define all tutorial sequences."""

	# Basic movement tutorial
	tutorials["basic_moves"] = {
		"name": "Basic Chess Moves",
		"steps": [
			{
				"text": "Welcome to Strike Chess! Let's learn the basics.\n\nClick anywhere to continue.",
				"highlight": [],
				"wait_for": "click"
			},
			{
				"text": "This is your army. White pieces start at the bottom.\n\nYour goal: Capture the enemy King!",
				"highlight": ["friendly_pieces"],
				"wait_for": "click"
			},
			{
				"text": "Click on a piece to see where it can move.\n\nTry selecting your PAWN.",
				"highlight": ["pawns"],
				"wait_for": "select_pawn"
			},
			{
				"text": "Great! The highlighted squares show legal moves.\n\nPawns move forward but capture diagonally.",
				"highlight": ["valid_moves"],
				"wait_for": "click"
			},
			{
				"text": "Now try moving your pawn forward.\n\nClick on a highlighted square.",
				"highlight": ["valid_moves"],
				"wait_for": "make_move"
			},
			{
				"text": "Excellent! You've made your first move!\n\nNow the opponent will respond.",
				"highlight": [],
				"wait_for": "click",
				"auto_advance": 2.0
			}
		]
	}

	# Powerup tutorial
	tutorials["powerups"] = {
		"name": "Strike Chess Powerups",
		"steps": [
			{
				"text": "Strike Chess has TACTICAL POWERUPS!\n\nCapturing pieces earns you points.",
				"highlight": [],
				"wait_for": "click"
			},
			{
				"text": "Points can be spent on powerful abilities.\n\nPawn = 1pt, Knight/Bishop = 3pt, Rook = 5pt, Queen = 9pt",
				"highlight": ["points_display"],
				"wait_for": "click"
			},
			{
				"text": "Open the powerup menu with [TAB] or click the button.\n\nTry it now!",
				"highlight": ["powerup_button"],
				"wait_for": "open_powerup_menu"
			},
			{
				"text": "Here are your available powerups!\n\nGrayed out = not enough points\nBright = ready to use",
				"highlight": ["powerup_menu"],
				"wait_for": "click"
			},
			{
				"text": "SHIELD (5 pts): Protects a piece for 3 turns\nGUN (7 pts): Destroy an enemy in line of sight",
				"highlight": [],
				"wait_for": "click"
			},
			{
				"text": "AIRSTRIKE (10 pts): 3x3 area bombardment\nTACTICAL NUKE (20 pts): 5x5 destruction!",
				"highlight": [],
				"wait_for": "click"
			},
			{
				"text": "Higher tier powerups unlock as you earn more points.\n\nUse them wisely to turn the tide of battle!",
				"highlight": [],
				"wait_for": "click"
			}
		]
	}

	# Special pieces tutorial
	tutorials["special_pieces"] = {
		"name": "Special Piece Abilities",
		"steps": [
			{
				"text": "Each piece type has unique strengths!\n\nLet's review them.",
				"highlight": [],
				"wait_for": "click"
			},
			{
				"text": "KNIGHTS can jump over other pieces.\n\nThey're perfect for surprise attacks!",
				"highlight": ["knights"],
				"wait_for": "click"
			},
			{
				"text": "BISHOPS control diagonals.\n\nTwo bishops together are very powerful!",
				"highlight": ["bishops"],
				"wait_for": "click"
			},
			{
				"text": "ROOKS dominate files and ranks.\n\nThey're excellent in the endgame.",
				"highlight": ["rooks"],
				"wait_for": "click"
			},
			{
				"text": "The QUEEN is your most powerful piece.\n\nShe combines Rook + Bishop movement!",
				"highlight": ["queen"],
				"wait_for": "click"
			},
			{
				"text": "Protect your KING at all costs!\n\nIf the King is captured, you lose!",
				"highlight": ["king"],
				"wait_for": "click"
			}
		]
	}

	# Campaign tutorial
	tutorials["campaign"] = {
		"name": "Campaign Mode",
		"steps": [
			{
				"text": "Welcome to the Strike Chess Campaign!\n\nYou are a commander leading your forces.",
				"highlight": [],
				"wait_for": "click"
			},
			{
				"text": "Move your tank across the map to reach battle nodes.\n\nUse WASD or click to navigate.",
				"highlight": ["tank"],
				"wait_for": "click"
			},
			{
				"text": "Each node is a chess battle against the AI.\n\nDefeat all enemies to complete the chapter!",
				"highlight": ["mission_nodes"],
				"wait_for": "click"
			},
			{
				"text": "Your difficulty increases as you progress.\n\nRecruit -> Rookie -> Soldier -> ... -> Nexus",
				"highlight": [],
				"wait_for": "click"
			},
			{
				"text": "Good luck, Commander!\n\nThe fate of the board rests in your hands.",
				"highlight": [],
				"wait_for": "click"
			}
		]
	}

func _create_ui():
	"""Create tutorial UI elements."""
	# Main instruction panel
	instruction_panel = Panel.new()
	instruction_panel.custom_minimum_size = Vector2(600, 150)
	instruction_panel.anchors_preset = Control.PRESET_CENTER_BOTTOM
	instruction_panel.position = Vector2(-300, -180)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15, 0.95)
	style.border_color = Color(0, 0.7, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	instruction_panel.add_theme_stylebox_override("panel", style)

	# Instruction text
	instruction_label = RichTextLabel.new()
	instruction_label.bbcode_enabled = true
	instruction_label.fit_content = true
	instruction_label.position = Vector2(20, 15)
	instruction_label.size = Vector2(560, 80)
	instruction_label.add_theme_font_size_override("normal_font_size", 20)
	instruction_label.add_theme_color_override("default_color", Color.WHITE)
	instruction_panel.add_child(instruction_label)

	# Hint label
	hint_label = Label.new()
	hint_label.text = "Click to continue..."
	hint_label.position = Vector2(20, 105)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	hint_label.add_theme_font_size_override("font_size", 16)
	instruction_panel.add_child(hint_label)

	# Skip button
	skip_button = Button.new()
	skip_button.text = "Skip Tutorial"
	skip_button.position = Vector2(380, 105)
	skip_button.size = Vector2(100, 30)
	skip_button.pressed.connect(_on_skip_pressed)
	instruction_panel.add_child(skip_button)

	# Next button
	next_button = Button.new()
	next_button.text = "Next"
	next_button.position = Vector2(490, 105)
	next_button.size = Vector2(90, 30)
	next_button.pressed.connect(_on_next_pressed)
	instruction_panel.add_child(next_button)

	add_child(instruction_panel)

func start_tutorial(tutorial_key: String):
	"""Start a specific tutorial."""
	if not tutorials.has(tutorial_key):
		push_error("Tutorial not found: " + tutorial_key)
		return

	current_tutorial = tutorial_key
	current_step = 0
	current_state = TutorialState.ACTIVE
	visible = true

	emit_signal("tutorial_started", tutorial_key)
	_show_current_step()

func _show_current_step():
	"""Display the current tutorial step."""
	var tutorial = tutorials[current_tutorial]
	if current_step >= tutorial["steps"].size():
		_complete_tutorial()
		return

	var step = tutorial["steps"][current_step]

	# Update instruction text
	instruction_label.text = step["text"]

	# Update hint based on wait condition
	match step.get("wait_for", "click"):
		"click":
			hint_label.text = "Click to continue..."
			current_state = TutorialState.WAITING_INPUT
		"select_pawn":
			hint_label.text = "Select a pawn to continue..."
			current_state = TutorialState.WAITING_INPUT
		"make_move":
			hint_label.text = "Make a move to continue..."
			current_state = TutorialState.WAITING_INPUT
		"open_powerup_menu":
			hint_label.text = "Press TAB to open powerups..."
			current_state = TutorialState.WAITING_INPUT
		_:
			hint_label.text = ""
			current_state = TutorialState.ACTIVE

	# Handle auto advance
	if step.has("auto_advance"):
		auto_advance_delay = step["auto_advance"]
		auto_advance_timer = 0.0
	else:
		auto_advance_delay = 0.0

	# Request highlights
	var highlights = step.get("highlight", [])
	emit_signal("highlight_requested", highlights)

	emit_signal("tutorial_step_changed", current_step)

func advance_step():
	"""Advance to next tutorial step."""
	if current_state != TutorialState.WAITING_INPUT and current_state != TutorialState.ACTIVE:
		return

	emit_signal("highlight_cleared")
	current_step += 1
	_show_current_step()

func notify_action(action: String):
	"""Notify the tutorial system of a player action."""
	if current_state != TutorialState.WAITING_INPUT:
		return

	var tutorial = tutorials.get(current_tutorial, {})
	var steps = tutorial.get("steps", [])
	if current_step >= steps.size():
		return

	var step = steps[current_step]
	var wait_for = step.get("wait_for", "click")

	if action == wait_for or (wait_for == "click" and action in ["click", "select_pawn", "make_move"]):
		advance_step()

func _complete_tutorial():
	"""Complete the current tutorial."""
	emit_signal("highlight_cleared")
	emit_signal("tutorial_complete", current_tutorial)

	current_state = TutorialState.INACTIVE
	current_tutorial = ""
	current_step = 0
	visible = false

func _on_skip_pressed():
	"""Skip the entire tutorial."""
	_complete_tutorial()

func _on_next_pressed():
	"""Move to next step."""
	advance_step()

func _process(delta):
	if current_state == TutorialState.INACTIVE:
		return

	# Handle auto advance
	if auto_advance_delay > 0:
		auto_advance_timer += delta
		if auto_advance_timer >= auto_advance_delay:
			advance_step()

	# Blink hint text
	if current_state == TutorialState.WAITING_INPUT:
		var blink = sin(Time.get_ticks_msec() * 0.005) * 0.3 + 0.7
		hint_label.modulate.a = blink

func _input(event):
	if current_state != TutorialState.WAITING_INPUT:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if clicking on the instruction panel
		var panel_rect = Rect2(instruction_panel.global_position, instruction_panel.size)
		if not panel_rect.has_point(event.position):
			notify_action("click")

func pause_tutorial():
	"""Pause the tutorial."""
	if current_state == TutorialState.ACTIVE or current_state == TutorialState.WAITING_INPUT:
		current_state = TutorialState.PAUSED
		visible = false

func resume_tutorial():
	"""Resume the tutorial."""
	if current_state == TutorialState.PAUSED:
		current_state = TutorialState.WAITING_INPUT
		visible = true

func is_active() -> bool:
	"""Check if a tutorial is active."""
	return current_state != TutorialState.INACTIVE

func get_available_tutorials() -> Array:
	"""Get list of available tutorials."""
	return tutorials.keys()

func get_tutorial_name(key: String) -> String:
	"""Get display name for a tutorial."""
	if tutorials.has(key):
		return tutorials[key]["name"]
	return key
