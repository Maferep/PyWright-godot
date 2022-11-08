extends Reference

var main

func _init(commands):
	main = commands.main

# TODO IMPLEMENT
# (should set debug mode on
#         """Used to turn debug mode on or off. Debug mode will print more errors to the screen,
#        and allow you to skip through any text."""
#        if value.lower() in ["on","1","true"]:
#            assets.variables["_debug"] = "on"
#        else:
#            assets.variables["_debug"] = "off"
func ws_debug(script, arguments):
	return Commands.DEBUG
	
func ws_print(script, arguments):
	print(Commands.join(arguments))
	
# TODO IMPLEMENT
# Steps through pywright debugger
func ws_step(script, arguments):
	pass
	
func ws_goto(script, arguments):
	var fail = Commands.keywords(arguments).get("fail", null)
	script.goto_label(arguments[0], fail)
	
func ws_top(script, arguments):
	script.goto_line_number(0)

func ws_label(script, arguments):
	main.stack.variables.set_val("_lastlabel", arguments[0])

# TODO
# need to verify some of the specifics. mainly why did we need parent?
#@category(
#    [VALUE('script_name',"name of the new script to load. Will look for 'script_name.script.txt', 'script_name.txt', or simple 'script_name', in the current case folder."),
#KEYWORD('label','A label in the loading script to jump to after it loads.','Execution starts at the top of the script instead of a label'),
#TOKEN('noclear','If this token is present, all the objects that exist will carry over into the new script.','Otherwise, the scene will be cleared.'),
#TOKEN('stack','Puts the new script on top of the current script, instead of replacing it. When the new script exits, the current script will resume following this "script" command.','The new script will replace the current script.')],
#type="gameflow")
#    def _script(self,command,scriptname,*args):
#        """Stops or pauses execution of the current script and loads a new script. If the token stack is included, then the current script will
#resume when the new script exits, otherwise, the current script will vanish."""
#        print "RUNNING SCRIPT:",scriptname
#        print assets.stack
#        label = None
#        for a in args:
#            if a.startswith("label="):
#                label = a.split("=",1)[1]
#        if "noclear" not in args:
#            for o in self.obs:
#                o.delete()
#        name = scriptname+".script"
#        try:
#            assets.open_script(name,False,".txt")
#        except file_error:
#            name = scriptname
#        if "stack" in args:
#            assets.addscene(name)
#        else:
#            p = self.parent
#            self.init(name)
#            self.parent = p
#        print "New stack:",assets.stack
#        while assets.cur_script.parent:
#            parent = assets.cur_script.parent
#            assets.cur_script.parent = parent.parent
#            #FIXME - How can we be removing a parent that's not there?
#            if parent in assets.stack:
#                assets.stack.remove(parent)
#        if label:
#            self.goto_result(label,backup=None)
#        print "Stack after clean up:",assets.stack
#        print "cur script",assets.cur_script
#        print "buildmode",assets.cur_script.buildmode
#        print "SCRIPT DEFAULTS"
#        self.execute_macro("defaults")
func ws_script(script, arguments, script_text=null):
	if Commands.keywords(arguments).get("label",null):
		# TODO jump to label when loading script
		print("DO SOMETHING WITH SCRIPTS LOADING A LABEL")
	if not "noclear" in arguments:
		Commands.clear_main_screen()
		pass
	else:
		arguments.erase("noclear")
	var path = Commands.join(arguments)
	if script_text:
		main.stack.add_script(script_text)
	else:
		path = script.has_script(path)
		if path:
			print("loading path:", path)
			main.stack.load_script(path)
	if not "stack" in arguments:
		main.stack.remove_script(script)
	Commands.save_scripts()
	return Commands.YIELD
	
# TODO IMPLEMENT
#    @category([VALUE("game","Path to game. Should be from the root, i.e. games/mygame or games/mygame/mycase"),
#                    VALUE("script","Script to look for in the game folder to run first","intro")],type="gameflow")
func ws_game(script, arguments):
	pass
	
# TODO IMPLEMENT
#        """Ends the currently running script and pops it off the stack. Multiple scripts
#        may be running in PyWright, in which case the next script on the stack will
#        resume running."""
#        print "ending script",self
#        if self in assets.stack:
#            assets.stack.remove(self)
#            if "enter" in self.held: self.held.remove("enter")
#            if self.parent:
#                self.parent.held = []
#                self.parent.world = self.world
#        if not assets.stack:
#            assets.variables.clear()
#            assets.stop_music()
#            assets.stack[:] = []
#            assets.make_start_script(False)
#        return
func ws_endscript(script, arguments):
	pass

# TODO IMPLEMENT (not sure how this is different from endscript
#    @category([],type="gameflow")
#    def _exit(self,command):
#        """Deletes the currently running scene/script from execution. If there are any scenes underneath, they will
#        resume."""
#        del assets.stack[-1]
func ws_exit(script, arguments):
	pass
	
# TODO IMPLEMENT
func ws_waitenter(script, arguments):
	pass

func ws_savegame(script, arguments):
	return Commands.NOTIMPLEMENTED
	
func ws_loadgame(script, arguments):
	return Commands.NOTIMPLEMENTED
	
func ws_screenshot(script, arguments):
	return Commands.NOTIMPLEMENTED