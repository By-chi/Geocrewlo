# 继承自Godot的CharacterBody2D节点，定义为Entity基类
# 所有游戏实体（玩家、AI）均继承此类，包含实体通用的核心逻辑（生命值、武器、移动、视野等）
extends CharacterBody2D
class_name Entity

# 导出变量：治疗计时器（控制受伤后的自动回血）
@export var heal_timer:Timer
# 缓存上一次掉落的枪支（避免重复生成同枪支）
var last_gun:Gun
# 实体当前生命值（初始值从EntityData配置中获取）
var health:=EntityData.health

# 重生虚函数（空实现，由子类（Player/AI）重写具体重生逻辑）
func rebirth()->void:
	pass

# 核心方法：设置实体生命值，处理受伤、治疗、死亡逻辑
# 参数：new_health-目标生命值，mastermind-造成生命值变化的源头（伤害者/治疗者）
func set_health(new_health:float,mastermind:Entity)->void:
	# 若生命值降低（受伤），启动治疗计时器（根据受伤量计算治疗时长）
	if new_health<EntityData.health:
		heal_timer.start((EntityData.health-new_health)*0.01*EntityData.heal_base_time)
		if is_player&&get("aiming"):
			camera.position+=Vector2(randf_range(-100,100),randf_range(-100,100))
	# 处理死亡逻辑（生命值≤0时）
	if new_health<=0:
		
		# 玩家锁血判定（开启"锁血"选项时，仅将生命值设为0，不触发死亡）
		if is_player&&Global.option_data["玩家"]["锁血"]:
			health=0
			return
		# 死亡时掉落当前持有枪支
		if gun!=null:
			# 复制当前枪支（避免原枪支被销毁）
			var gun_duplicate:=gun.duplicate()
			gun_duplicate.global_position=gun.global_position  # 保持掉落位置
			gun_duplicate.host=null  # 清除持有者关联
			# 销毁上一次掉落的枪支（防止枪支堆积）
			if last_gun!=null&&last_gun.host==null:
				last_gun.queue_free()
			last_gun=gun_duplicate  # 缓存本次掉落枪支
			gun_duplicate.id=gun.id  # 保持枪支ID一致
			Global.game_main.add_child(gun_duplicate)  # 将掉落枪支添加到场景
		
		# 死亡分数计算
		GameData.camp_score[camp-1]+=1  # 所属阵营分数+1（可能为死亡统计，需结合游戏逻辑）
		if mastermind.camp!=camp:  # 若伤害者是敌对阵营（正常击杀）
			GameData.score[mastermind.camp][mastermind.id]+=1  # 伤害者个人分数+1
			GameData.mortality_database[camp][id]+=1  # 所属阵营死亡次数+1
		else:  # 若伤害者是友阵营（误杀）
			GameData.score[mastermind.camp][mastermind.id]-=1  # 伤害者个人分数-1
		
		# 添加击杀公告（全局显示）
		GameData.add_elimination_announcement(mastermind,self)
		
		# 若伤害者是玩家，播放对应音效（击杀/误杀）
		if mastermind.is_player:
			if mastermind.camp!=camp:
				audio_stream_player.stream=load("res://sound/entity/kill_"+str(randi()%4)+".mp3")  # 随机击杀音效（4种）
			else:
				audio_stream_player.stream=preload("res://sound/entity/manslaughter.mp3")  # 误杀音效
			audio_stream_player.play()
		
		# 根据游戏模式处理复活逻辑
		match Global.init_args["Mode"]:
			0:  # 模式0：固定出生点复活
				var playstarts:Array=Global.game_main.playstarts[camp]  # 获取所属阵营的出生点列表
				position=playstarts[randi()%playstarts.size()]  # 随机选择一个出生点
				new_health=EntityData.health  # 恢复满生命值
				if gun!=null:  # 重置枪支状态
					gun.is_init=true
					gun.id=gun.id  # 触发枪支初始化（重新加载配置）
			1:  # 模式1：随机在同阵营实体附近复活
				position=Global.entity_list[camp][id-randi()%Global.entity_list[camp].size()].position+Vector2(1,1)  # 同阵营实体位置偏移
				new_health=EntityData.health  # 恢复满生命值
				if gun!=null:  # 重置枪支状态
					gun.is_init=true
					gun.id=gun.id
			2:  # 模式2：死亡后禁用（不复活）
				set_physics_process(false)  # 关闭物理帧更新
				set_process(false)  # 关闭普通帧更新
				is_dead=true  # 标记为死亡
				if camera.enabled:  # 若当前实体的相机开启（如玩家），切换到其他存活实体的相机
					for i in Global.entity_list[camp]:
						if !i.is_dead:
							i.camera.enabled=true
							camera.enabled=false
							break
				position=Vector2(114514,114514)  # 把死亡实体位置设为无效值（避免干扰）
		
		# 调用重生方法（子类实现具体逻辑）
		rebirth()
		Global.game_main.UI.score.value=GameData.camp_score[0]/float(GameData.camp_score[0]+GameData.camp_score[1])*100
		Global.game_main.UI.score_red.text=str(GameData.camp_score[0])
		Global.game_main.UI.score_blue.text=str(GameData.camp_score[1])
		if self==Global.game_main.UI.entity||mastermind==Global.game_main.UI.entity:
			Global.game_main.UI.Kd.text=str(GameData.score[Global.game_main.UI.entity.camp][Global.game_main.UI.entity.id])+" - "+str(GameData.mortality_database[Global.game_main.UI.entity.camp][Global.game_main.UI.entity.id])

	if self==Global.game_main.UI.entity:
		Global.game_main.UI.lifebar.value=new_health
	# 更新当前生命值
	health=new_health

# 导出变量：用于播放音效（击杀、受伤、换弹等）
@export var audio_stream_player:AudioStreamPlayer
# 导出变量：受伤碰撞区域（检测是否被攻击/拾取物品）
@export var injury_area:Area2D
# 导出变量：实体精灵（显示外观）
@export var sprite:Sprite2D
# 导出变量：射线节点容器（用于视野遮挡检测）
@export var rays:Node2D
# 导出变量：视野碰撞区域（检测实体是否进入/离开视野）
@export var view:Area2D
# 导出变量：实体名称标签（显示ID或名称）
@export var name_label:Label

# 实体唯一ID（用于全局索引）
var id:int
# 基础移动速度（从EntityData读取配置）
var move_speed:=EntityData.move_speed
# 冲刺速度倍率（冲刺时的速度系数）
var sprint_speed_rate:=EntityData.sprint_speed_rate
# 当前移动速度（基础速度/冲刺速度）
var speed:=move_speed
# 旋转加速度（控制精灵旋转的平滑度）
var rotational_acceleration:=EntityData.rotational_acceleration
# 手部稳定性（影响枪支后坐力和扩散恢复）
var hand_strength:=EntityData.hand_strength
# 精灵旋转速度
var rotate_speed:=0.0
# 是否为玩家（区分玩家/AI）
var is_player:=false
# 所属阵营（0/1，用于区分敌我）
var camp:=0
# 是否死亡（标记实体存活状态）
var is_dead:=false

# 导出变量：动画播放器（控制移动、冲刺等动画）
@export var animation:AnimationPlayer
# 导出变量：实体相机（玩家实体使用，跟随视角）
@export var camera:Camera2D
# 移动速度向量（控制物理移动方向和速度）
var move_velocity:=Vector2.ZERO

# 输入处理虚函数（子类（如Player）重写，处理键盘/手柄输入）
func _input(event: InputEvent) -> void:
	pass

# 射击方法（调用当前持有枪支的射击逻辑）
func shoot()->void:
	if gun==null||Global.is_over:  # 无枪支或游戏结束时，不执行射击
		return
	gun.shoot()  # 调用Gun类的shoot方法

# 节点就绪时调用（初始化实体状态）
func _ready() -> void:
	camera.zoom=EntityData.zoom*Vector2.ONE
	
	# 根据阵营设置实体颜色（阵营0：红色，阵营1：蓝色）
	if camp==0:
		self_modulate=Color.RED*4  # 红色阵营（亮度×4）
	else:
		self_modulate=Color.DODGER_BLUE*4  # 蓝色阵营（亮度×4）
	$thumbnail.modulate=self_modulate  # 同步缩略图颜色（如UI显示）
	
	# 初始化视野相关数组（大小为总实体数的一半，可能为阵营对立配置）
	var size:int=int(Global.init_args["Population"])/2
	in_view.resize(size)  # 记录实体是否在视野区域内
	in_view.fill(false)
	no_obstruction.resize(size)  # 记录视野到实体是否无遮挡
	no_obstruction.fill(false)
	visible_entity.resize(size)  # 记录实体是否可见（在视野内且无遮挡）
	visible_entity.fill(false)
	
	# 为玩家/AI实体设置脚本保存属性（用于游戏存档/读档）
	if is_player:
		Global.set_script_save_properties(self,preload("res://scene/Node2D/entity/player.gd"))
	else:
		Global.set_script_save_properties(self,preload("res://scene/Node2D/entity/ai.gd"))

# 物理帧更新（每帧处理移动、旋转、视野检测）
func _physics_process(delta: float) -> void:
	# 阵营0实体的视野遮挡检测（通过射线判断是否有遮挡）
	if camp==0&&Engine.get_physics_frames()%5==0:
		for i in rays.get_children():  # 遍历所有射线节点
			# 若射线碰撞状态与当前无遮挡状态不一致，更新状态
			if !i.is_colliding()!=no_obstruction[i.to.id]:
				no_obstruction[i.to.id]=!i.is_colliding()  # 射线未碰撞=无遮挡
				no_obstruction_sync(id,i.to.id)  # 同步视野遮挡状态到目标实体
				update_visible_entity(i.to.id)  # 更新目标实体的可见性
	# 重置移动速度向量
	move_velocity=Vector2.ZERO
	
	# 冲刺状态判断：冲刺计时器未运行时，执行正常移动；运行时，使用冲刺速度
	if sprint_timer.is_stopped():
		move()  # 调用移动虚函数（子类实现具体移动逻辑）
		sprint_base_move=move_velocity  # 记录基础移动方向（用于冲刺时保持方向）
	else:
		move_velocity=sprint_base_move*sprint_speed_rate  # 冲刺速度=基础方向×冲刺倍率
	
	# 精灵旋转效果（每60帧更新一次，避免过度消耗性能）
	if Engine.get_physics_frames()%(Engine.physics_ticks_per_second/60)==0:
		rotate_speed+=rotational_acceleration*(move_velocity.x+move_velocity.y)  # 根据移动速度计算旋转加速度
		sprite.rotation+=rotate_speed  # 应用旋转
		rotate_speed*=0.9  # 旋转速度衰减（平滑停止旋转）
	
	# 应用物理移动
	velocity=move_velocity
	move_and_slide()

# 丢弃当前持有枪支
func drop_gun()->void:
	if gun!=null:
		var pos:=gun.global_position  # 记录枪支当前全局位置
		remove_child(gun)  # 从实体移除枪支
		gun.global_position=pos  # 保持枪支位置不变
		gun.host=null  # 清除枪支的持有者关联
		Global.game_main.add_child(gun)  # 将枪支添加到场景（成为可拾取物品）
		gun=null  # 清空当前枪支引用

# 拾取视野内的枪支
func pick_up_gun()->void:
	if gun==null:  # 仅当无枪支时可拾取
		for i in injury_area.get_overlapping_areas():  # 遍历受伤区域内的所有碰撞区域
			if i is Gun:  # 若碰撞区域属于Gun类
				var pos:=i.global_position  # 记录枪支位置
				Global.game_main.remove_child(i)  # 从场景移除枪支
				i.host=self  # 设置枪支持有者为当前实体
				gun=i  # 持有该枪支
				add_child(i)  # 将枪支添加为实体的子节点
				i.global_position=pos  # 保持枪支位置（后续由枪支自身调整到手持位置）
				break  # 拾取第一把枪支后退出循环

# 导出变量：冲刺CD计时器（控制冲刺的冷却时间）
@export var sprint_cd_timer:Timer
# 导出变量：冲刺计时器（控制冲刺的持续时间）
@export var sprint_timer:Timer
# 冲刺CD时长（从EntityData读取配置）
var sprint_cd:=EntityData.sprint_cd
# 冲刺持续时长（从EntityData读取配置）
var sprint_duration:=EntityData.sprint_duration
# 冲刺基础移动方向（冲刺时保持该方向）
var sprint_base_move:Vector2

# 执行冲刺
func sprint()->void:
	# 冲刺CD未结束或正在冲刺时，无法再次冲刺
	if !sprint_cd_timer.is_stopped()||!sprint_timer.is_stopped():
		return
	sprint_timer.start(sprint_duration)  # 启动冲刺计时器（控制冲刺时长）
	speed=move_speed*sprint_speed_rate  # 设置冲刺速度
	animation.play("sprint")  # 播放冲刺动画

# 导出变量：当前持有枪支
@export var gun:Gun

# 移动虚函数（子类（Player/AI）重写，实现具体移动逻辑）
func move() -> void:
	pass

# 判断枪支是否朝右（用于枪支精灵翻转）
func is_facing_right() -> bool:
	var normalized_angle = fmod(gun.rotation ,(2 * PI))  # 标准化旋转角度（0~2π）
	if normalized_angle < 0:
		normalized_angle += 2 * PI
	# 角度在0~π/2或3π/2~2π时，判定为朝右
	return normalized_angle < PI/2 or normalized_angle > 3 * PI/2

# 旋转枪支（根据朝向翻转枪支精灵）
func rotate_gun()->void:
	if is_facing_right():
		gun.scale.y=2  # 朝右时，Y轴缩放为2（正常方向）
	else:
		gun.scale.y=-2  # 朝左时，Y轴缩放为-2（水平翻转）

# 导出变量：方向线（可能用于调试移动方向）
@export var direction_line:ColorRect

# 普通帧更新（每帧处理枪支旋转）
func _process(delta: float) -> void:
	if gun!=null:  # 持有枪支时，实时更新枪支朝向
		rotate_gun()

# 生成冲刺残影（提升冲刺视觉效果）
func add_sprint_ghost()->void:
	var sprint_ghost:=preload("res://scene/Node2D/entity/sprint_ghost.tscn").instantiate()  # 实例化残影节点
	Global.game_main.add_child(sprint_ghost)  # 添加到场景
	sprint_ghost.rotation=sprite.rotation  # 同步残影旋转角度
	sprint_ghost.global_position=global_position  # 同步残影位置
	sprint_ghost.self_modulate=self_modulate  # 同步残影颜色
	# 创建淡出动画（0.2秒内从实体颜色变为透明）
	var tween:=sprint_ghost.create_tween()
	tween.tween_property(sprint_ghost,"self_modulate",Color.TRANSPARENT,0.2).set_ease(Tween.EASE_IN)

# 冲刺计时器超时回调（冲刺结束）
func _on_sprint_timeout() -> void:
	sprint_cd_timer.start(sprint_cd)  # 启动冲刺CD计时器
	speed=move_speed  # 恢复基础移动速度

#region 视野检测模块（管理实体的视野内实体状态）
# 记录实体是否在当前实体的视野区域内
var in_view:Array[bool]=[]
# 记录当前实体到目标实体的视野是否无遮挡
var no_obstruction:Array[bool]=[]
# 记录目标实体是否可见（在视野内且无遮挡）
var visible_entity:Array[bool]=[]

# 更新目标实体的可见性状态，并同步到全局阵营视野
func update_visible_entity(index:int)->void:
	var visible_value:=in_view[index]&&no_obstruction[index]  # 可见=在视野内+无遮挡
	visible_entity[index]=visible_value
	Global.update_camp_view(index,camp)  # 通知全局更新阵营视野配置（供AI目标检测使用）

# 视野遮挡状态双向同步（当前实体与目标实体互相同步遮挡状态）
func no_obstruction_sync(self_index:int,sync_index:int)->void:
	var to:Entity=Global.entity_list[1][sync_index]  # 获取目标实体（假设阵营1为对立阵营）
	to.no_obstruction[self_index]=no_obstruction[sync_index]  # 同步当前遮挡状态到目标实体
	to.update_visible_entity(self_index)  # 目标实体更新当前实体的可见性

# 视野区域进入/退出回调（处理实体进入/离开视野的状态更新）
# 参数：area-触发事件的碰撞区域，is_add-true=进入，false=离开
func _on_view_area_entered_or_exited(area:  Area2D,is_add:=true) -> void:
	var entity=area.get_parent().get_parent()  # 获取碰撞区域所属的实体
	# 若实体是CharacterBody2D且属于敌对阵营
	if entity.is_class("CharacterBody2D")&&entity.camp!=camp:
		in_view[entity.id]=is_add  # 更新目标实体是否在视野内
		update_visible_entity(entity.id)  # 更新可见性
#endregion

# 治疗计时器超时回调（自动回血）
func _on_heal_timeout() -> void:
	# 恢复33点生命值，不超过最大生命值（EntityData.health）
	set_health(min(health+33,EntityData.health),self)
