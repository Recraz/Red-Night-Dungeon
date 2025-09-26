extends EnemyState
class_name EnemySearchState

# Simple search state: go to last known player position, then wander
var search_target: Vector2

func enter():
	# State label will be updated by the state machine
	
	# Set target to last known player position
	if enemy and enemy.last_known_player_position != Vector2.ZERO:
		search_target = enemy.last_known_player_position
	else:
		# If no last known position, go to wander immediately
		state_machine.change_state("enemywanderstate")
		return
	
	# Set walking animation
	if enemy and enemy.animation_handler:
		var direction = (search_target - enemy.global_position).normalized()
		enemy.animation_handler.play_walking_animation(direction)

func update(_delta: float):
	# Check if player is detected again during search
	if enemy and enemy.can_detect_player():
		state_machine.change_state("enemychasestate")
		return

func physics_update(_delta: float):
	if not enemy:
		return
	
	# Check if reached the search target
	if enemy.global_position.distance_to(search_target) < 1.0:
		# Reached last known player position, go to wander
		state_machine.change_state("enemywanderstate")
		return
	
	# Move towards search target
	var direction: Vector2
	if enemy.use_context_steering and enemy.context_steering:
		# Use context steering to consider both obstacles and enemy separation
		direction = enemy.context_steering.get_best_direction(
			enemy.global_position,
			search_target,
			enemy,
			enemy.velocity
		)
		# If steering returns zero (no good path), use direct movement
		if direction == Vector2.ZERO:
			direction = (search_target - enemy.global_position).normalized()
	else:
		# Fallback to direct movement
		direction = (search_target - enemy.global_position).normalized()
	
	enemy.velocity = direction * enemy.speed
	
	# Update animations
	enemy.last_direction = direction
	if enemy.animation_handler:
		enemy.animation_handler.play_walking_animation(direction)
	
	# Apply movement
	enemy.move_and_slide()

func exit():
	if enemy:
		enemy.velocity = Vector2.ZERO
