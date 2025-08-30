extends Area2D
class_name Gun
@export var host:Entity
var ammunition_capacity:=0
var clip_capacity:int
@export var reload_timer:Timer
var id:=1:
	set(value):
		id=value
		$Sprite2D.texture=GunData.textures[id]
		$CollisionShape2D.shape.size=$Sprite2D.texture.get_size()
		spread_angle=GunData.base_spread_angle[id]
		if ammunition_capacity==0:
			ammunition_capacity=GunData.initial_ammunition_capacity[id]
			clip_capacity=GunData.clip_max_capacity[id]
		reload_timer.wait_time=GunData.reload_time[id]
var spread_angle:float
func _ready() -> void:
	id=id
@export var audio_stream_player2d:AudioStreamPlayer2D
var last_shoot_time:int
func shoot()->void:
	if host == null:
		return
		
	var interval:=Time.get_ticks_msec()-last_shoot_time
	if interval>=GunData.shoot_cds[id]:
		if clip_capacity>0:
			spread_angle=maxf(
			GunData.base_spread_angle[id],
			spread_angle-
			host.hand_strength*
			0.00000016*
			interval
			)
			Global.add_generic_particles(Global.MUZZLE_PARTICLES,to_global(GunData.muzzle[id]),rotation, Vector2(10, 10))
			#Global.add_muzzle_particles(to_global(GunData.muzzle[id]),rotation)
			for i in range(GunData.pellets_number[id]):
				var angle:=rotation+spread_angle*randf_range(-1,1)
				#print(spread_angle*randi_range(-1,1))
				var bullet:RayCast2D=preload("res://scene/Bullet/bullet.tscn").instantiate()
				bullet.rotation=angle
				bullet.global_position=global_position+Vector2.LEFT.rotated(angle)*200.0
				bullet.host=host
				bullet.gun_id=id
				bullet.move=Vector2.RIGHT.rotated(angle)*GunData.bullet_speeds[id]
				Global.game_main.add_child(bullet)
			position+=Vector2.LEFT.rotated(rotation)*GunData.recoil[id]
			audio_stream_player2d.stop()
			audio_stream_player2d.stream=GunData.shoot_sound[id]
			audio_stream_player2d.play()
			# 增加host查空
			if host != null and (!host.is_player||!Global.option_data["玩家"]["无限子弹"]):
				clip_capacity-=1
			reload_timer.stop()
			spread_angle+=GunData.burst_spread_increment[id]
			var rollback:=GunData.shoot_cds[id]-interval
			if rollback>-GunData.shoot_cds[id]:
				last_shoot_time=Time.get_ticks_msec()+rollback
			else:
				last_shoot_time=Time.get_ticks_msec()
		else:
			if reload_timer.is_stopped() && host != null && !host.audio_stream_player.playing:  # 增加host查空
				if host.is_player:
					host.audio_stream_player.stream=preload("res://sound/entity/no_bullets.mp3")
					host.audio_stream_player.play()
func _process(delta: float) -> void:
	if host!=null:
		position=position.move_toward(GunData.handheld_positions[id],host.hand_strength*delta)
func reload()->void:
	if host == null:
		return
		
	if reload_timer.is_stopped()&&clip_capacity!=GunData.clip_max_capacity[id]&&ammunition_capacity!=0:
		reload_timer.start()
		audio_stream_player2d.stream=GunData.reload_sound[id]
		audio_stream_player2d.play()


func _on_reload_timeout() -> void:
	var needed = GunData.clip_max_capacity[id] - clip_capacity
	if needed <= 0:
		return
	var to_reload = min(needed, ammunition_capacity)
	clip_capacity+=to_reload
	ammunition_capacity-=to_reload
