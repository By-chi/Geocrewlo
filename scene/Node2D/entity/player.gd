extends Entity

func init() -> void:
	camera.enabled=true
	is_player=true
	sprite.self_modulate=self_modulate
	resize_view()
	get_viewport().size_changed.connect(resize_view)
	direction_line.visible=true
func resize_view()->void:
	for i in Global.game_main.entity_list:
		for j in i:
			j.view.get_node("CollisionShape2D").shape.size=Vector2(get_window().size)/camera.zoom
func rotate_gun()->void:
	gun.look_at(get_global_mouse_position())
	#gun.rotation=lerpf((get_global_mouse_position()-gun.global_position).angle(),gun.rotation,0.9)
	super.rotate_gun()
	direction_line.rotation=gun.rotation
var aim_move_sensitivity:=2.5
func _input(event: InputEvent) -> void:
	#if event is InputEventKey:
		#
	if event is InputEventMouseMotion:
		if aiming:
			camera.position+=event.relative*aim_move_sensitivity
var aiming:=false:
	set(value):
		aiming=value
		if aiming:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			camera.position=Vector2.ZERO
func _process(delta: float) -> void:
	super._process(delta)
	if Input.is_action_pressed("射击"):
		shoot()
	if Input.is_action_just_pressed("冲刺"):
			sprint()
	elif Input.is_action_just_pressed("换弹"):
		gun.reload()
	elif Input.is_action_just_pressed("瞄准"):
		aiming=!aiming
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
func move() -> void:
	super.move()
	move_velocity=Input.get_vector("向左","向右","前进","后退").normalized()*speed
