extends Node
class_name CampaignProgress

# Campaign Progress - Save/Load system for story mode
# Matches pygame campaign_progress.py

signal progress_saved
signal progress_loaded
signal progress_reset

const SAVE_PATH = "user://campaign_progress.save"

# Progress data
var current_chapter: int = 0
var current_battle: int = 0
var completed_chapters: Array = []
var completed_battles: Dictionary = {}  # {chapter_idx: [battle_indices]}
var total_wins: int = 0
var total_losses: int = 0
var unlocked_powerups: Array = ["shield", "gun", "airstrike"]
var selected_loadout: Array = []
var statistics: Dictionary = {
	"pieces_captured": 0,
	"pieces_lost": 0,
	"powerups_used": 0,
	"perfect_wins": 0,  # Wins without losing any pieces
	"total_time_played": 0.0
}

# Settings
var auto_save: bool = true

func _ready():
	load_progress()

func save_progress():
	"""Save progress to file."""
	var save_data = {
		"current_chapter": current_chapter,
		"current_battle": current_battle,
		"completed_chapters": completed_chapters,
		"completed_battles": completed_battles,
		"total_wins": total_wins,
		"total_losses": total_losses,
		"unlocked_powerups": unlocked_powerups,
		"selected_loadout": selected_loadout,
		"statistics": statistics,
		"version": 1
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		emit_signal("progress_saved")
		return true

	return false

func load_progress() -> bool:
	"""Load progress from file."""
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()

		if save_data is Dictionary:
			current_chapter = save_data.get("current_chapter", 0)
			current_battle = save_data.get("current_battle", 0)
			completed_chapters = save_data.get("completed_chapters", [])
			completed_battles = save_data.get("completed_battles", {})
			total_wins = save_data.get("total_wins", 0)
			total_losses = save_data.get("total_losses", 0)
			unlocked_powerups = save_data.get("unlocked_powerups", ["shield", "gun", "airstrike"])
			selected_loadout = save_data.get("selected_loadout", [])
			statistics = save_data.get("statistics", statistics)

			emit_signal("progress_loaded")
			return true

	return false

func reset_progress():
	"""Reset all progress."""
	current_chapter = 0
	current_battle = 0
	completed_chapters.clear()
	completed_battles.clear()
	total_wins = 0
	total_losses = 0
	unlocked_powerups = ["shield", "gun", "airstrike"]
	selected_loadout.clear()
	statistics = {
		"pieces_captured": 0,
		"pieces_lost": 0,
		"powerups_used": 0,
		"perfect_wins": 0,
		"total_time_played": 0.0
	}

	save_progress()
	emit_signal("progress_reset")

func record_battle_win(chapter: int, battle: int, pieces_lost: int = 0, pieces_captured: int = 0):
	"""Record a battle victory."""
	total_wins += 1
	statistics["pieces_captured"] += pieces_captured
	statistics["pieces_lost"] += pieces_lost

	if pieces_lost == 0:
		statistics["perfect_wins"] += 1

	# Mark battle as completed
	var chapter_key = str(chapter)
	if not completed_battles.has(chapter_key):
		completed_battles[chapter_key] = []
	if battle not in completed_battles[chapter_key]:
		completed_battles[chapter_key].append(battle)

	# Check if chapter is complete
	_check_chapter_completion(chapter)

	# Unlock new powerups based on progress
	_check_powerup_unlocks()

	if auto_save:
		save_progress()

func record_battle_loss(chapter: int, battle: int, pieces_lost: int = 0, pieces_captured: int = 0):
	"""Record a battle loss."""
	total_losses += 1
	statistics["pieces_captured"] += pieces_captured
	statistics["pieces_lost"] += pieces_lost

	if auto_save:
		save_progress()

func record_powerup_used():
	"""Record a powerup being used."""
	statistics["powerups_used"] += 1

func _check_chapter_completion(chapter: int):
	"""Check if a chapter is fully completed."""
	var story_content = StoryContent.new()
	var battle_count = story_content.get_battle_count(chapter)
	var chapter_key = str(chapter)

	if completed_battles.has(chapter_key):
		if completed_battles[chapter_key].size() >= battle_count:
			if chapter not in completed_chapters:
				completed_chapters.append(chapter)

			# Advance to next chapter
			current_chapter = chapter + 1
			current_battle = 0

func _check_powerup_unlocks():
	"""Unlock new powerups based on progress."""
	# Unlock powerups at certain milestones
	var unlock_schedule = {
		2: ["smoke", "paratroopers"],
		4: ["recon", "medic"],
		6: ["nuke", "teleport"],
		8: ["freeze", "forcefield"],
		10: ["mind_control"],
		15: ["laser"],
		20: ["chopper"]
	}

	for wins_needed in unlock_schedule:
		if total_wins >= wins_needed:
			for powerup in unlock_schedule[wins_needed]:
				if powerup not in unlocked_powerups:
					unlocked_powerups.append(powerup)

func is_battle_completed(chapter: int, battle: int) -> bool:
	"""Check if a specific battle is completed."""
	var chapter_key = str(chapter)
	if completed_battles.has(chapter_key):
		return battle in completed_battles[chapter_key]
	return false

func is_chapter_completed(chapter: int) -> bool:
	"""Check if a chapter is completed."""
	return chapter in completed_chapters

func is_chapter_unlocked(chapter: int) -> bool:
	"""Check if a chapter is unlocked (playable)."""
	if chapter == 0:
		return true
	return is_chapter_completed(chapter - 1)

func get_current_progress() -> Dictionary:
	"""Get current progress as dictionary."""
	return {
		"chapter": current_chapter,
		"battle": current_battle,
		"wins": total_wins,
		"losses": total_losses
	}

func get_completion_percentage() -> float:
	"""Get overall completion percentage."""
	var story_content = StoryContent.new()
	var total_battles = 0
	var completed_count = 0

	for i in range(story_content.get_chapter_count()):
		total_battles += story_content.get_battle_count(i)
		var chapter_key = str(i)
		if completed_battles.has(chapter_key):
			completed_count += completed_battles[chapter_key].size()

	if total_battles == 0:
		return 0.0

	return (float(completed_count) / float(total_battles)) * 100.0

func get_win_rate() -> float:
	"""Get win rate percentage."""
	var total = total_wins + total_losses
	if total == 0:
		return 0.0
	return (float(total_wins) / float(total)) * 100.0

func has_save() -> bool:
	"""Check if a save file exists."""
	return FileAccess.file_exists(SAVE_PATH)

func delete_save():
	"""Delete the save file."""
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
