extends Node3D

@export_enum("Steam", "ENet") var net_mode: String = "Steam"

var lobby_id: int = 0
var peer

@export var player_scene: PackedScene

var is_host: bool = false
var is_joining: bool = false


func _ready() -> void:
	if net_mode == "ENet":
		peer = ENetMultiplayerPeer.new()
		$canvas/ui/join.disabled = false
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
		
		$canvas/ui/scroll/lobbies.add_child(button)


func open_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

		
func _add_player(id: int = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	
func _remove_player(id: int):
	if not self.has_node(str(id)):
		return
		
	self.get_node(str(id)).queue_free()
		


func _on_host_pressed() -> void:
	host_lobby()
	$canvas.queue_free()

func _on_lobby_id_text_changed(new_text: String) -> void:
	$canvas/ui/join.disabled = (new_text.length() == 0)

func _on_join_pressed() -> void:
	join_lobby($canvas/ui/lobby_id.text.to_int())
	$canvas.queue_free()

func _on_refresh_pressed() -> void:
	if $canvas/ui/scroll/lobbies.get_child_count() > 0:
		for n in $canvas/ui/scroll/lobbies.get_children():
			n.queue_free()
			
	open_lobby_list()
