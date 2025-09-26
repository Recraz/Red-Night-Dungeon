extends BaseSkill
class_name Slash

func _ready():
	# Call parent ready
	super._ready()
	
	# Only set values that aren't configured in the editor
	if skill_name == "BaseSkill":  # Only set if not already configured
		skill_name = "Slash"

func _on_skill_start():
	# Slash-specific behavior

	start_animation()

func start_animation():

	# Play the slash animation
	if animation_player:

		animation_player.play("slash")
		# Connect to animation finished signal to destroy the slash
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
	else:

		# Use parent's fallback timer system
		super.start_animation()

# Override to add timing debug
func _on_animation_finished(_animation_name: String):

	super._on_animation_finished(_animation_name)
