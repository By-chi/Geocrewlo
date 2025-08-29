extends CanvasLayer
func _process(delta: float) -> void:
	$Lifebar.value=Global.player.health
	if Global.player.gun!=null:
		$clip_capacity.text=str(Global.player.gun.clip_capacity)+"/"+str(Global.player.gun.ammunition_capacity)
	$score.value=GameData.camp_score[0]/float(GameData.camp_score[0]+GameData.camp_score[1])*100
	$score/Red.text=str(GameData.camp_score[0])
	$score/Blue.text=str(GameData.camp_score[1])
