extends Node2D
class_name BaseSkill

# Base class for all player skills
# This provides a common interface and functionality for all skills

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Signals
signal skill_started
signal skill_finished
signal skill_interrupted

# Skill properties
@export var skill_name: String = "BaseSkill"
@export var skill_duration: float = 1.0
@export var cooldown_time: float = 1.0
@export var energy_cost: int = 0
@export var offset_distance: float = 20.0
@export var can_move_during_skill: bool = false
@export var can_be_interrupted: bool = true
@export_enum("idle", "walk") var player_animation: String = "idle"
@export_enum("last_direction", "cursor_direction") var animation_direction: String = "last_direction"

# Internal state
var is_active: bool = false
var skill_direction: Vector2 = Vector2.RIGHT
var caster: Node2D = null

func _ready():
	# Override in derived classes if needed
	pass

# Called when the skill is activated
func activate(direction: Vector2, skill_caster: Node2D = null):
	if is_active:
		print("Skill %s is already active!" % skill_name)
		return false
	
	is_active = true
	skill_direction = direction.normalized()
	caster = skill_caster
	
	# Set position and rotation based on direction
	set_direction(skill_direction)
	
	# Emit signal and start skill
	skill_started.emit()
	_on_skill_start()
	
	return true

# Set the rotation/orientation of the skill
func set_direction(direction: Vector2):
	if direction.length() > 0:
		var angle = direction.angle()
		rotation = angle

# Override this in derived classes for specific skill behavior
func _on_skill_start():
	# Default behavior: start animation
	start_animation()

# Start the skill animation
func start_animation():
	if animation_player and animation_player.has_animation(skill_name.to_lower()):
		animation_player.play(skill_name.to_lower())
		# Connect to animation finished if not already connected
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
	else:
		# Fallback: use a timer for skill duration
		var timer = Timer.new()
		timer.wait_time = skill_duration
		timer.one_shot = true
		timer.timeout.connect(_on_skill_timeout)
		add_child(timer)
		timer.start()

# Called when skill should be interrupted
func interrupt():
	if not can_be_interrupted or not is_active:
		return false
	
	is_active = false
	skill_interrupted.emit()
	_cleanup()
	return true

# Get the duration of this skill
func get_skill_duration() -> float:
	if animation_player and animation_player.has_animation(skill_name.to_lower()):
		return animation_player.get_animation(skill_name.to_lower()).length
	return skill_duration

# Check if skill is currently active
func is_skill_active() -> bool:
	return is_active

# Animation finished callback
func _on_animation_finished(_animation_name: String):
	if is_active:
		_finish_skill()

# Timer fallback finished callback
func _on_skill_timeout():
	if is_active:
		_finish_skill()

# Internal method to finish the skill
func _finish_skill():
	is_active = false
	skill_finished.emit()
	_cleanup()

# Override this in derived classes for cleanup
func _cleanup():
	# Clean up timers
	for child in get_children():
		if child is Timer:
			child.queue_free()
	
	# Remove self from scene
	queue_free()

# Get skill data as dictionary (useful for save/load or UI)
func get_skill_data() -> Dictionary:
	return {
		"name": skill_name,
		"duration": skill_duration,
		"cooldown": cooldown_time,
		"energy_cost": energy_cost,
		"can_move": can_move_during_skill,
		"can_interrupt": can_be_interrupted
	}
