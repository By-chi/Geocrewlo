extends CanvasLayer
@export var lifebar:TextureProgressBar
@export var score:TextureProgressBar
@export var score_red:Label
@export var score_blue:Label
@export var score_time:Label
@export var clip_capacity:Label
@export var Kd:Label
@export var Fps:Label
@export var elimination_aannouncement:VBoxContainer
var entity:Entity
func _ready() -> void:
	Fps.visible=Global.option_data["显示"]["显示 \"FPS\""]
func _process(delta: float) -> void:
	if Engine.get_physics_frames()%30==0:
		entity=get_viewport().get_camera_2d().get_parent()
	if entity!=null:
		lifebar.value=entity.health
		if entity.gun!=null:
			clip_capacity.text=str(entity.gun.clip_capacity)+"/"+str(entity.gun.ammunition_capacity)
		score.value=GameData.camp_score[0]/float(GameData.camp_score[0]+GameData.camp_score[1])*100
		score_red.text=str(GameData.camp_score[0])
		score_blue.text=str(GameData.camp_score[1])
		Kd.text=str(GameData.score[entity.camp][entity.id])+" - "+str(GameData.mortality_database[entity.camp][entity.id])
	if (GameData.camp_score[0]>=GameData.target_score||GameData.camp_score[1]>=GameData.target_score)&&!Global.is_over:
		Global.game_over()
	else:
		score_time.text=str(int(Global.timer.time_left)).pad_zeros(3)
#region Fps
	if Global.option_data["显示"]["显示 \"FPS\""]:
		var fps:=Engine.get_frames_per_second()
		Fps.text=str(int(fps))
		var red:float
		if fps >= 100:
			red = 0.0
		elif fps >= 30:
			red = (100.0 - fps) / (100.0 - 30.0)
		else:
			red = 1.0
		var green:float
		if fps >= 100:
			green = 1.0
		elif fps >= 30:
			green = 1.0
		else:
			green = fps / 30.0
		red = max(0.0, min(1.0, red))
		green = max(0.0, min(1.0, green))
		Fps.self_modulate = Color(red, green, 0.0)
#endregion
