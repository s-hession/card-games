extends Node2D

const CARD = preload("res://Scenes/card.tscn")

var hand: Array

@rpc("authority","unreliable", "call_local")
func show_hand():
	var peer_id = multiplayer.get_unique_id()
	var txt:= "PLAYER HAND %s:   " % peer_id
	for card in hand:
		txt += str(card._rank) + " of " + str(card._suit) + "S, "
	txt = txt.trim_suffix(", ")
	print(txt)

@rpc("authority","unreliable", "call_local")
func add_to_hand(suit, rank):
	var card = CARD.instantiate()
	card.init_card(suit, rank)
	hand.append(card)
