extends Reference
class_name BaseCommand
var main
var global_state
func _init(global_state):
	main = global_state.main
	self.global_state = global_state
