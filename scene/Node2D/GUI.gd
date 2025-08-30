extends CanvasLayer
@export var lifebar:TextureProgressBar
@export var score:TextureProgressBar
@export var score_red:Label
@export var score_blue:Label
@export var clip_capacity:Label
@export var Kd:Label
@export var elimination_aannouncement:VBoxContainer
func _process(delta: float) -> void:
	lifebar.value=Global.player.health
	if Global.player.gun!=null:
		clip_capacity.text=str(Global.player.gun.clip_capacity)+"/"+str(Global.player.gun.ammunition_capacity)
	score.value=GameData.camp_score[0]/float(GameData.camp_score[0]+GameData.camp_score[1])*100
	score_red.text=str(GameData.camp_score[0])
	score_blue.text=str(GameData.camp_score[1])
	Kd.text=str(GameData.score[Global.player.camp][Global.player.id])+" - "+str(GameData.mortality_database[Global.player.camp][Global.player.id])
	if (GameData.camp_score[0]>=GameData.target_score||GameData.camp_score[1]>=GameData.target_score)&&!Global.is_over:
		Global.game_over()
