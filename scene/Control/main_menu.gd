extends CanvasLayer
@export var background:ColorRect
@export var button_list:VBoxContainer
var tween:Tween
var gradient :GradientTexture2D
var button_func={
	"Start":func():
	get_tree().change_scene_to_file("res://scene/Control/readiness_menu.tscn")
	,
	"Quit":func():
	get_tree().quit()
	,
	"Options":func():
	Global.menu._on_set_pressed()
	,
}
func _ready() -> void:
	gradient= background.material.get_shader_parameter("gradient")
	tween=background.create_tween()
	tween.tween_method(
		func(value:=0.0):
			gradient.fill_from.x=value
			button_list.size.x=(1-value)*308
			background.material.set_shader_parameter("gradient",gradient)
	,1.0,0.0,0.7).set_trans(Tween.TRANS_QUAD)
	for button in button_list.get_children():
		if button is Button:
			button.mouse_entered.connect(func():
				var button_tween:Tween=button.create_tween()
				button_tween.tween_method(
				func(value:=0.0):
					button.get_theme_stylebox("hover").content_margin_left=value
					button.get_theme_stylebox("normal").content_margin_left=value
				,button.get_theme_stylebox("normal").content_margin_left,button_list.size.x/2,0.2).set_trans(Tween.TRANS_QUAD)
			)
			button.mouse_exited.connect(func():
				var button_tween:Tween=button.create_tween()
				button_tween.tween_method(
				func(value:=0.0):
					button.get_theme_stylebox("normal").content_margin_left=value
					button.get_theme_stylebox("hover").content_margin_left=value
				,button.get_theme_stylebox("hover").content_margin_left,4.0,0.2).set_trans(Tween.TRANS_QUAD)
			)
			button.pressed.connect(button_func[button.name])
