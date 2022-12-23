extends Node

var z:int

var textboxScene = preload("res://System/UI/Textbox.tscn")
var factory = preload("res://System/ObjectFactory.gd").new()
var global_state 

export var PAUSE_MULTIPLIER = 0.10

enum {
	YIELD,              # Pause wrightscript for user input or animation
	END,                # End script
	UNDEFINED,          # Command we don't know about
	DEBUG,              # launch godot debugger
	NOTIMPLEMENTED,     # Command we don't care about
	NEXTLINE            # Run next execution frame
}

var SPRITE_GROUP = "PWSprites"   # Every wrightscript object should be in this
var CHAR_GROUP = "PWChar"        # Objects that are PWChar should be in this
var HIDDEN_CHAR_GROUP = "PWHiddenChar"   # We should only ever have 1 hidden character
var LIST_GROUP = "PWLists"
var BG_GROUP = "PWBG"
var FG_GROUP = "PWFG"
var CLEAR_GROUP = "PWCLEAR"   # Any object that should be cleared when setting a new background
var ARROW_GROUP = "PWARROWS"
var TEXTBOX_GROUP = "TEXTBOX_GROUP"
var PENALTY_GROUP = "PWPENALTY"
var centered_objects = ["fg"]

var external_commands = {}

# Helper functions
func value_replace(value):
	return global_state.variables().value_replace(value)

func clear_main_screen():
	for child in global_state.main_screen.get_children():
		global_state.main_screen.remove_child(child)
		child.queue_free()
		
func load_command_engine():
	global_state = GameState
	index_commands()
	
func create_textbox(line) -> Node:
	var l = textboxScene.instance()
	l.main = global_state.main
	l.text_to_print = line
	global_state.main_screen.add_child(l)
	return l

# TODO implement:
# loops
# flipx
# rotx, roty, rotz
# stack
# fade
var WAITERS = ["fg"]
func create_object(script, command, class_path, groups, arguments=[]):
	return factory.create_object(
		self.global_state.main, 
		self.global_state.main_screen, 
		script, 
		command, 
		class_path, 
		groups, 
		arguments)
	
func refresh_arrows(script):
	get_tree().call_group(ARROW_GROUP, "queue_free")
	var arrow_class = "res://System/UI/IArrow.gd"
	if script.is_inside_cross():
		arrow_class = "res://System/UI/IArrowCross.gd"
	var arrow = create_object(
		script,
		"uglyarrow",
		arrow_class,
		[ARROW_GROUP, SPRITE_GROUP],
		[]
	)
	if script.get_prev_statement() == null and "left" in arrow:
		arrow.left.get_children()[1].visible = false
		arrow.left.get_children()[2].visible = false
	if script.is_inside_cross():
		call_macro("show_present_button", script, [])
		call_macro("show_press_button", script, [])
	else:
		call_macro("hide_present_button", script, [])
		call_macro("hide_press_button", script, [])
		call_macro("show_court_record_button", script, [])
		
func hide_arrows(script):
	call_macro("hide_court_record_button", script, [])
	call_macro("hide_present_button", script, [])
	call_macro("hide_press_button", script, [])
	
func get_speaking_char():
	var characters = factory.get_objects(null, null, CHAR_GROUP)
	for character in characters:
		if character.script_name == global_state.variables().get_string("_speaking", null):
			return [character]
	for character in characters:
		return [character]
	return []
	
# Save/Load
func save_scripts():
	var data = {
		"variables": global_state.variables().store,
		"macros": global_state.stack().macros,
		"evidence_pages": global_state.stack().evidence_pages,
		"stack": []
	}
	for script in global_state.stack().scripts:
		var save_script = {
			"root_path": script.root_path,
			"filename": script.filename
		}
		data["stack"].append(save_script)
	var file = File.new()
	file.open("user://save.txt", File.WRITE)
	file.store_string(
		to_json(data)
	)
	file.close()
	
func _input(event):
	if event and event.is_action_pressed("quickload"):
		load_scripts()
	
func load_scripts():
	var file = File.new()
	var err = file.open("user://save.txt", File.READ)
	if err != OK:
		return false
	var json = file.get_as_text()
	var data = parse_json(json)
	file.close()
	
	clear_main_screen()
	global_state.stack().clear_scripts()
	global_state.stack().variables.store = data["variables"]
	global_state.stack().evidence_pages = data["evidence_pages"]
	global_state.stack().macros = data["macros"]
	
	for script_data in data["stack"]:
		global_state.stack().load_script(
			Filesystem.path_join(script_data["root_path"], script_data["filename"])
		)
		var script = global_state.stack().scripts[-1]
		#var script = load("WrightScript/WrightScript.gd").new()
		#script.main = main
		#main.stack.scripts.append(script)
		#script.root_path = script_data["root_path"]
		#script.filename = script_data["filename"]
		#script.lines = script_data["lines"]
		#script.labels = script_data["labels"]
		#script.line_num = script_data["line_num"]
		#script.line = script_data["line"]
	return true
# Call interface

func generate_command_map(version=""):
	# TODO implement versioning
	var path = "res://System/WrightScript/Commands/"
	var folder = Directory.new()
	if folder.open(path) != OK:
		print("ERROR: NO COMMANDS FOUND")
		assert(false)
	var command_files = []
	var file_name = "yes"
	folder.list_dir_begin()
	while file_name:
		file_name = folder.get_next()
		# Exported source files end in gdc
		if not (file_name.ends_with(".gd") or file_name.ends_with(".gdc")):
			continue
		command_files.append(path+file_name)
	if not command_files:
		print("ERROR: NO COMMANDS FOUND")
		assert(false)
	return command_files

func get_call_methods(object):
	var l = []
	for method in object.get_method_list():
		if method["name"].begins_with("ws_"):
			l.append(method["name"])
	return l

func index_commands():
	for command_file in generate_command_map():
		var extern = load(command_file).new(self.global_state)
		for command in get_call_methods(extern):
			external_commands[command] = extern

func call_command(command, script, arguments):
	command = value_replace(command)
	
	var args = []
	for arg in arguments:
		args.append(value_replace(arg))
	arguments = args

	if has_method("ws_"+command):
		return call("ws_"+command, script, arguments)

	if "ws_"+command in external_commands:
		var extern = external_commands["ws_"+command]
		return extern.callv("ws_"+command, [script, arguments])
	
	if command.begins_with("{") and command.ends_with("}"):
		return call_macro(command.substr(1,command.length()-2), script, arguments)
	
	if is_macro(command):
		return call_macro(command, script, arguments)
	return UNDEFINED
	
func is_macro(command):
	if command.begins_with("{") and command.ends_with("}"):
		return command.substr(1,command.length()-2)
	if global_state.stack().macros.has(command):
		return command
	return ""
	
# TODO - may need to support actually replacing macro text with the arguments passed, 
# but wont implement till we actually need to
func call_macro(command, script, arguments):
	command = is_macro(command)
	if not command:
		return
	var i = 1
	for arg in arguments:
		if "=" in arg:
			var spl = arg.split("=")
			global_state.variables().set_val(
				spl[0].strip_edges(),
				spl[1].strip_edges())
		else:
			global_state.variables().set_val(str(i), arg)
		i += 1
	var script_lines = global_state.stack().macros[command]
	var new_script = global_state.stack().add_script(PoolStringArray(script_lines).join("\n"))
	new_script.root_path = script.root_path
	new_script.filename = "{"+command+"}"
	# TODO not sure if this is how to handle macros that try to goto
	new_script.allow_goto_parent_script = true
	return YIELD
	
func macro_or_label(key, script, arguments):
	var is_macro = is_macro(key)
	if is_macro:
		return call_macro(is_macro, script, [])
	return script.goto_label(key)
	
# Script commands

func ws_draw_off(script, arguments):
	pass # No op, old pywright needed the user to determine when to pause to load many graphics
	
func ws_draw_on(script, arguments):
	pass

# Godot specific control commands

func ws_godotdebug(script, arguments):
	# You can use this command to enter the godot debugger
	pass
