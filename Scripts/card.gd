extends Node2D

var _rank
var _suit

#func init_card(suit:Enums.SUIT, rank:Enums.RANK):
func init_card(suit, rank):
	_suit = suit
	_rank = rank
