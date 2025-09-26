extends EnemyState
class_name EnemyIdleState

var detection_timer = 0.0
var detection_check_interval = 0.1  # Check for player every 0.1 seconds
var idle_duration = 2.0  # How long to stay idle before wandering
var idle_timer = 0.0

func enter():
	# State label will be updated by the state machine
	idle_timer = 0.0
	# Set idle animation based on last direction
	if enemy and enemy.animation_handler and enemy.animation_handler.animated_sprite:
		enemy.animation_handler.play_idle_animation(enemy.last_direction)

func update(delta: float):
	detection_timer += delta
	idle_timer += delta
	
	# Periodically check for player detection
	if detection_timer >= detection_check_interval:
		detection_timer = 0.0
		
		if enemy and enemy.can_detect_player():
			# Player detected with line of sight, switch to chase state
			state_machine.change_state("enemychasestate")
			return
	
	# After idle duration, switch to wander state
	if idle_timer >= idle_duration:
		state_machine.change_state("enemywanderstate")

func physics_update(_delta: float):
	# Stop movement while idle
	if enemy:
		enemy.velocity = Vector2.ZERO
		enemy.move_and_slide()

func exit():
	detection_timer = 0.0
	idle_timer = 0.0