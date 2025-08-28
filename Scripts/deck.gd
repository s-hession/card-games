extends Node2D


const CARD = preload("res://Scenes/card.tscn")

var current_deck: Array
var discarded_deck: Array
var deck_template: Resource
var deck_size: int 

var msg_deck_not_full:= "Deck does not contain %s cards"

func create_deck(template):
	deck_template = template
	deck_size = deck_template.deck_size
	create_cards()

func create_cards():
	var ranks = Enums.RANK
	if deck_template.use_jokers:
		ranks = Enums.RANK_J
	for suit in Enums.SUIT:
		for rank in ranks:
			var card = CARD.instantiate()
			card.init_card(suit, rank)
			current_deck.append(card)
	current_deck.shuffle()

func shuffle():
	if !is_deck_full():
		return
	current_deck.shuffle()
	
func is_deck_full() -> bool:
	if current_deck.size() != deck_size:
		print(msg_deck_not_full % str(deck_size)) #TODO
		return false
	return true
	

#func TODO_create_cards():
	#var ranks = Enums.RANK
	#if deck_template.use_jokers:
		#ranks = Enums.RANK_J
	#var temp_ranks
	#if deck_size != 52:
		#for val in ranks:
			#if ranks[val] >= deck_template.min_rank -2:
				#temp_ranks[val] = ranks[val]
	#ranks = temp_ranks
	#for suit in Enums.SUIT:
		#for rank in Enums.RANK:
			#var card = CARD.instantiate()
			#card.init_card(suit, rank)
			#current_deck.append(card)
	#current_deck.shuffle()
