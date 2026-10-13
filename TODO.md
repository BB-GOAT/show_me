- 解决showme_descriptors键名和文件名不符的问题

- 清理历史遗留无用代码（如果有）
- 函数使用LuaCATS注释法

- 游戏内实时修改模组设置，使用聊天命令 /show_me 打开模组设置面板（需要导入模组运行库中的MOD_util:AddUserCommand函数）。 面板UI参考...画成啥样好呢..（想好再说）
实时修改模组设置需要再次修改GetModconfig逻辑
修改设置这个动作需要使用 MOD_util:ChangeModConfig 函数


# 测试版结束之后的任务
- 进一步优化模组配置中的选项，不要提供“默认”选项，而是直接使用对应选项作为模组值