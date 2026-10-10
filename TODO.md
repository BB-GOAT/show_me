- GetTestString函数中，使用不同的文件处理不同的组件（参考Insight模组）；GetTestString传入的item参数 使用for循环遍历它的components来匹配show me支持识别的组件
对于Tag判断，使用一个table表来for循环HasTag
对于Prefab，复用并改造已有add_entity_description 函数（也使用不同的文件保存单个Prefab的信息获取方式，参考Insight模组）
- 模组语言文件统一管理，当前使用了 MY_STRINGS、SHOWME_STRINGS、FOOD_TAGS、INTERNAL_TIMERS、INTERNAL_STAGES、STRESS_TAGS、OTHER_TAGS、OTHER_TITLES 表来放不同的字符串，后续应合并表

- 清理历史遗留无用代码（如果有）
- 函数使用LuaCATS注释法

- 游戏内实时修改模组设置，使用聊天命令 /show_me 打开模组设置面板（需要导入模组运行库中的MOD_util:AddUserCommand函数）。 面板UI参考...画成啥样好呢..（想好再说）


# 测试版结束之后的任务
- 进一步优化模组配置中的选项，不要提供“默认”选项，而是直接使用对应选项作为模组值