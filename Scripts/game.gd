extends Node2D

@export var deck_template: Resource

@onready var label := $Label
@onready var btn_start_game := $"Start Game Button"


var DECK = preload("res://Scenes/deck.tscn")
var PLAYER = preload("res://Scenes/player.tscn")

var _deck
var _player_nodes: Array
var players_required:int = 3
var _local_player
var _selected_card:Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {} 

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name"}

var players_loaded = 0

#change scene also
var TESTING:bool = false #TODO command line arg

func _ready():
	if TESTING:
		players_required = 1
		players = {1:"Name"}
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.allow_object_decoding = true
	player_info["name"] = randi() % 20 #TODO more detailed player info
	
	SignalBus.InfoCardSelected.connect(set_selected_card)
	SignalBus.CardPlayed.connect(attempt_card_played)

func update_label():
	label.text = str(players.size())

#region Multiplayer
#TODO create lobby scene
func join_game(address = ""):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	update_label()


func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

	players[1] = player_info
	player_connected.emit(1, player_info)
	update_label()


func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null
	players.clear()


# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)


# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		#if players_loaded == players.size():
			#$/root/Game.start_game()
			#players_loaded = 0

func _on_player_connected(id):
	_register_player.rpc_id(id, player_info)

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	update_label()
	player_count_reached()

func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)
	update_label()

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)

func _on_connected_fail():
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

func player_count_reached():
	if players.size() == players_required:
		btn_start_game.visible = true
#endregion

#region Game
@rpc("any_peer","unreliable", "call_local")
func start():
	if multiplayer.is_server():
		if players.size() != players_required:
			return
		remove_start_button.rpc()
		create_players.rpc()

func finish_setup():
	create_deck()
	deal()
	show_hands.rpc()

@rpc("authority","unreliable", "call_local")
func remove_start_button():
	btn_start_game.queue_free()

@rpc("authority","unreliable", "call_local")
func create_players():
	_local_player = PLAYER.instantiate()
	add_child(_local_player)
	add_to_player_list.rpc_id(1, _local_player) #TODO dont pass serialized object

@rpc("any_peer","unreliable", "call_local")
func add_to_player_list(player:Node2D): #TODO other way to ensure all player objects ready
	_player_nodes.append(player)
	if _player_nodes.size() == players_required:
		finish_setup()

func create_deck():
	if multiplayer.is_server():
		_deck = DECK.instantiate()
		_deck.create_deck(deck_template)
		add_child(_deck)

@rpc("authority","unreliable", "call_local")
func deal():
	if !_deck.is_deck_full():
		return
	var i = 0
	var player_ids = players.keys()
	for card in _deck.current_deck:
		add_card_to_hand.rpc_id(player_ids[i], card._suit, card._rank) #TODO obj
		print(player_ids[i])
		i+= 1
		if i >= players_required:
			i =0

@rpc("authority","unreliable", "call_local")
func add_card_to_hand(suit, rank):
	_local_player.add_to_hand(suit, rank)

@rpc("authority","unreliable", "call_local")
func show_hands():
	_local_player.show_hand()

func set_selected_card(card:Node):
	_selected_card = card

func attempt_card_played():
	if _selected_card == null:
		return
	_selected_card.played() #TODO new func rpc call, clients
	spawn_card_on_remote.rpc(_selected_card._suit, _selected_card._rank)
	_selected_card = null

#breaks starfish pattern
@rpc("any_peer","unreliable","call_remote")
func spawn_card_on_remote(suit, rank):
	_local_player.show_opponent_card(suit, rank)

#endregion

func _on_start_game_button_pressed() -> void:
	start.rpc_id(1)
