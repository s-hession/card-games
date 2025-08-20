extends Node2D

const CARD = preload("res://Scenes/card.tscn")

var hand: Array

@rpc("authority","unreliable", "call_local")
func add_to_hand(suit, rank):
	var card = CARD.instantiate()
	card.init_card(suit, rank)
	add_child(card)
	hand.append(card)

func print_hand():
	var peer_id = multiplayer.get_unique_id()
	var txt:= "PLAYER HAND %s:   " % peer_id
	for card in hand:
		txt += str(card._rank) + " of " + str(card._suit) + "S, "
	txt = txt.trim_suffix(", ")
	print(txt)

@rpc("authority","unreliable", "call_local")
func show_hand(): #TODO give cards ID, remove from hand by id, signal
	#region Display Hand vars
	var card_idx:int =0 #TODO set here?
	var middle_card_pos:Vector2 = Vector2(600,450)
	var oscilate:int = 1
	var increment_dist:float = 0
	var increment_rot:float = 0
	var x_dist:float = 80
	var y_dist:float = 2
	var rot:float = 2.5
	if hand.size() % 2 == 0:
		increment_dist = 0.5
		increment_rot = 0.5
	#endregion
	for card in hand:
		middle_card_pos = Vector2(middle_card_pos.x + oscilate*increment_dist*x_dist, middle_card_pos.y + increment_rot*y_dist)
		card.global_position = middle_card_pos
		card.rotation_degrees = oscilate*increment_rot*rot
		card.init_transform(card_idx) #TODO rename
		if oscilate == 1:
			increment_rot += 1
		increment_dist += 1
		oscilate *= -1
		card_idx += 1

func remove_from_hand(idx:int):
	for card in hand: #TODO slow
		if card._index == idx:
			hand.erase(card)
			break
	show_hand()
