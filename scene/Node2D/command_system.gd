extends Panel

# 权限等级映射（全局唯一）
const PERMISSION_MAP: Dictionary = {
	"user": 0,
	"admin": 1
}

# 存储所有命令（键：命令名/别名，值：命令模块实例）
var commands: Dictionary = {}

# 注册命令模块（添加成功/失败提示）
func register_command(script: Script) -> void:
	# 检查脚本是否有效
	if not script:
		_print("[命令系统] 注册失败：传入的脚本无效（null）")
		return
	
	# 尝试创建命令实例
	var command_module = Node.new()
	if not command_module:
		_print("[命令系统] 注册失败：无法创建命令实例（脚本路径：{0}）".format([script.resource_path]))
		return
	
	# 尝试设置脚本
	command_module.set_script(script)
	if command_module.get_script() != script:
		_print("[命令系统] 注册失败：无法为实例设置脚本（脚本路径：{0}）".format([script.resource_path]))
		return
	
	# 添加到场景
	get_tree().root.add_child(command_module)
	
	# 注册主命令名和别名
	commands[command_module.command_name.to_lower()] = command_module
	for alias in command_module.aliases:
		commands[alias.to_lower()] = command_module
	
	# 注册成功提示
	_print("[命令系统] 注册成功：/{}（别名：{}，脚本路径：{}）".format([
		command_module.command_name,
		command_module.aliases,
		script.resource_path
	]))

func _ready() -> void:
	register_command(preload("res://scene/Node2D/commands/command_tp.gd"))
	register_command(preload("res://scene/Node2D/commands/command_set.gd"))

# 唯一的命令执行入口（所有命令都通过这里解析和执行）
func execute_command(command_string: String, executor_perm: String="admin") -> Dictionary:
	_print("\n[命令系统] 收到命令: {command_string} (执行者权限: {executor_perm})".format({"command_string":command_string,"executor_perm":executor_perm}))
	
	# 1. 基础验证与解析（全局唯一的解析逻辑）
	var parse_result = _parse_command(command_string)
	if not parse_result.success:
		return { success = false, message = parse_result.error }
	
	# 2. 查找对应的命令模块
	var command_head = parse_result.command_head
	if command_head not in commands:
		var message:= "未知命令: {command_head}".format({"command_head":command_head})
		_print(message)
		return { success = false,message=message}
		
	var command_module = commands[command_head]
	
	# 3. 权限检查（全局统一逻辑）
	var permission_check = _check_permission(executor_perm, command_module.permission_level)
	if not permission_check.success:
		return permission_check
	
	# 4. 调用命令模块的具体功能（模块化的功能实现）
	_print("[命令系统] 调度命令: /{command_head} (参数: {parse_result.args})".format({"command_head":command_head,"parse_result.args":parse_result.args}))
	var execute_result = command_module.execute(parse_result.args, executor_perm)
	_print(execute_result["message"])
	return execute_result

# 全局唯一的命令解析逻辑（所有命令共用）
func _parse_command(command_str: String) -> Dictionary:
	# 检查命令前缀
	if not command_str.begins_with("/"):
		return { success = false, error = "命令必须以 '/' 开头" }
	
	# 移除前缀并清理
	var content = command_str.substr(1).strip_edges()
	if content=="":
		return { success = false, error = "命令不能为空" }
	
	# 解析参数（支持引号包含空格）
	var args = []
	var current_arg = ""
	var in_quote = false
	var quote_char = ""
	
	for c in content:
		if c in ["\"", "'"]:
			if in_quote and c == quote_char:
				in_quote = false
				quote_char = ""
			elif not in_quote:
				in_quote = true
				quote_char = c
			else:
				current_arg += c
			continue
		
		if c == " " and not in_quote:
			if current_arg:
				args.append(current_arg)
				current_arg = ""
			continue
		
		current_arg += c
	
	if current_arg:
		args.append(current_arg)
	
	if in_quote:
		return { success = false, error = "未闭合的引号: {quote_char}" }
	
	return {
		success = true,
		command_head = args[0].to_lower(),
		args = args.slice(1)  # 去除命令头后的实际参数
	}

# 全局唯一的权限检查逻辑
func _check_permission(executor_perm: String, required_level: int) -> Dictionary:
	if not PERMISSION_MAP.has(executor_perm):
		return {
			success = false,
			message = "无效权限: {executor_perm}，允许值: {PERMISSION_MAP.keys()}".format({"executor_perm":executor_perm,"PERMISSION_MAP.keys()":PERMISSION_MAP.keys()})
		}
	
	var executor_level = PERMISSION_MAP[executor_perm]
	if executor_level < required_level:
		var required_str = _get_permission_str(required_level)
		return {
			success = false,
			message = "权限不足 (所需: {required_str}, 当前: {executor_perm})".format({"required_str":required_str,"executor_perm":executor_perm})
		}
	
	return { success = true }

# 辅助：权限等级转字符串
func _get_permission_str(level: int) -> String:
	for perm_str in PERMISSION_MAP:
		if PERMISSION_MAP[perm_str] == level:
			return perm_str
	return "unknown"

func _print(s:String):
	#print(str)
	$ScrollContainer/Label.text+="\n"+s


func close() -> void:
	hide()
	$ScrollContainer/Label.text=""
	
