extends Node2D

var label: Label

var _rank
var _suit
var text:String = "%s of %sS"
var _current_position
var _current_rotation
var _index:int

var b_mouse_over:bool =false
var selected:bool = false
var other_card_selected:bool = false
var b_played:bool = false

var hover_growth_scale:float = 1.5
var selected_growth_scale:float = 1.2
var played_location := Vector2(550,200)
var opponent_played_offset:= Vector2(-200, -50)
var opponent_played_rotation:int = 120

func _ready() -> void:
	SignalBus.CardSelected.connect(card_selected)

func card_selected(select:bool):
	if !selected:
		other_card_selected = select

func _physics_process(delta: float) -> void:
	if !b_played:
		clicked()

func clicked():
	if b_mouse_over and Input.is_action_just_pressed("select") and !other_card_selected: #TODO enums/ controller
		selected = !selected
		SignalBus.CardSelected.emit(selected)
		#TODO implement turns 
		if selected:
			SignalBus.InfoCardSelected.emit(self)
			scale *= selected_growth_scale
		else:
			SignalBus.InfoCardSelected.emit(null)
			scale /= selected_growth_scale

#func init_card(suit:Enums.SUIT, rank:Enums.RANK):
func init_card(suit, rank):
	_suit = suit
	_rank = rank
	label = $ColorRect/Label
	label.text = text % [str(_rank),  str(_suit)]

func init_transform(idx:int):
	_index = idx
	_current_position = position
	_current_rotation = rotation

func played():
	b_played = true
	position = played_location
	scale /= (hover_growth_scale * selected_growth_scale)
	get_parent().remove_from_hand(_index) #TODO signal?
	SignalBus.CardSelected.emit(false)

func played_by_opponent():
	var pos := played_location + opponent_played_offset #change for y addition but x subtration
	global_position = pos
	rotation_degrees = opponent_played_rotation
	selected = true
	b_played = true

func _on_control_mouse_entered() -> void:
	b_mouse_over = true
	if selected:
		return
	scale *= hover_growth_scale
	rotation_degrees = 0
	position = Vector2(_current_position.x, 400)

func _on_control_mouse_exited() -> void:
	b_mouse_over = false
	if selected:
		return
	scale /= hover_growth_scale
	rotation = _current_rotation
	position = _current_position
