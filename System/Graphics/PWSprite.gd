extends Node2D
class_name PWSprite

var animated_sprite:AnimatedSprite
var sprite_path:String
var script_name:String
var z:int

var width:int = 1
var height:int = 1

func load_info(path:String):
	print("load info:", path)
	var data = {
		'horizontal': '1',
		'vertical': '1'
	}
	var f = File.new()
	var err = f.open(path, File.READ)
	if err == OK:
		while not f.eof_reached():
			var line = f.get_line()
			if not line.strip_edges():
				print("next line info")
				continue
			var key_value = line.split(" ")
			data[key_value[0]] = key_value[1]
		f.close()
	if data.get('length', null)==null:
		data['length'] = int(data['horizontal']) * int(data['vertical'])
	return data

func load_animation(path:String, info=null):
	if not path.begins_with("res://"):
		path = "res://"+path
	sprite_path = path
	# Load pwv
	print("loading info:", path.rsplit(".", true, 1)[0]+'.txt')
	if not info:
		info = load_info(path.rsplit(".", true, 1)[0]+'.txt')
	print("txt:", info)

	var frames = Filesystem.load_atlas_frames(
		path, 
		int(info['horizontal']),
		int(info['vertical']),
		int(info['length'])
	)
	if frames:
		width = frames[0].region.size.x
		height = frames[0].region.size.y
	
	# Build animated sprite
	animated_sprite = AnimatedSprite.new()
	animated_sprite.use_parent_material = true
	add_child(animated_sprite)
	animated_sprite.frames = SpriteFrames.new()
	for frame in frames:
		animated_sprite.frames.add_frame("default", frame)
	animated_sprite.play("default")
	print("good")
	if info.get('loops') != "1" and info.get('loops') != "yes" and info.get('loops') != "true":
		animated_sprite.frames.set_animation_loop("default", false)
	else:
		animated_sprite.frames.set_animation_loop("default", true)
	rescale(width, height)
	
	material = ShaderMaterial.new()
	material.shader = load("res://System/Graphics/clear_pink.shader")
		
func from_frame(frame):
	width = frame.region.size.x
	height = frame.region.size.y
	animated_sprite = AnimatedSprite.new()
	animated_sprite.use_parent_material = true
	add_child(animated_sprite)
	animated_sprite.frames = SpriteFrames.new()
	animated_sprite.frames.add_frame("default", frame)
	material = ShaderMaterial.new()
	material.shader = load("res://System/Graphics/clear_pink.shader")
	
func rescale(size_x, size_y):
	var sc_w = float(size_x)/float(width)
	var sc_h = float(size_y)/float(height)
	animated_sprite.scale.x = sc_w
	animated_sprite.scale.y = sc_h
	width = size_x
	height = size_y
	animated_sprite.position = Vector2(width/2, height/2)
	animated_sprite.position = Vector2(width/2, height/2)

func _ready():
	if not animated_sprite:
		animated_sprite = AnimatedSprite.new()
		if sprite_path:
			print("loading...")
			load_animation(sprite_path)
		else:
			print("dont load")
		add_child(animated_sprite)

func set_grey(value):
	if material:
		material.set_shader_param("greyscale_amt", float(value))