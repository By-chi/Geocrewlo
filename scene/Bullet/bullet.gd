extends RayCast2D

var move:Vector2
var host:Entity
var gun_id:=0
var free:=false
@export var head:Area2D
var start_time:int
func _ready() -> void:
	scale.x=GunData.bullet_speeds[gun_id]/16000.0
	start_time=Time.get_ticks_msec()
	add_exception(host.injury_area)
	add_exception(host)
	for i in Global.game_main.entity_list:
		for j in i:
			add_exception(j.view)
			if !j.is_player:
				add_exception(j.dodge_area)
	add_exception(host.view)
	add_exception(head)
	if host.gun!=null:
		add_exception(host.gun)
	await get_tree().create_timer(0.1).timeout
	$AudioStreamPlayer2D.play()

func hit(node: Node2D) -> void:
	if free:
		return
	var entity=node.get_parent().get_parent()
	
	if entity.is_class("CharacterBody2D"):
		if host.is_player&&Global.option_data["玩家"]["秒杀"]:
			entity.set_health(0,host)
		else:
			entity.set_health(
				
				entity.health-
				GunData.damages[gun_id]+
				max(0,(Time.get_ticks_msec()-start_time)*
				GunData.damage_decay_rates[gun_id]),
				
				host
			)
		if host.is_player:
			host.audio_stream_player.stream=preload("res://sound/entity/hit.mp3")
			host.audio_stream_player.play()
	free=true
	queue_free()
func _physics_process(delta: float) -> void:
	if is_colliding():
		hit(get_collider())
	position+=move*delta
	
