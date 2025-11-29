extends Control

func _on_chapter_pressed(chapter_num: int):
	# Store selected chapter and start game
	# For now, just go to regular game
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
