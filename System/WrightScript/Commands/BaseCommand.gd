extends Reference
class_name BaseCommand
var main
var global_state
func _init(global_state):
	main = global_state.main
	self.global_state = global_state
func keywords(arguments, variables, remove=false):
	# TODO determine if we actually ALWAYS want to replace $ variables here
	var newargs = []
	var d = {}
	for arg in arguments:
		if "=" in arg:
			var split = arg.split("=", true, 1)
			d[split[0]] = variables.value_replace(split[1])
		else:
			newargs.append(arg)
	if remove:
		return [d, newargs]
	return d

func join(l, sep=" "):
	return PoolStringArray(l).join(sep)
