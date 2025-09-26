extends Node
class_name EnemyStateMachine

@export var initial_state: EnemyState

var current_state: EnemyState
var states: Dictionary = {}

func _ready():
	# Initialize all child states
	for child in get_children():
		if child is EnemyState:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.enemy = get_parent()
	
	# Set initial state immediately
	if initial_state:
		change_state(initial_state.name.to_lower())

func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func change_state(new_state_name: String):
	var new_state = states.get(new_state_name.to_lower())
	
	if new_state == current_state:
		return
	
	if current_state:
		current_state.exit()

	current_state = new_state

	if current_state:
		current_state.enter()
		# Update the state label with simplified state name
		var enemy = get_parent()
		if enemy and enemy.has_method("update_state_label"):
			var simple_name = get_simple_state_name(current_state.name)
			enemy.update_state_label(simple_name)

# Convert full state class names to simple names
func get_simple_state_name(full_name: String) -> String:
	match full_name.to_lower():
		"enemyidlestate":
			return "idle"
		"enemywanderstate":
			return "wander"
		"enemysearchstate":
			return "search"
		"enemychasestate":
			return "chase"
		_:
			return "unknown"

func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""