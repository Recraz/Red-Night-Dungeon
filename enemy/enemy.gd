extends CharacterBody2D
class_name Enemy

@export var speed = 70.0
@export var chase_range = 250.0
@export var detection_range = 200.0

# Context steering parameters
@export var use_context_steering = true
@export var steering_update_rate = 0.1  # How often to recalculate steering (in seconds)

# Enemy separation parameters
@export var separation_distance = 50.0  # Minimum distance to maintain from other enemies
@export var separation_strength = 1.5   # How strongly to avoid other enemies

# Line of sight parameters
@export var use_line_of_sight = true
@export var los_check_interval = 0.2  # How often to check LOS (in seconds)

@onready var animated_sprite = $AnimatedSprite2D
@onready var state_machine = $EnemyStateMachine
@onready var animation_handler = $AnimationHandler
@onready var context_steering = $ContextSteering
@onready var state_label = $StateLabel


var player: CharacterBody2D
var last_direction = Vector2.DOWN

# Context steering variables
var steering_timer = 0.0
var cached_steering_direction = Vector2.ZERO

# Line of sight variables
var los_timer = 0.0
var has_line_of_sight = false
var last_known_player_position = Vector2.ZERO
var time_since_lost_sight = 0.0


func _ready():

	# Add this enemy to the enemies group for separation behavior
	add_to_group("enemies")
	
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	
	# Ensure context steering is ready
	if context_steering:
		context_steering._ready()
	
	# Ensure animation handler is ready first
	await get_tree().process_frame
	
	# Manually call _ready on animation_handler if needed
	if animation_handler and not animation_handler.animated_sprite:
		animation_handler._ready()
	
	# Now safely initialize the animation
	if animation_handler and animation_handler.animated_sprite:
		animation_handler.play_idle_animation(last_direction)
	else:
		# Retry after another frame
		await get_tree().process_frame
		if animation_handler and animation_handler.animated_sprite:
			animation_handler.play_idle_animation(last_direction)
	
	# Initialize state label with current state
	if state_machine and state_machine.current_state and state_label:
		var simple_name = state_machine.get_simple_state_name(state_machine.current_state.name)
		state_label.text = simple_name



# Get distance to player
func get_distance_to_player() -> float:
	if not player:
		return INF
	return global_position.distance_to(player.global_position)

# Check if player is within detection range
func can_detect_player() -> bool:
	if not use_line_of_sight:
		return get_distance_to_player() <= detection_range
	
	# With LOS: must be in range AND visible
	return get_distance_to_player() <= detection_range and has_line_of_sight_to_player()

# Check if player is within chase range
func should_chase_player() -> bool:
	if not use_line_of_sight:
		return get_distance_to_player() <= chase_range
	
	# With LOS: can chase if in range and visible
	var in_range = get_distance_to_player() <= chase_range
	return in_range and has_line_of_sight_to_player()



# Get direction to player (for animations)
func get_direction_to_player() -> Vector2:
	if not player:
		return Vector2.DOWN
	return (player.global_position - global_position).normalized()

# Get smart movement direction using context steering
func get_smart_direction_to_player() -> Vector2:
	if not player or not context_steering:
		return get_direction_to_player()
	
	if not use_context_steering:
		return get_direction_to_player()
	
	# Update steering at specified intervals for performance
	steering_timer += get_process_delta_time()
	
	if steering_timer >= steering_update_rate or cached_steering_direction == Vector2.ZERO:
		# Use target position (current or last known) for steering
		var target_pos = get_target_position()
		# Set separation parameters in context steering
		if context_steering.has_method("set_separation_parameters"):
			context_steering.set_separation_parameters(separation_distance, separation_strength)
		cached_steering_direction = context_steering.get_best_direction(
			global_position,
			target_pos,
			self,
			velocity
		)
		steering_timer = 0.0
	
	return cached_steering_direction

# Check if the enemy has a clear path to the player
func has_clear_path_to_player() -> bool:
	if not player:
		return false
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		player.global_position,
		collision_mask  # Check against walls
	)
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()  # True if no obstacles between enemy and player

# Check line of sight to player (optimized with timer)
func has_line_of_sight_to_player() -> bool:
	if not use_line_of_sight or not player:
		return true  # Always "see" player if LOS is disabled
	
	# Update LOS check at intervals for performance
	los_timer += get_process_delta_time()
	
	if los_timer >= los_check_interval:
		los_timer = 0.0
		_update_line_of_sight()
	
	return has_line_of_sight

# Internal function to update line of sight status
func _update_line_of_sight():
	if not player:
		has_line_of_sight = false
		return
	
	var space_state = get_world_2d().direct_space_state
	
	# Cast ray from enemy to player
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		player.global_position,
		collision_mask  # Check against walls (layer 3)
	)
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		# Clear line of sight
		has_line_of_sight = true
		last_known_player_position = player.global_position
		time_since_lost_sight = 0.0
	else:
		# Blocked line of sight
		has_line_of_sight = false
		time_since_lost_sight += los_check_interval

# Get target position for movement (uses last known position if no LOS)
func get_target_position() -> Vector2:
	if not player:
		return global_position
	
	if not use_line_of_sight:
		return player.global_position
	
	# Use current position if visible, otherwise last known position
	if has_line_of_sight_to_player():
		return player.global_position
	else:
		return last_known_player_position

# Update the state label display
func update_state_label(state_text: String):
	if state_label:
		state_label.text = state_text
