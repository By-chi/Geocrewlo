# 继承自CanvasLayer，作为游戏的**全局管理器**（Global）
# 统筹游戏核心全局逻辑：游戏结束判定、粒子生成、输入控制、配置加载/保存、阵营视野同步、脚本属性保存等
extends CanvasLayer
# 游戏初始化参数字典（存储地图、人口、模式等启动配置，从主菜单传递）
var init_args:Dictionary
# 游戏主控制器节点引用（关联Game Main场景，用于操作实体、地图等）
var game_main:Node2D
# 玩家实体引用（全局唯一，供各脚本快速访问玩家信息）
var player:Entity
# 全局实体列表（二维数组：entity_list[阵营索引][实体索引] = 实体对象）
var entity_list: Array[Array]
# 阵营视野列表（标记敌对阵营实体是否在当前阵营的任意实体视野内，用于透视逻辑）
var camp_view:Array[Array]=[[],[]]

# 导出变量：全局游戏倒计时器（控制游戏时长，超时触发游戏结束）
@export var timer:Timer
# 导出变量：暂停菜单背景（ESC键触发显示）
@export var menu:ColorRect
# 导出变量：自定义鼠标光标精灵（替代系统光标）
@export var cursors:Sprite2D
# 游戏结束标记（防止重复触发游戏结束逻辑）
var is_over:=false

# 游戏结束核心逻辑（判定胜负、清理场景、切换结算界面）
func game_over()->void:
	if is_over:
		return
	is_over=true  # 标记游戏已结束
	Engine.time_scale=0.1  # 放慢时间流速（营造结束慢动作效果）
	
	# 判定获胜阵营（比较两大阵营分数）
	var winner:int
	if GameData.camp_score[0]>=GameData.camp_score[1]:
		winner=0  # 阵营0获胜
	else:
		winner=1  # 阵营1获胜
	
	# 播放胜负音效（根据玩家所属阵营判断）
	if winner==player.camp:
		player.audio_stream_player.stream=preload("res://sound/win.mp3")  # 胜利音效
	else:
		player.audio_stream_player.stream=preload("res://sound/losing.mp3")  # 失败音效
	player.audio_stream_player.stop()  # 停止当前播放的音效
	player.audio_stream_player.play()  # 播放胜负音效
	
	# 等待0.6秒（让慢动作和音效播放一段后恢复正常时间）
	await get_tree().create_timer(0.6).timeout
	Engine.time_scale=1  # 恢复正常时间流速
	
	# 清理所有实体（从游戏主节点移除）
	for i in entity_list:
		for j in i:
			game_main.remove_child(j)
	
	# 切换到结算菜单场景
	get_tree().change_scene_to_file("res://scene/Control/settlement_menu.tscn")

# 粒子系统常量（预加载常用粒子场景，避免重复加载）
const MUZZLE_PARTICLES = preload("res://scene/Node2D/muzzle_particles.tscn")  # 枪口火焰粒子
const SPARK_PARTICLES = preload("res://scene/Node2D/spark_particles.tscn")    # 碰撞火花粒子
const HIT_PARTICLES = preload("res://scene/Node2D/hit_particles.tscn")        # 击中实体粒子

# 通用粒子生成函数（统一管理粒子创建、配置和自动销毁）
# 参数：particles_scene-粒子场景，position-生成位置，_rotation-粒子旋转角度，custom_scale-粒子缩放
func add_generic_particles(particles_scene: PackedScene, position: Vector2, _rotation: float, custom_scale: Vector2) -> void:
	# 若关闭"生成粒子"选项，直接返回（性能优化）
	if !option_data["显示"]["生成粒子"]:
		return
	
	# 实例化粒子节点
	var particles = particles_scene.instantiate()
	particles.global_position = position  # 设置粒子生成位置
	particles.rotation = _rotation        # 设置粒子旋转角度
	particles.emitting = true             # 开启粒子发射
	# 粒子播放结束后自动销毁（避免内存泄漏）
	particles.finished.connect(func(): particles.queue_free())
	game_main.add_child(particles)        # 将粒子添加到游戏主节点
	particles.scale = custom_scale        # 设置粒子自定义缩放

# 全局输入事件处理（管理鼠标光标、暂停菜单触发）
func _input(event: InputEvent) -> void:
	# 鼠标移动事件：更新自定义光标的位置（跟随鼠标）
	if event is InputEventMouseMotion:
		cursors.position=event.position
	# 键盘按键事件：处理ESC键（触发游戏暂停和显示菜单）
	elif event is InputEventKey:
		if event.keycode==KEY_ESCAPE&&game_main!=null:
			get_tree().paused=true  # 暂停游戏
			if player.aiming:
				Input.mouse_mode=Input.MOUSE_MODE_HIDDEN
			menu.show()             # 显示暂停菜单

# 物理帧更新：让自定义光标缓慢旋转（提升视觉效果）
func _physics_process(delta: float) -> void:
	cursors.rotation+=0.4*delta  # 每帧增加0.4弧度旋转（约23度）

# 节点就绪初始化（游戏启动时执行）
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)  # 隐藏系统鼠标光标（使用自定义光标）
	load_options()  # 加载玩家保存的游戏设置（如显示、控制选项）
	randomize()     # 初始化随机数种子（确保随机结果不重复）
	for i in get_all_children_recursively(self):
		if i is Label:
			i.mouse_filter=Control.MOUSE_FILTER_PASS
		if i is Button||i is Label:
			i.mouse_entered.connect(func():
				$UI.stream=preload("res://sound/ui.mp3")
				$UI.play()
			)
	_on_save_pressed()
func get_all_children_recursively(node: Node) -> Array:
	var all_children = []
	
	# 获取直接子节点
	var direct_children = node.get_children()
	
	# 遍历直接子节点
	for child in direct_children:
		# 将当前子节点添加到结果数组
		all_children.append(child)
		
		# 递归获取当前子节点的所有子节点，并添加到结果数组
		var grand_children = get_all_children_recursively(child)
		# 使用append_array替代extend，兼容更多Godot版本
		all_children.append_array(grand_children)
	
	return all_children
# 更新阵营视野：判断某敌实体是否在当前阵营的任意实体视野内
# 参数：id-敌实体ID，camp-当前阵营索引
func update_camp_view(id:int,camp:int)->void:
	camp_view[camp][id]=false  # 默认标记为"不在视野内"
	
	# 遍历当前阵营的所有实体，检查是否有实体能看到该敌实体
	for i in entity_list[camp]:
		if i.visible_entity[id]:  # 若某实体能看到该敌实体
			camp_view[camp][id]=true  # 标记为"在视野内"
			break  # 找到一个即可，无需继续遍历
	
	# 玩家阵营特殊处理：未开启"透视"选项时，敌实体仅在视野内显示（隐藏视野外实体）
	if camp==player.camp&&!Global.option_data["玩家"]["透视"]:
		entity_list[camp-1][id].visible=camp_view[camp][id]

# 脚本切换时保存/加载属性（用于Player/AO脚本切换时保留实体状态，如生命值、枪支）
func set_script_save_properties(node:Node,script:Script)->void:
	save_all_properties(node)  # 第一步：保存节点当前所有属性
	node.set_script(script)     # 第二步：切换节点的脚本
	load_all_properties(node)  # 第三步：将保存的属性加载到新脚本

# 临时存储属性值的字典（key=属性名，value=属性值，用于脚本切换时过渡）
var _temp_saved_values: Dictionary = {}

# 保存节点的非私有、非script属性（排除内部属性，仅保留业务属性）
func save_all_properties(node: Node) -> bool:
	_temp_saved_values.clear()  # 清空临时字典
	var all_props = node.get_property_list()  # 获取节点所有属性列表
	if all_props == []:  # 无属性可保存时返回false
		return false
	
	# 遍历属性，筛选非私有（不以下划线开头）、非script的有效属性
	for prop in all_props:
		if prop["name"] == "script":  # 跳过script属性（避免脚本循环引用）
			continue
		# 仅保存非私有、非空类型的属性
		if not prop["name"].begins_with("_") and prop["type"] != TYPE_NIL:
			_temp_saved_values[prop["name"]] = node.get(prop["name"])
	return true

# 将保存的属性加载到切换脚本后的节点
func load_all_properties(node: Node) -> bool:
	if _temp_saved_values=={}:  # 无保存的属性时返回false
		return false
	
	# 遍历临时字典，为节点设置属性值
	for prop_name in _temp_saved_values:
		node.set(prop_name, _temp_saved_values[prop_name])
	_temp_saved_values.clear()  # 清空临时字典（释放内存）
	
	# 若节点有init方法，调用初始化（确保新脚本正常启动）
	if node.has_method("init"):
		node.init()
	return true

# 保存游戏设置（响应设置界面的"保存"按钮，将选项写入配置文件）
func _on_save_pressed() -> void:
	var options:=ConfigFile.new()  # 创建配置文件对象
	options.load("user://options.cfg")  # 加载已有的配置（若无则创建）
	
	# 遍历设置界面的所有选项（按标签页和控件分类）
	for i in $CanvasLayer3/Options/TabContainer.get_children():
		for j in i.get_node(^"HBoxContainer").get_children():
			# 处理复选框（如"生成粒子"、"透视"）
			if j.is_class("CheckButton"):
				options.set_value(i.name,j.text,j.button_pressed)
			# 处理标签对应的输入框（如"限制帧率"数值）
			elif j.is_class("Label"):
				options.set_value(i.name,j.text,j.get_child(0).text)
			# 处理按键绑定按钮（保存按键事件）
			elif j.is_class("Button")&&i.name=="按键绑定":
				options.set_value(i.name,j.name,InputMap.action_get_events(j.name)[0])
	
	options.save("user://options.cfg")  # 保存配置到用户目录
	option_data=config_to_nested_dict(options)  # 转换为嵌套字典方便使用
	_update_options()  # 应用新保存的设置
	$CanvasLayer3/Options.hide()  # 隐藏设置界面

# 加载游戏设置（游戏启动时调用，恢复玩家上次保存的选项）
func load_options()->void:
	var options:=ConfigFile.new()  # 创建配置文件对象
	options.load("user://options.cfg")  # 加载用户目录的配置文件
	option_data=config_to_nested_dict(options)  # 转换为嵌套字典
	
	# 刷新按键绑定界面（显示当前绑定的按键）
	$"CanvasLayer3/Options/TabContainer/按键绑定/HBoxContainer".update()
	
	# 遍历配置，为设置界面控件赋值
	for i in $CanvasLayer3/Options/TabContainer.get_children():
		for j in i.get_node(^"HBoxContainer").get_children():
			if !options.has_section(i.name):  # 无该标签页配置时跳过
				return
			# 恢复复选框状态
			if j.is_class("CheckButton"):
				var value=options.get_value(i.name,j.text)
				if value==null:
					continue
				j.button_pressed=value
			# 恢复输入框文本（如帧率数值）
			elif j.is_class("Label"):
				var value=options.get_value(i.name,j.text)
				if value==null:
					continue
				j.get_child(0).text=value
			# 恢复按键绑定（更新InputMap）
			elif j.is_class("Button")&&i.name=="按键绑定":
				var value=options.get_value(i.name,j.name)
				if value==null:
					continue
				InputMap.action_erase_events(j.name)  # 清除旧绑定
				InputMap.action_add_event(j.name,value)  # 应用新绑定
	
	_update_options()  # 应用加载的设置

# 游戏设置数据字典（存储当前生效的设置，如显示、控制、AI选项）
var option_data:Dictionary

# 将ConfigFile的扁平结构转换为嵌套字典（section→key→value，结构更清晰）
func config_to_nested_dict(config: ConfigFile) -> Dictionary:
	var nested_dict = {}
	# 遍历所有配置section（如"全局"、"显示"、"玩家"）
	for section in config.get_sections():
		var section_dict = {}
		# 遍历section下的所有key-value，存入子字典
		for key in config.get_section_keys(section):
			section_dict[key] = config.get_value(section, key)
		nested_dict[section] = section_dict
	return nested_dict

# 应用游戏设置（将加载/保存的配置应用到游戏运行时）
func _update_options()->void:
	if option_data.is_empty():  # 无配置时保存默认设置
		_on_save_pressed()
		return
	
	# 设置最大帧率（从"全局"→"限制帧率"读取）
	if str(option_data["全局"]["限制帧率"]).is_valid_int():
		Engine.max_fps=int(option_data["全局"]["限制帧率"])
	
	# 刷新按键绑定界面
	$"CanvasLayer3/Options/TabContainer/按键绑定/HBoxContainer".update()
	
	# 控制VHS&CRT效果显示（从"显示"→"VHS&CRT效果"读取）
	$CanvasLayer/ColorRect.visible=option_data["显示"]["\"VHS&CRT\" 效果"]
	
	# 控制辉光效果开启（从"显示"→"辉光效果"读取）
	$WorldEnvironment.environment.glow_enabled=option_data["显示"]["\"辉光\" 效果"]
	
	ProjectSettings.set_setting("display/window/stretch/scale",float(option_data["显示"]["分辨率缩放"]))
	#RenderingServer.viewport_set_size(get_viewport().get_viewport_rid(),int(option_data["显示"]["分辨率 宽"]),int(option_data["显示"]["分辨率 高"]))
	get_window().size=Vector2i(int(option_data["显示"]["分辨率 宽"]),int(option_data["显示"]["分辨率 高"]))
	if option_data["显示"]["全屏"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	print(ProjectSettings.get_setting("display/window/stretch/scale"))
	#get_tree().root.child_controls_changed()
	# 控制FPS显示（从"显示"→"显示FPS"读取，需游戏主节点已初始化）
	if game_main!=null:
		game_main.UI.Fps.visible=option_data["显示"]["显示 \"FPS\""]

# 全局倒计时器超时回调（游戏时间结束，触发游戏结束）
func _on_timer_timeout() -> void:
	game_over()
