extends ColorRect


func _on_bagpack_pressed() -> void:
	var bagpack:=preload("res://scene/Control/bagpack.tscn").instantiate()
	$"../../CanvasLayer3".add_child(bagpack)

func _on_quit_pressed() -> void:
	hide()
	get_tree().paused=false
	get_tree().change_scene_to_file("res://scene/Control/main_menu.tscn")


func _on_set_pressed() -> void:
	$"../../CanvasLayer3/Options".show()


func _on_continue_pressed() -> void:
	hide()
	if Global.player.aiming:
		Input.mouse_mode=Input.MOUSE_MODE_HIDDEN
	get_tree().paused=false
