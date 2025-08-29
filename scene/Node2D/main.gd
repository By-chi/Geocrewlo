extends Node2D
var arg:Dictionary
var map:TileMapLayer
var entity_list:Array[Array]
var playstarts:Array[Array]
func back_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scene/Control/main_menu.tscn")
func _ready() -> void:
	
	Global.game_main=self
	arg=Global.init_args
	if arg=={}:
		back_to_main_menu()
	map=load("res://scene/Map/"+MapData.names[arg["Map"]]+".tscn").instantiate()
	add_child(map)
	var half_population:=int(arg["Population"])/2
	Global.camp_view[0].resize(half_population)
	Global.camp_view[0].fill(false)
	Global.camp_view[1].resize(half_population)
	Global.camp_view[1].fill(false)
	GameData.camp_score.resize(2)
	GameData.camp_score.fill(0)
	GameData.score.resize(2)
	var arr:Array[int]
	arr.resize(half_population)
	arr.fill(0)
	GameData.score.fill(arr.duplicate())
	var player_id:=randi()%half_population
	var player_camp:=randi()%2
	for i in MapData.start_location[arg["Map"]].size():
		entity_list.append([])
		playstarts.append([])
		for j in half_population:
			var x:=lerpf(MapData.start_location[arg["Map"]][i].x,MapData.start_location[arg["Map"]][i].z,j/float(half_population))
			var y:=lerpf(MapData.start_location[arg["Map"]][i].y,MapData.start_location[arg["Map"]][i].w,j/float(half_population))
			var entity:=preload("res://scene/Node2D/entity/entity.tscn").instantiate()
			entity.position=Vector2(x,y)
			entity_list[i].append(entity)
			playstarts[i].append(Vector2(x,y))
			if entity_list[i].size()-1==player_id&&i==player_camp:
				entity.is_player=true
				Global.player=entity
			
			if i==0:
				entity.camp=0
			else:
				entity.camp=1
			entity.id=j
			add_child(entity)
	for i in half_population:
		for j in half_population:
			var ray:=preload("res://scene/Node2D/ray.tscn").instantiate()
			ray.from=entity_list[0][i]
			ray.to=entity_list[1][j]
			ray.add_exception(entity_list[0][i])
			ray.add_exception(entity_list[1][j])
			entity_list[0][i].rays.add_child(ray)
		
