extends Area2D

var b_mouse_over:bool = false

func _process(delta: float) -> void:
	if b_mouse_over and Input.is_action_just_pressed("select"):
		SignalBus.CardPlayed.emit()

func _on_mouse_entered() -> void:
	b_mouse_over = true

func _on_mouse_exited() -> void:
	b_mouse_over = false
