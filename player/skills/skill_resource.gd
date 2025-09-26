@tool
extends Resource
class_name SkillResource

# Resource class for skill configuration data
# This allows skills to be configured in the editor and saved as .tres files

@export_group("Basic Info")
@export var skill_name: String = "Unnamed Skill"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Mechanics")
@export var skill_scene: PackedScene  # The scene file for the skill
@export var skill_duration: float = 1.0
@export var cooldown_time: float = 1.0
@export var energy_cost: int = 0

@export_group("Behavior")
@export var can_move_during_skill: bool = false
@export var can_be_interrupted: bool = true
@export var requires_target: bool = false
@export var max_range: float = 100.0

@export_group("Animation")
@export var animation_name: String = ""
@export var use_player_animation: bool = false  # Whether to also play animation on player

@export_group("Effects")
@export var damage: int = 0
@export var knockback_force: float = 0.0
@export var status_effects: Array[String] = []

@export_group("Audio")
@export var activation_sound: AudioStream
@export var impact_sound: AudioStream

# Validation
func is_valid() -> bool:
	return skill_name != "" and skill_scene != null

# Get skill data as dictionary
func to_dict() -> Dictionary:
	return {
		"name": skill_name,
		"description": description,
		"duration": skill_duration,
		"cooldown": cooldown_time,
		"energy_cost": energy_cost,
		"can_move": can_move_during_skill,
		"can_interrupt": can_be_interrupted,
		"requires_target": requires_target,
		"max_range": max_range,
		"damage": damage,
		"knockback_force": knockback_force,
		"status_effects": status_effects
	}

# Create skill instance from this resource
func create_skill_instance() -> BaseSkill:
	if not skill_scene:
		print("Error: No skill scene assigned to %s" % skill_name)
		return null
	
	var skill_instance = skill_scene.instantiate()
	if not skill_instance is BaseSkill:
		print("Error: Skill scene must inherit from BaseSkill")
		skill_instance.queue_free()
		return null
	
	# Apply resource properties to the skill instance
	skill_instance.skill_name = skill_name
	skill_instance.skill_duration = skill_duration
	skill_instance.cooldown_time = cooldown_time
	skill_instance.energy_cost = energy_cost
	skill_instance.can_move_during_skill = can_move_during_skill
	skill_instance.can_be_interrupted = can_be_interrupted
	
	return skill_instance
