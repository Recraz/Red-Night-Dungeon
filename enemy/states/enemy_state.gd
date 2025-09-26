extends Node
class_name EnemyState

# Reference to the enemy
var enemy: Enemy
var state_machine: EnemyStateMachine

# Virtual methods to be overridden by child states
func enter():
	pass

func exit():
	pass

func update(_delta: float):
	pass

func physics_update(_delta: float):
	pass