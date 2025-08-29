extends CharacterBody2D
class_name Entity
@export var heal_timer:Timer
var health:=EntityData.health
func set_health(new_health:float,mastermind:Entity)->void:
	if new_health<EntityData.health:
		heal_timer.start((EntityData.health-new_health)*0.01*EntityData.heal_base_time)
	if new_health<=0:
		if is_player&&Global.option_data["玩家"]["锁血"]:
			health=0
			return
		GameData.camp_score[camp-1]+=1
		GameData.score[mastermind.camp][mastermind.id]+=1
		if mastermind.is_player:
			audio_stream_player.stream=load("res://sound/entity/kill_"+str(randi()%4)+".mp3")
			audio_stream_player.play()
		match Global.init_args["Mode"]:
			0:
				var playstarts:Array=Global.game_main.playstarts[camp]
				position=playstarts[randi()%playstarts.size()]
				gun.id=randi()%GunData.names.size()
				new_health=EntityData.health
			1:
				position=Global.game_main.entity_list[camp][id-randi()%Global.game_main.entity_list[camp].size()].position+Vector2(1,1)
				gun.id=randi()%GunData.names.size()
				new_health=EntityData.health
			2:
				set_physics_process(false)
				set_process(false)
				is_dead=true
				position=Vector2(114514,114514)
		if !is_player:
			set("destination",get("map").empty_tiles[randi()%get("map").empty_tiles.size()])
			set("move_name","Take a casual stroll")
			set("is_pathfinding",true)
	health=new_health
@export var audio_stream_player:AudioStreamPlayer
@export var injury_area:Area2D
@export var sprite:Sprite2D
@export var rays:Node2D
@export var view:Area2D
var id:int
var move_speed:=EntityData.move_speed
var sprint_speed_rate:=EntityData.sprint_speed_rate
var speed:=move_speed
var rotational_acceleration:=EntityData.rotational_acceleration
var hand_strength:=EntityData.hand_strength
var rotate_speed:=0.0
var is_player:=false
var camp:=0
var is_dead:=false

@export var animation:AnimationPlayer
@export var camera:Camera2D
var move_velocity:=Vector2.ZERO
func _input(event: InputEvent) -> void:
	pass
func shoot()->void:
	if gun==null:
		return
	gun.shoot()
func _ready() -> void:
	if camp==0:
		self_modulate=Color.RED*4
	else:
		self_modulate=Color.DODGER_BLUE*4
	$thumbnail.modulate=self_modulate
	var size:int=int(Global.init_args["Population"])/2
	in_view.resize(size)
	in_view.fill(false)
	no_obstruction.resize(size)
	no_obstruction.fill(false)
	visible_entity.resize(size)
	visible_entity.fill(false)
	if is_player:
		Global.set_script_save_properties(self,preload("res://scene/Node2D/entity/player.gd"))
	else:
		Global.set_script_save_properties(self,preload("res://scene/Node2D/entity/ai.gd"))
func _physics_process(delta: float) -> void:
	if camp==0:
		for i in rays.get_children():
			if !i.is_colliding()!=no_obstruction[i.to.id]:
				no_obstruction[i.to.id]=!i.is_colliding()
				no_obstruction_sync(id,i.to.id)
				update_visible_entity(i.to.id)
	
	move_velocity=Vector2.ZERO
	if sprint_timer.is_stopped():
		move()
		sprint_base_move=move_velocity
	else:
		move_velocity=sprint_base_move*sprint_speed_rate
	if Engine.get_physics_frames()%(Engine.physics_ticks_per_second/60)==0:
		rotate_speed+=rotational_acceleration*(move_velocity.x+move_velocity.y)
		sprite.rotation+=rotate_speed
		rotate_speed*=0.9
	velocity=move_velocity
	move_and_slide()



@export var sprint_cd_timer:Timer
@export var sprint_timer:Timer
var sprint_cd:=EntityData.sprint_cd
var sprint_duration:=EntityData.sprint_duration
var sprint_base_move:Vector2
func sprint()->void:
	if !sprint_cd_timer.is_stopped()||!sprint_timer.is_stopped():
		return
	sprint_timer.start(sprint_duration)
	speed=move_speed*sprint_speed_rate
	animation.play("sprint")
var gun:Area2D
func move() -> void:
	pass
func is_facing_right() -> bool:
	var normalized_angle = fmod(gun.rotation ,(2 * PI))
	if normalized_angle < 0:
		normalized_angle += 2 * PI
	return normalized_angle < PI/2 or normalized_angle > 3 * PI/2
func rotate_gun()->void:
	if is_facing_right():
		gun.scale.y=2
	else:
		gun.scale.y=-2
@export var direction_line:ColorRect
func _process(delta: float) -> void:
	if gun!=null:
		rotate_gun()
		

func add_sprint_ghost()->void:
	var sprint_ghost:=preload("res://scene/Node2D/entity/sprint_ghost.tscn").instantiate()
	Global.game_main.add_child(sprint_ghost)
	sprint_ghost.rotation=sprite.rotation
	sprint_ghost.global_position=global_position
	sprint_ghost.self_modulate=self_modulate
	var tween:=sprint_ghost.create_tween()
	tween.tween_property(sprint_ghost,"self_modulate",Color.TRANSPARENT,0.2).set_ease(Tween.EASE_IN)
func _on_sprint_timeout() -> void:
	sprint_cd_timer.start(sprint_cd)
	speed=move_speed




#region view
var in_view:Array[bool]=[]
var no_obstruction:Array[bool]=[]
var visible_entity:Array[bool]=[]
func update_visible_entity(index:int)->void:
	var visible_value:=in_view[index]&&no_obstruction[index]
	visible_entity[index]=visible_value
	Global.update_camp_view(index,camp)
func no_obstruction_sync(self_index:int,sync_index:int)->void:
	var to:Entity=Global.game_main.entity_list[1][sync_index]
	to.no_obstruction[self_index]=no_obstruction[sync_index]
	to.update_visible_entity(self_index)
func _on_view_area_entered_or_exited(area:  Area2D,is_add:=true) -> void:
	var entity=area.get_parent().get_parent()
	if entity.is_class("CharacterBody2D")&&entity.camp!=camp:
		in_view[entity.id]=is_add
		update_visible_entity(entity.id)

#endregion


func _on_heal_timeout() -> void:
	set_health(min(health+33,EntityData.health),self)
