extends SubViewport
@export var camera:Camera2D
func _ready() -> void:
	world_2d=get_tree().root.world_2d
	get_tree().root.set_canvas_cull_mask_bit(1,false)
func _physics_process(delta: float) -> void:
	camera.position=Global.player.position
