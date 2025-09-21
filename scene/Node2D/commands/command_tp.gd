extends "res://scene/Node2D/command_base.gd"

func _init():
	command_name = "tp"
	aliases = ["teleport"]
	description = "将目标传送到指定坐标"
	usage = "/tp <目标> <x> <y>"  # 新增目标参数说明
	permission_level = 1  # 仅管理员可执行

# 实现带目标参数的tp命令功能
func execute(args: Array, _executor_perm: String) -> Dictionary:
	# 检查参数数量（目标 + x + y，共3个参数）
	if args.size() != 3:
		return {
			success = false,
			message = "用法错误: {0}".format([usage])  # 使用format格式化字符串
		}
	
	# 提取参数：目标（字符串）、x坐标、y坐标
	var target = args[0]  # 执行目标（如玩家名、对象ID等字符串标识）
	var x = args[1].to_float()
	var y = args[2].to_float()
	
	# 验证目标有效性（简单检查非空，实际项目可根据需求扩展）
	if target=="":
		return {
			success = false,
			message = "目标不能为空"
		}
	elif !Global.global_names.has(target):
		return {
			success = false,
			message = "目标不存在"
		}
	elif !Global.global_names[target] is Node2D ||Global.global_names[target].get("position")==null:
		return {
			success = false,
			message = "目标不可用"
		}
	# 验证坐标是否为有效数字
	if x == null or y == null:
		return {
			success = false,
			message = "坐标必须是数字"
		}
	
	Global.global_names[target].position=Vector2(x,y)
	return {
		success = true,
		message = "已将 {0} 传送至 ({1}, {2})".format([target, x, y])  # 包含目标的结果消息
	}
