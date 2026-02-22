class_name Network
extends Node3D

# networking
var net_mode: String = "ENet"
var lobby_id: int = 0
var peer

var is_host: bool = false
var is_joining: bool = false

# references to game world
@onready var player_scene: PackedScene = preload("res://scenes/player.tscn")
@onready var players_container: PlayersContainer

@onready var current_lobby_list_vbox: VBoxContainer
@onready var current_lobby_id_prompt: LineEdit


func _ready() -> void:
	# setup peer based on network mode
	if net_mode == "ENet":
		peer = ENetMultiplayerPeer.new()
	elif net_mode == "Steam":
		peer = SteamMultiplayerPeer.new()
		print("Steam initialised: ", Steam.steamInit(480, true))
		Steam.initRelayNetworkAccess()
		Steam.lobby_created.connect(_on_lobby_created)
		Steam.lobby_joined.connect(_on_lobby_joined)
		Steam.lobby_match_list.connect(_on_lobby_match_list)
		open_lobby_list()

func host_lobby():
	is_host = true
	
	# create lobby based on network mode
	if net_mode == "ENet":
		peer.create_server(4040)
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		_add_player()
	elif net_mode == "Steam":
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 16)


func _on_lobby_created(result: int, lobby_id: int):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName()+"'s Lobby"))
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		_add_player()
		
		print("Lobby created: ", lobby_id)
		
		
func join_lobby(lobby_id: int = 0):
	is_joining = true
	
	if net_mode == "ENet":
		peer.create_client("127.0.0.1", 4040)
	elif net_mode == "Steam":
		Steam.joinLobby(lobby_id)
		
	multiplayer.multiplayer_peer = peer
	
	
func _on_lobby_joined(lobby_id: int, permissions: int, locked: bool, reponse: int):
	if not is_joining:
		return

	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	
	is_joining = false

func _on_lobby_match_list(lobbies):
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var member_count = Steam.getNumLobbyMembers(lobby)
		
		var button: Button = Button.new()
		button.set_text(str(lobby_name) + "| Players: " + str(member_count))
		button.set_size(Vector2(100, 5))
		button.connect("pressed", Callable(self, "join_lobby").bind(lobby))
		
		if current_lobby_list_vbox != null:
			current_lobby_list_vbox.add_child(button)


func open_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

		
func _add_player(id: int = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	players_container.add_child(player)
	
func _remove_player(id: int):
	if not players_container.has_node(str(id)):
		return
		
	players_container.get_node(str(id)).queue_free()
	
	
func _host_pressed() -> void:
	host_lobby()

func _join_pressed() -> void:
	join_lobby(current_lobby_id_prompt.text.to_int())

func _refresh_pressed() -> void:
	if current_lobby_list_vbox.get_child_count() > 0:
		for n in current_lobby_list_vbox.get_children():
			n.queue_free()
			
	open_lobby_list()
