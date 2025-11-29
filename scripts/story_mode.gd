extends Node

# Story Mode Singleton - Campaign with chapters, battles, and progression
# Exact replica of pygame story_mode.py

var current_chapter: int = 0
var current_battle: int = 0
var completed_battles: Array = []
var unlocked_chapters: Array = []
var seen_opening_crawls: Array = []

# All 9 chapters with battles
var chapters: Array = [
	{
		"id": "chapter_1",
		"title": "Pawn's Front",
		"opening_crawl": [
			"STRIKE CHESS",
			"",
			"Year 2067. The world is fractured.",
			"Governments have collapsed. Corporations rule.",
			"Warlords control what remains.",
			"",
			"You are a Commander for VANGUARD PMC.",
			"One of dozens of private military companies",
			"fighting for whoever pays the highest price.",
			"",
			"Your first real combat assignment:",
			"Clear forest insurgents from the northern sector.",
			"Standard contract. Routine operation.",
			"",
			"Simple work. Easy money.",
			"",
			"But in this world, nothing is ever simple.",
			"And everyone has a hidden agenda...",
		],
		"intro": [
			"Your first combat op for Vanguard PMC.",
			"Clear forest insurgents from woodland territory.",
			"",
			"Handler 'Overwatch' will guide you through comms.",
			"Prove yourself as PMC commander.",
		],
		"battles": [
			{
				"id": "forest_scout",
				"opponent": "Forest Scout",
				"difficulty": "recruit",
				"portrait": "BOT",
				"affiliation": "FOREST INSURGENTS",
				"rank": "GUERRILLA FIGHTER",
				"threat_level": "MINIMAL",
				"classification": "IRREGULAR",
				"specialization": "Forest Tactics",
				"pre_battle": [
					"OVERWATCH: Commander, this is Overwatch. I'll be your handler.",
					"OVERWATCH: First contact ahead. Forest insurgent scout.",
					"OVERWATCH: Keep it simple. Take the center, apply pressure.",
					"OVERWATCH: Show me what Vanguard PMC training taught you."
				],
				"victory": [
					"OVERWATCH: Clean work, Commander. Target neutralized.",
					"OVERWATCH: Moving to next objective.",
					"*First combat success. You're proving yourself.*"
				],
				"defeat": [
					"OVERWATCH: Commander down. Mission failed.",
					"OVERWATCH: Regroup and try again."
				],
				"special_rules": {
					"player_starting_points": 0,
					"tutorial_hints": true
				}
			},
			{
				"id": "insurgent_leader",
				"opponent": "Insurgent Leader",
				"difficulty": "rookie",
				"portrait": "SGT",
				"affiliation": "FOREST INSURGENTS",
				"rank": "CELL COMMANDER",
				"threat_level": "MODERATE",
				"classification": "GUERRILLA",
				"specialization": "Ambush Tactics",
				"pre_battle": [
					"LEADER: You corporate dogs think you can just walk into our forest?",
					"LEADER: This is our territory. We know every tree, every path.",
					"LEADER: Your fancy PMC tactics won't save you here.",
					"LEADER: Let's see if you're as good as they say."
				],
				"victory": [
					"LEADER: Fall back! We can't hold this position!",
					"LEADER: Retreat into the deep forest!",
					"*The insurgents scatter. Mission complete.*",
					"OVERWATCH: Good work, Commander. Vanguard is impressed."
				],
				"defeat": [
					"LEADER: The forest protects us. You never had a chance.",
					"LEADER: Tell your PMC we're not going anywhere."
				],
				"special_rules": {
					"enemy_starting_points": 2
				}
			}
		]
	},
	{
		"id": "chapter_2",
		"title": "Bishop's Walk",
		"intro": [
			"Secure the river delta for resource extraction company.",
			"Clear riverboat raiders from the waterway.",
			"",
			"Enemy tactics seem sophisticated.",
			"These aren't just random raiders - they're trained.",
		],
		"battles": [
			{
				"id": "river_patrol",
				"opponent": "River Patrol",
				"difficulty": "soldier",
				"portrait": "SCT",
				"pre_battle": [
					"PATROL: Got contacts on the waterway. Multiple signatures.",
					"PATROL: These ain't your typical river pirates.",
					"PATROL: We've got training. Military grade.",
					"PATROL: PMCs think they can just roll in here? Let's teach 'em."
				],
				"victory": [
					"PATROL: We're taking too much fire! Fall back!",
					"PATROL: Abandon the patrol boats!",
					"*The river patrol retreats downstream*"
				],
				"defeat": [
					"PATROL: River's ours. Tell your corpo clients that.",
					"PATROL: Another PMC down. Easy money."
				],
				"special_rules": {
					"enemy_starting_points": 3
				}
			},
			{
				"id": "river_boss",
				"opponent": "River Boss",
				"difficulty": "veteran",
				"portrait": "CMD",
				"pre_battle": [
					"BOSS: So Vanguard PMC sends their best to my river?",
					"BOSS: I've been running this waterway for five years.",
					"BOSS: Corpo money can't buy what we have - loyalty and skill.",
					"BOSS: Your client won't get their resource extraction site."
				],
				"victory": [
					"BOSS: You're better than I thought... damn PMC training.",
					"BOSS: Fall back! Get the boats out of here!",
					"BOSS: This isn't over. We'll be back.",
					"*River Boss retreats. The delta is secure.*"
				],
				"defeat": [
					"BOSS: Tell your corpo clients we're staying.",
					"BOSS: This river belongs to us, not them."
				],
				"special_rules": {
					"enemy_starting_points": 4
				}
			}
		]
	},
	{
		"id": "chapter_3",
		"title": "Gambit Gorge",
		"intro": [
			"Client: Sovereign Corp logistics company.",
			"Fight through canyon system to secure supply route.",
			"",
			"Intel suggests enemy was waiting - they knew you were coming.",
			"First hint something larger is happening.",
		],
		"battles": [
			{
				"id": "canyon_defender",
				"opponent": "Canyon Defender",
				"difficulty": "elite",
				"portrait": "DR",
				"pre_battle": [
					"DEFENDER: PMC convoy approaching through the gorge.",
					"DEFENDER: They were warned this route is hostile.",
					"DEFENDER: We've got high ground advantage on every position.",
					"DEFENDER: Sovereign Corp should've picked a different path."
				],
				"victory": [
					"DEFENDER: They flanked us! How did they know our positions?",
					"DEFENDER: Pull back to secondary defenses!",
					"*Canyon defenders retreat deeper into the gorge*"
				],
				"defeat": [
					"DEFENDER: The canyon holds. Like it always does.",
					"DEFENDER: Tell Sovereign their supply route is closed."
				],
				"special_rules": {
					"enemy_starting_points": 5
				}
			},
			{
				"id": "entrenched_commander",
				"opponent": "Entrenched Commander",
				"difficulty": "elite",
				"portrait": "CHP",
				"pre_battle": [
					"COMMANDER: You made it this far, PMC. Impressive.",
					"COMMANDER: But we knew you were coming. Every step.",
					"COMMANDER: Someone tipped us off about Sovereign's contract.",
					"COMMANDER: Makes you wonder who's really calling the shots, doesn't it?"
				],
				"victory": [
					"COMMANDER: Damn... you're good. Real good.",
					"COMMANDER: Canyon's yours. For now.",
					"COMMANDER: But ask yourself - who benefits from all this fighting?",
					"*Commander retreats. The canyon is clear... but something feels wrong.*"
				],
				"defeat": [
					"COMMANDER: Gambit Gorge remains impassable.",
					"COMMANDER: Tell Sovereign Corp we send our regards."
				],
				"special_rules": {
					"enemy_starting_points": 6
				}
			}
		]
	},
	{
		"id": "chapter_4",
		"title": "Rookspire",
		"intro": [
			"Client: Iron Meridian Corp.",
			"Assault desert stronghold held by rival PMC forces.",
			"",
			"They fight EXACTLY like you - same training, same gear.",
			"You find their orders: same employer. General Kaine.",
		],
		"battles": [
			{
				"id": "rival_pmc_squad",
				"opponent": "Rival PMC Squad",
				"difficulty": "commander",
				"portrait": "GEN",
				"pre_battle": [
					"SQUAD LEAD: Contact! We've got Vanguard PMC incoming!",
					"SQUAD LEAD: Why are we fighting other mercs? Doesn't matter. Orders are orders.",
					"SQUAD LEAD: They move like us. Trained the same way.",
					"SQUAD LEAD: Let's see who's better."
				],
				"victory": [
					"SQUAD LEAD: Pull back! We're taking heavy losses!",
					"SQUAD LEAD: Damn... they're good...",
					"*You search the stronghold ruins. Find intel documents.*",
					"OVERWATCH: Commander, you need to see this. Their orders. Same employer."
				],
				"defeat": [
					"SQUAD LEAD: Target down. Rookspire secure.",
					"SQUAD LEAD: Just another PMC contract."
				],
				"special_rules": {
					"enemy_starting_points": 7
				}
			},
			{
				"id": "enemy_commander",
				"opponent": "Enemy Commander",
				"difficulty": "commander",
				"portrait": "ASN",
				"pre_battle": [
					"COMMANDER: So you found the orders. You know the truth now.",
					"COMMANDER: General Kaine contracts us all. Plays us against each other.",
					"COMMANDER: We're all just pawns in his game.",
					"COMMANDER: But I've got a job to do. Same as you."
				],
				"victory": [
					"COMMANDER: You win. Rookspire is yours.",
					"COMMANDER: But it won't change anything. Kaine's got more like us.",
					"COMMANDER: Good luck, merc. You're gonna need it.",
					"*The pieces are starting to fall into place. General Kaine.*"
				],
				"defeat": [
					"COMMANDER: Rookspire holds. Contract complete.",
					"COMMANDER: Just business. Nothing personal."
				],
				"special_rules": {
					"enemy_starting_points": 8
				}
			}
		]
	},
	{
		"id": "chapter_5",
		"title": "Knight's Frost",
		"intro": [
			"Orders: Eliminate all hostiles in mountain settlement.",
			"You arrive to find civilians, not military. Families.",
			"",
			"Orders are clear: No survivors.",
			"YOU REFUSE. Go rogue. Your PMC now hunts you.",
		],
		"battles": [
			{
				"id": "settlement_patrol",
				"opponent": "Settlement Patrol",
				"difficulty": "commander",
				"portrait": "ILU",
				"pre_battle": [
					"OVERWATCH: Commander, new orders from Kaine. Eliminate all targets.",
					"OVERWATCH: Intel says hostile settlement. Armed insurgents.",
					"*You arrive at the coordinates. It's not a military target.*",
					"PATROL: Who are you? We're just families trying to survive!",
					"PATROL: Please, we have children here! We're not soldiers!"
				],
				"victory": [
					"PATROL: Thank you... thank you for not...",
					"PATROL: We'll evacuate immediately. We're gone.",
					"*You cut comms with Overwatch. Refuse the orders.*",
					"OVERWATCH: Commander? Commander, respond! ...He's gone rogue."
				],
				"defeat": [
					"PATROL: You're no better than Kaine...",
					"*This path is not who you are.*"
				],
				"special_rules": {
					"enemy_starting_points": 9
				}
			},
			{
				"id": "kaine_loyalist",
				"opponent": "Kaine Loyalist",
				"difficulty": "commander",
				"portrait": "SPY",
				"pre_battle": [
					"LOYALIST: All units, deserter located. Orders: terminate.",
					"LOYALIST: You refused a direct order, Commander.",
					"LOYALIST: Kaine doesn't tolerate weakness or conscience.",
					"LOYALIST: You're done. Vanguard PMC is hunting you now."
				],
				"victory": [
					"LOYALIST: Damn traitor... you'll pay for this...",
					"*More will come. You're marked for death.*",
					"*But you couldn't kill those civilians. Some lines can't be crossed.*",
					"OVERWATCH: All units, priority target. Commander is hostile. Shoot on sight."
				],
				"defeat": [
					"LOYALIST: Deserter eliminated. Target down.",
					"LOYALIST: Orders are orders. You should've remembered that."
				],
				"special_rules": {
					"enemy_starting_points": 10
				}
			}
		]
	},
	{
		"id": "chapter_6",
		"title": "King's Hold",
		"intro": [
			"Hunted through frozen wilderness by your former PMC.",
			"They know all your moves - you trained together.",
			"",
			"About to be captured when another group intervenes.",
			"'The Outcasts' - deserters who also refused orders.",
		],
		"battles": [
			{
				"id": "hunter_squad",
				"opponent": "Hunter Squad",
				"difficulty": "commander",
				"portrait": "ENG",
				"pre_battle": [
					"HUNTER: Target acquired. It's the Commander.",
					"HUNTER: They trained us. Know all our tactics.",
					"HUNTER: Doesn't matter. We have orders. Hunt them down.",
					"HUNTER: Sorry, Commander. Just business."
				],
				"victory": [
					"HUNTER: Damn... they're too good...",
					"HUNTER: All units, target escaped. Regroup!",
					"*You're surrounded. About to be captured when...*",
					"???: Need a hand? We've been tracking you."
				],
				"defeat": [
					"HUNTER: Target down. Commander neutralized.",
					"HUNTER: Deserter eliminated. Returning to base."
				],
				"special_rules": {
					"enemy_starting_points": 11
				}
			},
			{
				"id": "hunter_squad_leader",
				"opponent": "Hunter Squad Leader",
				"difficulty": "champion",
				"portrait": "BMB",
				"pre_battle": [
					"LEADER: You taught me everything, Commander.",
					"LEADER: But Vanguard pays me to forget that.",
					"LEADER: Kaine wants you dead. Big bounty on your head.",
					"LEADER: Let's finish this."
				],
				"victory": [
					"LEADER: You always were... the best...",
					"*The Outcasts arrive. Fire suppressing Vanguard forces.*",
					"SHEPHERD: Come with us if you want to live, Commander.",
					"SHEPHERD: We're deserters too. We fight Kaine now. Join us."
				],
				"defeat": [
					"LEADER: Target terminated. Commander is down.",
					"LEADER: Bounty collected. Kaine will be pleased."
				],
				"special_rules": {
					"enemy_starting_points": 12
				}
			}
		]
	},
	{
		"id": "chapter_7",
		"title": "Isle of Check",
		"intro": [
			"Intel reveals General Kaine's HQ location.",
			"Offshore island fortress in the Pacific.",
			"",
			"The Outcasts plan amphibious assault.",
			"Beach landing. This is the final push.",
		],
		"battles": [
			{
				"id": "beach_defender",
				"opponent": "Coastal Defense",
				"difficulty": "champion",
				"portrait": "MEC",
				"pre_battle": [
					"SHEPHERD: This is it. Kaine's island fortress.",
					"SHEPHERD: We go in hard and fast. Beach assault.",
					"DEFENSE: Incoming boats! All units, defensive positions!",
					"DEFENSE: They're assaulting the beach! Hold the line!"
				],
				"victory": [
					"DEFENSE: They've breached the beach!",
					"DEFENSE: Fall back to the jungle!",
					"*Coastal defenses are overrun*"
				],
				"defeat": [
					"DEFENSE: The beaches remain secure.",
					"DEFENSE: Another failed island invasion."
				],
				"special_rules": {
					"enemy_starting_points": 13
				}
			},
			{
				"id": "coastal_commander",
				"opponent": "Coastal Commander",
				"difficulty": "champion",
				"portrait": "TIM",
				"pre_battle": [
					"COMMANDER: Impressive. You breached the beach defenses.",
					"COMMANDER: But the island fortress has multiple defense rings.",
					"COMMANDER: General Kaine pays well for loyalty.",
					"COMMANDER: You won't reach the main compound."
				],
				"victory": [
					"COMMANDER: The island's lost! Kaine... you bastard...",
					"COMMANDER: All units evacuate! Fall back to the mainland!",
					"SHEPHERD: We did it, Commander. The beach is ours.",
					"SHEPHERD: Tomorrow, we hit the industrial complex. End this."
				],
				"defeat": [
					"COMMANDER: Island fortress stands. Kaine remains secure.",
					"COMMANDER: Another assault repelled."
				],
				"special_rules": {
					"enemy_starting_points": 14
				}
			}
		]
	},
	{
		"id": "chapter_8",
		"title": "Ironworks",
		"intro": [
			"Fight through Kaine's industrial fortress complex.",
			"Elite guards, mechanized units, everything.",
			"",
			"Heavy casualties on both sides. Brutal combat.",
			"Shepherd sacrifices himself so you can advance.",
		],
		"battles": [
			{
				"id": "elite_guard",
				"opponent": "Elite Guard",
				"difficulty": "champion",
				"portrait": "NEC",
				"pre_battle": [
					"SHEPHERD: This is Kaine's last line of defense. Elite guards.",
					"SHEPHERD: We push through here, we reach his command center.",
					"GUARD: Hostiles breaching the industrial complex!",
					"GUARD: General Kaine wants them alive. Or dead. Preferably dead."
				],
				"victory": [
					"GUARD: They're breaking through! Call for reinforcements!",
					"GUARD: Fall back to the inner compound!",
					"SHEPHERD: We're almost there, Commander. Keep pushing!",
					"*Heavy casualties on both sides. The fighting is brutal.*"
				],
				"defeat": [
					"GUARD: Insurgents eliminated. Complex secure.",
					"GUARD: Kaine's fortress holds strong."
				],
				"special_rules": {
					"enemy_starting_points": 15
				}
			},
			{
				"id": "mechanized_unit",
				"opponent": "Mechanized Unit",
				"difficulty": "master",
				"portrait": "ORC",
				"pre_battle": [
					"MECH: Deploying heavy combat units. Target the leaders.",
					"SHEPHERD: Mechs! Everyone take cover!",
					"SHEPHERD: Commander, get to the command center! I'll hold them here!",
					"SHEPHERD: Go! I'll buy you time! End Kaine!"
				],
				"victory": [
					"MECH: Unit destroyed. Combat effectiveness: zero.",
					"*You hear the explosion behind you. Shepherd's last stand.*",
					"*Radio silence. He's gone. He bought you the time you needed.*",
					"*For Shepherd. For The Outcasts. For everyone Kaine hurt.*"
				],
				"defeat": [
					"MECH: All targets eliminated. Threat neutralized.",
					"MECH: Industrial fortress remains secure."
				],
				"special_rules": {
					"enemy_starting_points": 16
				}
			}
		]
	},
	{
		"id": "chapter_9",
		"title": "Knightlight City",
		"intro": [
			"Enter Kaine's penthouse command center.",
			"Neon-lit cityscape below. Face to face with the tyrant.",
			"",
			"Time to end General Kaine's reign.",
			"This is the final confrontation.",
		],
		"battles": [
			{
				"id": "kaine_bodyguard",
				"opponent": "Kaine's Bodyguard",
				"difficulty": "master",
				"portrait": "BER",
				"pre_battle": [
					"*You enter the penthouse. Neon lights illuminate the city below.*",
					"BODYGUARD: One more obstacle before you reach the General.",
					"BODYGUARD: I've been paid very well to stop you here.",
					"BODYGUARD: Nothing personal. Just the job."
				],
				"victory": [
					"BODYGUARD: You earned your way here... Commander...",
					"*The bodyguard falls. The path to Kaine is clear.*",
					"*You push open the final door.*"
				],
				"defeat": [
					"BODYGUARD: Contract fulfilled. Target eliminated.",
					"BODYGUARD: Kaine pays his debts. Unlike some."
				],
				"special_rules": {
					"enemy_starting_points": 17
				}
			},
			{
				"id": "general_kaine",
				"opponent": "General Kaine",
				"difficulty": "master",
				"portrait": "GM",
				"pre_battle": [
					"KAINE: So you've reached my penthouse. Impressive.",
					"KAINE: You threw away everything. For what? Conscience? Morality?",
					"KAINE: In this world, only the strong survive.",
					"KAINE: I gave you purpose. Structure. A place in the new order.",
					"KAINE: You want to judge me? You pulled the trigger."
				],
				"victory": [
					"KAINE: You... actually beat me...",
					"KAINE: All my plans... my empire...",
					"KAINE: You're stronger than I thought, Commander.",
					"*General Kaine is defeated. His reign ends here.*",
					"",
					"VICTORY!",
					"Kaine's network is dismantled. The PMCs are freed.",
					"For Shepherd. For The Outcasts. For everyone who refused."
				],
				"defeat": [
					"KAINE: As I calculated. I'm always three moves ahead.",
					"KAINE: Soldiers ARE murderers. I just pointed you at targets.",
					"KAINE: Your conscience made you weak."
				],
				"special_rules": {
					"enemy_starting_points": 20,
					"boss_battle": true,
					"dramatic_music": true
				}
			}
		]
	}
]

# Enemy intel data for each chapter (displayed on campaign map)
var enemy_intel: Dictionary = {
	0: {
		"enemies": "Forest Insurgents",
		"special": "Guerrilla Tactics",
		"boss": "Unnamed Leader",
		"description": "First combat op. Clear insurgents from woodland territory. Prove yourself as PMC commander."
	},
	1: {
		"enemies": "Riverboat Raiders",
		"special": "Amphibious Combat",
		"boss": "River Boss",
		"description": "Secure waterway for corporate client. Enemy shows sophisticated tactics - more than just raiders."
	},
	2: {
		"enemies": "Canyon Defenders",
		"special": "High Ground Control",
		"boss": "Entrenched Commander",
		"description": "Fight through canyon passages. Enemy seems prepared. Question: who tipped them off?"
	},
	3: {
		"enemies": "Rival PMC Forces",
		"special": "Professional Training",
		"boss": "Enemy Commander",
		"description": "Assault desert fortress held by rival PMCs. They fight like you. Find intel on General Kaine."
	},
	4: {
		"enemies": "Mountain Patrol",
		"special": "Cold Weather Ops",
		"boss": "Settlement Leader",
		"description": "Orders to eliminate civilian settlement. Refuse and go rogue. Your PMC now hunts you."
	},
	5: {
		"enemies": "Your Former PMC",
		"special": "They Know Your Tactics",
		"boss": "Hunter Squad Leader",
		"description": "Survive the hunt. Meet 'The Outcasts' - deserters who also refused immoral orders."
	},
	6: {
		"enemies": "Kaine's Naval Defense",
		"special": "Island Fortifications",
		"boss": "Coastal Commander",
		"description": "Beach assault on General Kaine's island HQ with The Outcasts. Time to fight back."
	},
	7: {
		"enemies": "Elite Guards",
		"special": "Mechanized Units",
		"boss": "Shepherd (Sacrifice)",
		"description": "Fight through Kaine's industrial complex. Heavy casualties. Shepherd sacrifices himself."
	},
	8: {
		"enemies": "Kaine's Best Forces",
		"special": "Enhanced Tactics",
		"boss": "General Kaine",
		"description": "Final confrontation in high-rise command center. End the tyrant's reign. Choose your path."
	}
}

func _ready():
	# Initialize all chapters as unlocked for testing (like pygame version)
	unlocked_chapters = []
	for i in range(9):
		unlocked_chapters.append(true)

	load_progress()

func get_current_chapter() -> Dictionary:
	"""Get the current chapter data."""
	if current_chapter < chapters.size():
		return chapters[current_chapter]
	return {}

func get_current_battle() -> Dictionary:
	"""Get the current battle data."""
	var chapter = get_current_chapter()
	if chapter.size() > 0 and current_battle < chapter["battles"].size():
		return chapter["battles"][current_battle]
	return {}

func select_chapter(chapter_index: int) -> bool:
	"""Select a chapter to play."""
	if chapter_index >= 0 and chapter_index < chapters.size() and unlocked_chapters[chapter_index]:
		current_chapter = chapter_index
		current_battle = 0
		return true
	return false

func complete_battle(battle_id: String, won: bool = true):
	"""Mark a battle as complete."""
	if won and not completed_battles.has(battle_id):
		completed_battles.append(battle_id)

		# Check if we should unlock the next chapter
		var chapter = get_current_chapter()
		if chapter.size() > 0:
			# Check if all battles in current chapter are complete
			var all_complete = true
			for battle in chapter["battles"]:
				if not completed_battles.has(battle["id"]):
					all_complete = false
					break

			if all_complete:
				# Unlock next chapter
				var next_chapter_idx = current_chapter + 1
				if next_chapter_idx < chapters.size():
					unlocked_chapters[next_chapter_idx] = true

		save_progress()

func is_battle_completed(battle_id: String) -> bool:
	"""Check if a battle has been completed."""
	return completed_battles.has(battle_id)

func is_battle_unlocked(battle_id: String, chapter_index: int = -1) -> bool:
	"""Check if a battle is unlocked."""
	# Boot Camp (chapter 0) battles are ALWAYS unlocked for training
	if battle_id in ["training_bot", "sergeant_cole"]:
		return true

	# If chapter is not unlocked, battle is not unlocked
	if chapter_index >= 0:
		if not unlocked_chapters[chapter_index]:
			return false

	# First battle of each chapter is always unlocked if chapter is unlocked
	for chapter_idx in range(chapters.size()):
		if chapter_index >= 0 and chapter_idx != chapter_index:
			continue

		var chapter = chapters[chapter_idx]
		for battle_idx in range(chapter["battles"].size()):
			var battle = chapter["battles"][battle_idx]
			if battle["id"] == battle_id:
				# First battle is always unlocked
				if battle_idx == 0:
					return true
				# Other battles need previous battle completed
				var prev_battle = chapter["battles"][battle_idx - 1]
				return completed_battles.has(prev_battle["id"])

	return false

func save_progress():
	"""Save story mode progress."""
	var save_data = {
		"current_chapter": current_chapter,
		"current_battle": current_battle,
		"completed_battles": completed_battles,
		"unlocked_chapters": unlocked_chapters,
		"seen_opening_crawls": seen_opening_crawls
	}

	var file = FileAccess.open("user://story_progress.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_progress():
	"""Load story mode progress."""
	if FileAccess.file_exists("user://story_progress.json"):
		var file = FileAccess.open("user://story_progress.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			file.close()

			if parse_result == OK:
				var save_data = json.data
				current_chapter = save_data.get("current_chapter", 0)
				current_battle = save_data.get("current_battle", 0)
				completed_battles = save_data.get("completed_battles", [])
				seen_opening_crawls = save_data.get("seen_opening_crawls", [])
				# Keep all chapters unlocked for testing
				unlocked_chapters = []
				for i in range(9):
					unlocked_chapters.append(true)

func get_chapter_title(index: int) -> String:
	"""Get the title of a chapter by index."""
	if index >= 0 and index < chapters.size():
		return chapters[index]["title"]
	return ""

func get_enemy_intel_for_chapter(index: int) -> Dictionary:
	"""Get enemy intel data for a chapter."""
	if enemy_intel.has(index):
		return enemy_intel[index]
	return {}
