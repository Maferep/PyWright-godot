extends Node2D

var main
var nametag := ""
var text_to_print := ""
var packs := []
var printed := ""
var wait_signal := "tree_exited"
var z:int

# states while printing
var center = false
var diffcolor = false

enum {
	TEXT_PACK,
	COMMAND_PACK
}

class Pack:
	var type = TEXT_PACK
	var text := ""
	func _init(type, text):
		self.type = type
		self.text = text

# Called when the node enters the scene tree for the first time.
func _ready():
	if not main:
		return
	$NametagBackdrop/Label.text = ""
	$Backdrop/Label.bbcode_text = ""
	if main.stack.variables.get_int("_textbox_lines", 3) == 2:
		$Backdrop/Label.margin_bottom = 14
		$Backdrop/Label.set("custom_constants/line_separation", 8)
	z = ZLayers.z_sort["textbox"]
	add_to_group(Commands.TEXTBOX_GROUP)
	Commands.refresh_arrows(main.stack.scripts[-1])
	update_nametag()

func update_nametag():
	# Lookup character name
	var nametag
	for character in Commands.get_speaking_char():
		nametag = main.stack.variables.get_string(
			"char_"+character.char_name+"_name", 
			character.char_name.capitalize()
		)
	if not nametag:
		$NametagBackdrop.visible = false
	else:
		$NametagBackdrop/Label.text = nametag
		$NametagBackdrop.visible = true
		
func update_emotion(emotion):
	for character in Commands.get_speaking_char():
		character.load_emotion(emotion)

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		click_continue()
		
func queue_free():
	Commands.hide_arrows(main.stack.scripts[-1])
	.queue_free()
			
func click_continue(immediate_skip=false):
	if not immediate_skip and (text_to_print or packs):
		while text_to_print or packs:
			_process(1)
	else:
		queue_free()
		
func click_next():
	main.stack.scripts[-1].next_statement()
	click_continue(true)

func click_prev():
	main.stack.scripts[-1].prev_statement()
	click_continue(true)
		
func get_next_pack():
	var i = 0
	var pack = ""
	var found_bracket = false
	while i < text_to_print.length():
		var c = text_to_print[i]
		pack += c
		if not found_bracket and i == 0 and c == '{':
			found_bracket = true
			i += 1
			continue
		if found_bracket and i != 0 and c == '}':
			text_to_print = text_to_print.substr(i+1)
			return Pack.new(COMMAND_PACK, pack.substr(1, pack.length()-2))
		if not found_bracket and i > 0 and c == '{':
			text_to_print = text_to_print.substr(i)
			return Pack.new(TEXT_PACK, pack.left(pack.length()-1))
		i += 1
	text_to_print = ""
	return Pack.new(TEXT_PACK, pack)

# TODO finish execute markup base commands
# TODO execute macros
func execute_markup(pack:Pack):
	var args = []
	for command in [
		"sfx", "sound", "delay", "spd", "_fullspeed", "_endfullspeed",
		"wait", "center", "type", "next", "tbon", "tboff", 
		"e", "f", "s", "p", "c", "$"
	]:
		if pack.text.begins_with(command):
			args = pack.text.substr(command.length()).strip_edges()
			if args:
				args = args.split(" ")
			else:
				args = []
			pack.text = command
			break
	match pack.text:
		"n":
			$Backdrop/Label.bbcode_text += "\n"
		"center":
			if not center:
				$Backdrop/Label.bbcode_text += "[center]"
			else:
				$Backdrop/Label.bbcode_text += "[/center]"
			center = not center
		"c":
			if diffcolor:
				$Backdrop/Label.bbcode_text += "[/color]"
			if not args:
				diffcolor = false
			else:
				$Backdrop/Label.bbcode_text += "[color=#"+Colors.string_to_hex(args[0])+"]"
				diffcolor = true
		"e":
			Commands.call_command("emo", main.top_script(), args)
			#update_emotion(args[0])
		"$":
			return main.stack.variables.get_string(args[0])
		"sfx":
			pass
		"sound":
			pass
		"delay":   # delay character printing for a time
			pass
		"spd":
			pass
		"_fullspeed":
			pass
		"_endfullspeed":
			pass
		"wait":  # set wait mode to auto or manual
			pass
		"type":
			pass
		"next":
			queue_free()
		"tbon":
			pass
		"tboff":
			pass
		"e":
			pass
		"f":
			pass
		"s":
			pass
		"p":
			pass

func _process(dt):
	update_nametag()
	if text_to_print and not packs:
		var next_pack = get_next_pack()
		while text_to_print:
			packs.append(next_pack)
			next_pack = get_next_pack()
		packs.append(next_pack)
	if packs:
		for character in Commands.get_speaking_char():
			character.play_state("talk")
		if packs[0].type == TEXT_PACK:
			if packs[0].text.length()>0:
				$Backdrop/Label.bbcode_text += packs[0].text.substr(0,1)
				packs[0].text = packs[0].text.substr(1)
			else:
				packs.remove(0)
		elif packs[0].type == COMMAND_PACK:
			var t = execute_markup(packs[0])
			if t:
				$Backdrop/Label.bbcode_text += t
			packs.remove(0)
	else:
		for character in Commands.get_speaking_char():
			character.play_state("blink")
