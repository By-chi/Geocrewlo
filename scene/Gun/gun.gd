# 继承自Area2D，定义为Gun类，用于处理游戏中枪支的各种逻辑（射击、换弹、属性管理等）
extends Area2D
class_name Gun

# 导出变量，枪支的持有者（实体，如玩家或敌人）
@export var host:Entity

# 总弹药容量（备用弹药）
var ammunition_capacity:=0
# 当前弹夹容量
var clip_capacity:int:
	set(value):
		clip_capacity=value
		if host==Global.game_main.UI.entity:
			Global.game_main.UI.clip_capacity.text=str(clip_capacity)+"/"+str(ammunition_capacity)
# 初始化标记，确保某些配置只在首次初始化时执行
var is_init:=true
# 导出变量，换弹计时器（控制换弹时间）
@export var reload_timer:Timer

# 枪支ID（用于从GunData中获取对应配置），带有setter方法处理属性初始化
var id:=1:
	set(value):
		id=value
		# 仅在初始化时执行一次性配置
		if is_init:
			# 设置枪支精灵纹理
			$Sprite2D.texture=GunData.textures[id]
			# 调整碰撞形状大小以匹配纹理
			$CollisionShape2D.shape.size=$Sprite2D.texture.get_size()
			# 从配置中获取初始总弹药容量
			ammunition_capacity=GunData.initial_ammunition_capacity[id]
			# 从配置中获取弹夹最大容量
			clip_capacity=GunData.clip_max_capacity[id]
			# 设置换弹计时器时长
			reload_timer.wait_time=GunData.reload_time[id]
			shoot_cds=GunData.shoot_cds[id]
			# 标记初始化完成
			is_init=false
			audio_stream_player2d.max_polyphony=max(1,int(GunData.shoot_sound[id].get_length()/shoot_cds))
		# 更新扩散角度（每次ID变更时生效）
		spread_angle=GunData.base_spread_angle[id]

# 子弹扩散角度（影响射击精度）
var spread_angle:float

# 节点就绪时调用
func _ready() -> void:
	# 触发id的setter方法，执行初始化配置
	id=id

# 导出变量，用于播放枪支相关音效（射击、换弹等）
@export var audio_stream_player2d:AudioStreamPlayer2D
# 上次射击的时间戳（毫秒），用于控制射击间隔
var last_shoot_time:int
var shoot_cds:=0
# 射击逻辑函数
func shoot()->void:
	# 如果没有持有者，不执行射击
	if host == null:
		return
	# 计算距离上次射击的时间间隔
	var interval:=Time.get_ticks_msec()-last_shoot_time
	# 检查是否满足射击冷却时间
	if interval>=shoot_cds:
		# 检查弹夹是否有子弹
		if clip_capacity>0:
			# 在枪口位置生成枪口粒子效果
			Global.add_generic_particles(
				Global.MUZZLE_PARTICLES, 
				to_global(GunData.muzzle[id]),  # 枪口在全局坐标系中的位置
				rotation,  # 粒子旋转角度与枪支一致
				Vector2(10, 10)  # 粒子大小
			)
			
			# 根据枪支配置生成多发子弹（散弹枪可能多发）
			for i in range(GunData.pellets_number[id]):
				# 计算每颗子弹的随机扩散角度
				var angle:=rotation+spread_angle*randf_range(-1,1)
				#var angle:=rotation+spread_angle
				# 实例化子弹节点
				var bullet:RayCast2D=preload("res://scene/Bullet/bullet.tscn").instantiate()
				# 设置子弹旋转角度
				bullet.rotation=angle
				# 设置子弹初始位置（从枪口前方发射）
				bullet.global_position=global_position
				bullet.start_position=bullet.global_position
				bullet.last_position=bullet.global_position
				# 设置子弹的持有者
				bullet.host=host
				# 记录子弹对应的枪支ID
				bullet.gun_id=id
				# 设置子弹移动方向和速度
				bullet.move=Vector2.RIGHT.rotated(angle)*GunData.bullet_speeds[id]
				# 将子弹添加到游戏主节点
				
				Global.game_main.add_child(bullet)
			
			# 应用后坐力（枪支位置后移）
			position+=Vector2.LEFT.rotated(rotation)*GunData.recoil[id]
			if Engine.get_frames_per_second()>15||randi()%10==0:
				# 播放射击音效
				audio_stream_player2d.stop()
				audio_stream_player2d.stream=GunData.shoot_sound[id]
				audio_stream_player2d.play()
			
			# 减少弹夹容量（玩家且未开启无限子弹时生效）
			if host != null and (!host.is_player||!Global.option_data["玩家"]["无限子弹"]):
				clip_capacity-=1
			
			# 停止换弹计时器（射击中断换弹）
			reload_timer.stop()
			# 增加连射扩散（连续射击精度下降）
			spread_angle+=GunData.burst_spread_increment[id]
			
			# 校准下次射击时间（处理射击间隔溢出，确保射速稳定）
			var rollback:=shoot_cds-interval
			if rollback>-shoot_cds:
				last_shoot_time=Time.get_ticks_msec()+rollback
			else:
				last_shoot_time=Time.get_ticks_msec()
		else:
			# 弹夹空时播放空仓音效（避免重复播放）
			if reload_timer.is_stopped() && host != null && !host.audio_stream_player.playing:
				if host.is_player:
					host.audio_stream_player.stream=preload("res://sound/entity/no_bullets.mp3")
					host.audio_stream_player.play()
var last_adjust_scattering_time:=0.0
# 每帧更新处理
func _process(delta: float) -> void:
	# 如果有持有者，使枪支向手持目标位置移动（受手部力量影响移动速度）
	if host!=null:
		position=position.move_toward(GunData.handheld_positions[id],host.hand_strength*delta)
		var interval:=Time.get_ticks_msec()-last_adjust_scattering_time
		spread_angle=maxf(
			GunData.base_spread_angle[id],  # 基础扩散角度（最小扩散）
			spread_angle-
			host.hand_strength*
			0.00000016*
			interval  # 随时间减少扩散（提升精度）
		)
		last_adjust_scattering_time=Time.get_ticks_msec()
# 换弹逻辑函数
func reload()->void:
	# 没有持有者则不执行换弹
	if host == null:
		return
	
	# 检查是否可以换弹：换弹计时器未运行、弹夹未满、有备用弹药
	if reload_timer.is_stopped()&&clip_capacity!=GunData.clip_max_capacity[id]&&ammunition_capacity!=0:
		# 启动换弹计时器
		reload_timer.start()
		# 播放换弹音效
		audio_stream_player2d.stream=GunData.reload_sound[id]
		audio_stream_player2d.play()
# 换弹计时器超时回调（完成换弹）
func _on_reload_timeout() -> void:
	# 计算需要补充的弹药量（弹夹最大容量 - 当前弹夹容量）
	var needed = GunData.clip_max_capacity[id] - clip_capacity
	if needed <= 0:
		return
	# 计算实际可补充的弹药（取需要量和备用弹药的最小值）
	var to_reload = min(needed, ammunition_capacity)
	# 更新弹夹容量和总弹药容量
	clip_capacity+=to_reload
	ammunition_capacity-=to_reload
