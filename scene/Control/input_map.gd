# 继承自VBoxContainer，用于创建一个输入映射配置面板，显示并允许修改游戏中的快捷键
extends VBoxContainer

# 用于跟踪当前正在修改快捷键的按钮（null表示未处于修改状态）
var monitoring
# 正则表达式对象，用于处理按键文本（去除多余的括号及内容）
var regex = RegEx.new()

# 更新界面显示的函数，用于刷新快捷键列表
func update() -> void:
	# 清除所有现有子节点（按钮），实现界面刷新
	for j in get_children():
		remove_child(j)
		j.queue_free()
	
	# 编译正则表达式，用于匹配并移除文本末尾的括号及内容（如"(A)"）
	regex.compile(r"\s*\([^)]*\)$")
	
	# 遍历InputMap中的所有动作
	for i in InputMap.get_actions():
		# 过滤条件：不处理以"ui_"开头的动作，且只处理有绑定事件的动作
		if !i.begins_with("ui_")&&!InputMap.action_get_events(i).is_empty():
			# 创建一个按钮用于显示和修改该动作的快捷键
			var button:=Button.new()
			# 获取该动作的第一个绑定事件，处理文本（去除括号内容）作为按键显示
			var key:=regex.sub(InputMap.action_get_events(i)[0].as_text(), "", 1)
			# 设置按钮文本：动作名 + 对应的按键（用空格分隔对齐）
			button.text=i+"          "+key
			# 设置按钮为切换模式（按下后保持选中状态）
			button.toggle_mode=true
			# 用动作名作为按钮的名称，便于后续识别
			button.name=i
			# 覆盖按钮的字体大小为40
			button.add_theme_font_size_override("font_size",40)
			# 覆盖按钮的正常状态样式
			button.add_theme_stylebox_override("normal",preload("res://scene/Control/button_normal.stylebox"))
			# 覆盖按钮的悬停状态样式
			button.add_theme_stylebox_override("hover",preload("res://scene/Control/button_hover.stylebox"))
			# 按钮文本左对齐
			button.alignment=HORIZONTAL_ALIGNMENT_LEFT
			
			# 绑定按钮的pressed信号（当按钮被按下/切换时触发）
			button.pressed.connect(
				func():
					# 如果按钮处于按下状态（选中）
					if button.button_pressed:
						# 记录当前正在修改的按钮
						monitoring=button
						# 禁用其他所有按钮，只保留当前选中的可交互
						for j in get_children():
							j.disabled=j!=button
			)
			
			# 将按钮添加到容器中
			add_child(button)

# 处理输入事件的函数，用于捕获并修改快捷键
func _input(event: InputEvent) -> void:
	# 如果未处于修改状态（monitoring为null），或事件是鼠标移动，则不处理
	if monitoring==null||event is InputEventMouseMotion:
		return
	
	# 如果按下了"ui_accept"动作（通常是确认键，如Enter），取消修改状态
	if event.is_action("ui_accept"):
		monitoring=null
		# 启用所有按钮
		for j in get_children():
			j.disabled=false
		return
	
	# 处理输入事件：提取按键文本（去除括号内容）
	var key:=regex.sub(event.as_text(), "", 1)
	# 更新当前正在修改的按钮文本（显示新的按键）
	monitoring.text=monitoring.name+"          "+key
	# 清除该动作原有的所有绑定事件
	InputMap.action_erase_events(monitoring.name)
	# 为该动作添加新的事件（绑定新的快捷键）
	InputMap.action_add_event(monitoring.name,event)
