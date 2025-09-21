extends "res://scene/Node2D/command_base.gd"

func _init():
	command_name = "set"
	aliases = ["set_value"]
	description = "设置目标的属性值"
	usage = "/set <目标> <属性名称> <值>"  # 新增目标参数说明
	permission_level = 1  # 仅管理员可执行

# 实现带目标参数的tp命令功能
func execute(args: Array, _executor_perm: String) -> Dictionary:
	if args.size() != 3:
		return {
			success = false,
			message = "用法错误: {0}".format([usage])  # 使用format格式化字符串
		}
	var target = args[0]  # 执行目标（如玩家名、对象ID等字符串标识）
	var target_property:NodePath = args[1]
	var value = args[2]
	
	
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
	elif Global.global_names[target].get_indexed(target_property)==null:
		return {
			success = false,
			message = "属性不存在"
		}
	Global.global_names[target].set_indexed(target_property,type_convert(value,typeof(Global.global_names[target].get_indexed(target_property))))
	return {
		success = true,
		message = "已将 {0} 的 {1} 设置成 {2}".format([args[0],args[1],args[2]])
	}
