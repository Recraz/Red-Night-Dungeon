extends CharacterBody2D

@export var speed = 100.0
@onready var animated_sprite = $AnimatedSprite2D
@onready var state_machine = $StateMachine
@onready var animation_handler = $AnimationHandler


var last_direction = Vector2.DOWN

func _ready():

	
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
