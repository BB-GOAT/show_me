---@diagnostic disable: lowercase-global
local L = locale ~= "zh" and locale ~= "zhr" and locale ~= "zht"
version = "0.64.1"
version_compatible = "0.64.1"
name = L and "Show Me (New)" or "Show Me (中文)"
author = "冰冰羊, 傳說覺悟, Star, +Serp"

description = "当前版本: " .. version .. "\n" ..
[[
最新更新：
- 支持管理高亮显示功能应用在哪些地方

如果遇到问题请及时留言反馈
并且可以在模组设置中关闭beta版show me以(尝试)解决问题
历史更新日志请前往创意工坊页面查看

如果不显示血量，是因为与简易血条MOD一起开启了，要显示请在模组设置 → 显示血量 → 是
]]

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

dst_compatible = true          -- 兼容联机版
forge_compatible = true        -- 兼容熔炉
gorge_compatible = true        -- 兼容暴食
dont_starve_compatible = false -- 不兼容单机版

all_clients_require_mod = true
client_only_mod = false
server_only_mod = false

api_version = 10
priority = 0.00666155465 --Priority does not matter.

server_filter_tags = {
    "showme " .. version,
    "show me 中文",
    "show me new"
}

---@param label string|nil 标题
---@param client_config boolean|nil 是否仅显示在客户端设置页面上
---@return table
local function SkipSpace(label, client_config)
    return { name = "", label = label, hover = "", options = { { description = "", data = false }, }, default = false, client =
    client_config }
end


local color_options = {
    { description = "默认", data = -1, },
    { description = "0%", data = 0, },
    { description = "10%", data = 0.1, },
    { description = "20%", data = 0.2, },
    { description = "30%", data = 0.3, },
    { description = "40%", data = 0.4, },
    { description = "50%", data = 0.5, },
    { description = "60%", data = 0.6, },
    { description = "70%", data = 0.7, },
    { description = "80%", data = 0.8, },
    { description = "90%", data = 0.9, },
    { description = "100%", data = 1, },
}

-- live_config = true：支持游戏内实时修改（/showme 面板只显示带此标记的配置项）
configuration_options =
{
    {
        name = "use_beta2",
        label = "是否使用Beta版本",
        hover = "",
        options =
        {
            { description = "否", data = false, hover = "遇到了问题？请前往创意工坊反馈；若无法发送评论请换个加速器" },
            { description = "是", data = true, hover = "感谢参与测试~有BUG请及时反馈" },
        },
        default = true,
    },
    SkipSpace("信息控制"),
    {
        name = "lang",
        label = "语言 Language",
        --hover = "",
        options =
        {
            { description = "自动", data = "auto", hover = "检测语言包" },
            { description = "简体中文", data = "chs", hover = "简体中文" },
            { description = "繁体中文", data = "cht", hover = "繁体中文" },
            { description = "English", data = "en", hover = "English" },
        },
        default = "auto",
        live_config = true,
    },
    {
        name = "food_style",
        label = "食物属性样式",
        options =
        {
            { description = "默认", data = 0, hover = "默认是 \"详细\"" },
            { description = "详细", data = 1, hover = "饥饿: +12.5 / 精神: -10 / 生命: +3" },
            { description = "简洁", data = 2, hover = "+12.5 / -10 / +3" },
        },
        default = 0,
        live_config = true,
    },
    {
        name = "food_order",
        label = "食物属性格式",
        options =
        {
            { description = "默认", data = 0, hover = "默认是 \"标准\"" },
            { description = "标准", data = 1, hover = "饥饿 / 精神 / 生命" },
            { description = "自定", data = 2, hover = "生命 / 饥饿 / 精神" },
        },
        default = 0,
        live_config = true,
    },
    {
        name = "food_estimation",
        label = "预计腐烂",
        hover = "预测食物腐烂时间！",
        options =
        {
            { description = "默认", data = -1, hover = "是" },
            { description = "否", data = 0, hover = "否" },
            { description = "是", data = 1, hover = "是" },
        },
        default = -1,
        live_config = true,
    },
    {
        name = "perish_style",
        label = "食物腐烂样式",
        hover = "不新鲜于: 0.1 天( 0.3 天)",
        options =
        {
            { description = "总天数", data = 0, hover = "预计腐烂: 0.3 天" },
            { description = "阶段", data = 1, hover = "不新鲜于：0.1 天" },
            { description = "两者", data = 2, hover = "不新鲜于: 0.1 天( 0.3 天)" },
        },
        default = 2,
        live_config = true,
    },
    {
        name = "show_food_units",
        label = "显示食物单位",
        hover = "显示食物单位，比如肉类、蔬菜类、水果类！",
        options =
        {
            { description = "默认", data = -1, hover = "是" },
            { description = "否", data = 0, hover = "否" },
            { description = "是", data = 1, hover = "是" },
            { description = "禁止", data = 2, hover = "服务端将不会发送属性信息给客户端" },
        },
        default = -1,
        live_config = true,
    },
    {
        name = "show_uses",
        label = "显示工具用途",
        hover = "",
        options =
        {
            { description = "默认", data = -1, hover = "是" },
            { description = "否", data = 0, hover = "否" },
            { description = "是", data = 1, hover = "是" },
            { description = "禁止", data = 2, hover = "服务端将不会发送属性信息给客户端" },
        },
        default = -1,
        live_config = true,
    },
    {
        name = "show_nutrients",
        label = "显示肥料值",
        hover = "",
        options =
        {
            { description = "关闭", data = false, hover = "" },
            { description = "详细", data = 1, hover = "催长剂: 8 / 堆肥: 8 / 粪肥: 32" },
            { description = "简洁", data = 2, hover = "肥料: 8 / 8 / 32" },
        },
        default = 1,
        live_config = true,
    },
    {
        name = "display_hp",
        label = "显示血量",
        --hover = "",
        options =
        {
            { description = "自动", data = -1, hover = "取决于安装的模组" },
            { description = "否", data = 0, hover = "鼠标指针查看生物将不显示血量" },
            { description = "是", data = 1, hover = "显示鼠标指针下的生物血量" },
            { description = "禁止", data = 2, hover = "服务端将不会发送属性信息给客户端" },
        },
        default = 1,
        live_config = true,
    },
    {
        name = "show_fueled",
        label = "穿戴装备天数",
        hover = "",
        options =
        {
            { description = "关闭", data = false, hover = "不显示" },
            { description = "时间", data = 1, hover = "耐久: 1:19" },
            { description = "天数", data = 2, hover = "耐久: 6.8 天" },
            { description = "两者", data = 3, hover = "耐久: 3:59 ( 0.5 天 )" },
        },
        default = 3,
        live_config = true,
    },
    {
        name = "show_fuel",
        label = "物品燃料值",
        hover = "显示物品的燃料值，例如草、木材、腐烂食物等",
        options =
        {
            { description = "关闭", data = false, hover = "关闭后火堆的燃烧效率也将隐藏" },
            { description = "开启", data = true, hover = "燃料值: 0:30" },
        },
        default = true,
        live_config = true,
    },
    {
        name = "show_planar_resist",
        label = "显示位面抵抗",
        hover = "在显示工具、武器攻击附加显示位面抵抗造成的伤害",
        options =
        {
            { description = "关闭", data = false, hover = "关闭后生物上显示“拥有位面抵抗”也将隐藏" },
            { description = "开启", data = true, hover = "攻击力: 68 ( 位抗: 41.3 )" },
        },
        default = true,
        live_config = true,
    },
    {
        name = "T_crop_mode",
        label = "农作物状态显示",
        hover = "例如缺肥料、水分、家族、有杂草等，成长计时不受影响",
        options = {
            { description = "开启", data = 2 },
            { description = "耕作先驱帽/沃姆伍德", data = 1, hover = "需装备耕作先驱帽或园艺帽才能查看，沃姆伍德可直接查看" },
            { description = "关闭", data = 0 },
        },
        default = 2,
        live_config = true,
    },
    {
        name = "show_buddle_item",
        label = "显示捆绑包内容",
        options =
        {
            { description = "是", data = 1 },
            { description = "否", data = 0 },
        },
        default = 1,
        live_config = true,
    },
    {
        name = "item_info_mod",
        label = "兼容item info模组",
        hover = "如果打开，Show me将不显示与item info相同的信息",
        options =
        {
            { description = "关闭", data = 0, hover = "没开item info模组默认关闭就好" },
            { description = "开启", data = 1, hover = "** Show me将不显示与item info相同的信息 **" },
        },
        default = 0,
        live_config = true,
    },
    {
        name = "show_itemmimic",
        label = "显示拟态信息（Beta）",
        hover = "显示拟态物品的显形倒计时及暂停状态，仅Beta版生效",
        options =
        {
            { description = "关闭", data = false },
            { description = "开启", data = true, hover = "拟态显形: 0:30" },
        },
        default = true,
        live_config = true,
    },
    {
        name = "show_klaus_sack_loot",
        label = "显示赃物袋重要战利品（Beta）",
        hover = "显示赃物袋中已生成的重要战利品，仅Beta版生效。默认关闭；服务器设为禁止时，所有客户端均无法查看",
        options =
        {
            { description = "否", data = 0 },
            { description = "是", data = 1 },
            { description = "禁止", data = 2, hover = "服务端将不会发送战利品信息给客户端" },
        },
        default = 0,
        live_config = true,
    },
    SkipSpace("物品查找", true),
    {
        name = "highlight_containers",
        label = "高亮容器",
        hover = "高亮存有查找物品的容器，以及恶液储存箱中展示的料理",
        options = {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = true,
        live_config = true,
        client = true,
    },
    {
        name = "highlight_inventory",
        label = "高亮物品栏物品",
        hover = "高亮物品栏、装备栏、背包和已打开容器中的同类物品图标",
        options = {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = true,
        live_config = true,
        client = true,
    },
    {
        name = "highlight_ground",
        label = "高亮地面物品",
        hover = "高亮地面上与手持物品或配方材料同类的物品",
        options = {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = true,
        live_config = true,
        client = true,
    },
    SkipSpace("物品查找高亮颜色"),
    {
        name = "chestR",
        label = "红色值",
        hover = "拿起物品或查看配方材料时，高亮同类物品；红绿蓝全为0%或100%时无彩色效果",
        options = color_options,
        default = -1,
        live_config = true,
    },
    {
        name = "chestG",
        label = "绿色值",
        hover = "拿起物品或查看配方材料时，高亮同类物品；红绿蓝全为0%或100%时无彩色效果",
        options = color_options,
        default = -1,
        live_config = true,
    },
    {
        name = "chestB",
        label = "蓝色值",
        hover = "拿起物品或查看配方材料时，高亮同类物品；红绿蓝全为0%或100%时无彩色效果",
        options = color_options,
        default = -1,
        live_config = true,
    },
    SkipSpace("其它"),
    {
        name = "Show_range",
        label = "覆盖范围显示",
        hover = "显示避雷针、高树的覆盖范围",
        options =
        {
            { description = "关闭", data = false, hover = "" },
            { description = "开启", data = true, hover = "使用有问题就关掉吧" },
        },
        default = true,
    },
    {
        name = "Show_naughtiness",
        label = "淘气值显示",
        hover = "显示玩家的淘气值\n如果开启了【综合状态显示】模组，淘气值将显示在它的小部件里，否则在人物头顶说出淘气值",
        options = {
            { description = "关闭", data = false },
            { description = "开启", data = true, hover = "使用有问题就关掉吧" },
        },
        default = true,
    },
}