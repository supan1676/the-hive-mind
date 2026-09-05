extends AIController3D

# This script just forwards the questions to the Enemy Parent
@onready var enemy = get_parent()

func get_obs() -> Dictionary:
	return enemy.get_obs()

func get_reward() -> float:
	return enemy.get_reward()

func get_action_space() -> Dictionary:
	return enemy.get_action_space()

func set_action(action):
	enemy.set_action(action)
