#extends Entity
####################################旧版####################################
#var map:TileMapLayer
#
#
##region test
##region
#var target_entity
#var target_position:=Vector2.ZERO
#func get_optimized_aim_point(a_pos: Vector2, b_pos: Vector2, a_move_v: Vector2, bullet_speed: float) -> Vector2:
	#return a_pos + a_move_v * (a_pos - b_pos).length() / bullet_speed
	#
#func _process(delta: float) -> void:
	#super._process(delta)
	#if Engine.get_physics_frames()%2==0:
		#var old=target_entity
		#target_entity=null
		#for i in Global.camp_view[camp].size():
			#if Global.camp_view[camp][i]&&no_obstruction[i]:
				#target_entity=Global.game_main.entity_list[camp-1][i]
				#if target_entity.is_dead:
					#target_entity=null
					#continue
				#if Global.init_args["AI_Level"]>=6:
					#target_position=get_optimized_aim_point(
						#target_entity.global_position,
						#global_position,
						#target_entity.velocity,
						#GunData.bullet_speeds[gun.id]
					#)
				#else:
					#target_position=target_entity.global_position
				#
				#break
		#if target_entity==null&&old!=null&&Global.init_args["AI_Level"]>=4:
			#if target_position!=Vector2.ZERO&&move_name!="Track the enemy":
				#destination=map.local_to_map(map.to_local(target_position))
				#move_name="Track the enemy"
	#if target_entity!=null:
		#shoot()
		#pass
	#else:
		#gun.reload()
#var move_name:="Free"
#func shoot()->void:
	#super.shoot()
	#if gun.clip_capacity==0:
		#gun.reload()
#func rotate_gun()->void:
	#if target_entity==null:
		#return
	#gun.look_at(target_position)
	##gun.rotation=move_toward(gun.rotation,(target_position-global_position).angle(),6*get_physics_process_delta_time())
	#super.rotate_gun()
#var dodge_area:Area2D
#func init() -> void:
	#camera.enabled=false
	#is_player=false
	#sprite.self_modulate=self_modulate
	#map=Global.game_main.map
	#destination=map.empty_tiles[randi()%map.empty_tiles.size()]
	#move_name="Take a casual stroll"
	#is_pathfinding=true
	#dodge_area=Area2D.new()
	#var collision_shape:=CollisionShape2D.new()
	#collision_shape.shape=CircleShape2D.new()
	#collision_shape.shape.radius=min(Global.init_args["AI_Level"]*50,400)
	#dodge_area.area_entered.connect(on_area_entered_dodge_area)
	#dodge_area.add_child(collision_shape)
	#add_child(dodge_area)
	#sprint_timer.timeout.connect(func():
		#is_pathfinding=true
		#)
		#
#func on_area_entered_dodge_area(area: Area2D)->void:
	#var bullet:=area.get_parent()
	#if bullet.is_class("RayCast2D")&&bullet.host!=self:
		#var ab: Vector2 = position - bullet.position
		#var dot_ab_mv: float = ab.dot(bullet.move)
		#var mv_length_squared: float = bullet.move.length_squared()
		#var ab_parallel: Vector2 = (dot_ab_mv / mv_length_squared) * bullet.move
		#sprint_base_move = (ab - ab_parallel).normalized()*move_speed
		#move_velocity=sprint_base_move
		#sprint()
		#destination=map.empty_tiles[randi()%map.empty_tiles.size()]
		#move_name="Take a casual stroll"
		##is_pathfinding=false
#func move()->void:
	#super.move()
	#if is_pathfinding:
		#if !path.is_empty():
			#var direction:Vector2=map.map_to_local(path[0])*map.scale-position
			#move_velocity=direction.normalized()*speed
			#if direction.length_squared()<=1024:
				#path.remove_at(0)
			#
		#else:
			##is_pathfinding=false
			#destination=map.empty_tiles[randi()%map.empty_tiles.size()]
			#move_name="Take a casual stroll"
#var is_pathfinding:=false
#func _get_pos_on_map()->Vector2i:
	#return map.local_to_map(map.to_local(global_position))
##var line:Line2D
#var destination:Vector2:
	#set(value):
		#if !map.astar.is_in_boundsv(value):
			#value=map.empty_tiles[randi()%map.empty_tiles.size()]
			#move_name="Take a casual stroll"
		#destination=value
		#
		#path=map.astar.get_point_path(_get_pos_on_map(),destination)
		##if line!=null:
			##line.queue_free()
		##line=Line2D.new()
		##line.points=path
		##line.scale=map.scale
		##line.width=0.2
		##Global.game_main.add_child(line)
#var path:PackedVector2Array
extends Entity
var map:TileMapLayer

# 慢反应相关变量
var reaction_delay_ms: int = 800-Global.init_args["AI_Level"]*125  # 默认延迟500毫秒，可根据AI等级调整
var detected_target  # 检测到的目标（未经过延迟处理）
var target_detected_time: int = 0  # 检测到目标的时间戳
var target_lost_time: int = 0  # 丢失目标的时间戳

#region test
#region
var target_entity  # 经过延迟处理的实际目标
var target_position:=Vector2.ZERO

func get_optimized_aim_point(a_pos: Vector2, b_pos: Vector2, a_move_v: Vector2, bullet_speed: float) -> Vector2:
	return a_pos + a_move_v * (a_pos - b_pos).length() / bullet_speed

func _process(delta: float) -> void:
	super._process(delta)
	if Engine.get_physics_frames()%2==0:
		var old_detected = detected_target
		detected_target = null
		
		# 检测潜在目标
		for i in Global.camp_view[camp].size():
			if Global.camp_view[camp][i] && no_obstruction[i]:
				var potential_target = Global.game_main.entity_list[camp-1][i]
				if potential_target.is_dead:
					continue
				
				detected_target = potential_target
				var aim_pos:Vector2=detected_target.global_position
				if Global.init_args["AI_Level"]<7||Global.option_data["AI"]["AI 预瞄"]:
					aim_pos+=Vector2(randf(),randf())*(35-Global.init_args["AI_Level"]*5)
					
				
				# 更新目标位置
				if Global.init_args["AI_Level"] >= 6:
					target_position = get_optimized_aim_point(
						aim_pos,
						global_position,
						detected_target.velocity,
						GunData.bullet_speeds[gun.id]
					)
				else:
					target_position = aim_pos
				
				break
		
		# 处理目标获取延迟
		var current_time = Time.get_ticks_msec()
		if detected_target != null:
			# 如果检测到新目标，更新检测时间
			if old_detected != detected_target:
				target_detected_time = current_time
			
			# 达到延迟时间后才确认目标
			if current_time - target_detected_time >= reaction_delay_ms:
				target_entity = detected_target
		else:
			# 处理目标丢失延迟
			if target_entity != null:
				# 记录丢失开始时间
				if target_lost_time == 0:
					target_lost_time = current_time
				
				# 达到延迟时间后才确认丢失
				if current_time - target_lost_time >= reaction_delay_ms:
					target_entity = null
					target_lost_time = 0
			else:
				target_lost_time = 0
		
		# 目标丢失后的追踪逻辑（保持原样，但使用延迟后的target_entity）
		if target_entity == null && old_detected != null && (Global.init_args["AI_Level"] >= 4||Global.option_data["AI"]["AI 追踪"])&&target_position != Vector2.ZERO && move_name != "Track the enemy":
				destination = map.local_to_map(map.to_local(target_position))
				move_name = "Track the enemy"
	
	if target_entity != null:
		if Global.option_data["AI"]["AI 攻击"]:
			shoot()
	else:
		gun.reload()

var move_name:="Free"

func shoot()->void:
	super.shoot()
	if gun.clip_capacity == 0:
		gun.reload()

func rotate_gun()->void:
	if target_entity == null:
		return
	gun.look_at(target_position)
	#gun.rotation=move_toward(gun.rotation,(target_position-global_position).angle(),6*get_physics_process_delta_time())
	super.rotate_gun()

var dodge_area:Area2D

func init() -> void:
	camera.enabled = false
	is_player = false
	sprite.self_modulate = self_modulate
	map = Global.game_main.map
	destination = map.empty_tiles[randi()%map.empty_tiles.size()]
	move_name = "Take a casual stroll"
	is_pathfinding = true
	
	# 根据AI等级调整反应延迟，等级越高延迟越低
	reaction_delay_ms = max(100, 800 - Global.init_args["AI_Level"] * 100)
	
	dodge_area = Area2D.new()
	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = CircleShape2D.new()
	collision_shape.shape.radius = min(Global.init_args["AI_Level"]*50, 400)
	dodge_area.area_entered.connect(on_area_entered_dodge_area)
	dodge_area.add_child(collision_shape)
	add_child(dodge_area)
	sprint_timer.timeout.connect(func():
		is_pathfinding = true
		)

func on_area_entered_dodge_area(area: Area2D)->void:
	if !Global.option_data["AI"]["AI 闪避子弹"]:
		return
	var bullet := area.get_parent()
	if bullet.is_class("RayCast2D") && bullet.host != self:
		var ab: Vector2 = position - bullet.position
		var dot_ab_mv: float = ab.dot(bullet.move)
		var mv_length_squared: float = bullet.move.length_squared()
		var ab_parallel: Vector2 = (dot_ab_mv / mv_length_squared) * bullet.move
		sprint_base_move = (ab - ab_parallel).normalized() * move_speed
		move_velocity = sprint_base_move
		sprint()
		destination = map.empty_tiles[randi()%map.empty_tiles.size()]
		move_name = "Take a casual stroll"
		#is_pathfinding=false

func move()->void:
	super.move()
	if is_pathfinding:
		if !path.is_empty():
			var direction:Vector2 = map.map_to_local(path[0])*map.scale - position
			move_velocity = direction.normalized() * speed
			if direction.length_squared() <= 1024:
				path.remove_at(0)
		else:
			#is_pathfinding=false
			destination = map.empty_tiles[randi()%map.empty_tiles.size()]
			move_name = "Take a casual stroll"

var is_pathfinding := false

func _get_pos_on_map()->Vector2i:
	return map.local_to_map(map.to_local(global_position))

#var line:Line2D
var destination:Vector2:
	set(value):
		if !Global.option_data["AI"]["AI 移动"]:
			return
		if !map.astar.is_in_boundsv(value):
			value = map.empty_tiles[randi()%map.empty_tiles.size()]
			move_name = "Take a casual stroll"
		destination = value
		path = map.astar.get_point_path(_get_pos_on_map(), destination)
		#if line!=null:
			#line.queue_free()
		#line=Line2D.new()
		#line.points=path
		#line.scale=map.scale
		#line.width=0.2
		#Global.game_main.add_child(line)

var path:PackedVector2Array
