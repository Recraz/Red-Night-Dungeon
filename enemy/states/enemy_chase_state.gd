extends EnemyState
class_name EnemyChaseState

func enter():
	# State label will be updated by the state machine
	
	# Set initial animation based on direction to player
	if enemy and enemy.player:
		var direction = enemy.get_direction_to_player()
		if enemy.animation_handler:
			enemy.animation_handler.play_walking_animation(direction)

func update(_delta: float):
	# Check if player is still in chase range and visible
	if enemy and not enemy.should_chase_player():
		# Check if we should search or go idle
		if enemy.use_line_of_sight and enemy.time_since_lost_sight > 0:
			# Lost sight recently, search for player
			state_machine.change_state("enemysearchstate")
		else:
			# Player too far or lost sight for too long, return to wander
			state_machine.change_state("enemywanderstate")
		return

func physics_update(_delta: float):
	if not enemy or not enemy.player:
		return
	
	# Use smart steering if available, fallback to direct movement
	var direction: Vector2
	if enemy.use_context_steering and enemy.context_steering:
		direction = enemy.get_smart_direction_to_player()
		# If steering returns zero (no good path), try direct movement to target
		if direction == Vector2.ZERO:
			var target_pos = enemy.get_target_position()
			direction = (target_pos - enemy.global_position).normalized()
	else:
		# Fallback to direct movement to target position
		var target_pos = enemy.get_target_position()
		direction = (target_pos - enemy.global_position).normalized()
	
	# Apply movement with the calculated direction
	enemy.velocity = direction * enemy.speed
	
	# Update last direction for idle animation
	enemy.last_direction = direction
	
	# Update walking animation
	if enemy.animation_handler:
		enemy.animation_handler.play_walking_animation(direction)
	
	# Apply movement
	enemy.move_and_slide()

func exit():
	if enemy:
		enemy.velocity = Vector2.ZERO
