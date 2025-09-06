# 继承自Entity基类，专门实现玩家实体的逻辑（扩展输入控制、瞄准、视角调整等玩家专属功能）
extends Entity

# 重生时替换枪支的ID（-1表示不替换，使用原枪支配置）
var replacement_gun_id:=-1

# 玩家实体初始化方法（重写并扩展父类逻辑）
func init() -> void:
	# 启用玩家专属相机（用于游戏视角跟随）
	camera.enabled=true
	# 标记当前实体为玩家（区别于AI）
	is_player=true
	# 同步玩家精灵颜色（继承自阵营配置）
	sprite.self_modulate=self_modulate
	# 初始化时调整视野范围（适配初始窗口大小）
	resize_view()
	# 绑定窗口大小变化事件（窗口缩放时自动调整视野）
	get_viewport().size_changed.connect(resize_view)
	# 显示方向线（玩家移动/瞄准方向的可视化调试/提示）
	direction_line.visible=true

# 玩家重生逻辑（重写父类虚函数，处理玩家专属重生行为）
func rebirth()->void:
	# 若指定了重生替换枪支ID，处理枪支配置
	if replacement_gun_id!=-1:
		if gun!=null:  # 若已有枪支，重置并应用替换ID
			gun.is_init=true  # 重新初始化枪支
			gun.id=replacement_gun_id  # 赋值替换枪支ID（触发枪支属性更新）
		else:  # 若无枪支，实例化新枪支并配置
			var gun_node:=preload("res://scene/Gun/gun.tscn").instantiate()  # 加载枪支场景
			add_child(gun_node)  # 将枪支添加为玩家子节点
			gun.is_init=true  # 初始化枪支
			gun_node.id=replacement_gun_id  # 应用替换枪支ID

# 根据窗口大小和相机缩放，调整玩家视野碰撞体大小（确保视野范围适配屏幕）
func resize_view()->void:
	# 遍历所有实体（玩家和AI），更新它们的视野碰撞体大小
	for i in Global.entity_list:
		for j in i:
			# 视野碰撞体大小 = 窗口大小 / 相机缩放比例（保证视野覆盖屏幕范围）
			j.view.get_node("CollisionShape2D").shape.size=Vector2(get_window().size)/camera.zoom

# 玩家枪支旋转逻辑（重写父类方法，实现“瞄准鼠标”功能）
func rotate_gun()->void:
	# 让枪支朝向鼠标的全局位置（核心：玩家通过鼠标控制瞄准方向）
	gun.look_at(get_global_mouse_position())
	super.rotate_gun()  # 调用父类方法（处理枪支精灵翻转，适配左右朝向）
	direction_line.rotation=gun.rotation  # 同步方向线旋转（可视化瞄准方向）

# 瞄准状态下的视角移动灵敏度（控制鼠标拖动视角的速度）
var aim_move_sensitivity:=2.5

# 玩家输入事件处理（重写父类虚函数，响应键盘/鼠标输入）
func _input(event: InputEvent) -> void:
	# 处理鼠标移动事件（仅在瞄准状态下生效）
	if event is InputEventMouseMotion:
		if aiming:
			# 瞄准状态下，鼠标拖动控制相机位置（实现视角平移）
			camera.position+=event.relative*aim_move_sensitivity

# 瞄准状态标记（控制视角模式和鼠标显示），带setter方法处理状态切换
var aiming:=false:
	set(value):
		aiming=value  # 更新瞄准状态
		if aiming:
			# 瞄准状态：捕获鼠标（鼠标隐藏，仅通过移动控制视角）
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			# 非瞄准状态：隐藏鼠标+重置相机位置（视角回归玩家中心）
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			camera.position=Vector2.ZERO

# 玩家每帧逻辑处理（重写父类方法，响应按键输入）
func _process(delta: float) -> void:
	super._process(delta)  # 调用父类_process（处理枪支旋转等基础逻辑）
	
	# 按键响应：按住“射击”键，执行射击
	if Input.is_action_pressed("射击"):
		shoot()
	# 按键响应：按下“冲刺”键，执行冲刺
	elif Input.is_action_just_pressed("冲刺"):
		sprint()
	# 按键响应：按下“换弹”键，且持有枪支时，执行换弹
	elif Input.is_action_just_pressed("换弹")&&gun!=null:
		gun.reload()
	# 按键响应：按下“瞄准”键，切换瞄准状态（开启/关闭）
	elif Input.is_action_just_pressed("瞄准"):
		aiming=!aiming
	# 按键响应：按下“丢弃”键，丢弃当前持有枪支
	elif Input.is_action_just_pressed("丢弃"):
		drop_gun()
	# 按键响应：按下“拾取”键，拾取附近枪支
	elif Input.is_action_just_pressed("拾取"):
		pick_up_gun()

# 玩家物理帧更新（重写父类方法，保持基础物理逻辑）
func _physics_process(delta: float) -> void:
	super._physics_process(delta)  # 调用父类_physics_process（处理移动、碰撞等）

# 玩家移动逻辑（重写父类虚函数，通过输入向量控制移动）
func move() -> void:
	super.move()  # 调用父类move（空实现，预留扩展）
	# 从输入系统获取移动向量：水平（左/右）、垂直（前/后），归一化后乘速度
	move_velocity=Input.get_vector("向左","向右","前进","后退").normalized()*speed
