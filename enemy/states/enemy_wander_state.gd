extends EnemyState
class_name EnemyWanderState

@export var wander_speed = 35.0
@export var obstacle_detection_distance = 40.0
@export var direction_smoothing = 2.0
@export var direction_change_interval = 3.0
@export var idle_chance_interval = 2.0  # Check for idle transition every 2 seconds
@export var idle_probability = 0.3  # 30% chance to go idle when checked

var desired_direction: Vector2
var current_direction: Vector2
var direction_change_timer = 0.0
var detection_timer = 0.0
var detection_check_interval = 0.1  # Check for player every 0.1 seconds
var idle_check_timer = 0.0  # Timer for checking idle transition

func enter():
	# State label will be updated by the state machine
	desired_direction = Vector2.RIGHT.rotated(randf() * TAU)
	current_direction = desired_direction
	direction_change_timer = 0.0
	detection_timer = 0.0
	idle_check_timer = 0.0
	
	if enemy and enemy.animation_handler:
		enemy.animation_handler.play_walking_animation(current_direction)

func update(delta: float):
	detection_timer += delta
	direction_change_timer += delta
	idle_check_timer += delta
	
	# Periodically check for player detection
	if detection_timer >= detection_check_interval:
		detection_timer = 0.0
		
		if enemy and enemy.can_detect_player():
			state_machine.change_state("enemychasestate")
			return
	
	# Periodically check if enemy should go idle
	if idle_check_timer >= idle_chance_interval:
		idle_check_timer = 0.0
		if randf() < idle_probability:
			state_machine.change_state("enemyidlestate")
			return
	
	# Change desired direction periodically
	if direction_change_timer >= direction_change_interval:
		direction_change_timer = 0.0
		desired_direction = Vector2.RIGHT.rotated(randf() * TAU)
	
	# Check for obstacles and adjust direction
	_avoid_obstacles()
	
	# Smooth direction changes
	current_direction = current_direction.lerp(desired_direction, delta * direction_smoothing)

func physics_update(_delta: float):
	if enemy:
		# Use context steering for movement if available and enabled
		var final_direction = current_direction
		
		if enemy.use_context_steering and enemy.context_steering:
			# Use context steering to consider both obstacles and enemy separation
			var target_position = enemy.global_position + current_direction * 100.0  # Wander target
			var steering_direction = enemy.context_steering.get_best_direction(
				enemy.global_position,
				target_position,
				enemy,
				enemy.velocity
			)
			
			# If steering suggests a direction, blend it with the current wander direction
			if steering_direction != Vector2.ZERO:
				final_direction = current_direction.lerp(steering_direction, 0.7)
		
		enemy.velocity = final_direction * wander_speed
		enemy.move_and_slide()
		
		# Update animation and last direction
		if enemy.velocity.length() > 0.1:
			if enemy.animation_handler:
				enemy.animation_handler.play_walking_animation(final_direction)
			enemy.last_direction = final_direction.normalized()

func exit():
	direction_change_timer = 0.0
	detection_timer = 0.0
	idle_check_timer = 0.0

func _avoid_obstacles():
	if not enemy:
		return
	
	var space_state = enemy.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		enemy.global_position,
		enemy.global_position + desired_direction * obstacle_detection_distance,
		enemy.collision_mask
	)
	
	var result = space_state.intersect_ray(query)
	
	if not result.is_empty():
		# Obstacle detected, choose new direction
		# Try perpendicular directions first
		var perpendicular_right = desired_direction.rotated(PI/2)
		var perpendicular_left = desired_direction.rotated(-PI/2)
		
		# Test which perpendicular direction is clearer
		var right_query = PhysicsRayQueryParameters2D.create(
			enemy.global_position,
			enemy.global_position + perpendicular_right * obstacle_detection_distance,
			enemy.collision_mask
		)
		var left_query = PhysicsRayQueryParameters2D.create(
			enemy.global_position,
			enemy.global_position + perpendicular_left * obstacle_detection_distance,
			enemy.collision_mask
		)
		
		var right_result = space_state.intersect_ray(right_query)
		var left_result = space_state.intersect_ray(left_query)
		
		# Choose the clearest direction
		if right_result.is_empty() and left_result.is_empty():
			# Both directions clear, choose randomly
			desired_direction = perpendicular_right if randf() > 0.5 else perpendicular_left
		elif right_result.is_empty():
			desired_direction = perpendicular_right
		elif left_result.is_empty():
			desired_direction = perpendicular_left
		else:
			# Both blocked, turn around
			desired_direction = -desired_direction
		
		# Reset the timer to avoid immediate direction changes
		direction_change_timer = 0.0
