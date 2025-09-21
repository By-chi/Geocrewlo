# 继承自RayCast2D，用于处理子弹/射线的碰撞检测和运动逻辑
extends RayCast2D

# 子弹移动方向和速度向量
var move:Vector2
# 发射该子弹的实体（如玩家或敌人）
var host:Entity
# 枪械ID，用于获取对应枪械的伤害、速度等数据
var gun_id:=0
# 标记子弹是否已失效（避免重复处理碰撞）
var free:=false
# 导出变量，关联到头部碰撞区域（可能用于判定爆头）
@export var head:Area2D
# 子弹发射的起始时间（毫秒），用于计算伤害衰减
var start_time:int
var trajectory:Sprite2D=null
# 节点就绪时调用的函数
func _ready() -> void:
	last_fps=Engine.get_physics_frames()
	speed=move.length()
	# 根据枪械速度设置缩放比例（可能用于视觉效果或碰撞检测范围）
	scale.x=GunData.bullet_speeds[gun_id]/16000.0
	# 记录子弹发射的起始时间
	start_time=Time.get_ticks_msec()
	# 添加碰撞例外，避免子弹立即击中发射者自身的受伤区域
	add_exception(host.injury_area)
	if Global.option_data["显示"]["弹道"]&&Engine.get_frames_per_second()>30:
		trajectory=Sprite2D.new()
		var gradient:=GradientTexture1D.new()
		gradient.gradient=Gradient.new()
		gradient.gradient.set_color(0,Color.TRANSPARENT)
		trajectory.texture=gradient


		trajectory.scale=Vector2(0,3)
		trajectory.rotation=rotation
		trajectory.global_position=host.gun.to_global(GunData.muzzle[host.gun.id])
		trajectory.ready.connect(func():
			var node:=trajectory
			get_tree().create_timer(0.3).timeout.connect(
				func():
					var tween:=node.create_tween()
					tween.tween_property(node,"self_modulate",Color.TRANSPARENT,0.1)
					tween.finished.connect(node.queue_free)
			)
		)

		Global.game_main.add_child(trajectory)
	else:
		$Sprite2D.show()
	if Engine.get_frames_per_second()>15:
		# 等待0.1秒后播放子弹发射/飞行音效
		await get_tree().create_timer(0.1).timeout
		$AudioStreamPlayer2D.play()
	get_tree().create_timer(4).timeout.connect(queue_free)
	
	
	

# 处理碰撞逻辑的函数，参数为碰撞到的节点
func hit(node: Node2D) -> void:
	# 如果子弹已失效，则不处理
	if free:
		return
	# 获取碰撞节点的祖父节点（通常实体的根节点）
	var entity=node.get_parent().get_parent()
	#如果碰撞到的是实体（如敌人、玩家）
	if entity is Entity:
		# 检查是否开启友伤，如果未开启且目标与发射者同阵营，则不造成伤害
		if !Global.option_data["全局"]["友伤"]&&entity.camp==host.camp:
			return
		# 如果发射者是玩家且开启了秒杀选项，直接将目标生命值设为0
		if host.is_player&&Global.option_data["玩家"]["秒杀"]:
			entity.set_health(0,host)
		else:
			# 计算伤害：基础伤害 + 随时间衰减的伤害（确保不小于0）
			entity.set_health(
				entity.health-
				GunData.damages[gun_id]+
				max(0,(Time.get_ticks_msec()-start_time)*
				GunData.damage_decay_rates[gun_id]),
				
				host  # 传入伤害来源（发射者）
			)
		
		# 如果发射者是玩家，播放击中音效
		if host.is_player:
			host.audio_stream_player.stream=preload("res://sound/entity/hit.mp3")
			host.audio_stream_player.play()
		elif entity.is_player&&Global.option_data["显示"]["受击提示"]:
			var sprite:=Sprite2D.new()
			sprite.texture=preload("res://texture/main/hit_prompt.png")
			sprite.position=Vector2.LEFT.rotated(rotation)*600
			sprite.ready.connect(func():
				get_tree().create_timer(0.5).timeout.connect(sprite.queue_free)
				,)
			Global.player.add_child(sprite)
		# 在碰撞点添加击中粒子效果
		Global.add_generic_particles(Global.HIT_PARTICLES,get_collision_point(),rotation,Vector2(60,60))
		
	# 如果碰撞到的不是实体（如墙壁、地面等）
	else:
		# 在碰撞点添加火花粒子效果
		Global.add_generic_particles(Global.SPARK_PARTICLES, get_collision_point(),get_collision_normal().angle(),Vector2(6,6))
	if trajectory!=null:
		trajectory.global_position=(start_position+get_collision_point())*0.5
		trajectory.scale.x=abs((get_collision_point()-start_position).length()/256.0)
	set_physics_process(false)
	# 标记子弹已失效
	free=true
	# 销毁子弹节点
	queue_free()
var speed:float
var start_position:Vector2
# 物理帧更新函数，处理子弹运动和碰撞检测
var last_position:Vector2
var period:=1
var last_fps:=0
func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames()%period==0:
		period=max(1,240/Engine.get_frames_per_second())
		var multiple:=Engine.get_physics_frames()-last_fps
		# 检查是否发生碰撞，如果是则处理碰撞逻辑
		if is_colliding():
			hit(get_collider())
		elif trajectory!=null:
			trajectory.global_position+=move*delta*multiple*0.5
			trajectory.scale.x=max(0,trajectory.scale.x+speed*delta*multiple/256.0-0.2)
		position=last_position
		# 根据移动向量和delta时间更新子弹位置
		last_position+=move*delta*multiple
		target_position=to_local(last_position)
		#Engine.time_scale=1
		last_fps=Engine.get_physics_frames()
	
	
