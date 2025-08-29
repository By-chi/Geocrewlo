extends RayCast2D
var from:Entity
var to:Entity
func _physics_process(delta: float) -> void:
	target_position=from.to_local(to.global_position)
