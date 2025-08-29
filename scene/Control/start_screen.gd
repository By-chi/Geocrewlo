extends ColorRect
@export var logo:TextureRect
var tween:Tween
const logo_textures:=[
	"res://texture/logo/logo_large_color_light.svg",
	"res://texture/logo/icon.jpg",
	"res://texture/logo/game_icon.svg",
]
const mian_scene:="res://scene/Control/main_menu.tscn"
func _ready() -> void:
	tween=logo.create_tween().set_loops(logo_textures.size())
	tween.tween_method(
		func(value:=0.0):
			logo.material.set_shader_parameter("burst_progress",value)
	,1.0,0.0,0.7).set_trans(Tween.TRANS_QUAD)
	tween.loop_finished.connect(
		func(loop_count: int):
		logo.texture=load(logo_textures[loop_count])
		)
	tween.finished.connect(
		func():
			get_tree().change_scene_to_file(mian_scene)
	)
