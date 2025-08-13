extends Node2D

var hand: Array

func show_hand():
	var txt:= "PLAYER HAND:   "
	for card in hand:
		txt += str(card._rank) + " of " + str(card._suit) + "S, "
	txt = txt.trim_suffix(", ")
	print(txt)

func add_to_hand(card):
	hand.append(card)
