extends RayCast2D
var from:Entity
var to:Entity
var period:=1
func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames()%period==0:
		period=max(1,480/Engine.get_frames_per_second())
		target_position=from.to_local(to.global_position)
