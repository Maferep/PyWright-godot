extends Node

var main:Node
var main_screen:Node
var centered_objects = ["fg"]

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func value_replace(value):
	# Replace from variables if starts with $
	# TODO move to stack
	if value.begins_with("$"):
		return main.stack.variables.get_string(value.substr(1))
	return value
	
func keywords(arguments, remove=false):
	# TODO determine if we actually ALWAYS want to replace $ variables here
	var newargs = []
	var d = {}
	for arg in arguments:
		if "=" in arg:
			var split = arg.split("=", true, 1)
			d[split[0]] = value_replace(split[1])
		else:
			newargs.append(arg)
	if remove:
		return [d, newargs]
	return d

# TODO implement:
# loops
# flipx
# rotx, roty, rotz
# stack
# fade
var WAITERS = ["fg"]
func create_object(caller, script, command, class_path, groups, arguments=[]):
	var object:Node
	object = load(class_path).new()
	main_screen.add_child(object)
	if "main" in object:
		object.main = main
	var x=int(keywords(arguments).get("x", 0))
	var y=int(keywords(arguments).get("y", 0))
	object.position = Vector2(x, y)
	if command in ["bg", "fg"]:
		var filename = caller.Filesystem.lookup_file(
			"art/"+command+"/"+arguments[0]+".png",
			script.root_path
		)
		if not filename:
			main.log_error("No file found for "+arguments[0]+" tried: "+"art/"+command+"/"+arguments[0]+".png")
			return null
		object.load_animation(filename)
	elif command in ["gui"]:
		var frame = caller.Filesystem.lookup_file(
			"art/"+keywords(arguments).get("graphic", "")+".png",
			script.root_path
		)
		var frameactive = caller.Filesystem.lookup_file(
			"art/"+keywords(arguments).get("graphichigh", "")+".png",
			script.root_path
		)
		object.load_art(frame, frameactive, keywords(arguments).get("button_text", ""))
		object.area.rect_position = Vector2(0, 0)
	elif "PWChar" in class_path:
		object.load_character(
			arguments[0], 
			keywords(arguments).get("e", "normal"),
			script.root_path
		)
	elif "PWEvidence" in class_path:
		object.load_art(script.root_path, arguments[0])
	elif object.has_method("load_animation"):
		object.load_animation(
			caller.Filesystem.lookup_file(
				"art/"+arguments[0]+".png",
				script.root_path
			)
		)
	elif object.has_method("load_art"):
		object.load_art(script.root_path)
	var center = Vector2()
	if command in centered_objects:
		object.position += Vector2(256/2-object.width/2, 192/2-object.height/2)
	caller.last_object = object
	if arguments:
		object.script_name = keywords(arguments).get("name", arguments[0])
		object.add_to_group("name_"+object.script_name)
	if keywords(arguments).get("z", null)!=null:
		object.z = int(keywords(arguments)["z"])
	else:
		object.z = ZLayers.z_sort[command]
	for group in groups:
		object.add_to_group(group)
	object.name = object.script_name
	#Set object to wait mode if possible and directed to
	if "wait" in object:
		object.set_wait(command in WAITERS)
		# If we say to wait or nowait, apply it
		if "wait" in arguments:
			object.set_wait(true)    #Try to make the object wait, if it is a single play animation that has more than one frame
		if "nowait" in arguments:
			object.set_wait(false)
	return object
