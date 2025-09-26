extends Node

# Centralized InputManager singleton for handling both keyboard and virtual controller input
# Serves as the single source of truth for movement input across all game states

func _ready():
	# Make this a singleton/autoload
	pass

# Get direction input from keyboard or virtual controller
func get_direction_input() -> Vector2:
	var input_direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	# Normalize diagonal movement
	if input_direction.length() > 1.0:
		input_direction = input_direction.normalized()
	
	return input_direction

# Check if any movement input is being pressed
func has_movement_input() -> bool:
	return get_direction_input().length() > 0

# Get individual direction checks if needed
func is_moving_left() -> bool:
	return Input.is_action_pressed("move_left")

func is_moving_right() -> bool:
	return Input.is_action_pressed("move_right")

func is_moving_up() -> bool:
	return Input.is_action_pressed("move_up")

func is_moving_down() -> bool:
	return Input.is_action_pressed("move_down")

# Check for basic input (left mouse button)
func is_basic_pressed() -> bool:
	return Input.is_action_just_pressed("basic")

func is_basic_held() -> bool:
	return Input.is_action_pressed("basic")
