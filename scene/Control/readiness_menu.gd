extends Control


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Control/main_menu.tscn")

@export var map:OptionButton
@export var mode:OptionButton
@export var population:SpinBox
@export var AI_level:SpinBox
func _on_continue_pressed() -> void:
	Global.init_args={
		"Map":map.selected,
		"Mode":mode.selected,
		"Population":int(population.value),
		"AI_Level":AI_level.value,
	}
	get_tree().change_scene_to_file("res://scene/Node2D/main.tscn")
