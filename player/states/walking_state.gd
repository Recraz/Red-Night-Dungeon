extends State
class_name WalkingState

func enter():
	pass

func physics_update(_delta: float):
	# Check for basic attack input first
	if InputManager.is_basic_pressed():

		state_machine.change_state("skillstate")
		return
	
	# Get input direction using InputManager
	var input_direction = InputManager.get_direction_input()
	
	# Check if player stopped moving
	if input_direction.length() == 0:
		state_machine.change_state("idlestate")
		return
	
	# Update last direction
	player.last_direction = input_direction
	
	# Set velocity
	player.velocity = input_direction * player.speed
	
	# Update walking animation
	if player and player.animation_handler:
		player.animation_handler.play_walking_animation(input_direction)
	
	# Apply movement
	player.move_and_slide()
