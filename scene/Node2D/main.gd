# 继承自Node2D，作为游戏的**主控制器**（Game Main）
# 负责游戏初始化的核心流程：加载地图、生成实体（玩家/AI）、初始化游戏数据、创建视野检测射线等
extends Node2D

# 存储游戏初始化参数的字典（如地图选择、人口数量、游戏模式等，从全局变量Global传递）
var arg: Dictionary
# 游戏地图节点（TileMapLayer类型，用于渲染游戏地形和碰撞）
var map: TileMapLayer

# 各阵营的出生点数组（二维数组：playstarts[阵营索引][实体索引] = 出生位置Vector2）
var playstarts: Array[Array]
# 导出变量：游戏UI层（用于显示分数、倒计时、公告等UI元素）
@export var UI: CanvasLayer

# 返回到主菜单场景的函数
func back_to_main_menu() -> void:
	# 切换场景到主菜单（通过场景文件路径）
	get_tree().change_scene_to_file("res://scene/Control/main_menu.tscn")


# 节点就绪时调用（游戏启动的核心初始化逻辑）
func _ready() -> void:
	# 1. 初始化游戏基础状态
	Global.timer.start(300)  # 启动全局计时器（推测为300秒游戏倒计时）
	Global.is_over=false     # 标记游戏未结束
	Global.entity_list.clear()  # 清空全局实体列表（避免上一局数据残留）
	Global.game_main = self     # 将当前主控制器实例赋值给全局变量，供其他脚本调用

	# 2. 验证初始化参数：若参数为空（未正确进入游戏），直接返回主菜单
	arg = Global.init_args
	if arg == {}:
		back_to_main_menu()

	# 3. 加载游戏地图（从MapData配置中获取地图名称，实例化地图场景）
	map = load("res://scene/Map/" + MapData.names[arg["Map"]] + ".tscn").instantiate()
	add_child(map)  # 将地图添加到主场景

	# 4. 计算核心数值：实体总数量的一半（阵营0和阵营1各占一半）
	var half_population := int(arg["Population"]) / 2

	# 5. 根据游戏模式设置目标分数（不同模式胜利条件不同）
	if arg["Mode"]==0||arg["Mode"]==1:
		GameData.target_score=100  # 模式0/1：目标分数100（推测为积分制）
	elif arg["Mode"]==2:
		GameData.target_score=half_population  # 模式2：目标分数=阵营人数（推测为全灭制）

	# 6. 初始化阵营视野数组（用于AI目标检测，标记敌对阵营实体是否在视野内）
	Global.camp_view[0].resize(half_population)  # 阵营0的视野列表（对应阵营1的实体数量）
	Global.camp_view[0].fill(false)              # 初始化为false（无实体在视野内）
	Global.camp_view[1].resize(half_population)  # 阵营1的视野列表（对应阵营0的实体数量）
	Global.camp_view[1].fill(false)

	# 7. 初始化游戏数据结构（分数统计、死亡率统计）
	GameData.camp_score.resize(2)  # 阵营分数数组（索引0=阵营0，索引1=阵营1）
	GameData.camp_score.fill(0)    # 初始分数为0
	GameData.score.resize(half_population)          # 个人分数数组（每个实体的分数）
	GameData.mortality_database.resize(half_population)  # 死亡率数据库（记录各实体死亡次数）
	
	# 初始化个人分数和死亡率的二维数组（[实体ID][目标ID]）
	var arr: Array[int]
	arr.resize(half_population)
	arr.fill(0)  # 初始值为0
	for i in half_population:
		GameData.score[i]=arr.duplicate()          # 复制空数组到每个实体的分数列表
		GameData.mortality_database[i]=arr.duplicate()  # 复制空数组到每个实体的死亡率列表

	# 8. 随机生成玩家信息（玩家在实体中的位置和所属阵营）
	var player_id := randi() % half_population  # 随机玩家ID（在阵营内的索引）
	var player_camp := randi() % 2              # 随机玩家阵营（0或1）

	# 9. 生成实体（玩家+AI）及对应出生点
	# 遍历地图配置中的出生点区域（MapData.start_location存储各阵营的出生区域）
	for i in MapData.start_location[arg["Map"]].size():
		Global.entity_list.append([])  # 为当前阵营添加实体列表
		playstarts.append([])          # 为当前阵营添加出生点列表

		# 为当前阵营生成half_population个实体（每个实体对应一个出生点）
		for j in half_population:
			# 计算实体的出生位置（在阵营出生区域内线性插值，均匀分布）
			var x := lerpf(
				MapData.start_location[arg["Map"]][i].x,  # 出生区域左边界X
				MapData.start_location[arg["Map"]][i].z,  # 出生区域右边界X
				j / float(half_population)                # 插值比例（0~1）
			)
			var y := lerpf(
				MapData.start_location[arg["Map"]][i].y,  # 出生区域下边界Y
				MapData.start_location[arg["Map"]][i].w,  # 出生区域上边界Y
				j / float(half_population)                # 插值比例（0~1）
			)

			# 实例化实体（从entity场景加载）
			var entity := preload("res://scene/Node2D/entity/entity.tscn").instantiate()
			entity.position = Vector2(x, y)  # 设置实体出生位置
			Global.entity_list[i].append(entity)  # 将实体添加到全局阵营实体列表
			playstarts[i].append(Vector2(x, y))   # 记录该实体的出生点

			# 标记当前实体为玩家（匹配随机生成的玩家阵营和ID）
			if Global.entity_list[i].size() - 1 == player_id && i == player_camp:
				entity.is_player = true  # 标记为玩家实体
				Global.player = entity   # 将玩家实体赋值给全局变量，供其他脚本调用

			# 设置实体的阵营（索引0=阵营0，索引1=阵营1）
			if i == 0:
				entity.camp = 0
			else:
				entity.camp = 1
			entity.id = j  # 设置实体在阵营内的唯一ID（0~half_population-1）
			add_child(entity)  # 将实体添加到主场景
			entity.name_label.text="p"+str(i)+str(j)  # 设置实体名称标签（格式：p+阵营+ID，如p01）

	# 10. 创建视野检测射线（仅阵营0→阵营1，用于遮挡检测）
	# 遍历阵营0的每个实体，为其创建指向阵营1每个实体的射线
	for i in half_population:
		for j in half_population:
			var ray := preload("res://scene/Node2D/ray.tscn").instantiate()  # 实例化射线节点
			ray.from = Global.entity_list[0][i]  # 射线起点：阵营0的第i个实体
			ray.to = Global.entity_list[1][j]    # 射线终点：阵营1的第j个实体
			# 添加射线碰撞例外：避免射线检测到自身和目标实体（防止误判遮挡）
			ray.add_exception(Global.entity_list[0][i])
			ray.add_exception(Global.entity_list[1][j])
			# 将射线添加到阵营0实体的rays节点下（由实体管理自身视野射线）
			Global.entity_list[0][i].rays.add_child(ray)
