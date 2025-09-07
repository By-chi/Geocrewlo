extends Control
@export var red_rect:ColorRect
@export var blue_rect:ColorRect
func _ready() -> void:
	Input.mouse_mode=Input.MOUSE_MODE_HIDDEN
	var tween_color:Tween
	var tween_scale:Tween
	if GameData.camp_score[0]>=GameData.camp_score[1]:
		red_rect.z_index=1
		red_rect.pivot_offset.y=red_rect.size.y/2
		tween_color=red_rect.create_tween()
		tween_color.tween_property(red_rect,"modulate",Color(6, 6, 6),1.0).set_trans(Tween.TRANS_QUART)
		tween_scale=red_rect.create_tween()
		tween_scale.tween_property(red_rect,"scale",Vector2(2,1),1.0).set_trans(Tween.TRANS_QUART)
	else:
		blue_rect.z_index=1
		blue_rect.pivot_offset.y=blue_rect.size.y/2
		blue_rect.pivot_offset.x=blue_rect.size.x
		tween_color=blue_rect.create_tween()
		tween_color.tween_property(blue_rect,"modulate",Color(6, 6, 6),1.0).set_trans(Tween.TRANS_QUART)
		tween_scale=blue_rect.create_tween()
		tween_scale.tween_property(blue_rect,"scale",Vector2(2,1),1.0).set_trans(Tween.TRANS_QUART)
	var red_list:Array=Global.entity_list[0].duplicate()
	red_list.sort_custom(func(a,b):
		if calculate_player_score(
				GameData.score[0][a.id],
				GameData.mortality_database[0][a.id],
				GameData.camp_score[0],
				GameData.camp_score[1],
				red_list.size()*2
		)>calculate_player_score(
				GameData.score[0][b.id],
				GameData.mortality_database[0][b.id],
				GameData.camp_score[0],
				GameData.camp_score[1],
				red_list.size()*2
		):
			return true
		return false
	)
	var blue_list:Array=Global.entity_list[1].duplicate()
	blue_list.sort_custom(func(a,b):
		if calculate_player_score(
				GameData.score[1][a.id],
				GameData.mortality_database[1][a.id],
				GameData.camp_score[1],
				GameData.camp_score[0],
				blue_list.size()*2
		)>calculate_player_score(
				GameData.score[1][b.id],
				GameData.mortality_database[1][b.id],
				GameData.camp_score[1],
				GameData.camp_score[0],
				blue_list.size()*2
		):
			return true
		return false
	)
	for i in red_list:
		var label:=Label.new()
		if Global.entity_list[0][i.id].is_player:
			label.self_modulate=Color.LIME_GREEN
		var tween=label.create_tween()
		var score:=calculate_player_score(
					GameData.score[0][i.id],
					GameData.mortality_database[0][i.id],
					GameData.camp_score[0],
					GameData.camp_score[1],
					red_list.size()*2
					)
		var i_name_label_text:String=i.name_label.text
		var i_id:int=i.id
		tween.tween_method(func(value:=0.0):
			label.text="{0}        {1}  -  {2}        {3}".format(
				[i_name_label_text,
				str(GameData.score[0][i_id]),
				str(GameData.mortality_database[0][i_id]),
				str(value*score).pad_decimals(2)
				]
			)
			,0.0,1.0,3
		)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_FILL
		label.add_theme_font_size_override("font_size",40)
		
		$Red2/VBoxContainer.add_child(label)
	for i in blue_list:
		var label:=Label.new()
		if Global.entity_list[1][i.id].is_player:
			label.self_modulate=Color.LIME_GREEN
		var score:=calculate_player_score(
					GameData.score[1][i.id],
					GameData.mortality_database[1][i.id],
					GameData.camp_score[1],
					GameData.camp_score[0],
					red_list.size()*2
					)
		var tween=label.create_tween()
		var i_name_label_text:String=i.name_label.text
		var i_id:int=i.id
		tween.tween_method(func(value:=0.0):
			label.text="{0}        {1}  -  {2}        {3}".format(
				[i_name_label_text,
				str(GameData.score[1][i_id]),
				str(GameData.mortality_database[1][i_id]),
				str(value*score).pad_decimals(2)
				]
			)
			,0.0,1.0,3
		)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_FILL
		label.add_theme_font_size_override("font_size",40)
		$Blue2/VBoxContainer.add_child(label)
	for i in Global.entity_list:
		for j in i:
			j.queue_free()
# 计算玩家评分的核心函数   (--AI生成--)
# 参数说明:
# - k: 个人击杀数
# - d: 个人死亡数
# - team_kills: 团队总击杀数
# - enemy_kills: 敌方总击杀数
# - total_players: 总玩家数
func calculate_player_score(k: int, d: int, team_kills: int, enemy_kills: int, total_players: int) -> float:
	# 确保输入值有效
	if total_players <= 0:
		push_warning("总玩家数必须大于0")
		return 0.0
		
	var team_size: float = total_players / 2.0  # 假设两队人数平均分配
	
	# 处理团队总击杀为0的边界情况
	var t: float = float(team_kills) if float(team_kills) > 0 else (1.0 if k > 0 else 0.1)
	
	# 计算击杀价值部分
	var base_kill_score: float = calculate_base_kill_score(enemy_kills)
	var team_impact: float = calculate_team_impact(k, t, team_size)
	var kill_value: float = base_kill_score * team_impact
	
	# 计算死亡惩罚部分
	var base_death_penalty: float = calculate_base_death_penalty(enemy_kills, total_players)
	var survival_factor: float = calculate_survival_factor(d, enemy_kills, team_size)
	var death_penalty: float = base_death_penalty * survival_factor
	
	# 最终得分
	var final_score: float = kill_value - death_penalty
	
	# 确保得分不会过低或过高（可根据游戏平衡调整）
	return clampf(final_score, -100.0, 2000.0)


# 计算基础击杀分数
func calculate_base_kill_score(enemy_kills: int) -> float:
	# 处理敌方总击杀为0的边界情况
	if enemy_kills <= 0:
		return 10.0  # 新手局默认基础分
		
	# 使用换底公式计算以10为底的对数
	return (log(enemy_kills + 1) / log(10)) * 10.0


# 计算团队影响因子
func calculate_team_impact(personal_kills: int, team_kills: float, team_size: float) -> float:
	if team_kills <= 0 or team_size <= 0:
		return 0.0
		
	# 个人贡献比例 × 团队效率修正
	var contribution_ratio: float = personal_kills / team_kills
	var team_efficiency: float = sqrt(team_kills / team_size)
	
	return contribution_ratio * team_efficiency


# 计算基础死亡惩罚
func calculate_base_death_penalty(enemy_kills: int, total_players: int) -> float:
	if total_players <= 0:
		return 0.0
		
	# 敌方击杀效率越高，死亡惩罚越低
	return (enemy_kills / float(total_players)) * 10.0


# 计算生存因子
func calculate_survival_factor(personal_deaths: int, enemy_kills: int, team_size: float) -> float:
	# 处理个人无死亡的情况
	if personal_deaths == 0:
		return 0.5  # 中等生存能力默认值
		
	# 处理敌方总击杀为0的边界情况
	if enemy_kills <= 0:
		return personal_deaths * 0.1  # 特殊处理避免除零
		
	# 个人死亡占敌方总击杀比例 × 团队规模修正
	var death_ratio: float = personal_deaths / float(enemy_kills)
	var team_scale: float = team_size / enemy_kills
	
	return sqrt(death_ratio * team_scale)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Control/main_menu.tscn")
