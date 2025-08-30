extends Control
var selective_id:int
func _ready()->void:
	if Global.player.gun!=null:
		select(Global.player.gun.id)
	for i in GunData.names.size():
		var option:=Button.new()
		option.icon=GunData.textures[i]
		option.custom_minimum_size.y=40
		option.add_theme_stylebox_override("normal",preload("res://scene/Control/button_normal.stylebox"))
		option.add_theme_stylebox_override("hover",preload("res://scene/Control/button_hover.stylebox"))
		option.add_theme_font_size_override("font_size",40)
		option.pressed.connect(select.bind(i))
		$Left/ScrollContainer/VBoxContainer.add_child(option)
func select(id:int)->void:
	selective_id=id
	$Right/Name.text=GunData.names[id]
	$Right/Show/TextureRect.texture=GunData.textures[id]


func _on_equip_pressed() -> void:
	Global.player.replacement_gun_id=selective_id
	queue_free()

func _on_back_pressed() -> void:
	queue_free()
