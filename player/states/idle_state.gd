extends State
class_name IdleState

func enter():
	# Set idle animation based on last direction
	if player and player.animation_handler and player.animation_handler.animated_sprite:
		player.animation_handler.play_idle_animation(player.last_direction)

func physics_update(_delta: float):
	# Check for basic attack input first
	if InputManager.is_basic_pressed():

		state_machine.change_state("skillstate")
		return
	
	# Check for movement input using InputManager
	var input_direction = InputManager.get_direction_input()
	
	if input_direction.length() > 0:
		state_machine.change_state("walkingstate")
		return
	
	# Stop movement immediately
	player.velocity = Vector2.ZERO
	player.move_and_slide()
