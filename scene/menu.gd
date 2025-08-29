extends ColorRect


func _on_bagpack_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	hide()
	get_tree().paused=false
	get_tree().change_scene_to_file("res://scene/Control/main_menu.tscn")


func _on_set_pressed() -> void:
	$"../../CanvasLayer3/Options".show()


func _on_continue_pressed() -> void:
	hide()
	get_tree().paused=false
