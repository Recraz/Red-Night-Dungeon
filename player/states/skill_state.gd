extends State
class_name SkillState

# Reference to skill manager
var skill_manager: SkillManager
var current_skill_name: String = ""
var skill_manager_initialized: bool = false
var current_skill_instance: BaseSkill = null
var stored_animation_direction: Vector2
var slash_flip_h: bool = false

func _ensure_skill_manager():
	if not skill_manager_initialized:
		# Get skill manager from player
		skill_manager = _get_or_create_skill_manager()
		
		if not skill_manager:
	
			return
		
		# Set the player reference
		skill_manager.set_player(player)
		

		skill_manager_initialized = true

func _get_or_create_skill_manager() -> SkillManager:
	# Ensure player reference is valid
	if not player:
	
		return null
	
	# Look for existing skill manager on player
	var skill_manager_node = player.get_node_or_null("SkillManager")
	if skill_manager_node and skill_manager_node is SkillManager:

		return skill_manager_node
	
	# If not found, print error message

	return null

func _set_player_animation_for_skill(skill_instance: BaseSkill):
	# Set player animation based on skill's player_animation property
	if not player or not player.animation_handler:
		return
	
	# Use the stored direction instead of recalculating
	var direction = stored_animation_direction

	
	match skill_instance.player_animation:
		"idle":
			player.animation_handler.play_idle_animation(direction)

		"walk":
			player.animation_handler.play_walking_animation(direction)

		_:
			# Default to idle if unknown animation type
			player.animation_handler.play_idle_animation(direction)


func _store_animation_direction_for_skill(skill_instance: BaseSkill):
	# Store the direction when skill starts to use consistently throughout skill duration
	match skill_instance.animation_direction:
		"last_direction":
			stored_animation_direction = player.last_direction

		"cursor_direction":
			# Calculate cursor direction relative to player
			var mouse_pos = player.get_global_mouse_position()
			stored_animation_direction = (mouse_pos - player.global_position).normalized()
			# Update player's last_direction to maintain cursor direction after skill
			player.last_direction = stored_animation_direction

		_:
			# Default to last direction
			stored_animation_direction = player.last_direction


func enter():

	
	# Ensure skill manager is initialized
	_ensure_skill_manager()
	
	# Check if skill manager was successfully created
	if not skill_manager:

		_exit_to_previous_state()
		return
	
	# Get cursor direction from player position
	var mouse_pos = player.get_global_mouse_position()
	var cursor_direction = (mouse_pos - player.global_position).normalized()
	
	# Try to activate slash skill directly from scene
	var slash_scene = preload("res://player/skills/basic/slash/slash.tscn")
	var slash_instance = slash_scene.instantiate()
	
	if slash_instance:
		# Store reference to current skill
		current_skill_instance = slash_instance
		
		# Store the animation direction when skill starts
		_store_animation_direction_for_skill(slash_instance)
		
		# Set player animation based on skill preference
		_set_player_animation_for_skill(slash_instance)
		
		# Add to player and activate
		player.add_child(slash_instance)
		
		# Toggle flip state and apply to sprite
		slash_flip_h = !slash_flip_h
		if slash_instance.sprite:
			slash_instance.sprite.flip_h = slash_flip_h
		
		# Position skill based on direction
		var offset = cursor_direction * slash_instance.offset_distance
		slash_instance.position = offset
		
		# Connect skill finished signal
		if not slash_instance.skill_finished.is_connected(_on_skill_finished):
			slash_instance.skill_finished.connect(_on_skill_finished.bind("Slash"))
		
		# Activate the skill
		if slash_instance.activate(cursor_direction, player):
			current_skill_name = "Slash"

		else:

			slash_instance.queue_free()
			current_skill_instance = null
			_exit_to_previous_state()
	else:

		_exit_to_previous_state()
	
	# Stop player movement during skill
	player.velocity = Vector2.ZERO

func update(_delta: float):
	# Update player animation during skill if needed
	if current_skill_instance and player and player.animation_handler:
		_set_player_animation_for_skill(current_skill_instance)

func physics_update(_delta: float):
	# Keep player stationary during skill
	player.velocity = Vector2.ZERO
	player.move_and_slide()

func _on_skill_finished(_skill_name: String):

	current_skill_name = ""
	current_skill_instance = null
	
	# Check if player should return to walking or idle
	var input_direction = InputManager.get_direction_input()
	if input_direction.length() > 0:

		state_machine.change_state("walkingstate")
	else:

		state_machine.change_state("idlestate")

func _exit_to_previous_state():
	# Fallback if skill activation fails
	var input_direction = InputManager.get_direction_input()
	if input_direction.length() > 0:
		state_machine.change_state("walkingstate")
	else:
		state_machine.change_state("idlestate")

func exit():
	# Disconnect from skill manager signals
	if skill_manager and skill_manager.skill_finished.is_connected(_on_skill_finished):
		skill_manager.skill_finished.disconnect(_on_skill_finished)
