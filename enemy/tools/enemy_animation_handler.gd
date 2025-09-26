extends Node
class_name EnemyAnimationHandler

@onready var animated_sprite: AnimatedSprite2D

func _ready():
	# Get the AnimatedSprite2D from parent
	animated_sprite = get_parent().get_node("AnimatedSprite2D")
	
	if not animated_sprite:
		# AnimatedSprite2D not found, handle gracefully
		return

func play_idle_animation(direction: Vector2):
	if not animated_sprite:
		return
	
	# Determine which idle animation to play based on direction
	var animation_name: String
	
	if abs(direction.x) > abs(direction.y):
		# Horizontal movement
		if direction.x > 0:
			animation_name = "idle_right"
		else:
			animation_name = "idle_left"
	else:
		# Vertical movement
		if direction.y > 0:
			animation_name = "idle_down"
		else:
			animation_name = "idle_up"
	
	animated_sprite.play(animation_name)

func play_walking_animation(direction: Vector2):
	if not animated_sprite:
		return
	
	# Determine which walking animation to play based on direction
	var animation_name: String
	
	if abs(direction.x) > abs(direction.y):
		# Horizontal movement
		if direction.x > 0:
			animation_name = "walk_right"
		else:
			animation_name = "walk_left"
	else:
		# Vertical movement
		if direction.y > 0:
			animation_name = "walk_down"
		else:
			animation_name = "walk_up"
	
	animated_sprite.play(animation_name)