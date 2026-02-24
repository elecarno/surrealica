extends Control

@onready var join_button: Button = $network/vbox/hbox/join
@onready var cli: Label = $terminal/vbox/cli
@onready var cmd_input: LineEdit = $terminal/vbox/cmd

var mouse_mode: bool = true
var active: bool = true

func _ready() -> void:
	$crt.visible = true
	$network.visible = true
	$terminal.visible = false
	
	if network.net_mode == "Steam":
		join_button.disabled = true
	else:
		join_button.disabled = false


func _on_host_pressed() -> void:
	network._host_pressed()
	mouse_mode = false
	$network.visible = false
	$terminal.visible = true
	get_parent().get_parent().can_escape = true
	cmd_input.grab_focus()

func _on_join_pressed() -> void:
	network.current_lobby_id_prompt = $network/vbox/lobby_id
	network._join_pressed()
	mouse_mode = false
	$network.visible = false
	$terminal.visible = true
	get_parent().get_parent().can_escape = true
	cmd_input.grab_focus()


func _on_refresh_pressed() -> void:
	network.current_lobby_list_vbox = $network/vbox/scroll/lobbies
	network._refresh_pressed()


func _on_lobby_id_text_changed(new_text: String) -> void:
	if network.net_mode == "Steam":
		join_button.disabled = (new_text.length() == 0)
	else:
		join_button.disabled = false
		
		
func _input(event: InputEvent) -> void:
	if mouse_mode: return
	if not active: 
		cmd_input.release_focus()
		return
	
	var cmd: String = cmd_input.text
	
	# command input
	if (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		if event.keycode == KEY_ENTER:
			cmd_input.text = ""
			cli.text = ""
			cli.text += "\n\n> " + cmd
			run_command(cmd.rstrip(" \t\n"))
			
			
func run_command(cmd: String):
	cli.text += "\n"
	match cmd:
		"help":
			cli.text += (
				"\nplayers : show a list of all players currently connected to the world"
			)
		"players":
			pass
		"ping":
			cli.text += "\npong"
		_:
			cli.text += "\nunknown command, use \"help\" to see a list of all commands"
			
	
