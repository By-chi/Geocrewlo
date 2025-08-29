extends CanvasLayer
var init_args:Dictionary
var game_main:Node2D
var player:Entity
var camp_view:Array[Array]=[[],[]]
@export var menu:ColorRect
@export var cursors:Sprite2D
func add_muzzle_particles(position:Vector2,particles_rotation:float)->void:
	if !option_data["显示"]["生成粒子"]:
		return
	var particles:=preload("res://scene/Node2D/muzzle_particles.tscn").instantiate()
	particles.global_position=position
	particles.rotation=particles_rotation
	particles.emitting=true
	
	particles.finished.connect(func():
		particles.queue_free()
	)
	game_main.add_child(particles)
	particles.scale=Vector2(10,10)
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cursors.position=event.position
	elif event is InputEventKey:
		if event.keycode==KEY_ESCAPE&&game_main!=null:
			get_tree().paused=true
			menu.show()
func _physics_process(delta: float) -> void:
	cursors.rotation+=0.4*delta
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	load_options()
func update_camp_view(id:int,camp:int)->void:
	camp_view[camp][id]=false
	for i in game_main.entity_list[camp]:
		if i.visible_entity[id]:
			camp_view[camp][id]=true
			break
	if camp==player.camp&&!Global.option_data["玩家"]["透视"]:
		game_main.entity_list[camp-1][id].visible=camp_view[camp][id]

func set_script_save_properties(node:Node,script:Script)->void:
	save_all_properties(node)
	node.set_script(script)
	load_all_properties(node)

# 用于临时存储所有属性的信息和值
var _temp_saved_values: Dictionary = {}  # 存储属性值（键为属性名）

## 第一步：保存脚本内定义的所有属性（完全排除script属性）
func save_all_properties(node: Node) -> bool:
	_temp_saved_values.clear()
	var all_props = node.get_property_list()
	if all_props == []:
		return false
	for prop in all_props:
		if prop["name"] == "script":
			continue
		if not prop["name"].begins_with("_") and prop["type"] != TYPE_NIL:
			_temp_saved_values[prop["name"]] = node.get(prop["name"])
	return true


## 第二步：加载保存的所有属性到新脚本
func load_all_properties(node: Node) -> bool:
	if _temp_saved_values=={}:
		return false
	for prop_name in _temp_saved_values:
		node.set(prop_name, _temp_saved_values[prop_name])
	_temp_saved_values.clear()
	if node.has_method("init"):
		node.init()
	return true

## 保存设置
func _on_save_pressed() -> void:
	var options:=ConfigFile.new()
	options.load("user://options.cfg")
	for i in $CanvasLayer3/Options/TabContainer.get_children():
		for j in i.get_children():
			if j.is_class("CheckButton"):
				options.set_value(i.name,j.text,j.button_pressed)
			elif j.is_class("Label"):
				options.set_value(i.name,j.text,j.get_child(0).text)
	options.save("user://options.cfg")
	option_data=config_to_nested_dict(options)
	_update_options()
func load_options()->void:
	var options:=ConfigFile.new()
	options.load("user://options.cfg")
	option_data=config_to_nested_dict(options)
	_update_options()
	
	for i in $CanvasLayer3/Options/TabContainer.get_children():
		for j in i.get_children():
			var value=options.get_value(i.name,j.text)
			if value==null:
				continue
			if j.is_class("CheckButton"):
				j.button_pressed=value
			elif j.is_class("Label"):
				j.get_child(0).text=value
	
var option_data:Dictionary
##将ConfigFile数据转换为嵌套字典结构
##格式: {section: {key: value, ...}, ...}
func config_to_nested_dict(config: ConfigFile) -> Dictionary:
	var nested_dict = {}
	for section in config.get_sections():
		var section_dict = {}
		for key in config.get_section_keys(section):
			section_dict[key] = config.get_value(section, key)
		nested_dict[section] = section_dict
	return nested_dict
func _update_options()->void:
	if option_data.is_empty():
		_on_save_pressed()
		return
	
	$CanvasLayer/ColorRect.visible=option_data["显示"]["\"VHS&CRT\" 效果"]
	$WorldEnvironment.environment.glow_enabled=option_data["显示"]["\"辉光\" 效果"]
