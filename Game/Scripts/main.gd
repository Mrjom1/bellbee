extends Node

## Owns the current screen (title or stage) and swaps between them.

var current: Node


func _ready() -> void:
	Game.main = self
	show_title()


func show_title() -> void:
	get_tree().paused = false
	_swap(Title.new())


func start_stage() -> void:
	get_tree().paused = false
	_swap(Stage.new())


func _swap(node: Node) -> void:
	if current != null:
		current.queue_free()
	current = node
	add_child(node)
