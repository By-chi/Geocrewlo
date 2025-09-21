extends Object

# 命令基本信息（每个命令模块自行定义）
var command_name: String = ""  # 命令名（如"say"）
var aliases: Array[String] = []  # 别名（如["s"]）
var description: String = ""  # 描述
var usage: String = ""  # 用法说明
var permission_level: int = 0  # 所需权限等级

# 具体命令的执行逻辑（每个命令模块必须实现）
# args: 解析后的参数数组
# executor_perm: 执行者权限字符串（如"admin"）
func execute(args: Array[String], executor_perm: String) -> Dictionary:
	return {
		success = false,
		message = "命令功能未实现"
	}
