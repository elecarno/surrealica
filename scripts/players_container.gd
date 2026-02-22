class_name PlayersContainer
extends Node3D

func _ready() -> void:
	network.players_container = self

func get_client_player() -> Player:
	return get_node(str(multiplayer.get_unique_id()))
