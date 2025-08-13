extends Node2D

@export var deck_template: Resource

@onready var label := $Label

var DECK = preload("res://Scenes/deck.tscn")
var PLAYER = preload("res://Scenes/player.tscn")

var _deck
var _players: Array
var number_of_players: int = 4

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

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	player_info["name"] = randi() % 20

func update_label():
	label.text = str(players.size())

#region Multiplayer

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

#endregion

#region Game
func start():
	create_deck()
	create_players(number_of_players)
	deal()
	show_hands()

func create_deck():
	_deck = DECK.instantiate()
	_deck.create_deck(deck_template)
	add_child(_deck)
	
func create_players(amount):
	for i in amount:
		var player = PLAYER.instantiate()
		_players.append(player)
		add_child(player)

func deal():
	if !_deck.is_deck_full():
		return
	var i = 0
	for card in _deck.current_deck:
		_players[i].add_to_hand(card)
		i+= 1
		if i >= 4:
			i =0

func show_hands():
	for player in _players:
		player.show_hand()
#endregion
