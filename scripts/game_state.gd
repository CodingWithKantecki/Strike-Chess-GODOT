extends Node

# GameState - Global game state singleton
# Stores settings that persist between scenes

# Sandbox settings
var sandbox_elo: int = 1000
var sandbox_mode: bool = false

# Current game mode
var current_mode: String = "campaign"  # campaign, sandbox, tutorial, multiplayer

# Campaign progress
var current_chapter: int = 0
var chapters_completed: Array = []

# Player stats
var total_wins: int = 0
var total_losses: int = 0

func reset_sandbox():
	"""Reset sandbox settings to defaults."""
	sandbox_elo = 1000
	sandbox_mode = false

func start_sandbox_game(elo: int):
	"""Start a sandbox game with given ELO."""
	sandbox_elo = elo
	sandbox_mode = true
	current_mode = "sandbox"

func start_campaign_game(chapter: int):
	"""Start a campaign game."""
	current_chapter = chapter
	sandbox_mode = false
	current_mode = "campaign"

func get_ai_difficulty() -> float:
	"""Get AI difficulty as a 0-1 value based on ELO."""
	# Convert ELO 600-2000 to 0-1 range
	return clamp((sandbox_elo - 600.0) / 1400.0, 0.0, 1.0)

func get_opponent_name() -> String:
	"""Get display name for current opponent."""
	if sandbox_mode:
		return str(sandbox_elo) + " ELO Bot"
	else:
		return "Chapter " + str(current_chapter + 1) + " AI"
