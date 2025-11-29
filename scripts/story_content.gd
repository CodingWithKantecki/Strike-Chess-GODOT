extends Node
class_name StoryContent

# Story Mode Content - All 9 chapters with dialogue, crawls, and battle data
# Matches pygame story_mode.py content

# Chapter data structure
var chapters: Array = [
	# CHAPTER 0: Tutorial
	{
		"name": "Training Grounds",
		"theme": "WCP",
		"weather": "NONE",
		"crawl": [
			"STRIKE CHESS",
			"",
			"The year is 2157.",
			"Chess has evolved beyond a game of pure intellect.",
			"",
			"With tactical powerups and devastating weapons,",
			"every match is a battle for survival.",
			"",
			"You are a new recruit,",
			"about to begin your journey...",
		],
		"intro_dialogue": [
			"COMMANDER: Welcome to the Strike Chess Academy, recruit.",
			"COMMANDER: Here you'll learn the basics of tactical chess warfare.",
			"COMMANDER: Don't let the familiar pieces fool you...",
			"COMMANDER: This isn't your grandfather's chess.",
		],
		"battles": [
			{
				"name": "Training Match 1",
				"difficulty": "recruit",
				"pre_dialogue": [
					"INSTRUCTOR: Let's start with the basics.",
					"INSTRUCTOR: Move your pieces. Capture the enemy.",
					"INSTRUCTOR: Simple enough, right?",
				],
				"post_dialogue": [
					"INSTRUCTOR: Good work, recruit!",
					"INSTRUCTOR: You're ready for more advanced training.",
				]
			},
			{
				"name": "Training Match 2",
				"difficulty": "recruit",
				"pre_dialogue": [
					"INSTRUCTOR: Now let's try using powerups.",
					"INSTRUCTOR: Capture pieces to earn points.",
					"INSTRUCTOR: Press TAB to open the powerup menu.",
				],
				"post_dialogue": [
					"INSTRUCTOR: Excellent!",
					"INSTRUCTOR: You've completed basic training.",
					"COMMANDER: Report to the front lines immediately.",
				]
			}
		]
	},

	# CHAPTER 1: First Deployment
	{
		"name": "First Blood",
		"theme": "JUNGLE",
		"weather": "NONE",
		"crawl": [
			"CHAPTER 1",
			"FIRST BLOOD",
			"",
			"Your training is complete.",
			"",
			"The enemy has invaded the Southern Territories.",
			"It's time to prove your worth",
			"on the battlefield.",
		],
		"intro_dialogue": [
			"COMMANDER: This is your first real mission, soldier.",
			"COMMANDER: The enemy is entrenched in the jungle.",
			"COMMANDER: Take them out. Show no mercy.",
		],
		"battles": [
			{
				"name": "Jungle Skirmish",
				"difficulty": "rookie",
				"pre_dialogue": [
					"SCOUT: Enemy spotted ahead!",
					"SCOUT: They don't look too experienced.",
					"YOU: Perfect. Let's move.",
				],
				"post_dialogue": [
					"YOU: Target neutralized.",
					"COMMANDER: Good work. Continue your advance.",
				]
			},
			{
				"name": "River Crossing",
				"difficulty": "rookie",
				"pre_dialogue": [
					"SCOUT: Sir, enemy forces blocking the river!",
					"YOU: We push through. No retreat.",
				],
				"post_dialogue": [
					"COMMANDER: Impressive. You've secured the crossing.",
					"COMMANDER: The path to the enemy base is open.",
				]
			}
		]
	},

	# CHAPTER 2: Rising Tensions
	{
		"name": "Rising Tensions",
		"theme": "JUNGLE",
		"weather": "FOG",
		"crawl": [
			"CHAPTER 2",
			"RISING TENSIONS",
			"",
			"Your victories have not gone unnoticed.",
			"",
			"The enemy is sending reinforcements.",
			"A fog has rolled in...",
			"making every move more dangerous.",
		],
		"intro_dialogue": [
			"COMMANDER: The fog will limit visibility.",
			"COMMANDER: But it works both ways.",
			"COMMANDER: Use it to your advantage.",
		],
		"battles": [
			{
				"name": "Fog of War",
				"difficulty": "soldier",
				"pre_dialogue": [
					"SCOUT: I can barely see anything!",
					"YOU: Stay alert. They're out there.",
				],
				"post_dialogue": [
					"YOU: Got them.",
					"SCOUT: How did you even see them?",
				]
			},
			{
				"name": "Blind Assault",
				"difficulty": "soldier",
				"pre_dialogue": [
					"COMMANDER: Enemy stronghold ahead.",
					"COMMANDER: The fog is our only cover.",
					"YOU: Then let's not waste it.",
				],
				"post_dialogue": [
					"COMMANDER: Stronghold captured!",
					"COMMANDER: You're becoming quite the tactician.",
				]
			}
		]
	},

	# CHAPTER 3: Storm Warning
	{
		"name": "Storm Warning",
		"theme": "JUNGLE",
		"weather": "RAIN",
		"crawl": [
			"CHAPTER 3",
			"STORM WARNING",
			"",
			"A massive storm approaches.",
			"",
			"The enemy thinks the weather",
			"will stop your advance.",
			"",
			"They are wrong.",
		],
		"intro_dialogue": [
			"COMMANDER: The storm is here.",
			"COMMANDER: Rain won't stop our operation.",
			"YOU: Nothing will.",
		],
		"battles": [
			{
				"name": "Thunder Strike",
				"difficulty": "veteran",
				"pre_dialogue": [
					"SCOUT: Lightning everywhere, sir!",
					"YOU: Good. Let them fear the storm.",
				],
				"post_dialogue": [
					"SCOUT: We're unstoppable!",
					"YOU: Don't get cocky. Stay focused.",
				]
			},
			{
				"name": "Flood Zone",
				"difficulty": "veteran",
				"pre_dialogue": [
					"COMMANDER: The river is flooding!",
					"COMMANDER: Complete your objective quickly!",
					"YOU: Understood. Moving out.",
				],
				"post_dialogue": [
					"COMMANDER: Mission complete.",
					"COMMANDER: The enemy is in full retreat.",
				]
			}
		]
	},

	# CHAPTER 4: The Counter-Offensive
	{
		"name": "Counter-Offensive",
		"theme": "JUNGLE",
		"weather": "NONE",
		"crawl": [
			"CHAPTER 4",
			"COUNTER-OFFENSIVE",
			"",
			"The storm has passed.",
			"",
			"But the enemy has regrouped",
			"and launched a massive counter-attack.",
			"",
			"Hold the line at all costs.",
		],
		"intro_dialogue": [
			"COMMANDER: They're throwing everything at us!",
			"COMMANDER: This is their last desperate push.",
			"YOU: Then let's make it count.",
		],
		"battles": [
			{
				"name": "Defensive Stand",
				"difficulty": "elite",
				"pre_dialogue": [
					"SCOUT: They just keep coming!",
					"YOU: Let them come. We're ready.",
				],
				"post_dialogue": [
					"SCOUT: The attack is faltering!",
					"YOU: Press the advantage!",
				]
			},
			{
				"name": "Breaking Point",
				"difficulty": "elite",
				"pre_dialogue": [
					"COMMANDER: This is it!",
					"COMMANDER: Break them now, or we lose everything!",
				],
				"post_dialogue": [
					"COMMANDER: VICTORY! The enemy is broken!",
					"COMMANDER: You've saved the entire front!",
				]
			}
		]
	},

	# CHAPTER 5: Winter Campaign
	{
		"name": "Winter Campaign",
		"theme": "JUNGLE",  # Would use winter theme if available
		"weather": "SNOW",
		"crawl": [
			"CHAPTER 5",
			"WINTER CAMPAIGN",
			"",
			"Months have passed.",
			"Winter has arrived.",
			"",
			"The enemy has retreated to",
			"their mountain stronghold.",
			"",
			"Now we take the fight to them.",
		],
		"intro_dialogue": [
			"COMMANDER: The cold is brutal.",
			"COMMANDER: But we must advance.",
			"YOU: The cold doesn't bother me.",
		],
		"battles": [
			{
				"name": "Frozen Valley",
				"difficulty": "commander",
				"pre_dialogue": [
					"SCOUT: The valley is frozen solid!",
					"YOU: Good footing. Let's go.",
				],
				"post_dialogue": [
					"SCOUT: The valley is ours!",
					"YOU: Onward. To the mountains.",
				]
			},
			{
				"name": "Mountain Pass",
				"difficulty": "commander",
				"pre_dialogue": [
					"COMMANDER: The mountain pass is heavily defended.",
					"COMMANDER: This won't be easy.",
					"YOU: Nothing worth doing ever is.",
				],
				"post_dialogue": [
					"COMMANDER: The pass is secured!",
					"COMMANDER: The enemy stronghold is within reach.",
				]
			}
		]
	},

	# CHAPTER 6: The Fortress
	{
		"name": "The Fortress",
		"theme": "CITY",
		"weather": "FOG",
		"crawl": [
			"CHAPTER 6",
			"THE FORTRESS",
			"",
			"The enemy's mountain fortress",
			"looms ahead.",
			"",
			"Its walls have never been breached.",
			"",
			"Until now.",
		],
		"intro_dialogue": [
			"COMMANDER: This is their last stronghold.",
			"COMMANDER: Take it, and we win the war.",
			"YOU: Consider it done.",
		],
		"battles": [
			{
				"name": "Outer Walls",
				"difficulty": "champion",
				"pre_dialogue": [
					"SCOUT: The walls are massive!",
					"YOU: Every wall has a weakness.",
				],
				"post_dialogue": [
					"YOU: The outer walls have fallen!",
					"COMMANDER: Excellent! Push into the keep!",
				]
			},
			{
				"name": "Inner Sanctum",
				"difficulty": "champion",
				"pre_dialogue": [
					"COMMANDER: The enemy general is inside!",
					"COMMANDER: Capture or eliminate!",
					"YOU: Understood.",
				],
				"post_dialogue": [
					"YOU: Target neutralized.",
					"COMMANDER: The fortress is ours!",
					"COMMANDER: But... something's wrong.",
				]
			}
		]
	},

	# CHAPTER 7: Betrayal
	{
		"name": "Betrayal",
		"theme": "CITY",
		"weather": "RAIN",
		"crawl": [
			"CHAPTER 7",
			"BETRAYAL",
			"",
			"It was a trap.",
			"",
			"The enemy general was a decoy.",
			"Your own commanders have betrayed you.",
			"",
			"Now you fight alone.",
		],
		"intro_dialogue": [
			"TRAITOR: Did you really think it would be that easy?",
			"TRAITOR: You've outlived your usefulness.",
			"YOU: You'll regret this.",
		],
		"battles": [
			{
				"name": "Surrounded",
				"difficulty": "master",
				"pre_dialogue": [
					"TRAITOR: Give up! You're surrounded!",
					"YOU: I've been in worse situations.",
				],
				"post_dialogue": [
					"YOU: Who's next?",
					"TRAITOR: Impossible!",
				]
			},
			{
				"name": "Escape",
				"difficulty": "master",
				"pre_dialogue": [
					"YOU: Time to get out of here.",
					"ALLY: Sir! I'm still loyal! This way!",
				],
				"post_dialogue": [
					"ALLY: We made it!",
					"YOU: Now we regroup. And we strike back.",
				]
			}
		]
	},

	# CHAPTER 8: Final Stand
	{
		"name": "Final Stand",
		"theme": "CITY",
		"weather": "NONE",
		"crawl": [
			"CHAPTER 8",
			"FINAL STAND",
			"",
			"You've gathered loyal forces.",
			"",
			"The traitors have seized control",
			"of the capital city.",
			"",
			"This ends today.",
		],
		"intro_dialogue": [
			"ALLY: Sir, the loyalists are ready.",
			"ALLY: We follow you to the end.",
			"YOU: Then let's end this.",
		],
		"battles": [
			{
				"name": "City Gates",
				"difficulty": "nexus",
				"pre_dialogue": [
					"TRAITOR: You actually came back?",
					"YOU: To watch you fall.",
				],
				"post_dialogue": [
					"YOU: The gates are open.",
					"ALLY: To the palace!",
				]
			},
			{
				"name": "The Throne",
				"difficulty": "nexus",
				"pre_dialogue": [
					"TRAITOR: This is MY kingdom now!",
					"YOU: A kingdom built on lies.",
					"YOU: It ends here.",
				],
				"post_dialogue": [
					"TRAITOR: No... this can't be...",
					"YOU: It's over.",
					"ALLY: Victory! The war is won!",
					"",
					"STRIKE CHESS",
					"",
					"THE END",
					"",
					"Thank you for playing.",
				]
			}
		]
	}
]

func get_chapter(index: int) -> Dictionary:
	"""Get chapter data by index."""
	if index >= 0 and index < chapters.size():
		return chapters[index]
	return {}

func get_chapter_count() -> int:
	"""Get total number of chapters."""
	return chapters.size()

func get_chapter_name(index: int) -> String:
	"""Get chapter name by index."""
	var chapter = get_chapter(index)
	return chapter.get("name", "Unknown Chapter")

func get_chapter_crawl(index: int) -> Array:
	"""Get opening crawl text for chapter."""
	var chapter = get_chapter(index)
	return chapter.get("crawl", [])

func get_chapter_theme(index: int) -> String:
	"""Get theme for chapter."""
	var chapter = get_chapter(index)
	return chapter.get("theme", "CITY")

func get_chapter_weather(index: int) -> String:
	"""Get weather for chapter."""
	var chapter = get_chapter(index)
	return chapter.get("weather", "NONE")

func get_battle_count(chapter_index: int) -> int:
	"""Get number of battles in chapter."""
	var chapter = get_chapter(chapter_index)
	var battles = chapter.get("battles", [])
	return battles.size()

func get_battle(chapter_index: int, battle_index: int) -> Dictionary:
	"""Get battle data."""
	var chapter = get_chapter(chapter_index)
	var battles = chapter.get("battles", [])
	if battle_index >= 0 and battle_index < battles.size():
		return battles[battle_index]
	return {}

func get_battle_difficulty(chapter_index: int, battle_index: int) -> String:
	"""Get difficulty for a specific battle."""
	var battle = get_battle(chapter_index, battle_index)
	return battle.get("difficulty", "medium")

func get_intro_dialogue(chapter_index: int) -> Array:
	"""Get intro dialogue for chapter."""
	var chapter = get_chapter(chapter_index)
	return chapter.get("intro_dialogue", [])

func get_pre_battle_dialogue(chapter_index: int, battle_index: int) -> Array:
	"""Get dialogue before a battle."""
	var battle = get_battle(chapter_index, battle_index)
	return battle.get("pre_dialogue", [])

func get_post_battle_dialogue(chapter_index: int, battle_index: int) -> Array:
	"""Get dialogue after a battle."""
	var battle = get_battle(chapter_index, battle_index)
	return battle.get("post_dialogue", [])
