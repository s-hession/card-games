extends Control

const GAME:= preload("res://scenes/game.tscn") #TODO game manager

func _on_host_button_pressed() -> void:
	var game = GAME.instantiate()
	get_tree().get_root().add_child(game)
	game.create_game()
	queue_free()


func _on_join_button_pressed() -> void:
	var game = GAME.instantiate()
	get_tree().get_root().add_child(game)
	game.join_game()
	queue_free()
