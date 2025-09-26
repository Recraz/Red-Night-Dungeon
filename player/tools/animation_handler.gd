extends Node
class_name AnimationHandler

@onready var animated_sprite: AnimatedSprite2D
var player: CharacterBody2D

# Animation states
enum AnimationType {
	IDLE,
	WALKING
}

# Direction mappings
enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

# Animation name mappings
var animation_names = {
	AnimationType.IDLE: {
		Direction.UP: "idle_up",
		Direction.DOWN: "idle_down",
		Direction.LEFT: "idle_left",
		Direction.RIGHT: "idle_right"
	},
	AnimationType.WALKING: {
		Direction.UP: "walk_up",
		Direction.DOWN: "walk_down",
		Direction.LEFT: "walk_left",
		Direction.RIGHT: "walk_right"
	}
}

func _ready():
	player = get_parent()
	animated_sprite = player.get_node("AnimatedSprite2D")

func play_animation(animation_type: AnimationType, direction_vector: Vector2):
	if not animated_sprite:
		return
	
	var direction = get_direction_from_vector(direction_vector)
	var animation_name = animation_names[animation_type][direction]
	
	# Always play the animation to ensure it starts properly
	animated_sprite.play(animation_name)

func play_idle_animation(direction_vector: Vector2):
	play_animation(AnimationType.IDLE, direction_vector)

func play_walking_animation(direction_vector: Vector2):
	play_animation(AnimationType.WALKING, direction_vector)

func get_direction_from_vector(direction_vector: Vector2) -> Direction:
	# Determine primary direction based on which component is larger
	if abs(direction_vector.x) > abs(direction_vector.y):
		return Direction.RIGHT if direction_vector.x > 0 else Direction.LEFT
	else:
		return Direction.DOWN if direction_vector.y > 0 else Direction.UP

func get_current_animation() -> String:
	return animated_sprite.animation

func is_playing(animation_name: String) -> bool:
	return animated_sprite.animation == animation_name

func stop_animation():
	animated_sprite.stop()

func set_animation_speed(speed: float):
	animated_sprite.speed_scale = speed

func get_animation_speed() -> float:
	return animated_sprite.speed_scale
