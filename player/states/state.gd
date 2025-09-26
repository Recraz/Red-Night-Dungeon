extends Node
class_name State

# Reference to the player
var player: CharacterBody2D
var state_machine: StateMachine

# Virtual methods to be overridden by child states
func enter():
	pass

func exit():
	pass

func update(_delta: float):
	pass

func physics_update(_delta: float):
	pass

func handle_input(_event: InputEvent):
	pass
