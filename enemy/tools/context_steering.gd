extends Node
class_name ContextSteering

# Context-based steering behavior for enemy AI
# This system evaluates multiple movement directions and selects the best one
# to avoid obstacles while moving towards the target

# Number of directions to evaluate (8 for 8-directional movement)
const DIRECTION_COUNT = 8
# How far ahead to check for obstacles
const RAYCAST_DISTANCE = 40.0
# Minimum interest value to consider a direction viable
const MIN_INTEREST_THRESHOLD = 0.1

var directions: Array[Vector2] = []
var interest: Array[float] = []
var danger: Array[float] = []

# Separation parameters (can be configured per enemy)
var separation_distance = 50.0
var separation_strength = 1.5

func _ready():
	_initialize_directions()

# Set separation parameters from the enemy
func set_separation_parameters(distance: float, strength: float):
	separation_distance = distance
	separation_strength = strength

# Initialize the 8 directional vectors
func _initialize_directions():
	directions.clear()
	interest.clear()
	danger.clear()
	
	for i in range(DIRECTION_COUNT):
		var angle = i * PI * 2.0 / DIRECTION_COUNT
		directions.append(Vector2(cos(angle), sin(angle)))
		interest.append(0.0)
		danger.append(0.0)

# Calculate the best movement direction using context steering
func get_best_direction(
	from_position: Vector2, 
	target_position: Vector2, 
	character_body: CharacterBody2D,
	current_velocity: Vector2 = Vector2.ZERO
) -> Vector2:
	
	# Reset arrays
	for i in range(DIRECTION_COUNT):
		interest[i] = 0.0
		danger[i] = 0.0
	
	# Calculate interest towards target
	_calculate_target_interest(from_position, target_position)
	
	# Calculate danger from obstacles
	_calculate_obstacle_danger(from_position, character_body)
	
	# Calculate danger from other enemies (separation)
	_calculate_enemy_separation_danger(from_position, character_body)
	
	# Add momentum preservation (slight bias towards current direction)
	_add_momentum_bias(current_velocity)
	
	# Combine interest and danger to find best direction
	return _select_best_direction()

# Calculate interest values for moving towards the target
func _calculate_target_interest(from_position: Vector2, target_position: Vector2):
	var to_target = (target_position - from_position).normalized()
	
	for i in range(DIRECTION_COUNT):
		# Higher interest for directions closer to target direction
		var dot_product = directions[i].dot(to_target)
		# Convert from [-1, 1] to [0, 1] range
		interest[i] = max(0.0, dot_product)

# Calculate danger values for each direction based on obstacles
func _calculate_obstacle_danger(from_position: Vector2, character_body: CharacterBody2D):
	var space_state = character_body.get_world_2d().direct_space_state
	
	for i in range(DIRECTION_COUNT):
		var raycast_end = from_position + directions[i] * RAYCAST_DISTANCE
		
		# Create raycast query
		var query = PhysicsRayQueryParameters2D.create(
			from_position, 
			raycast_end, 
			character_body.collision_mask  # Check against walls (layer 3)
		)
		
		var result = space_state.intersect_ray(query)
		
		if result:
			# Calculate danger based on how close the obstacle is
			var hit_distance = from_position.distance_to(result.position)
			var danger_factor = 1.0 - (hit_distance / RAYCAST_DISTANCE)
			danger[i] = max(danger[i], danger_factor)
			
			# Add danger to adjacent directions to create smoother avoidance
			var prev_index = (i - 1 + DIRECTION_COUNT) % DIRECTION_COUNT
			var next_index = (i + 1) % DIRECTION_COUNT
			danger[prev_index] = max(danger[prev_index], danger_factor * 0.5)
			danger[next_index] = max(danger[next_index], danger_factor * 0.5)

# Add slight bias towards current movement direction for smoother movement
func _add_momentum_bias(current_velocity: Vector2):
	if current_velocity.length_squared() < 0.01:
		return  # No significant current movement
	
	var normalized_velocity = current_velocity.normalized()
	var momentum_strength = 0.2  # How much to bias towards current direction
	
	for i in range(DIRECTION_COUNT):
		var dot_product = directions[i].dot(normalized_velocity)
		if dot_product > 0:
			interest[i] += dot_product * momentum_strength

# Select the best direction by combining interest and danger
func _select_best_direction() -> Vector2:
	var best_direction = Vector2.ZERO
	var best_score = -1.0
	var total_weight = 0.0
	
	# Calculate final scores (interest - danger)
	for i in range(DIRECTION_COUNT):
		var final_score = interest[i] - danger[i]
		
		if final_score > MIN_INTEREST_THRESHOLD:
			# Use weighted average for smoother movement
			var weight = final_score
			best_direction += directions[i] * weight
			total_weight += weight
			
			# Also track the single best direction as fallback
			if final_score > best_score:
				best_score = final_score

	# Normalize the weighted direction
	if total_weight > 0:
		best_direction = best_direction / total_weight
		return best_direction.normalized()
	
	# Fallback: if no good direction found, return zero vector
	return Vector2.ZERO

# Calculate danger from other enemies to maintain separation
func _calculate_enemy_separation_danger(from_position: Vector2, character_body: CharacterBody2D):
	# Find all enemies in the scene
	var enemies = character_body.get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		# Skip self
		if enemy == character_body:
			continue
			
		# Check if this enemy is close enough to matter
		var distance_to_enemy = from_position.distance_to(enemy.global_position)
		if distance_to_enemy > separation_distance:
			continue
			
		# Calculate direction from this enemy to the other enemy
		var direction_to_enemy = (enemy.global_position - from_position).normalized()
		
		# Calculate danger based on distance (closer = more dangerous)
		var danger_factor = (separation_distance - distance_to_enemy) / separation_distance
		danger_factor = clamp(danger_factor, 0.0, 1.0) * separation_strength
		
		# Apply danger to directions that move towards the other enemy
		for i in range(DIRECTION_COUNT):
			var dot_product = directions[i].dot(direction_to_enemy)
			if dot_product > 0:  # Moving towards the other enemy
				danger[i] = max(danger[i], danger_factor * dot_product)
				
				# Add some danger to adjacent directions for smoother avoidance
				var prev_index = (i - 1 + DIRECTION_COUNT) % DIRECTION_COUNT
				var next_index = (i + 1) % DIRECTION_COUNT
				danger[prev_index] = max(danger[prev_index], danger_factor * dot_product * 0.3)
				danger[next_index] = max(danger[next_index], danger_factor * dot_product * 0.3)

# Debug function to visualize the context maps
func get_debug_info() -> Dictionary:
	return {
		"directions": directions,
		"interest": interest,
		"danger": danger
	}