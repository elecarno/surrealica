extends Control

@onready var network: Network = get_tree().get_root().get_node("network")

@onready var join_button: Button = $network/vbox/hbox/join

var mouse_mode: bool = true

func _ready() -> void:
	$crt.visible = true
	if network.net_mode == "Steam":
		join_button.disabled = true
	else:
		join_button.disabled = false

func _on_host_pressed() -> void:
	network._host_pressed()

func _on_join_pressed() -> void:
	network.current_lobby_id_prompt = $network/vbox/lobby_id
	network._join_pressed()

func _on_refresh_pressed() -> void:
	network.current_lobby_list_vbox = $network/vbox/scroll/lobbies
	network._refresh_pressed()

func _on_lobby_id_text_changed(new_text: String) -> void:
	if network.net_mode == "Steam":
		join_button.disabled = (new_text.length() == 0)
	else:
		join_button.disabled = false
		
		
func _physics_process(delta: float) -> void:
	if mouse_mode: return
