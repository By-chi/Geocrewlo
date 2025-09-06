# 继承自Entity类，实现游戏中AI实体的核心逻辑（目标检测、移动、射击、闪避等行为）
extends Entity

# 关联的 TileMapLayer，用于AI的路径查找和地图位置计算
var map:TileMapLayer

# 慢反应相关变量（模拟AI思考延迟）
var reaction_delay_ms: int = 800-Global.init_args["AI_Level"]*125:  # 反应延迟（毫秒），AI等级越高延迟越低
	set(value):
		reaction_delay_ms=value
		await get_tree().create_timer(0.1).timeout
		reaction_delay_ms=800-Global.init_args["AI_Level"]*125
var detected_target  # 即时检测到的潜在目标（未经过延迟确认）
var target_detected_time: int = 0  # 首次检测到目标的时间戳（用于计算延迟）
var target_lost_time: int = 0  # 丢失目标的起始时间戳（用于延迟确认丢失）

# 实际跟踪的目标及位置（经过延迟处理）
var target_entity  # 经过反应延迟后确认的目标实体
var target_position:=Vector2.ZERO  # 目标的瞄准位置（可能包含预瞄偏移）

# 计算子弹预瞄点（考虑目标移动速度和子弹速度，实现提前射击）
# 参数：a_pos-目标位置, b_pos-自身位置, a_move_v-目标移动速度, bullet_speed-子弹速度
func get_optimized_aim_point(a_pos: Vector2, b_pos: Vector2, a_move_v: Vector2, bullet_speed: float) -> Vector2:
	# 计算子弹飞行时间（距离/子弹速度），再根据目标移动速度计算提前量
	return a_pos + a_move_v * (a_pos - b_pos).length() / bullet_speed

# 每帧更新逻辑
func _process(delta: float) -> void:
	super._process(delta)  # 调用父类的_process方法
	
	# 每2帧执行一次目标检测（优化性能）
	if Engine.get_physics_frames()%2==0:
		var old_detected = detected_target  # 记录上一帧检测到的目标
		detected_target = null  # 重置当前检测目标
		
		# 检测潜在目标（遍历敌对阵营实体）
		for i in Global.camp_view[camp].size():
			# 检查视野内是否有可见目标（无遮挡）
			if Global.camp_view[camp][i] && no_obstruction[i]:
				var potential_target = Global.entity_list[camp-1][i]
				# 跳过已死亡的目标
				if potential_target.is_dead:
					continue
				
				# 确认检测到有效目标
				detected_target = potential_target
				var aim_pos:Vector2=detected_target.global_position  # 基础瞄准位置为目标位置
				
				# 根据AI等级或设置添加随机瞄准偏移（模拟精度误差）
				if Global.init_args["AI_Level"]<7||Global.option_data["AI"]["AI 预瞄"]:
					aim_pos+=Vector2(randf(),randf())*(35-Global.init_args["AI_Level"]*5)  # 等级越高偏移越小
				
				# 计算预瞄位置（高等级AI使用）
				if Global.init_args["AI_Level"] >= 6&&gun!=null:
					target_position = get_optimized_aim_point(
						aim_pos,  # 目标位置（含随机偏移）
						global_position,  # 自身位置
						detected_target.velocity,  # 目标移动速度
						GunData.bullet_speeds[gun.id]  # 当前枪支子弹速度
					)
				else:
					target_position = aim_pos  # 低等级AI直接瞄准目标当前位置
				
				break  # 找到第一个目标后停止检测
		
		# 处理目标检测的延迟逻辑
		var current_time = Time.get_ticks_msec()
		if detected_target != null:
			# 若检测到新目标，更新检测时间戳
			if old_detected != detected_target:
				target_detected_time = current_time
			
			# 当检测时间超过反应延迟，确认目标
			if current_time - target_detected_time >= reaction_delay_ms:
				target_entity = detected_target
		else:
			# 处理目标丢失的延迟逻辑
			if target_entity != null:
				# 首次丢失目标时记录时间
				if target_lost_time == 0:
					target_lost_time = current_time
				
				# 超过延迟时间后确认丢失目标
				if current_time - target_lost_time >= reaction_delay_ms:
					target_entity = null
					target_lost_time = 0
			else:
				target_lost_time = 0
		
		# 目标丢失后的追踪逻辑（高等级AI或开启追踪时生效）
		if target_entity == null && old_detected != null && (Global.init_args["AI_Level"] >= 4||Global.option_data["AI"]["AI 追踪"])&&target_position != Vector2.ZERO && move_name != "Track the enemy":
				# 设置目标位置为地图坐标，开始追踪
				destination = map.local_to_map(map.to_local(target_position))
				move_name = "Track the enemy"  # 标记移动状态为追踪敌人
	
	# 若有确认目标且开启AI攻击，执行射击
	if target_entity != null:
		if Global.option_data["AI"]["AI 攻击"]:
			reaction_delay_ms=800-Global.init_args["AI_Level"]*125*0.65
			shoot()
	# 无目标时自动换弹
	elif gun!=null:
		reaction_delay_ms=800-Global.init_args["AI_Level"]*125*0.65
		gun.reload()

# 记录当前移动状态的名称（用于调试和状态标识）
var move_name:="Free"

# 射击逻辑（重写父类方法）
func shoot()->void:
	super.shoot()  # 调用父类射击方法
	# 弹夹为空时自动换弹
	if gun.clip_capacity == 0:
		gun.reload()

# 旋转枪支瞄准目标
func rotate_gun()->void:
	if target_entity == null:
		return
	# 让枪支瞄准目标位置
	gun.look_at(target_position)
	super.rotate_gun()  # 调用父类旋转方法

# 用于检测子弹的闪避区域
var dodge_area:Area2D

# 初始化AI实体
func init() -> void:
	camera.enabled = false  # 禁用AI的相机
	is_player = false  # 标记为非玩家实体
	sprite.self_modulate = self_modulate  # 设置精灵颜色
	map = Global.game_main.map  # 获取地图引用
	# 随机设置初始目的地（从地图空点中选择）
	destination = map.empty_tiles[randi()%map.empty_tiles.size()]
	move_name = "Take a casual stroll"  # 初始移动状态为闲逛
	is_pathfinding = true  # 开启寻路
	
	# 根据AI等级调整反应延迟（最低100ms）
	reaction_delay_ms = max(100, 800 - Global.init_args["AI_Level"] * 100)
	
	# 创建闪避区域（用于检测接近的子弹）
	dodge_area = Area2D.new()
	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = CircleShape2D.new()
	# 闪避区域半径随AI等级提升（最大400）
	collision_shape.shape.radius = min(Global.init_args["AI_Level"]*50, 400)
	# 绑定区域进入事件（检测子弹）
	dodge_area.area_entered.connect(on_area_entered_dodge_area)
	dodge_area.add_child(collision_shape)
	add_child(dodge_area)
	
	# 冲刺计时器超时回调（恢复寻路）
	sprint_timer.timeout.connect(func():
		is_pathfinding = true
		)

# 子弹进入闪避区域时触发的闪避逻辑
func on_area_entered_dodge_area(area: Area2D)->void:
	# 若关闭AI闪避，则不处理
	if !Global.option_data["AI"]["AI 闪避子弹"]:
		return
	reaction_delay_ms=800-Global.init_args["AI_Level"]*125*0.65
	# 检查进入区域的是否为敌方子弹
	var bullet := area.get_parent()
	if bullet.is_class("RayCast2D") && bullet.host != self:
		# 友伤关闭时，忽略同阵营子弹
		if !Global.option_data["全局"]["友伤"]&&camp==bullet.host.camp:
			return
		
		# 计算闪避方向（垂直于子弹飞行路径的方向）
		var ab: Vector2 = position - bullet.position  # 自身到子弹的向量
		var dot_ab_mv: float = ab.dot(bullet.move)  # 计算向量点积
		var mv_length_squared: float = bullet.move.length_squared()  # 子弹速度向量长度平方
		var ab_parallel: Vector2 = (dot_ab_mv / mv_length_squared) * bullet.move  # 平行于子弹路径的分量
		# 垂直于子弹路径的方向作为闪避方向
		sprint_base_move = (ab - ab_parallel).normalized() * move_speed
		move_velocity = sprint_base_move  # 设置移动速度
		sprint()  # 执行冲刺
		# 随机设置新目的地，恢复闲逛状态
		destination = map.empty_tiles[randi()%map.empty_tiles.size()]
		move_name = "Take a casual stroll"

# 重生逻辑
func rebirth()->void:
	# 重生时随机切换枪支
	if gun!=null:
		gun.id=randi()%GunData.names.size()
	# 随机设置新目的地，恢复闲逛
	destination=map.empty_tiles[randi()%map.empty_tiles.size()]
	move_name="Take a casual stroll"
	is_pathfinding=true  # 重新开启寻路

# 移动逻辑（重写父类方法）
func move()->void:
	super.move()  # 调用父类移动方法
	if is_pathfinding:
		if !path.is_empty():
			# 计算到下一个路径点的方向
			var direction:Vector2 = map.map_to_local(path[0])*map.scale - position
			move_velocity = direction.normalized() * speed  # 设置移动速度
			# 到达路径点后移除该点
			if direction.length_squared() <= 32768:
				path.remove_at(0)
		else:
			# 路径为空时，随机设置新目的地（闲逛）
			destination = map.empty_tiles[randi()%map.empty_tiles.size()]
			move_name = "Take a casual stroll"

# 是否正在寻路的标记
var is_pathfinding := false

# 获取自身在地图上的坐标（格子坐标）
func _get_pos_on_map()->Vector2i:
	return map.local_to_map(map.to_local(global_position))

# 目的地属性（设置时自动计算路径）
var destination:Vector2:
	set(value):
		# 若关闭AI移动，则不更新目的地
		if !Global.option_data["AI"]["AI 移动"]:
			return
		# 若目的地超出地图范围，随机选择一个空点
		if !map.astar.is_in_boundsv(value):
			value = map.empty_tiles[randi()%map.empty_tiles.size()]
			move_name = "Take a casual stroll"
		destination = value
		# 计算从当前位置到目的地的路径
		path = map.astar.get_point_path(_get_pos_on_map(), destination)

# 寻路路径（由A*算法计算的格子坐标数组）
var path:PackedVector2Array
