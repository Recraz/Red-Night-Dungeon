extends Node
class_name SkillManager

# Skill Manager - Handles skill registration, cooldowns, and execution
# This is a singleton that manages all skills for the player

signal skill_activated(skill_name: String)
signal skill_finished(skill_name: String)
signal skill_cooldown_finished(skill_name: String)

# Registered skills
var registered_skills: Dictionary = {}  # skill_name -> SkillResource
var skill_cooldowns: Dictionary = {}    # skill_name -> float (remaining time)
var active_skills: Array[BaseSkill] = []
var current_player: Node2D = null

# Energy/mana system
var max_energy: int = 100
var current_energy: int = 100
var energy_regen_rate: float = 10.0  # per second

func _ready():
	# Start energy regeneration
	set_process(true)

func _process(delta: float):
	# Update cooldowns
	_update_cooldowns(delta)
	
	# Regenerate energy
	_regenerate_energy(delta)
	
	# Clean up finished skills
	_cleanup_finished_skills()

# Set the player reference
func set_player(player: Node2D):
	current_player = player

# Register a skill using a SkillResource
func register_skill(skill_resource: SkillResource) -> bool:
	if not skill_resource or not skill_resource.is_valid():
		print("SkillManager: Invalid skill resource")
		return false
	
	registered_skills[skill_resource.skill_name] = skill_resource
	skill_cooldowns[skill_resource.skill_name] = 0.0
	print("SkillManager: Registered skill '%s'" % skill_resource.skill_name)
	return true

# Register multiple skills at once
func register_skills(skill_resources: Array[SkillResource]):
	for skill_resource in skill_resources:
		register_skill(skill_resource)

# Check if a skill is available (registered, not on cooldown, enough energy)
func is_skill_available(skill_name: String) -> bool:
	if not registered_skills.has(skill_name):
		return false
	
	var skill_resource = registered_skills[skill_name]
	
	# Check cooldown
	if skill_cooldowns[skill_name] > 0:
		return false
	
	# Check energy cost
	if current_energy < skill_resource.energy_cost:
		return false
	
	# Check if player is already using a non-interruptible skill
	for active_skill in active_skills:
		if not active_skill.can_be_interrupted:
			return false
	
	return true

# Activate a skill
func activate_skill(skill_name: String, direction: Vector2 = Vector2.RIGHT) -> bool:
	if not is_skill_available(skill_name):
		print("SkillManager: Skill '%s' is not available" % skill_name)
		return false
	
	var skill_resource = registered_skills[skill_name]
	var skill_instance = skill_resource.create_skill_instance()
	
	if not skill_instance:
		print("SkillManager: Failed to create skill instance for '%s'" % skill_name)
		return false
	
	# Add skill to the player
	if current_player:
		current_player.add_child(skill_instance)
		
		# Position skill based on direction and player position
		var offset_distance = 20.0  # Default offset
		var offset = direction.normalized() * offset_distance
		skill_instance.position = offset
	
	# Activate the skill
	if skill_instance.activate(direction, current_player):
		# Consume energy
		current_energy -= skill_resource.energy_cost
		
		# Start cooldown
		skill_cooldowns[skill_name] = skill_resource.cooldown_time
		
		# Track active skill
		active_skills.append(skill_instance)
		
		# Connect signals
		skill_instance.skill_finished.connect(_on_skill_finished.bind(skill_name, skill_instance))
		skill_instance.skill_interrupted.connect(_on_skill_interrupted.bind(skill_name, skill_instance))
		
		# Emit signal
		skill_activated.emit(skill_name)
		
		print("SkillManager: Activated skill '%s'" % skill_name)
		return true
	else:
		# Failed to activate, clean up
		skill_instance.queue_free()
		return false

# Get all registered skill names
func get_registered_skills() -> Array[String]:
	return registered_skills.keys()

# Get skill resource by name
func get_skill_resource(skill_name: String) -> SkillResource:
	return registered_skills.get(skill_name)

# Get remaining cooldown time for a skill
func get_skill_cooldown(skill_name: String) -> float:
	return skill_cooldowns.get(skill_name, 0.0)

# Interrupt all active skills (useful for state changes)
func interrupt_all_skills():
	for skill in active_skills.duplicate():  # Use duplicate to avoid modification during iteration
		skill.interrupt()

# Force finish all skills (emergency cleanup)
func force_finish_all_skills():
	for skill in active_skills.duplicate():
		skill._finish_skill()

# Energy management
func set_max_energy(value: int):
	max_energy = value
	current_energy = min(current_energy, max_energy)

func get_current_energy() -> int:
	return current_energy

func get_max_energy() -> int:
	return max_energy

func add_energy(amount: int):
	current_energy = min(current_energy + amount, max_energy)

func consume_energy(amount: int) -> bool:
	if current_energy >= amount:
		current_energy -= amount
		return true
	return false

# Private methods
func _update_cooldowns(delta: float):
	for skill_name in skill_cooldowns.keys():
		if skill_cooldowns[skill_name] > 0:
			skill_cooldowns[skill_name] -= delta
			if skill_cooldowns[skill_name] <= 0:
				skill_cooldowns[skill_name] = 0
				skill_cooldown_finished.emit(skill_name)

func _regenerate_energy(delta: float):
	if current_energy < max_energy:
		add_energy(int(energy_regen_rate * delta))

func _cleanup_finished_skills():
	# Remove null references (skills that have been queue_free'd)
	active_skills = active_skills.filter(func(skill): return is_instance_valid(skill))

func _on_skill_finished(skill_name: String, skill_instance: BaseSkill):
	active_skills.erase(skill_instance)
	skill_finished.emit(skill_name)
	print("SkillManager: Skill '%s' finished" % skill_name)

func _on_skill_interrupted(skill_name: String, skill_instance: BaseSkill):
	active_skills.erase(skill_instance)
	print("SkillManager: Skill '%s' interrupted" % skill_name)
