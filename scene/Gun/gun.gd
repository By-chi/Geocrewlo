extends Area2D
class_name Gun
var host:Entity
var ammunition_capacity:int
var clip_capacity:int
@export var reload_timer:Timer
var id:=3:
	set(value):
		id=value
		$Sprite2D.texture=GunData.textures[id]
		$CollisionShape2D.shape.size=$Sprite2D.texture.get_size()
		
		ammunition_capacity=GunData.initial_ammunition_capacity[id]
		clip_capacity=GunData.clip_max_capacity[id]
		reload_timer.wait_time=GunData.reload_time[id]
var is_helding:=false:
	set(value):
		is_helding=value
		if is_helding:
			host=get_parent()
			host.gun=self
			scale=Vector2(2,2)
			position=GunData.handheld_positions[id]
		else:
			host=null
			host.gun=null
func _ready() -> void:
	id=id
	is_helding=get_parent().get_script().get_global_name()=="Entity"
@export var audio_stream_player2d:AudioStreamPlayer2D
var last_shoot_time:int
func shoot()->void:
	if Time.get_ticks_msec()-last_shoot_time>=GunData.shoot_cds[id]:
		if clip_capacity>0:
			last_shoot_time=Time.get_ticks_msec()
			Global.add_muzzle_particles(to_global(GunData.muzzle[id]),rotation)
			var bullet:RayCast2D=preload("res://scene/Bullet/bullet.tscn").instantiate()
			bullet.rotation=rotation
			bullet.global_position=global_position+Vector2.LEFT.rotated(rotation)*200.0
			bullet.host=host
			bullet.gun_id=id
			bullet.move=Vector2.RIGHT.rotated(rotation)*GunData.bullet_speeds[id]
			Global.game_main.add_child(bullet)
			position+=Vector2.LEFT.rotated(rotation)*GunData.recoil[id]
			audio_stream_player2d.stop()
			audio_stream_player2d.stream=GunData.shoot_sound[id]
			audio_stream_player2d.play()
			if !host.is_player||!Global.option_data["玩家"]["无限子弹"]:
				clip_capacity-=1
			reload_timer.stop()
			
		else:
			if !audio_stream_player2d.playing:
				audio_stream_player2d.stream=preload("res://sound/entity/no_bullets.mp3")
				audio_stream_player2d.play()
func _process(delta: float) -> void:
	if host!=null:
		position=position.move_toward(GunData.handheld_positions[id],host.hand_strength*delta)
func reload()->void:
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
