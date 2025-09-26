extends Node
class_name StateMachine

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready():
	# Initialize all child states
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.player = get_parent()
	
	# Set initial state immediately
	if initial_state:
		change_state(initial_state.name.to_lower())

func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func _input(event):
	if current_state:
		current_state.handle_input(event)

func _unhandled_input(event):
	if current_state:
		current_state.handle_input(event)

func change_state(new_state_name: String):
	var new_state = states.get(new_state_name.to_lower())
	
	if new_state == current_state:
		return
	
	if current_state:
		current_state.exit()

	current_state = new_state

	if current_state:
		current_state.enter()

func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""
