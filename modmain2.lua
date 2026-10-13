_G = GLOBAL
local _G = _G
_G.setmetatable(env, {
    __index = function(t, k)
        if not modname:find("workshop%-") then
            local info = _G.debug.getinfo(2)
            if string.find(info.source, modname) then
                print("[Show Me] 当前正在尝试从全局环境获取值", k, "调用于", info.source, info.currentline)
            end
        end
        return _G.rawget(_G, k)
    end
})

if _G.KnownModIndex:IsModEnabledAny("workshop-2189004162") then
    print("[Show Me] 检测到有笨蛋同时开启了Show Me和Insight模组，已停止加载Show Me！")
    return
end

print(modinfo.name .. " : v" .. modinfo.version .. " Beta版模式")

local function printinvalid(rpcname, player) -- 客户端发送无效RPC时的处理
    print(string.format("Invalid %s RPC from (%s) %s", rpcname, player.userid or "", player.name or ""))

    --This event is for MODs that want to handle players sending invalid rpcs
    _G.TheWorld:PushEvent("invalidrpc", { player = player, rpcname = rpcname })
end

function Import(modulename, env)
    local f = _G.kleiloadlua(modulename)
    if f and type(f) == "function" then
        _G.setfenv(f, env or _G)
        return f()
    end
end
Upvaluehelper = Import(MODROOT .. "bbgoat_upvaluehelper.lua")

-- 组件描述文件表
local showme_descriptors = _G.setmetatable({}, {
    __index = function(self, comp_name)
        local path = MODROOT .. "scripts/showme_descriptors/" .. comp_name .. ".lua"
        if not _G.kleifileexists(path) then
            _G.rawset(self, comp_name, false)
            return false
        end
        local descriptor = require("showme_descriptors/" .. comp_name)
        _G.rawset(self, comp_name, descriptor)
        return descriptor
    end,
})

local prefab_routes, tag_routes, field_routes, weapon_routes = {}, {}, {}, {} -- Prefab、Tag、字段、手持特定武器

-- 第三方模组适配接口：注册额外的组件识别，请在 AddSimPostInit 等游戏启动后的时机调用，确保本模组已加载
-- descriptor 形如 { Describe = function(component, context) ... end }，context 结构见 GetTestString 内的 context
_G.ShowMe = {
    env = env, -- 本模组环境
    AddComponentDescriptor = function(comp_name, descriptor) -- 注册组件描述
        if type(comp_name) ~= "string" or type(descriptor) ~= "table" or type(descriptor.Describe) ~= "function" then
            print("[Show Me] AddComponentDescriptor 无效注册：需要 (string 组件名, 含 Describe 函数的 table)", comp_name)
            return
        end
        if showme_descriptors[comp_name] then
            print("[Show Me] 覆盖注册组件描述：", comp_name)
        end
        _G.rawset(showme_descriptors, comp_name, descriptor)
    end,
    AddPrefabDescriptor = function(prefab_name, descriptor) -- 注册单 prefab 描述
        if type(prefab_name) ~= "string" or type(descriptor) ~= "table" or type(descriptor.Describe) ~= "function" then
            print("[Show Me] AddPrefabDescriptor 无效注册：需要 (string prefab 名, 含 Describe 函数的 table)", prefab_name)
            return
        end
        if prefab_routes[prefab_name] then
            print("[Show Me] 覆盖注册 prefab 描述：", prefab_name)
        end
        prefab_routes[prefab_name] = descriptor
    end,
}

--处理浮点数
local round2=function(num, idp)    -- num处理的目标数字, idp保留的小数位数
    return _G.tonumber(string.format("%." .. (idp or 0) .. "f", num)) -- 例如：idp传入数字为2，则连接字符串是 %.2f
end

local TheNet = _G.TheNet
local SERVER_SIDE = TheNet:GetIsServer()    --服务器
local CLIENT_SIDE = TheNet:GetIsClient() or (SERVER_SIDE and not TheNet:IsDedicated())    --本地
local show_naughtiness = GetModConfigData("Show_naughtiness") -- 显示淘气值

-- 服务器端模组配置
local server_config = {
    food_order = GetModConfigData("food_order"), -- 食物属性格式
    food_style = GetModConfigData("food_style"), -- 食物属性样式
    display_hp = GetModConfigData("display_hp"), -- 显示血量
    food_estimation = GetModConfigData("food_estimation"), -- 预计腐烂
    show_food_units = GetModConfigData("show_food_units"), -- 显示食物单位
    show_uses = GetModConfigData("show_uses"), -- 显示工具用途
    show_buddle_item = GetModConfigData("show_buddle_item"), -- 显示捆绑包内容
    item_info_mod = GetModConfigData("item_info_mod"), -- 兼容item info模组
    perish_style = GetModConfigData("perish_style"), -- 食物腐烂样式
    show_nutrients = GetModConfigData("show_nutrients"), -- 显示肥料值
    show_fuel = GetModConfigData("show_fuel"), -- 物品燃料值
    show_fueled = GetModConfigData("show_fueled"), -- 穿戴装备天数
    show_planar_resist = GetModConfigData("show_planar_resist"), -- 显示位面抵抗
}

local client_config = {
    food_order = GetModConfigData("food_order", true), -- 食物属性格式
    food_style = GetModConfigData("food_style", true), -- 食物属性样式
    display_hp = GetModConfigData("display_hp", true), -- 显示血量
    food_estimation = GetModConfigData("food_estimation", true), -- 预计腐烂
    show_food_units = GetModConfigData("show_food_units", true), -- 显示食物单位
    show_uses = GetModConfigData("show_uses", true), -- 显示工具用途
    show_buddle_item = GetModConfigData("show_buddle_item", true), -- 显示捆绑包内容
    item_info_mod = GetModConfigData("item_info_mod", true), -- 兼容item info模组
    perish_style = GetModConfigData("perish_style", true), -- 食物腐烂样式
    show_nutrients = GetModConfigData("show_nutrients", true), -- 显示肥料值
    show_fuel = GetModConfigData("show_fuel", true), -- 物品燃料值
    show_fueled = GetModConfigData("show_fueled", true), -- 穿戴装备天数
    show_planar_resist = GetModConfigData("show_planar_resist", true), -- 显示位面抵抗
}
local player_config = {}

AddModRPCHandler("ShowMe","SendConfig",function(player, config)
    if not _G.checkstring(config) then
        printinvalid("ShowMe.SendConfig", player)
        return
    end
    config = _G.DecodeAndUnzipString(config)
    if not _G.type(config) == "table" then
        printinvalid("ShowMe.SendConfig", player)
        return
    end

    player_config[player] = config
end)

-- 定义语言表(定义在模组环境以便其它模组调用)
MY_DATA = {}
MY_STRINGS = {}              -- 主字符串表
SHOWME_STRINGS = {}          -- 显示用字符串
FOOD_TAGS = {}               -- 食物标签
INTERNAL_TIMERS = {}         -- 计时器名称
INTERNAL_STAGES = {}         -- 阶段名称
STRESS_TAGS = {}             -- 作物标签
OTHER_TAGS = {}              -- 其他标签描述
OTHER_TITLES = {}            -- 其他标签描述2

-- 加载语言
for k,v in pairs(Import(MODROOT .. "showme_chs.lua")) do
    env[k] = v
end

Import(MODROOT .. "main/language.lua", env)

local renderers_data = Import(MODROOT .. "main/renderers.lua", env)
local DataTimerFn = renderers_data.DataTimerFn
local GetPrefabFancyName = renderers_data.GetPrefabFancyName

Import(MODROOT .. "main/temperature_client.lua", env) -- 温度相关

-- 描述文件工具（容器腐烂/食物增益/debuff 计时/计时器黑名单）
local buffs_data = Import(MODROOT .. "main/buffs_timers.lua", env)
local GetPerishTime = buffs_data.GetPerishTime
local KNOWN_BUFFS = buffs_data.KNOWN_BUFFS
local GetDebuffTime = buffs_data.GetDebuffTime
local IsUselessTimer = buffs_data.IsUselessTimer

-- 新版农作物信息相关函数
local tile_data = Import(MODROOT .. "main/tile_utils.lua", env)
local GetTileNutrientsAtPoint = tile_data.GetTileNutrientsAtPoint
local GetTileMoistureAtPoint = tile_data.GetTileMoistureAtPoint

-- 识别启用的其它模组
local server_mods_data = Import(MODROOT .. "main/check_mods.lua", env)
server_config.is_HealthInfo = server_mods_data.is_HealthInfo -- 简易血条
server_config.is_DisplayFoodValues = server_mods_data.is_DisplayFoodValues -- Display food values

Import(MODROOT .. "main/hint_system.lua", env) -- 信息显示
Import(MODROOT .. "main/chest_highlight.lua", env) -- 箱子高亮

-------------------------------------------------- CLIENT --------------------------------------------------

if CLIENT_SIDE then
    AddPlayersAfterInit(function(inst)
        if inst ~= _G.ThePlayer then
            return
        end
        if show_naughtiness and _G.KnownModIndex:IsModEnabledAny("workshop-376333686") then
            OnShowMeNaughtyAction() -- 初始化 综合状态显示 模组显示的淘气值默认信息
        end

        SendModRPCToServer(MOD_RPC.ShowMe.SendConfig, _G.ZipAndEncodeString(client_config)) -- 发送本地模组配置
    end)
end

-------------------------------------------------- HOST --------------------------------------------------

--只在主机上工作
if SERVER_SIDE then

local select = _G.select
local desc_table
local function cn(key, ...)
    local data = MY_DATA[key]
    if data == nil then
        return
    end
    local parts = {}
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then
            parts[#parts + 1] = tostring(v)
        end
    end
    table.insert(desc_table, data.sym .. table.concat(parts, ","))
end

-- prefab/feature 描述路由：单 prefab 文件按文件名注册，feature 文件自声明负责的 prefabs/tags
local PREFAB_DESCRIPTOR_FILES = {
    "showme_prefab_descriptors/nightmare_timepiece",
    "showme_prefab_descriptors/moon_fissure",
    "showme_prefab_descriptors/flower_evil",
    "showme_prefab_descriptors/cannonball_rock_item",
    "showme_prefab_descriptors/orchitwigs",
    "showme_prefab_descriptors/shadow_battleaxe",
}
local FEATURE_DESCRIPTOR_FILES = {
    "showme_feature_descriptors/pond_fish",
    "showme_feature_descriptors/fridge",
    "showme_feature_descriptors/slingshot_ammo",
    "showme_feature_descriptors/world_gauge",
    "showme_feature_descriptors/spice",
    "showme_feature_descriptors/hungerslow",
    "showme_feature_descriptors/winter_tree",
    "showme_feature_descriptors/boat_parts",
    "showme_feature_descriptors/halloween_potion",
    "showme_feature_descriptors/special_item_notes",
    "showme_feature_descriptors/rebirth_amulet",
    "showme_feature_descriptors/charged_days",
    "showme_feature_descriptors/special_weapon_notes",
    "showme_feature_descriptors/slingshot_upgrades",
    "showme_feature_descriptors/wx78_modules",
    "showme_feature_descriptors/battlesong_notes",
    "showme_feature_descriptors/abigail_elixir",
    "showme_feature_descriptors/food_units",
    "showme_feature_descriptors/season_rocks",
    "showme_feature_descriptors/weapon_resist",
}
for _, path in ipairs(PREFAB_DESCRIPTOR_FILES) do
    prefab_routes[string.match(path, "([^/]+)$")] = require(path)
end
for _, path in ipairs(FEATURE_DESCRIPTOR_FILES) do
    local mod = require(path)
    for name in pairs(mod.prefabs or {}) do prefab_routes[name] = mod end
    for name in pairs(mod.tags or {}) do tag_routes[name] = mod end
    for name in pairs(mod.fields or {}) do field_routes[name] = mod end
    for name in pairs(mod.viewer_holding or {}) do weapon_routes[name] = mod end
end

local descriptor_utils = {
    round2 = round2,
    KNOWN_BUFFS = KNOWN_BUFFS, -- 食物增益注册表（TUNING 键名与显示名）
    DataTimerFn = DataTimerFn,
    GetPerishTime = GetPerishTime,
    GetPrefabFancyName = GetPrefabFancyName,
    GetDebuffTime = GetDebuffTime,
    IsUselessTimer = IsUselessTimer,
    Upvaluehelper = Upvaluehelper,
    GetTileNutrientsAtPoint = GetTileNutrientsAtPoint,
    GetTileMoistureAtPoint = GetTileMoistureAtPoint,
}

--- 把条目编码进 desc_table：data_key 走 MY_DATA 协议（客户端渲染，跟随客户端语言），description 走 "@" 旁路（服务器文本）
---@param entry table 条目 { priority, data_key, params } 或 { priority, description }
local function EncodeEntry(entry)
    if entry.data_key then
        cn(entry.data_key, _G.unpack(entry.params or {})) -- cn 内部容错无效 key
    elseif entry.description then
        table.insert(desc_table, "@" .. entry.description)
    end
end

--- 主人识别
---@param item table 被查看的实体
---@return table|nil entries 协议条目数组：owner 词条；无主人时为 nil
local function GetOwnerEntries(item)
    local entries = {}
    local mine = item.components.mine
    if mine and mine.nick then
        table.insert(entries, { data_key = "owner", params = { mine.nick } })
        return entries
    end
    if item.stealable and item.stealable.owner and item.stealable.owner ~= "_?\1" then
        table.insert(entries, { data_key = "owner", params = { item.stealable.owner } })
        return entries
    elseif item.owner and type(item.owner) == "string" and string.sub(item.owner, 1, 3) ~= "KU_" then
        --不知道名字是什么，但这就是“主人”，所以需要取出来，而且这绝对不是user_id。
        table.insert(entries, { data_key = "owner", params = { item.owner } })
        return entries
    end
end

--获取物品信息
function GetTestString(item, viewer)
    desc_table = {} --旧的 desc 将被取消
    local prefab = item.prefab
    local item_descriptors = {}
    local context = {
            player = viewer, -- 获取此信息的玩家
            entity = item, -- 对应实体
            utils = descriptor_utils, -- 共享工具函数
            modenv = env, -- 模组环境
            config = {
                server = server_config, -- 服务器端配置
                client = player_config[viewer] or server_config, -- 客户端配置
            },

            -- 语言数据（相关代码待重构）
            -- str = { TODO },
    }
    local function CollectEntries(result)
        if not result then
            return
        end
        -- 单条目对象靠 data_key/description 识别，数组则直接展开
        if result[1] == nil and (result.data_key or result.description) then
            result = { result }
        end
        for _, entry in ipairs(result) do
            entry.order = #item_descriptors -- 插入序号，供同优先级排序保持来源代码顺序
            table.insert(item_descriptors, entry)
        end
    end

    -- 按组件获取信息
    for components_name, component in pairs(item.components or {}) do
        local descriptor = showme_descriptors[components_name]
        if descriptor and descriptor.Describe then
            CollectEntries(descriptor.Describe(component, context))
        end
    end

    -- 按Prefab名获取信息
    local pdesc = prefab_routes[prefab]
    if pdesc and pdesc.Describe then
        CollectEntries(pdesc.Describe(context))
    end

    -- 按Tag获取信息：反向遍历实体自身 tags 查路由表，避免全表逐键 HasTag（引擎内线性扫描物品标签）
    for _, tag_name in ipairs(item.tags or {}) do
        local tdesc = tag_routes[tag_name]
        if tdesc and tdesc.Describe then
            CollectEntries(tdesc.Describe(context))
        end
    end

    -- 按字段获取信息
    for field_name, fdesc in pairs(field_routes) do
        if item[field_name] and fdesc.Describe then
            CollectEntries(fdesc.Describe(context))
        end
    end

    -- 查看者手持武器路由（weapon_resist：冰杖/睡眠吹箭/排箫显示目标抗性）
    local viewer_inventory = viewer.components.inventory
    local viewer_weapon = viewer_inventory and viewer_inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
    if viewer_weapon then
        local wdesc = weapon_routes[viewer_weapon.prefab]
        if wdesc and wdesc.Describe then
            CollectEntries(wdesc.Describe(context))
        end
    end

    table.sort(item_descriptors, function(a, b)
        local pa, pb = a.priority or 0, b.priority or 0
        if pa ~= pb then
            return pa > pb -- 优先级高的信息放前面
        end
        return a.order < b.order -- Lua 排序不稳定，同优先级按插入顺序
    end)

    -- 条目写入 desc_table
    for _, entry in ipairs(item_descriptors) do
        EncodeEntry(entry)
    end


    -- 主人识别
    local owner_entries = GetOwnerEntries(item)
    if owner_entries then
        for _, entry in ipairs(owner_entries) do
            EncodeEntry(entry)
        end
    end

    --Mod support:
    if item.GetShowItemInfo then
        local custom1, custom2, custom3 = item:GetShowItemInfo(viewer)
        if custom1 then table.insert(desc_table, "@"..tostring(custom1)) end
        if custom2 then table.insert(desc_table, "@"..tostring(custom2)) end
        if custom3 then table.insert(desc_table, "@"..tostring(custom3)) end
    end

    return table.concat(desc_table,"\2") --an error with no info
end    -- 函数GetTestString END

-- 服务器处理end
end

-------------------------------------------------- HOST & CLIENT AGAIN --------------------------------------------------

PrefabFiles = { "showme_range" } --加载prefab文件
if GetModConfigData("Show_range") and SERVER_SIDE then --范围显示功能
    modimport("main/showme_range_indicators.lua")
end

if show_naughtiness then --显示淘气值加载的文件
    modimport("main/showme_naughtiness.lua")
end