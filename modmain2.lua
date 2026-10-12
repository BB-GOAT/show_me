--源码来自Star版本，本人只略懂代码，边学边更新，如果你有对此模组兴趣欢迎继承更新。--在此非常感谢对此模组提供协助的所有人

--[[
--致模组开发者: 你的模组容器可使用以下代码，实现与ShowMe联动容器高亮。    --源开发者 Star 留
    TUNING.MONITOR_CHESTS = TUNING.MONITOR_CHESTS or {}
    TUNING.MONITOR_CHESTS.chestprefab = true    -- chestprefab 即你的容器代码名称

--多容器模式, 优先级高低判断可同时加上
--优先级高于 ShowMe
    TUNING.MONITOR_CHESTS = TUNING.MONITOR_CHESTS or {}
    for _, v in ipairs(容器列表) do
        TUNING.MONITOR_CHESTS[v] = true
    end

--优先级低于 ShowMe        --来自 风铃草 —— 穹妹
    for k, m in pairs(ModManager.mods) do
        if m and _G.rawget(m, "SHOWME_STRINGS") then
            if m.postinitfns and m.postinitfns.PrefabPostInit and m.postinitfns.PrefabPostInit.treasurechest then
                for _,v in ipairs(容器列表) do
                    m.postinitfns.PrefabPostInit[v] = m.postinitfns.PrefabPostInit.treasurechest
                end
            end
            break
        end
    end
--]]

local _G = GLOBAL

-- 给漏写GLOBAL和_G的上保险
_G.setmetatable(env, {
    __index = function(t, k)
        if not modname:find("workshop%-") then
            local info = _G.debug.getinfo(2)
            if not string.find(info.source, modname) then return end
            print("[Show Me 中文] 当前正在尝试从全局环境获取值", k, "调用于", info.source, info.currentline)
        end
        return _G.rawget(_G, k)
    end
})

if _G.KnownModIndex:IsModEnabledAny("workshop-2189004162") then
    print("Show Me (中文) 检测到有笨蛋同时开启了Show Me和Insight模组，已停止加载Show Me！")
    return
end

print(modinfo.name .. " : v" .. modinfo.version)

local function printinvalid(rpcname, player) -- 客户端发送无效RPC时的处理
    print(string.format("Invalid %s RPC from (%s) %s", rpcname, player.userid or "", player.name or ""))

    --This event is for MODs that want to handle players sending invalid rpcs
    _G.TheWorld:PushEvent("invalidrpc", { player = player, rpcname = rpcname })
end

local function Import(modulename)
    local f = _G.kleiloadlua(modulename)
    if f and type(f) == "function" then
        _G.setfenv(f, _G)
        return f()
    end
end
Upvaluehelper = Import(MODROOT .. "bbgoat_upvaluehelper.lua")

local GetGlobal=function(gname,default)
    local res=_G.rawget(_G,gname)
    if res == nil and default ~= nil then
        _G.rawset(_G,gname,default)
        return default
    end
    return res
end

--处理浮点数
local round2=function(num, idp)    -- num处理的目标数字, idp保留的小数位数
    return _G.tonumber(string.format("%." .. (idp or 0) .. "f", num)) -- 例如：idp传入数字为2，则连接字符串是 %.2f
end

-- 增加其他模组的兼容性
local mods = GetGlobal("mods",{})

local GetTime = _G.GetTime    --计时器
local TheNet = _G.TheNet
local SERVER_SIDE = TheNet:GetIsServer()    --服务器
local CLIENT_SIDE = TheNet:GetIsClient() or (SERVER_SIDE and not TheNet:IsDedicated())    --本地

local tonumber = _G.tonumber

--- 读取模组配置
--- 优先级：客户端设置 > 服务器设置；任一端取"默认"选项即表示跟随另一端。
---@param optionname string 配置项名称
---@param default any "默认"值，用于判断是否跟随另一端
---@return any value 实际生效的配置值
local function Switch(optionname, default)
    local value = GetModConfigData(optionname, true) -- 客户端设置
    if value == default then
        local server = GetModConfigData(optionname) -- 服务器设置
        if server ~= default then
            value = server
        end
    end
    return value
end

local food_order = Switch("food_order", 0) -- 食物属性格式
local food_style = Switch("food_style", 0) -- 食物属性样式
-- local display_hp = Switch("display_hp", -1) -- 显示血量
local show_food_units = Switch("show_food_units", -1) -- 显示食物单位

local chestR = Switch("chestR", -1) -- 红色值
chestR = chestR == -1 and 0.3 or chestR
local chestG = Switch("chestG", -1) -- 绿色值
chestG = chestG == -1 and 1 or chestG
local chestB = Switch("chestB", -1) -- 蓝色值
chestB = chestB == -1 and 1 or chestB

local item_info_mod = Switch("item_info_mod", 0) -- 兼容item info模组
local perish_style = Switch("perish_style", 0) -- 食物腐烂样式
local show_fuel = Switch("show_fuel", true) -- 物品燃料值
-- local show_fueled = Switch("show_fueled", 3) -- 穿戴装备天数
-- local show_planar_resist = Switch("show_planar_resist", true) -- 显示位面抵抗
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

-- 从 "?idx:" 前缀解码到 MY_STRINGS 中的索引
local function decodeDataPrefix(str)
    local _, stop_pos, id = string.find(str, "^%?(%d+):")
    return tonumber(id) or 0, stop_pos and (stop_pos + 1) or 2
end

local function encodeDataPrefix(idx)
    return "?" .. tostring(idx) .. ":"
end

-- 语言调用
local MY_DATA_BY_ID = {}
do
    local i = 1
    for k,str in _G.orderedPairs(MY_STRINGS) do
        MY_DATA[k] = {
            desc = str,    -- MY_DATA.armor.desc 则显示 防御：
            id = i,    -- 索引ID
            sym = encodeDataPrefix(i), -- 编码后的前缀（如 "?1:"）
            fn = nil, --默认值: desc .. " " .. param1，可覆盖例如：MY_DATA.buff.fn
            percent = nil, --在数字末尾添加“%”，例如：MY_DATA.sanity_character.percent = true
        }
        MY_DATA_BY_ID[i] = k
        i = i + 1
    end
end

do
    local support_languages = {
        -- zh = "chs", --Chinese for Steam
        -- zhr = "chs", --Chinese for WeGame
        -- ch = "chs", --Chinese mod
        -- chs = "chs", --Chinese mod
        -- sc = "chs", --simple Chinese
        -- chinese = "chs", --Chinese mod
        zht = "cht", --traditional Chinese for Steam
        tc = "cht", --traditional Chinese
        cht = "cht", --Chinese mod
        en = "en", --English
    }

    -- 链接字符串表
    local function LinkTables(tbl, fallback)
        GLOBAL.setmetatable(tbl, {
            __index = fallback,  -- 查找 tbl 中不存在的键时回退到 fallback
        })

        -- 对嵌套表格也进行同样的操作
        for key, value in pairs(tbl) do
            if type(value) == "table" then
                LinkTables(value, fallback[key])
            end
        end
    end

    local lang = Switch("lang", "auto")
    print("Detected language for ShowMe: ", lang, lang == "auto" and _G.LanguageTranslator.defaultlang or "")

    if lang == "auto" then
        lang = _G.LanguageTranslator.defaultlang or "en"
    end
    lang = lang:lower()

    if support_languages[lang] then
        local lang_data = Import(MODROOT .. "showme_" .. support_languages[lang] .. ".lua") -- 加载语言
        for k,v in pairs(lang_data) do
            if k ~= "MY_STRINGS" then
                LinkTables(v, env[k])
                env[k] = v
            else
                for key, value in pairs(v) do
                    if MY_DATA[key] then
                        MY_DATA[key].desc = value
                    end
                end
            end
        end
    end
end

local o_t = OTHER_TITLES
local function DefaultDisplayFn(arr) --输入有一个特殊的结构：{ data, param }。 data 是对 MY_DATA 元素的引用，param 是对数组 p 的引用。
    if arr.data == nil then
        return arr.param_str --以来自服务器的形式显示字符串（没有第一个字符）。 对“@”符号的适配
    end
    if arr.data.sign ~= nil and (tonumber(arr.param[1]) or -1) >= 0 then
        arr.param[1] = "+" .. tostring(arr.param[1])
    end
    local s = arr.data.desc .. " " .. tostring(arr.param[1])
    if arr.data.percent ~= nil then
        s = s .. "%"
    end
    return s
end

local function DefaultFraction(arr) --典型输出：“名称：cur / max”
    local cur,mx = arr.param[1], arr.param[2]
    return arr.data.desc .. " " .. cur .. " / " .. mx
end

--农作物
MY_DATA.nutrient.fn = function(arr)
    return string.format(o_t.nutrient, arr.param[1] or 0, arr.param[2] or 0, arr.param[3] or 0, arr.param[4] or 0)
end

local function slice(tbl, start)
    local result = {}
    for i = start, #tbl do
        result[#result + 1] = tbl[i]
    end
    return result
end

MY_DATA.stress_tag.fn = function(arr)
    local subArr = slice(arr.param, 2)
    local arr1 = {}
    for key, value in pairs(subArr) do
        table.insert(arr1, STRESS_TAGS[value] or "未知")
    end
    return string.format(SHOWME_STRINGS.pressure, arr.param[1]) .. "\n" .. table.concat(arr1, ", ")
end


--创建其他tag
MY_DATA.other_tag.fn = function(arr)
    local key = arr.param[1]
    if OTHER_TAGS[key] then
        return OTHER_TAGS[key]
    end
end

MY_DATA.sanity.fn = function(arr)
    local str = DefaultDisplayFn(arr)
    if arr.param[2] == '1' then -- on pick up
        return str .. SHOWME_STRINGS.onpickup --花朵采摘
    end
    return str
end
--BUFF
MY_DATA.buff.fn = function(arr)
    local name = SHOWME_STRINGS[arr.param[1]] or arr.param[1]
    local bonus = tonumber(arr.param[3])
    local days = arr.param[2]
    if bonus then
        bonus = round2((bonus - 1) * 100)
        if bonus >= 0 then
            bonus = "+" .. tostring(bonus)
        end
    end
    arr.param[1] = name
    arr.param[3] = bonus
    if bonus then
        return name .. ' ' .. tostring(bonus) .. '%'
            .. (days ~= '0' and SHOWME_STRINGS.chixu .. tostring(days) .. ' ' .. SHOWME_STRINGS.days or '')
    end
    return name .. SHOWME_STRINGS.chixu .. tostring(days) .. ' ' .. SHOWME_STRINGS.days
end
--生物巢
MY_DATA.children.fn = function(arr)
    local inside = arr.param[1]
    local maximum = arr.param[2]
    local outside = arr.param[3]
    if outside then
        return arr.data.desc .. "(" .. inside .. "+" .. outside .. ") / " .. maximum
    else
        return arr.data.desc .. inside .. " / " .. maximum
    end
end
--BOSS对玩家的伤害信息
MY_DATA.strength.fn = function(arr)
    if not arr.param[2] then
        return DefaultDisplayFn(arr)
    end
    return arr.data.desc .. " " .. tostring(arr.param[1]) .. " ( " .. SHOWME_STRINGS.pvp .. round2(tostring(arr.param[2]) * tostring(arr.param[1]) * 0.01 + tostring(arr.param[1]),1).." )" --BOSS对玩家的伤害值，直接显示常值好了
end

MY_DATA.hp.fn = function(arr)
    local cur,mx = arr.param[1], arr.param[2]
    return cur .. " / " .. mx
end
MY_DATA.owner.fn = function(arr)
    return arr.data.desc .. " " .. arr.param_str  --如果名称中有逗号，将忽略逗号。
end
MY_DATA.loyal.fn = function(arr)
    if (tonumber(arr.param[1]) or 0) > 9000 then --忠诚大于9000
        return arr.data.desc .. " " .. SHOWME_STRINGS.loyal
    end
    return DefaultDisplayFn(arr)
end

MY_DATA.water.fn = DefaultFraction
MY_DATA.water_poisoned.fn = function(arr)
    return arr.data.desc
end

local function DataTimerFn(seconds)
    if (not seconds) then
        return 'error'
    end
    local total = tonumber(seconds)
    if not total then
        return "???"
    end
    total = math.abs(total)
    local hours = math.floor(total / 3600)
    local mins = math.floor((total % 3600) / 60)
    local secs = math.floor(total % 60)
    return
        (hours > 0 and (hours .. ':'
            .. (mins > 9 and mins or ('0' .. mins)) .. ':'
            .. (secs > 9 and secs or ('0' .. secs))
        ) or ( mins .. ':'
            .. (secs > 9 and secs or ('0' .. secs))
        ))
end
--植物生长时间
MY_DATA.timer.fn = function(arr)
    local name = arr.param[2]
    local s;
    if INTERNAL_TIMERS[name] and INTERNAL_TIMERS[name] ~= "" then
        s = INTERNAL_TIMERS[name] .. ': '
    else
        s = arr.data.desc .. (name and (' "'..name..'": ') or ': ')
    end
    return s .. DataTimerFn(arr.param[1])
        .. (arr.param[3] == '1' and ' ('..SHOWME_STRINGS.paused..')' --作物生长状态
            or (arr.param[3] == '2' and ' ('..SHOWME_STRINGS.stopped..')' or ''))
end
--例如：蜂箱，蘑菇农场
MY_DATA.harvest.fn = function(arr)
    local maxproduce = arr.param[3]
    if not maxproduce then
        return DefaultDisplayFn(arr)
    end
    local name = arr.param[1]
    local produce = arr.param[2]
    local count_str = produce .. '/' .. maxproduce
    local tm = arr.param[4]
    local paused = (arr.param[5] == '0')
    if (tm) then
        return count_str .. ', +1 ' .. (_G.STRINGS.NAMES[name:upper()] or name) .. SHOWME_STRINGS._in .. DataTimerFn(tm)
            .. (paused and '('..SHOWME_STRINGS.paused..')' or '')
    else
        return count_str .. ' ' .. (_G.STRINGS.NAMES[name:upper()] or name)
    end
end


MY_DATA.durability.fn = DefaultFraction
--武器上显示的攻击BUFF
MY_DATA.dmg.fn = function(arr)
    local str = DefaultDisplayFn(arr)
    if arr.param[2] then --buff 时间
        str = str .. ' ↑ ' .. DataTimerFn(arr.param[2])
    end
    return str
end
MY_DATA.armor.fn = MY_DATA.dmg.fn
MY_DATA.effectiveness.fn = MY_DATA.dmg.fn

-- Temperature: +10, 0:05
MY_DATA.food_temperature.fn = function(arr) -- { temperature, time }
    local temperature_str = arr.param[1]
    if tonumber(temperature_str) > 0 then
        temperature_str = '+' .. temperature_str
    end
    local time_str = DataTimerFn(arr.param[2])
    return SHOWME_STRINGS.temperature .. ': ' .. temperature_str .. ', ' .. time_str
end


MY_DATA.sanity_character.percent = true
MY_DATA.sanity.sign = true
MY_DATA.sanityaura.sign = true
MY_DATA.dmg_character.percent = true
MY_DATA.dmg_character.sign = true
MY_DATA.speed.percent = true
MY_DATA.speed.sign = true
MY_DATA.temperature.sign = true
MY_DATA.armor.percent = true
MY_DATA.armor_character.percent = true
MY_DATA.armor_character.sign = true
MY_DATA.waterproof.percent = true
MY_DATA.dmg_bonus.sign = true

MY_DATA.watergainspeed.sign = true
MY_DATA.sip.sign = true

MY_DATA.trade_gold.sign = true
MY_DATA.trade_rock.sign = true

MY_DATA.effectiveness.percent = true
MY_DATA.force.percent = true
MY_DATA.repairer.sign = true

local AOS_Temperature_fn --将游戏中的温度单位转换为摄氏度、华氏度。
local is_Fahrenheit = false
local function ConvertTemperature(val)
    if not val then
        return "???"
    end
    if is_Fahrenheit then
        return math.floor(1.8*(val) + 32.5).."\176F" -- \176 是 ° 的符号，来自【综合状态显示】模组
    else
        return math.floor(val*0.5 + 0.5) .. "\176C"
    end
end

local function MainConvertTemperature(val)
    return AOS_Temperature_fn and AOS_Temperature_fn(tonumber(val)) or ConvertTemperature(tonumber(val))
end

MY_DATA.temperature.sign = true
MY_DATA.temperature.fn = function(arr)
    arr.param[1] = MainConvertTemperature(arr.param[1])
    return DefaultDisplayFn(arr)
end

--从STRINGS.NAMES获取物品名称
local showme_item_names = {}
local function GetPrefabFancyName(prefab)
    local product = tostring(prefab or "nil")
    local name = _G.STRINGS.NAMES[string.upper(product)] or showme_item_names[string.upper(product)]
    if name == nil then    --如果NAMES获取不到就获取一个prefab的对象, 为解决部分在容器里不显示中文的问题
        local item = _G.SpawnPrefab(prefab)
        if item then
            if item.GetDisplayName then
                name = string.gsub(item:GetDisplayName(), "\n", "")    --通过对象获取 GetDisplayName
                if name then
                    showme_item_names[string.upper(product)] = name -- 保存到局部变量里
                end
            end
            item:Remove()
            item = nil
        end
    end
    return name or product
end
--烹饪锅
MY_DATA.cookpot.fn = function(arr)
    return arr.data.desc .. " " .. GetPrefabFancyName(arr.param[1])
end
--食物信息
MY_DATA.food.fn = function(arr)
    local hg,sn,hp = arr.param[1],arr.param[2],arr.param[3]
    if food_order <= 1 then
        if food_style <= 1 then
            return MY_DATA.hunger.desc .. " "..hg.." / "..MY_DATA.sanity.desc.." "..sn.." / "..MY_DATA.health.desc.." "..hp
        else
            return hg.." / "..sn.." / "..hp
        end
    else
        if food_style <= 1 then
            return MY_DATA.health.desc.." "..hp.." / "..MY_DATA.hunger.desc.." "..hg.." / "..MY_DATA.sanity.desc.." "..sn
        else
            return hp.." / "..hg.." / "..sn
        end
    end
end
--食物填充单位
MY_DATA.units_of.fn = function(arr)
    local s = FOOD_TAGS[arr.param[2]]
    s = s ~= "" and s or arr.param[2] --If translation exists.
    if arr.param[1] == "1" then
        return SHOWME_STRINGS.units_1 .. s
    else
        return arr.param[1] .. SHOWME_STRINGS.units_many .. s
    end
end
--工具可用度
MY_DATA.uses_of.fn = function(arr)
    if arr.param[1] == "1" then
        return SHOWME_STRINGS.uses_1 .. arr.param[2]
    else
        return arr.param[1] .. SHOWME_STRINGS.uses_many .. arr.param[2]
    end
end
--距离腐烂
MY_DATA.perish.fn = function(arr)
    local days = SHOWME_STRINGS.days
    local t1 = arr.param[1]           -- 距下一阶段
    local stage = arr.param[2]        -- "stale" | "spoiled" | "" 
    local t2 = arr.param[3] or t1     -- 距真正腐烂（服务端新增的第3参数）
	local desc = arr.data.desc

    -- 非食物（如 will_die/grow_in 等复用本 fn 的调用），保持原有阶段输出
    if arr.data ~= MY_DATA.perish then
        if stage == "stale" then
            desc = SHOWME_STRINGS.stale_in
        elseif stage == "spoiled" then
            desc = SHOWME_STRINGS.spoiled_in
        end
        return desc .. t1 .. days
    end

    if perish_style == 1 then	-- 阶段：距离不新鲜 / 变质 / 腐烂
        if stage == "stale" then
            desc = SHOWME_STRINGS.stale_in
        elseif stage == "spoiled" then
            desc = SHOWME_STRINGS.spoiled_in
        end
        return desc .. t1 .. days

    elseif perish_style == 2 then	-- 两者
        if stage ~= "stale" and stage ~= "spoiled" then	-- 已经变质：没有下一阶段可报，只显示腐烂
            return desc .. t1 .. days
        end
        local stage_desc = (stage == "stale") and SHOWME_STRINGS.stale_in or SHOWME_STRINGS.spoiled_in
        return stage_desc .. t1 .. days .. "( " .. t2 .. days .. " )"

    else	-- 默认：距离腐烂
        return desc .. t2 .. days
    end
end
--将生物的距离腐烂定义为距离死亡
local PerishFunction = function(arr)
    return MY_DATA.perish.fn(arr) --Redirect to perish function with another description - "Will die in..."
end

MY_DATA.will_die.fn = PerishFunction
MY_DATA.will_dry.fn = PerishFunction --Здесь тоже просто делаем ссылку.
MY_DATA.grow_in.fn = PerishFunction
MY_DATA.just_time.fn = PerishFunction
--鱼桶返鲜
MY_DATA.fresh.fn = function(arr)
    if (arr.param[1] == "0" or arr.param[1] == "-0") then
        return SHOWME_STRINGS.already_fresh;
    elseif (arr.param[1] and arr.param[1]:sub(1,1) == '-') then
        return SHOWME_STRINGS.cheat_fresh;
    end
    return PerishFunction(arr);
end
--冰箱保鲜程度
MY_DATA.frigde.fn = function(arr)
    local v = tonumber(arr.param[1]);
    if v == 0 then
        return SHOWME_STRINGS.norot; --hard coded
    elseif v == 1 then
        return 'Broken';
    elseif v > 1 then
        return SHOWME_STRINGS.hot ..round2((v-1)*100)..'%';
    elseif v > 0.5 then
        return SHOWME_STRINGS.weak ..round2((v-0.5)*200)..'%';
    elseif v > 0 then
        return SHOWME_STRINGS.cold ..round2(1/(v)+1)..'x'; --少了数，应该再+1
    elseif v < 0 then
        return SHOWME_STRINGS.refresh ..round2((-v)*1)..'%';
    end
    return 'Paradox '..tostring(v); --error
end

local CONST_COUNT = { ['1'] = '(1)', ['2'] = '(2)', ['3'] = '(3)', ['4'] = '(4)', ['5'] = '(5)', ['6'] = '(6)', ['7'] = '(7)',
     ['8'] = '(8)', ['9'] = '(9)', ['10'] = '(10)', ['11'] = '(11)', ['12'] = '(12)', ['13'] = '(13)', ['14'] = '(14)',
     ['15'] = '(15)', ['16'] = '(16)', ['17'] = '(17)', ['18'] = '(18)', ['19'] = '(19)', ['20'] = '(20)',
     ['21'] = '(21)', ['22'] = '(22)', ['23'] = '(23)', ['24'] = '(24)', ['25'] = '(25)',
     ['26'] = '(26)', ['27'] = '(27)', ['28'] = '(28)', ['29'] = '(29)', ['30'] = '(30)',
     ['31'] = '(31)', ['32'] = '(32)', ['33'] = '(33)', ['34'] = '(34)', ['35'] = '(35)',
     ['36'] = '(36)', ['37'] = '(37)', ['38'] = '(38)', ['39'] = '(39)', ['40'] = '(40)',
     ['0'] = '', --如果没有可堆叠的组件，那么根本不会显示数量。
}

--包裹生物食物信息
--param[1] - 产品
--param[2] - 剩余天数或为零
MY_DATA.perish_product.fn = function(arr)
    local name = GetPrefabFancyName(arr.param[1]) .. (
        CONST_COUNT[arr.param[2]] or ('(' .. tostring(arr.param[2]) .. ')')
    )
    if not arr.param[3] then --未指定时间
        return name
    end
    arr.param[1] = arr.param[3] --dirty hack!!! Preparing for using in PerishFunction
    --arr.param[2] = nil --need not
    return name.. ":" .. PerishFunction(arr) -- desc == ""
end

MY_DATA.heal.sign = true
MY_DATA.fuel.percent = true
MY_DATA.obedience.percent = true
MY_DATA.domest.percent = true
--MY_DATA.fuel.percent = true
--MY_DATA.fuel.percent = true
--MY_DATA.fuel.percent = true
--物品：百分比
MY_DATA.crop.fn = function(arr) -- Product: percent
    return GetPrefabFancyName(arr.param[1]) .. ": " .. tostring(arr.param[2]) .. "%"
end
--用于石果、大理石
MY_DATA.growable.fn = function(arr) -- stage num or name, time, paused (1/0)
    arr=arr.param;
    local stagename = tonumber(arr[1]) and (SHOWME_STRINGS.jieduan .. arr[1]) or arr[1];  --大理石生长
    if INTERNAL_STAGES[stagename] and INTERNAL_STAGES[stagename] ~= "" then
        stagename = INTERNAL_STAGES[stagename]
    end
    local time_str = DataTimerFn(arr[2]);
    return stagename .. (arr[3] == '1' and ' ('..SHOWME_STRINGS.paused..') : ' or ' : ') .. time_str;
end
--厨师食物记忆
MY_DATA.food_memory.fn = function(arr)
    local perc = tonumber(arr.param[1])
    perc = perc and (round2(perc * 100) .. '%') or tostring(arr.param[1])
    return arr.data.desc .. '(' .. perc .. '): ' .. DataTimerFn(arr.param[2])
end

if show_food_units == 0 or show_food_units == 2 then
    MY_DATA.units_of.hidden = true
end

--尝试检测客户端模组并通过 RPC 发送它们
AddModRPCHandler("ShowMe","AOS",function(inst)
    --调用此函数将禁用此玩家的提示。
    inst.has_AlwaysOnStatus = true
end)

--local AOS_Temperature_fn --客户端转换游戏温度的功能。 

--We climb into the client interface in order to reduce the displayed temperature
if CLIENT_SIDE then
    --We make the most correct function in the world "AddPlayersPostInit"
    --GetGlobal("mods",{})
    --if not _G.rawget(_G,"mods") then _G.rawset(_G,"mods",{}) end
    if not mods.player_preinit_fns then
        mods.player_preinit_fns={}
        --Dirty hack
        local old_MakePlayerCharacter = require("prefabs/player_common")
        local function new_MakePlayerCharacter(...)
            local inst=old_MakePlayerCharacter(...)
            for _,v in ipairs(mods.player_preinit_fns) do
                v(inst)
            end
            return inst
        end
        _G.package.loaded["prefabs/player_common"] = new_MakePlayerCharacter
    end

    local function AddPlayersPreInit(fn)
        table.insert(mods.player_preinit_fns,fn)
    end

    local player_postinit_fns = {}
    local function AddPlayersPostInit(fn) -- <<<--------- Вот она!
        table.insert(player_postinit_fns,fn)
    end

    local done_players = {}
    AddPlayersPreInit(function(inst)
        local s = inst.prefab or inst.name
        if not done_players[s] then
            done_players[s] = true
            AddPrefabPostInit(s,function(inst)
                for _,v in ipairs(player_postinit_fns) do
                    v(inst)
                end
            end)
        end
    end)

    local player_afterinit_fns = {}
    function AddPlayersAfterInit(fn)
        table.insert(player_afterinit_fns,fn)
    end
    AddPlayersPostInit(function(inst)
        if #player_afterinit_fns > 0 then
            inst:DoTaskInTime(0,function(inst)
                for i=1,#player_afterinit_fns do
                    player_afterinit_fns[i](inst)
                end
            end)
        end
    end)

    --А вот и не угадали. Не трогаем интерфейс. Вместо этого определяем настройки и лишь в случае их отсутствия трогаем интерфейс.

    --温度检查。 反向格式和转换为通用摄氏度。
    local tonumber = _G.tonumber
    local function FixTemperature(s)
        if type(s) ~= "string" then
            return s --Вообще не строка. Что за?
        end
        --На конце может быть один из конкретных вариантов строки.
        local sep = s:find("\176",1,true)
        if not sep then
            return s
        end
        local pre, pst = tonumber(s:sub(1,sep-1)), s:sub(sep+1)
        if not pre then
            return s --字符串的第一部分不是数字。
        end
        if pst == "C" then
            return s --这是摄氏温度，无需转换。
        elseif pst == "F" then
            --华氏温度
            is_Fahrenheit = true
            return s
        else
            --我们假设温度以游戏单位为单位，我们用摄氏度来解决这个问题。
            return ConvertTemperature(pre) --TODO：减少中有一个小错误。 在 5.1 的温度下，数字 2 将出现，尽管它应该是 3。
        end
    end

    local AOS_UNITS, AOS_UNIT

    --Interface patching feature on the client. Triggered for all players upon spawn.
    local function FixClient(inst)
        if inst ~= _G.ThePlayer then
            return
        end

        local status = inst.HUD and inst.HUD.controls and inst.HUD.controls.status
        if not status then
            print("ERROR SHOW_ME: Can't fix client side status!")
            return
        end
        local AOS
        AOS_UNITS = TUNING.COMBINED_STATUS_UNITS
        AOS_UNIT = TUNING.COMBINED_STATUS_UNIT
        if (AOS_UNITS and AOS_UNIT and AOS_UNITS[AOS_UNIT]) then
            AOS = true
            AOS_Temperature_fn = AOS_UNITS[AOS_UNIT]
        else --旧版本的 AOS
            if status.temperature then
                AOS = true
                local old_SetString = status.temperature.num.SetString
                status.temperature.num.SetString = function(self,s,...)
                    return old_SetString(self,FixTemperature(s),...)
                end
            end
            if status.worldtemp then
                AOS = true
                local old_SetString = status.worldtemp.num.SetString
                status.worldtemp.num.SetString = function(self,s,...)
                    return old_SetString(self,FixTemperature(s),...)
                end
            end
        end
        if AOS then
            SendModRPCToServer(MOD_RPC.ShowMe.AOS)
        end

        if show_naughtiness and _G.KnownModIndex:IsModEnabledAny("workshop-376333686") then
            OnShowMeNaughtyAction() -- 初始化 综合状态显示 模组显示的淘气值默认信息
        end

        SendModRPCToServer(MOD_RPC.ShowMe.SendConfig, _G.ZipAndEncodeString(client_config))
    end
    AddPlayersAfterInit(FixClient)
end

-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------- HOST -----------------------------------------------------------------
--只在主机上工作。
if TheNet and TheNet:GetIsServer() then

--检测启用的模组
local mod_names     --названия всех модов (чтобы не дергать джвижок)
local mod_names_nover --названия модов с обрезанной версией (если смысловая часть достаточно длинная)
mod_names = {}
mod_names_nover = {}
local function GetAllModNames()
    if not (_G.KnownModIndex and _G.KnownModIndex.savedata and _G.KnownModIndex.savedata.known_mods
        and _G.ModManager and _G.ModManager.enabledmods)
    then
        return
    end
    local folders = {} --ассоциативный массив включенных модов (по папкам)
    for _,v in ipairs(_G.ModManager.enabledmods) do
        folders[v]=true
    end
    for folder, mod in pairs(_G.KnownModIndex.savedata.known_mods) do
        local name = mod.modinfo.name
        if name then
            mod_names[name]=folders[folder] and true or false
            --print("NEW_MOD: "..name.." "..tostring(mod_names[name]))
            local s=string.match(name,"^(.-)([0-9%._ ]+)$")
            if s then
                mod_names_nover[s]=name --обрезаем номер версии с конца
                --вместо true сохраняем полное имя мода (чтобы идентифицировать его в системе)
            else
                mod_names_nover[name]=name
            end
        end
    end
end
GetAllModNames()
mods.mod_names = mod_names
mods.mod_names_nover = mod_names_nover

local function SearchForModsByName()
    mods.active_mods_by_name = {}
    if not (_G.KnownModIndex and _G.KnownModIndex.savedata and _G.KnownModIndex.savedata.known_mods) then
        print("ERROR COMMON LIB: Can't find KnownModIndex!")
        return
    end
    for name,mod in pairs(_G.KnownModIndex.savedata.known_mods) do
        if (mod.enabled or mod.temp_enabled or _G.KnownModIndex:IsModForceEnabled(name)) --Мод активен
            and not mod.temp_disabled --И не отключен
        then
            local real_name = mod.modinfo.name
            if real_name == nil then
                print("SHOW_ME ERROR: real_name of a mod is nil,",tostring(name))
                --TODO: error if TUNING.STAR_DEBUG 
            else
                mods.active_mods_by_name[real_name] = true
            end
        end
    end
end
SearchForModsByName()

local is_HealthInfo = nil --检查服务器血量显示模组
for name in pairs(mods.active_mods_by_name) do
    if name:find("简易血条",1,true) or name:find("Health Bar",1,true) then
        is_HealthInfo = true
        break
    end
end
server_config.is_HealthInfo = is_HealthInfo

local is_DisplayFoodValues = mods.active_mods_by_name["Display food values"]
server_config.is_DisplayFoodValues = is_DisplayFoodValues -- 服务器检测结果：供 edible 描述文件判断是否隐藏食物属性

local cooking = require("cooking")

local ing = cooking.ingredients

local world_state
AddPrefabPostInit("world",function(inst)
    world_state = inst.state
end)

--容器
local function GetPerishTime(inst, c)
    local modifier = 1
    local owner = c.inventoryitem and c.inventoryitem.owner or nil
    if not owner and c.occupier then
        owner = c.occupier:GetOwner() --Для птичек?
    end

    if owner then
        if owner.components.preserver ~= nil then
            modifier = owner.components.preserver:GetPerishRateMultiplier(inst) or modifier -- 传入被检查物品, 使容器能够正确显示保鲜度
        elseif owner:HasTag("fridge") then
            if inst:HasTag("frozen") and not owner:HasTag("nocool") and not owner:HasTag("lowcool") then
                modifier = TUNING.PERISH_COLD_FROZEN_MULT
            else
                modifier = TUNING.PERISH_FRIDGE_MULT
            end
        elseif owner:HasTag("foodpreserver") then
            modifier = TUNING.PERISH_FOOD_PRESERVER_MULT
        elseif owner:HasTag("cage") and inst:HasTag("small_livestock") then
            modifier = TUNING.PERISH_CAGE_MULT
        end

        if owner:HasTag("spoiler") then
            modifier = modifier * TUNING.PERISH_GROUND_MULT
        end
    else
        modifier = TUNING.PERISH_GROUND_MULT
    end

    if inst:GetIsWet() then
        modifier = modifier * TUNING.PERISH_WET_MULT
    end

    if world_state.temperature < 0 then
        if inst:HasTag("frozen") and not c.perishable.frozenfiremult then
            modifier = TUNING.PERISH_COLD_FROZEN_MULT
        else
            modifier = modifier * TUNING.PERISH_WINTER_MULT
        end
    end

    if c.perishable.frozenfiremult then
        modifier = modifier * TUNING.PERISH_FROZEN_FIRE_MULT
    end

    if world_state.temperature > TUNING.OVERHEAT_TEMP then
        modifier = modifier * TUNING.PERISH_SUMMER_MULT
    end

    if c.perishable.localPerishMultiplyer then
        modifier = modifier * c.perishable.localPerishMultiplyer
    end

    modifier = modifier * TUNING.PERISH_GLOBAL_MULT

    local old_val = c.perishable.perishremainingtime
    if old_val ~= nil then
        local delta = old_val / modifier
        if delta ~= nil then --and delta >= 0 then
            if delta < 0 and c.perishable.perishtime and c.perishable.perishtime > 0 then --modifier < 0 !
                return delta, (c.perishable.perishremainingtime - c.perishable.perishtime) / modifier, modifier;
            end
            return delta, nil, modifier
        end
    end
end

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

--食物BUFF 信息显示
--local test_buff_seen = {buff_playerabsorption=1, buff_workeffectiveness=1, buff_attack=1}
local KNOWN_BUFFS = {
    buff_workeffectiveness = {
        name = SHOWME_STRINGS.xiaolv,
        duration = 'BUFF_WORKEFFECTIVENESS_DURATION',
        power = 'BUFF_WORKEFFECTIVENESS_MODIFIER',
    },
    buff_playerabsorption = {
        name = SHOWME_STRINGS.fangyu,
        duration = 'BUFF_PLAYERABSORPTION_DURATION',
        power = 'BUFF_PLAYERABSORPTION_MODIFIER',
        shift = true,
    },
    buff_attack = {
        name = SHOWME_STRINGS.gongji,
        duration = 'BUFF_ATTACK_DURATION',
        power = 'BUFF_ATTACK_MULTIPLIER',
    },
    buff_moistureimmunity = {
        name = SHOWME_STRINGS.fangshui,
        duration = 'BUFF_MOISTUREIMMUNITY_DURATION',
        --power = 'BUFF_WORKEFFECTIVENESS_MODIFIER',
    },
    buff_electricattack = {
        name = SHOWME_STRINGS.gandian,
        duration = 'BUFF_ELECTRICATTACK_DURATION',
        --power = 'BUFF_WORKEFFECTIVENESS_MODIFIER',
    },
    wormlight_light_greater = {
        name = SHOWME_STRINGS.faguang,
        duration = function()
            return TUNING.WORMLIGHT_DURATION and TUNING.WORMLIGHT_DURATION * 4 -- multiplier is hardcoded, sadly. See wormlight.lua
        end,
        --power = 'BUFF_WORKEFFECTIVENESS_MODIFIER',
    },
    healthregenbuff = {
        name = SHOWME_STRINGS.huifu,
        duration = 'JELLYBEAN_DURATION',
        --power = 'BUFF_WORKEFFECTIVENESS_MODIFIER',
    },
}
--debuff时间
local function GetDebuffTime(viewer, buff_name)
    local d = viewer.components.debuffable
    if not d then
        return
    end
    for k,v in pairs(d.debuffs) do
        if k == buff_name then
            local timer = v.inst.components.timer
            if timer and timer.GetTimeLeft then
                local tm = timer:GetTimeLeft('buffover')
                return tm
            end
            break
        end
    end
end

--在船上显示木材、树枝修理度
local function AddBoatStatus(viewer)
    if viewer.boat_status_task then
        viewer.boat_status_task:Cancel()
    end
    viewer.boat_status_task = viewer:DoTaskInTime(120,function(inst)
        inst.boat_status_task = nil
    end)
end

local USELESS_TIMERS = {	-- 生物巢定时器屏蔽
    --default for all prefabs
    toadstool = { channeltick = true },
    all = { ChildSpawner_RegenPeriod = true, ChildSpawner_SpawnPeriod = true, dominant = true },	-- 下次刷新, 下次放出
	wobybig = { decay = true },	-- 沃比的消失屏蔽掉
    wobysmall = { decay = true },
    hermitcrab = { speak_time = true, complain_time = true, salad = true },
}

local function IsUselessTimer(prefab,name)
    local data = USELESS_TIMERS[prefab]
    if not data then
        return USELESS_TIMERS.all[name]
    end
    if data == name then
        return true
    end
    if type(data) == 'table' and data[name] then
        return true
    end
    return USELESS_TIMERS.all[name]
end

--农作物信息
local OldGetTileDataAtPoint = nil
local _nutrientgrid = nil
local _moisturegrid = nil
local _drinkersgrid = nil
local _overlaygrid = nil

local farming_manager
AddComponentPostInit("farming_manager", function(self)
    if not (_G.TheWorld and _G.TheWorld.ismastersim) then return end
    farming_manager = self
    self.inst:ListenForEvent("worldmapsetsize", function(...)
        _nutrientgrid = Upvaluehelper.GetUpvalue(self.OnSave, "_nutrientgrid")
        _moisturegrid = Upvaluehelper.GetUpvalue(self.OnSave, "_moisturegrid")
        _drinkersgrid = Upvaluehelper.GetUpvalue(self.GetDebugString, "_drinkersgrid")
        _overlaygrid = Upvaluehelper.GetUpvalue(self.GetDebugString, "_overlaygrid")
    end)
end)

--- Get tile nutrients at point
local function GetTileNutrientsAtPoint(x, y, z)
    local nutrients
    local tx, ty = _G.TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
    nutrients = {farming_manager:GetTileNutrients(tx, ty)}
    return {
        formula = nutrients[1],
        compost = nutrients[2],
        manure = nutrients[3]
    }
end

local function GetTileDataAtPoint(x, y, z)
    if OldGetTileDataAtPoint then
        return OldGetTileDataAtPoint(false, x, y, z)
    end

    if not _nutrientgrid or not _moisturegrid or not _drinkersgrid or not _overlaygrid then
        if not _nutrientgrid then print("Show Me (中文) 警告：未找到上值 _nutrientgrid") end
        if not _moisturegrid then print("Show Me (中文) 警告：未找到上值 _moisturegrid") end
        if not _drinkersgrid then print("Show Me (中文) 警告：未找到上值 _drinkersgrid") end
        if not _overlaygrid then print("Show Me (中文) 警告：未找到上值 _overlaygrid") end
        return
    end

    local tx, ty = _G.TheWorld.Map:GetTileCoordsAtPoint(x, y, z)

    return {
        belowsoiltile = _G.TheWorld.components.undertile and _G.TheWorld.components.undertile:GetTileUnderneath(tx, ty) or nil,
        soil_drinkers = _drinkersgrid:GetDataAtPoint(tx, ty),
        nutrients_overlay = _overlaygrid:GetDataAtPoint(tx, ty),
        nutrients = _nutrientgrid:GetDataAtPoint(tx, ty),
        soilmoisture = _moisturegrid:GetDataAtPoint(tx, ty)
    }
end

--- Gets tile moisture at point
local function GetTileMoistureAtPoint(x, y, z)
    local data = GetTileDataAtPoint(x, y, z)
    return data and data.soilmoisture or 0
end

--安全取值TUNING
local function safe_tuning(path, default)    -- path传入的值，default手动设置的默认值，当传入的值为nil时使用手动设置的默认值
    local t = TUNING
    for part in string.gmatch(path, "[^.]+") do
        if t[part] == nil then
            return default
        end
        t = t[part]
    end
    return t
end

-- 辅助函数：将结果（字符串或字符串数组）插入 desc_table，自动添加 "@" 前缀
local function insert_description(result, desc_table)
    if type(result) == "table" then
        for _, str in ipairs(result) do
            if str then
                table.insert(desc_table, "@" .. str)
            end
        end
    elseif type(result) == "string" then
        table.insert(desc_table, "@" .. result)
    end
    -- 其他类型忽略（如 nil）
end

-- 注册表1：按 prefab 分发的处理器
local desc_handlers = {}
desc_handlers.batbat = function()
    local drain = safe_tuning("BATBAT_DRAIN", 0)
    return string.format(o_t.batbat, drain, -0.5 * drain)
end

desc_handlers.ruins_bat = function()
    local level = safe_tuning("RUINS_BAT_SHADOW_LEVEL", 0)
    return string.format(o_t.ruins_bat, level * 10) .. "%"
end

desc_handlers.ruinshat = function()
    local level = safe_tuning("RUINSHAT_SHADOW_LEVEL", -1.3)  -- 保证 (level+1.3) 非负
    return string.format(o_t.ruinshat, (level + 1.3) * 10) .. "%"
end

desc_handlers.spice_salt = function()
    local health = safe_tuning("SPICE_MULTIPLIERS.SPICE_SALT.HEALTH", 0)
    return string.format(o_t.spice_salt, health * 100) .. "%"
end

desc_handlers.slingshotammo_slow = function()
    local mult = safe_tuning("SLINGSHOT_AMMO_MOVESPEED_MULT", 1)
    local dur  = safe_tuning("SLINGSHOT_AMMO_MOVESPEED_DURATION", 0)
    local percent = math.ceil((mult - 1) * 100)
    return string.format(o_t.sammo_slow, percent .. "%", dur)
end

desc_handlers.slingshotammo_honey = function()
    local penalty = safe_tuning("BEEQUEEN_HONEYTRAIL_SPEED_PENALTY", 1)
    return string.format(o_t.sammo_honey, math.ceil((penalty - 1) * 100) .. "%")
end

desc_handlers.slingshotammo_purebrilliance = function()
    local planar = safe_tuning("SLINGSHOT_BRILLIANCE_MARK_PLANAR_DAMAGE", 0)
    local timeout = safe_tuning("SLINGSHOT_BRILLIANCE_MARK_TIMEOUT", 0)
    return string.format(o_t.mpl_hit, planar, timeout)
end

desc_handlers.slingshotammo_horrorfuel = function()
    local planar = safe_tuning("SLINGSHOT_HORROR_PLANAR_DAMAGE", 0)
    local ticks  = safe_tuning("SLINGSHOT_HORROR_TICKS", 0)
    return string.format(o_t.shf_hit, planar, ticks)
end

-- 这两个分支调用了 cn("aoe", ...) ，通过一个自定义插入方式处理
desc_handlers.slingshotammo_stinger = function(item, desc_table)
    local aoe = safe_tuning("SLINGSHOT_AMMO_DAMAGE_STINGER_AOE", 0)
    cn("aoe", aoe)   -- 假设 cn 是全局函数，直接调用
    -- 不返回任何描述（因为 cn 内部已插入）
    return nil
end

desc_handlers.slingshotammo_moonglass = function(item, desc_table)
    local aoe = safe_tuning("SLINGSHOT_AMMO_DAMAGE_MOONGLASS_AOE", 0)
    cn("aoe", aoe)
    return nil
end

desc_handlers.slingshot_band_pigskin = function()
    local range = safe_tuning("SLINGSHOT_MOD_BONUS_RANGE_1", 0)
    local speed = safe_tuning("SLINGSHOT_MOD_SPEED_MULT_1", 0)
    return {
        string.format(o_t.slingshot_range, range),
        string.format(o_t.ammo_speed, speed)
    }
end

desc_handlers.slingshot_band_tentacle = function()
    local range = safe_tuning("SLINGSHOT_MOD_BONUS_RANGE_2", 0)
    local speed = safe_tuning("SLINGSHOT_MOD_SPEED_MULT_2", 0)
    return {
        string.format(o_t.slingshot_range, range),
        string.format(o_t.ammo_speed, speed)
    }
end

desc_handlers.slingshot_band_mimic = function()
    local range = safe_tuning("SLINGSHOT_MOD_BONUS_RANGE_2", 0)
    local speed = safe_tuning("SLINGSHOT_MOD_SPEED_MULT_2", 0)
    local chance = safe_tuning("SLINGSHOT_MOD_FREE_AMMO_CHANCE", 0)
    local result = {
        string.format(o_t.slingshot_range, range),
        string.format(o_t.ammo_speed, speed),
        string.format(o_t.slingshot_speed, chance * 100 .. "%")  -- 只返回第三个，由主函数插入
    }
    return result
end

-- -------------------- WX78 模块分支 --------------------
desc_handlers.wx78module_maxhealth = function()
    local boost = safe_tuning("WX78_MAXHEALTH_BOOST", 0)
    local mult = 1   -- 默认
    return string.format(o_t.maxhealth, boost * mult)
end

desc_handlers.wx78module_maxhealth2 = function()
    local boost = safe_tuning("WX78_MAXHEALTH_BOOST", 0)
    local mult = safe_tuning("WX78_MAXHEALTH2_MULT", 1)
    return string.format(o_t.maxhealth, boost * mult)
end

desc_handlers.wx78module_maxsanity = function()
    local boost = safe_tuning("WX78_MAXSANITY_BOOST", 0)
    -- 额外插入 sanity 描述（通过 cn）
    local dapper = safe_tuning("WX78_MAXSANITY_DAPPERNESS", 0)
    cn("sanity", round2(dapper * 60))
    return string.format(o_t.maxsanity, boost)
end

desc_handlers.wx78module_maxsanity1 = function()
    local boost = safe_tuning("WX78_MAXSANITY1_BOOST", 0)
    return string.format(o_t.maxsanity, boost)
end

desc_handlers.wx78module_maxhunger = function()
    local boost = safe_tuning("WX78_MAXHUNGER_BOOST", 0)
    local slow = safe_tuning("WX78_MAXHUNGER_SLOWPERCENT", 0)
    local result = {
        string.format(o_t.maxhunger, boost),
        string.format(o_t.hungerslow, (1 - slow) * 100 .. "%")
    }
    return result
end

desc_handlers.wx78module_maxhunger1 = function()
    local boost = safe_tuning("WX78_MAXHUNGER1_BOOST", 0)
    return string.format(o_t.maxhunger, boost)
end

desc_handlers.wx78module_movespeed = function()
    local added = math.floor(safe_tuning("WILSON_RUN_SPEED", 1) * 4 + 1)
    cn("speed", added)
    return nil
end

desc_handlers.wx78module_movespeed2 = function()
    local added = math.floor(safe_tuning("WILSON_RUN_SPEED", 1) * 4 + 1)
    cn("speed", added)
    cn("other_tag", "wx78_movespeed2")
    return nil
end

desc_handlers.wx78module_bee = function()
    local dapper = safe_tuning("WX78_MAXSANITY_DAPPERNESS", 0)
    cn("sanity", round2(dapper * 60))
    local health_pertick = safe_tuning("WX78_BEE_HEALTHPERTICK", 0)
    local tick_period = safe_tuning("WX78_BEE_TICKPERIOD", 0)
    local sanity_boost = safe_tuning("WX78_MAXSANITY_BOOST", 0)
    return {
        string.format(o_t.healthpertick, health_pertick) .. " / " .. tick_period .. o_t.second,
        string.format(o_t.maxsanity, sanity_boost)
    }
end

desc_handlers.wx78module_music = function()
    local aura = safe_tuning("WX78_MUSIC_SANITYAURA", 0)
    cn("sanity", round2(aura * 60, 1))
    cn("other_tag", "wx78_music")
    return nil
end

desc_handlers.wx78module_heat = function()
    local hot_rate = safe_tuning("WX78_PERISH_HOTRATE", 1)
    local result = string.format(o_t.wx78_hot_cold, "+" .. (hot_rate - 1) * 100 .. "%")
    cn("other_tag", "wx78_moisture")
    cn("other_tag", "wx78_heat")
    return result
end

desc_handlers.wx78module_cold = function()
    local cold_rate = safe_tuning("WX78_PERISH_COLDRATE", 1)
    local ice_moist = safe_tuning("WX78_COLD_ICEMOISTURE", 0)
    local result = {
        string.format(o_t.wx78_hot_cold, (cold_rate - 1) * 100 .. "%"),
        string.format(o_t.wx78_cold3, ice_moist .. "%")
    }
    cn("other_tag", "wx78_cold")
    return result
end

-- -------------------- 女武神书 --------------------
local song_handlers = {}
local song_tunings = require("prefabs/battlesongdefs").song_defs

song_handlers[song_tunings.battlesong_durability] = function()
    local mod = safe_tuning("BATTLESONG_DURABILITY_MOD", 0)
    return string.format(o_t.bs_dy, (1 - mod) * 100) .. "%"
end

song_handlers[song_tunings.battlesong_healthgain] = function()
    local delta = safe_tuning("BATTLESONG_HEALTHGAIN_DELTA", 0)
    local singer = safe_tuning("BATTLESONG_HEALTHGAIN_DELTA_SINGER", 0)
    return string.format(o_t.bs_hp, delta, singer)
end

song_handlers[song_tunings.battlesong_sanitygain] = function()
    local delta = safe_tuning("BATTLESONG_SANITYGAIN_DELTA", 0)
    return string.format(o_t.bs_san, delta)
end

song_handlers[song_tunings.battlesong_sanityaura] = function()
    local mod = safe_tuning("BATTLESONG_NEG_SANITY_AURA_MOD", 0)
    return string.format(o_t.bs_desan, (1 - mod) * 100) .. "%"
end

song_handlers[song_tunings.battlesong_fireresistance] = function()
    local mod = safe_tuning("BATTLESONG_FIRE_RESIST_MOD", 0)
    return string.format(o_t.bs_fire, (1 - mod) * 100) .. "%"
end

song_handlers[song_tunings.battlesong_instant_taunt] = function()
    return o_t.bs_it
end

song_handlers[song_tunings.battlesong_instant_panic] = function()
    local panic = safe_tuning("BATTLESONG_PANIC_TIME", 0)
    return string.format(o_t.bs_ip, panic)
end

song_handlers[song_tunings.battlesong_shadowaligned] = function()
    local bonus = safe_tuning("BATTLESONG_SHADOWALIGNED_VS_LUNAR_BONUS", 1)
    local resist = safe_tuning("BATTLESONG_SHADOWALIGNED_SHADOW_RESIST", 1)
    return {
        string.format(o_t.bs_shadow, (bonus - 1) * 100) .. "%",
        string.format(o_t.bs_shadow2, (resist - 1) * 100) .. "%"
    }
end

song_handlers[song_tunings.battlesong_lunaraligned] = function()
    local bonus = safe_tuning("BATTLESONG_LUNARALIGNED_VS_SHADOW_BONUS", 1)
    local resist = safe_tuning("BATTLESONG_LUNARALIGNED_LUNAR_RESIST", 1)
    return {
        string.format(o_t.bs_lunar, (bonus - 1) * 100) .. "%",
        string.format(o_t.bs_lunar2, (resist - 1) * 100) .. "%"
    }
end


-- 主入口：根据 prefab 分发处理（包括 battlesong 子分发）
local function add_entity_description(item, desc_table)
    local handler = desc_handlers[item.prefab]
    if handler then
        local result = handler(item, desc_table)  -- 传入 desc_table 以便 cn 等操作
        if result then
            insert_description(result, desc_table)
        end
    end
end

-- 女武神书
local function process_songdata(item, desc_table)
    local handler = song_handlers[item.songdata]
    if handler then
        local result = handler(item)
        if result then
            insert_description(result, desc_table)
        end
    end
end

-- 阿比盖尔药水
local function process_potion(item, desc_table)
    local g_pt = item.potion_tunings
    if not g_pt then return end

    local day_time = TUNING.TOTAL_DAY_TIME or 480  -- 默认值
    local f_duration = TUNING.GHOSTLYELIXIR_FASTREGEN_DURATION or 0

    if g_pt.TICK_FN then
        if g_pt.DURATION == f_duration then
            local heal = safe_tuning("GHOSTLYELIXIR_FASTREGEN_HEALING", 0)
            table.insert(desc_table, "@" .. string.format(o_t.healthpertick, heal) .. " /" .. o_t.second .. "," .. SHOWME_STRINGS.chixu .. g_pt.DURATION .. o_t.second)
        else
            local heal = safe_tuning("GHOSTLYELIXIR_SLOWREGEN_HEALING", 0)
            table.insert(desc_table, "@" .. string.format(o_t.healthpertick, heal) .. " /" .. o_t.second .. "," .. SHOWME_STRINGS.chixu .. g_pt.DURATION / day_time .. SHOWME_STRINGS.days)
        end
    elseif g_pt.ONDETACH then
        table.insert(desc_table, "@" .. string.format(o_t.ghost_atk, g_pt.DURATION / day_time))
    elseif g_pt.speed_hauntable == true then
        local speed_mult = safe_tuning("GHOSTLYELIXIR_SPEED_LOCO_MULT", 1)
        table.insert(desc_table, "@" .. string.format(o_t.ghost_sd, (speed_mult - 1) * 100 .. "%", g_pt.DURATION / day_time))
    elseif g_pt.shield_prefab then
        if g_pt.shield_prefab == "abigailforcefieldretaliation" then
            local retaliation = safe_tuning("GHOSTLYELIXIR_RETALIATION_DAMAGE", 0)
            table.insert(desc_table, "@" .. string.format(o_t.ghost_atkf, retaliation))
        end
        table.insert(desc_table, "@" .. string.format(o_t.ghost_shd, g_pt.DURATION / day_time))
    end
end

-- 支持识别的组件
local showme_descriptors = {
    compostingbin = require("showme_descriptors/compostingbin"), -- 堆肥桶
    fueled = require("showme_descriptors/fueled"), -- 建筑燃料与服饰耐久
    health = require("showme_descriptors/health"), -- 血量与防御
    hunger = require("showme_descriptors/hunger"), -- 饥饿
    perishable = require("showme_descriptors/perishable"), -- 生物剩余寿命
    sanity = require("showme_descriptors/sanity"), -- 精神
    follower = require("showme_descriptors/follower"), -- 主人与忠诚
    combat = require("showme_descriptors/combat"), -- 攻击力与位面
    domesticatable = require("showme_descriptors/domesticatable"), -- 驯服度
    growable = require("showme_descriptors/growable"), -- 生长阶段
    sanityaura = require("showme_descriptors/sanityaura"), -- 精神光环
    minionspawner = require("showme_descriptors/minionspawner"), -- 食人花
    stewer = require("showme_descriptors/stewer"), -- 烹饪锅
    cooldown = require("showme_descriptors/cooldown"), -- 充能冷却
    tool = require("showme_descriptors/tool"), -- 工具效率增益
    oar = require("showme_descriptors/oar"), -- 船桨
    temperature = require("showme_descriptors/temperature"), -- 实体温度
    instrument = require("showme_descriptors/instrument"), -- 乐器范围
    occupiable = require("showme_descriptors/occupiable"), -- 笼中生物
    dryer = require("showme_descriptors/dryer"), -- 晾肉架
    saddler = require("showme_descriptors/saddler"), -- 鞍具
    tradable = require("showme_descriptors/tradable"), -- 交易价值
    repairer = require("showme_descriptors/repairer"), -- 船修理
    harvestable = require("showme_descriptors/harvestable"), -- 可收获
    armor = require("showme_descriptors/armor"), -- 护甲防御与耐久
    weapon = require("showme_descriptors/weapon"), -- 武器伤害
    zupalexsrangedweapons = require("showme_descriptors/weapon"), -- 远程武器 mod（与 weapon 同文件）
    projectile = require("showme_descriptors/range"), -- 投射物与纯 combat 物品的攻击范围（生物与武器场景排除）
    healer = require("showme_descriptors/healer"), -- 治疗量
    finiteuses = require("showme_descriptors/finiteuses"), -- 使用次数
    insulator = require("showme_descriptors/insulator"), -- 保暖/隔热
    equippable = require("showme_descriptors/equippable"), -- 装备回san与移速
    dapperness = require("showme_descriptors/equippable"), -- 精神回复（与 equippable 同文件）
    waterproofer = require("showme_descriptors/waterproofer"), -- 防水
    edible = require("showme_descriptors/edible"), -- 食物属性
    fertilizer = require("showme_descriptors/fertilizer"), -- 肥料值
    pickable = require("showme_descriptors/pickable"), -- 采摘倒计时与次数
    crop = require("showme_descriptors/crop"), -- 旧农场作物生长进度
    unwrappable = require("showme_descriptors/unwrappable"), -- 捆绑包内容
    friendlevels = require("showme_descriptors/friendlevels"), -- 好感度
    stackable = require("showme_descriptors/stackable"), -- 超大堆叠实际数量
    pearldecorationscore = require("showme_descriptors/pearldecorationscore"), -- 寄居蟹装饰度
    farmplantstress = require("showme_descriptors/farmplantstress"), -- 农作物压力
    beerpower = require("showme_descriptors/beerpower"), -- 不灵电力
    waterpower = require("showme_descriptors/waterpower"), -- 不灵水量
    gaspower = require("showme_descriptors/gaspower"), -- 不灵气体
}

-- 描述文件运行在全局环境，modmain2 的 local 工具需经 context.utils 传入；搬移新组件时按需补充
local descriptor_utils = {
    round2 = round2,
    KNOWN_BUFFS = KNOWN_BUFFS, -- 食物增益注册表（TUNING 键名与显示名）
    DataTimerFn = DataTimerFn,
    GetPerishTime = GetPerishTime,
    GetPrefabFancyName = GetPrefabFancyName,
    GetDebuffTime = GetDebuffTime,
    IsUselessTimer = IsUselessTimer,
    safe_tuning = safe_tuning,
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

--- 石头上的季节信息（未开启季节时钟时的替代显示）
---@return table entries 协议条目数组：当前季节、季节剩余天数、世界温度
local function GetSeasonEntries()
    local w = _G.TheWorld.state -- 世界状态
    local entries = {}
    local season_keys = { iswinter = "S1", issummer = "S2", isspring = "S3", isautumn = "S4" } -- 四季互斥，只命中一个
    for flag, key in pairs(season_keys) do
        if w[flag] then
            table.insert(entries, { data_key = key })
            break
        end
    end
    table.insert(entries, { data_key = "remaining_days", params = { w.remainingdaysinseason } })
    table.insert(entries, { data_key = "temperature", params = { round2(w.temperature, 1) } })
    return entries
end

--- 主人识别三级链：mine 组件昵称 → stealable.owner → item.owner（跟随者/宠物实体的主人显示；字段非组件无法走描述文件锚点）
---@param item table 被查看的实体
---@return table|nil entries 协议条目数组：owner 词条；无主人时为 nil
local function GetOwnerEntries(item)
    local entries = {}
    if item.components.mine and item.components.mine.nick then
        table.insert(entries, { data_key = "owner", params = { item.components.mine.nick } })
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

local SLINGSHOT_AMMO_DATA -- 弹弓弹药数据
local function Get_SLINGSHOT_AMMO_DATA() -- 首次获取数据
    SLINGSHOT_AMMO_DATA = {}
    for i,v in pairs(_G.Prefabs) do        --获取官方Prefab
        if v.fn and _G.debug.getinfo(v.fn, "S").source == "scripts/prefabs/slingshotammo.lua" then        --Prefab 的Fn
            if v.name:sub(-5) == "_proj" then
                --table.insert(ammo_prefabs, Prefab(name, function() return fn(data) end, assets, prefabs))  --新
                --table.insert(ammo_prefabs, Prefab(v.name.."_proj", function() return projectile_fn(v) end, assets, prefabs))  --旧
                local ammo_data = Upvaluehelper.GetUpvalue(v.fn, "data") --"v" > "data"
                if ammo_data ~= nil and type(ammo_data) == "table" then
                    SLINGSHOT_AMMO_DATA[ammo_data.name] = ammo_data
                end
            end
        end
    end
end

--获取物品信息
function GetTestString(item, viewer)
    --line_cnt = 0
    desc_table = {} --旧的 desc 将被取消
    local prefab = item.prefab
    local c=item.components

    local item_descriptors = {}
    local processed_descriptors = {} -- 同一描述文件注册多个组件键时只执行一次
    for components_name, component in pairs(item.components or {}) do
        local descriptor = showme_descriptors[components_name]
        if descriptor and descriptor.Describe and not processed_descriptors[descriptor] then
            processed_descriptors[descriptor] = true
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

            local result = descriptor.Describe(component, context)
            if result then
                -- 单条目对象靠 data_key/description 识别，数组则直接展开
                if result[1] == nil and (result.data_key or result.description) then
                    result = { result }
                end
                for _, entry in ipairs(result) do
                    entry.order = #item_descriptors -- 插入序号，供同优先级排序保持组件内代码顺序
                    table.insert(item_descriptors, entry)
                end
            end
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

    --------------------------------------------------------------------------------------------------------------------

    if (prefab=="rock1" or prefab=="rock2") and not viewer.has_AlwaysOnStatus then    --没有开季节时钟则在石头上显示季节与剩余天数
        for _, entry in ipairs(GetSeasonEntries()) do
            EncodeEntry(entry)
        end
    -- elseif c.health and not item.grow_stage then
        --生物显示已全部由组件描述文件输出（血量/饥饿/精神等），无残留可显示项
    else
        --Part 1: primary info（烹饪锅、冷却已迁至 showme_descriptors/stewer.lua、cooldown.lua）
        --Part 2: secondary info
        --护甲、武器伤害、攻击范围已迁至 showme_descriptors/armor.lua、weapon.lua、range.lua（combat 键触发范围，见 range.lua）
        --工具工作效率增益已迁至 showme_descriptors/tool.lua
        --保暖/隔热已迁至 showme_descriptors/insulator.lua
        if prefab == "flower_evil" then -- 恶魔花无组件锚点，回 san 显示保留在主流程
            cn("sanity",-_G.TUNING.SANITY_TINY,1)
        end
        --装备移速加成已迁至 showme_descriptors/equippable.lua
        --防水已迁至 showme_descriptors/waterproofer.lua
        --船桨力度已迁至 showme_descriptors/oar.lua
        --食物属性（含温度/记忆/Warly BUFF）已迁至 showme_descriptors/edible.lua
        --肥料信息已迁至 showme_descriptors/fertilizer.lua
        --物品腐烂时间已并入 showme_descriptors/perishable.lua（生物寿命同文件）
        --显示食物填充单位
        if ing[prefab] and show_food_units ~= 2 then -- ==2 means that food info is forbidden on the server.
            for k,v in pairs(ing[prefab].tags) do
                if k~="precook" and k~="dried" then
                    cn("units_of",v,k)
                end
            end
        end
        --治疗量已迁至 showme_descriptors/healer.lua
        --工具、武器耐久已迁至 showme_descriptors/finiteuses.lua
        --温度
        --当前温度、乐器范围已迁至 showme_descriptors/temperature.lua、instrument.lua

        --装备饥饿减免
        if prefab=="beargervest" then
            table.insert(desc_table, "@"..string.format(o_t.hungerslow, (1-TUNING.ARMORBEARGER_SLOW_HUNGER)*100).."%")
        elseif prefab=="armorslurper" or prefab=="hat_albicans_mushroom" then
            table.insert(desc_table, "@"..string.format(o_t.hungerslow, (1-TUNING.ARMORSLURPER_SLOW_HUNGER)*100).."%")
        elseif prefab == "red_mushroomhat" or prefab == "green_mushroomhat" or prefab == "blue_mushroomhat" then
            table.insert(desc_table, "@"..string.format(o_t.hungerslow, (1-TUNING.MUSHROOMHAT_SLOW_HUNGER)*100).."%")
        end
        --主人识别三级链已收敛至 GetOwnerEntries；follower 组件的主人与忠诚度由 follower.lua 处理
        local owner_entries = GetOwnerEntries(item)
        if owner_entries then
            for _, entry in ipairs(owner_entries) do
                EncodeEntry(entry)
            end
        end
        --笼中生物倒计时、晾肉架已迁至 showme_descriptors/occupiable.lua、dryer.lua
        --鞍具、交易价值已迁至 showme_descriptors/saddler.lua、tradable.lua
        --冰箱 etc
        if TUNING.PERISH_FRIDGE_MULT ~= 0.5 and item:HasTag("fridge") then
            local fridge = tonumber(TUNING.PERISH_FRIDGE_MULT);
            if fridge then
                cn("frigde",round2(fridge,1))
            end
        end
        --船修理值、收获已迁至 showme_descriptors/repairer.lua、harvestable.lua
        --弹弓弹药
        if item:HasTag("slingshotammo") then
            if not SLINGSHOT_AMMO_DATA then Get_SLINGSHOT_AMMO_DATA() end
            local ammo_data = SLINGSHOT_AMMO_DATA and SLINGSHOT_AMMO_DATA[prefab]
            if ammo_data ~= nil then
                if ammo_data.damage ~= nil then cn("dmg", ammo_data.damage) end
                if ammo_data.planar ~= nil then cn("basedmg", ammo_data.planar) end
            end
        end

        -- 冬季盛宴树
        if item:HasTag("winter_tree") then
            local giftable = viewer.components.wintertreegiftable
            if giftable and giftable.GetDaysSinceLastGift then
                local days = giftable:GetDaysSinceLastGift()
                if type(days) == "number" then
                    if days >= 4 then
                        table.insert(desc_table, "@" .. MY_STRINGS.winter_gift_ready)
                    else
                        local remaining_days = math.ceil(4 - days)
                        table.insert(desc_table, "@" .. string.format(
                            MY_STRINGS.winter_gift_wait,
                            remaining_days
                        ))
                    end
                end
            end
        end
        ------------------Check prefabs?----------------------
        if prefab=="pond" or prefab=="pond_mos" or prefab=="pond_cave" or prefab=="oasislake" then --池塘
            if c.fishable and c.fishable.fishleft then
                cn(c.fishable.fishleft==1 and "fish" or "fishes",c.fishable.fishleft)
            end
        elseif prefab=="aqvarium" and item.data then
            if item.data.seeds and item.data.seeds>0 then --种子
                table.insert(desc_table, "@Seeds: "..tostring(item.data.seeds))
            end
            if item.data.meat and item.data.meat>0 then --肉
                table.insert(desc_table, "@Meat: "..tostring(item.data.meat))
                --desc = cn(desc,item.data.meat,"Meat:",true)
            end
            local need_wet= item.data.need_wet or 60
            if item.data.wet and item.data.wet>0 and item.data.wet<need_wet then --水
                table.insert(desc_table, "@Water: "..tostring(round2(100*item.data.wet/need_wet).."%"))
                --desc = cn(desc,round2(100*item.data.wet/need_wet).."%","Water:",true)
            end
            if item.total_heat then --总温度
                local temp = item.total_heat/10 --+ _G.TheWorld.state.temperature
                if temp>40 then temp = 40 end
                if temp>=0 then
                    cn("temperature",tostring(round2(temp,1)))
                end
            end
        elseif prefab=="rainometer" then --雨量计
            local function inSine(t, b, c, d)
                return -c * math.cos(t / d * (math.pi / 2)) + c + b
            end
            cn("precipitationrate",round2(inSine(_G.TheWorld.state.precipitationrate, 0, 0.75, 1),3).."/s")
            cn("wetness",round2(_G.TheWorld.state.wetness,1))
        elseif prefab=="winterometer" then --温度计
            local w=_G.TheWorld.state
            local tt=round2(w.temperature,1)
            cn("temperature",tt)
        elseif prefab=="spice_garlic" then
            local data = KNOWN_BUFFS.buff_playerabsorption
            cn("buff",data.name,0,TUNING[data.power]+1)
        elseif prefab=="spice_chili" then
            local data = KNOWN_BUFFS.buff_attack
            cn("buff",data.name,0,TUNING[data.power])
        elseif prefab=="spice_sugar" then
            local data = KNOWN_BUFFS.buff_workeffectiveness
            cn("buff",data.name,0,TUNING[data.power])
        elseif prefab=="moon_fissure" and c.sanityaura and c.sanityaura.aurafn then --月亮裂隙
            local current_sanity = c.sanityaura.aurafn(item, viewer)
            local max_sanity = 100/(TUNING.SEG_TIME*2) -- hardcoded!
            local effectiveness = current_sanity / max_sanity
            cn("effectiveness",round2(effectiveness * 100))
        elseif prefab=='boat' or prefab=='anchor' or prefab=='mast' or prefab=='boat_leak' or prefab=='mast_malbatross' or prefab=='steeringwheel' then --船工具
            --没有信息，只有船的状态
            AddBoatStatus(viewer)
        elseif prefab=="cannonball_rock_item" then
            cn("dmg", TUNING.CANNONBALL_DAMAGE)
        end

        --其他物品添加标签    VOIDCLOTH
        local o_t_list = {
        "orchitwigs",    --1
        "halloweenpotion_health_large", "halloweenpotion_health_small",    --2~3
        "halloweenpotion_sanity_large", "halloweenpotion_sanity_small",    --4~5
        "halloweenpotion_bravery_small", "halloweenpotion_bravery_large",    --6~7
        "slingshot_frame_wagpunk","slingshot_frame_wagpunk_0",    --8~9
        "wx78module_taser", "wx78module_nightvision", "wx78module_light", "slingshotammo_thulecite", "slingshotammo_freeze","slingshotammo_poop", "wolfgang_whistle",  "lileaves", "rosorns", "shark_teethhat", "brainjellyhat", "gashat", "onemanband", "armorseashell", "book_birds", "book_brimstone", "book_gardening", "book_silviculture", "book_sleep", "slingshot_frame_bone", "slingshot_frame_gems", "slingshot_handle_voidcloth", }
        for i, n in pairs(o_t_list) do
            if prefab == n then        --必须是列表里面的，不然全部物品都加上这些标签0.0!
                if i == 1 then
                    if c.weapon.onattack ~= nil then
                        cn("aoe", TUNING.BASE_SURVIVOR_ATTACK*0.7)    --兰草穗群伤，目前只能写死伤害
                    end
                elseif i > 1 and i <= 3 then
                    cn("other_tag", "halloweenpotion_health")
                elseif i > 3 and i <= 5 then
                    cn("other_tag", "halloweenpotion_sanity")
                elseif i > 5 and i <= 7 then
                    local potion_time = 0.5
                    if i == 7 then
                        potion_time = 0.75
                    end
                    table.insert(desc_table, "@"..string.format(o_t.hpotion_bravery, potion_time))
                elseif i > 7 and i <= 9 then
                    cn("other_tag", "slingshot_frame_wagpunk_0")
                elseif i > 9 then
                    cn("other_tag", n)
                end
            end
        end

        add_entity_description(item, desc_table)

        -- 女武神书
        process_songdata(item, desc_table)
        -- 阿比盖尔的药水
        process_potion(item, desc_table)

        --重生护符
        if (prefab == "ancient_amulet_red" or prefab == "amulet") and c.hauntable then
            cn("other_tag", "amulet")
        end
        --Charges: lightning rod / lamp
        if item.chargeleft and item.chargeleft > 0 then
            table.insert(desc_table, "@"..o_t.will_other..tostring(math.floor(item.chargeleft+0.5))..SHOWME_STRINGS.days) --避雷针
        end
        if show_fuel ~= false and c.fuel ~= nil then    --燃料信息
            table.insert(desc_table, "@"..o_t.ot_fuelval..DataTimerFn(c.fuel.fuelvalue))
        end
        --Mod support:
        if item.GetShowItemInfo then
            local custom1, custom2, custom3 = item:GetShowItemInfo(viewer)
            if custom1 then table.insert(desc_table, "@"..tostring(custom1)) end
            if custom2 then table.insert(desc_table, "@"..tostring(custom2)) end
            if custom3 then table.insert(desc_table, "@"..tostring(custom3)) end
        end

        --采摘倒计时/次数已迁至 showme_descriptors/pickable.lua
        --旧农场作物生长进度已迁至 showme_descriptors/crop.lua
        --捆绑包内容已迁至 showme_descriptors/unwrappable.lua
        --好感度已迁至 showme_descriptors/friendlevels.lua
		--堆叠上限已迁至 showme_descriptors/stackable.lua
		--寄居蟹装饰度已迁至 showme_descriptors/pearldecorationscore.lua
		-- 铥矿奖章, 仅在地洞世界显示当前噩梦阶段剩余时间, 读秒有点不准但能用就行
		if prefab == "nightmare_timepiece" and _G.TheWorld:HasTag("cave") then
			-- print("[ShowMe-DBG] === dumping world.components ===")
			-- for k, v in pairs(_G.TheWorld.components) do
				-- print(string.format("[ShowMe-DBG]   %s : %s", tostring(k), type(v)))
			-- end
			local phase = _G.TheWorld.state.nightmarephase
			local progress = _G.TheWorld.state.nightmaretimeinphase

			if phase and phase ~= "none" and progress then
				local SEG_TIME  = _G.TUNING.SEG_TIME or 30
				local PHASE_SEGS = {
					calm = _G.TUNING.NIGHTMARE_SEGS and _G.TUNING.NIGHTMARE_SEGS.CALM,
					warn = _G.TUNING.NIGHTMARE_SEGS and _G.TUNING.NIGHTMARE_SEGS.WARN,
					wild = _G.TUNING.NIGHTMARE_SEGS and _G.TUNING.NIGHTMARE_SEGS.WILD,
					dawn = _G.TUNING.NIGHTMARE_SEGS and _G.TUNING.NIGHTMARE_SEGS.DAWN,
				}
				local segs = PHASE_SEGS[phase]

				if segs and segs > 0 then
					-- 基础时长 = seg 数 × SEG_TIME；忽略 0~NIGHTMARE_SEG_VARIATION 的随机加成
					local remaining = segs * SEG_TIME * (1 - progress)
					if remaining > 0 then
						local name = o_t["nightmare_" .. phase] or phase
						table.insert(desc_table, "@" .. name .. ": " .. DataTimerFn(remaining))
					end
				end
			end
		end
        --农作物压力已迁至 showme_descriptors/farmplantstress.lua
    end
    --不灵电力/水量/气体已迁至 showme_descriptors/beerpower.lua、waterpower.lua、gaspower.lua

    --生物巢,生物：6/6
    if c.childspawner then
		local function IsSpawnerHouse(prefab)
			return prefab == "mermhouse_crafted" or prefab == "mermwatchtower"
		end

		local inside = math.floor(tonumber(c.childspawner.childreninside) or 0)
		local maximum = math.floor(tonumber(c.childspawner.maxchildren) or 0)
		local child_name = GetPrefabFancyName(c.childspawner.childname or MY_DATA.children.desc) .. ": " -- 直接从官方字符串拿生物名

		if IsSpawnerHouse(prefab) then -- 用于人鱼屋
			local spawner = c.childspawner

			local outside = spawner.CountChildrenOutside and spawner:CountChildrenOutside() or 0	-- 外出的
			local total = inside + outside	-- 屋内 + 屋外

			local cur_max = child_name .. total .. " / " .. maximum

			-- 判定"已停止"的两种依据（满足任一即视为停止）
			local timer = c.worldsettingstimer
			local tm = timer and timer.GetTimeLeft and timer:GetTimeLeft("ChildSpawner_RegenPeriod")

			if total >= maximum or not tm then
				-- 已达上限 或 计时器未在跑（例如白天 StopSpawning / 世界设置禁用）
				cur_max = cur_max .. " (" .. SHOWME_STRINGS.stopped .. ")"
			elseif tm > 0 then
				cur_max = cur_max .. " | " .. o_t.spawn_in .. DataTimerFn(tm)
			end

			table.insert(desc_table, "@" .. cur_max)
        else
			if inside and maximum then
				cn("children",round2(inside,0),round2(maximum,0))
			end
		end
    end

    --从武器信息看:
    if viewer.components.inventory then
        local weapon = viewer.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
        if weapon then
            local resist = nil --base resist
            local total_resist = nil --base + bonus resist
            local now = nil --amount of current resist
            if weapon.prefab=="icestaff" and c.freezable then
                resist = c.freezable.resistance
                total_resist = c.freezable.ResolveResistance and c.freezable:ResolveResistance() or resist
                if c.freezable.coldness and c.freezable.coldness ~= 0 then
                    now = round2(total_resist - c.freezable.coldness,1)
                end
            elseif (weapon.prefab=="blowdart_sleep" or weapon.prefab=="panflute") and c.sleeper then
                resist = c.sleeper.resistance
                total_resist = resist -- there is sleep time bonus but not sleep armor bonus
                if c.sleeper.sleepiness and c.sleeper.sleepiness ~= 0 then
                    now = round2(total_resist - c.sleeper.sleepiness,1)
                end
            end
            if resist then
                if total_resist ~= resist then
                    resist = resist .. '+' .. round2(math.abs(total_resist-resist),1)
                end
                if now then
                    resist = now .. ' / ' .. resist
                end
                cn("resist",resist)
            end
        end
    end
    if item.inlove and item.inlove>0 then
        if prefab=="chester" then
            cn("love",item.inlove/10)
        else
            cn("love",item.inlove)
        end
    end
    --Additional
    if c.timer and c.timer.timers then
        --local get_time = GetTime()
        local t = c.timer
        for name, data in pairs(t.timers) do
            if not IsUselessTimer(prefab,name) then
                --GetTimeLeft(name) IsPaused
                local tm = t:GetTimeLeft(name)
                local paused = t:IsPaused(name)
                if tm then
                    if item:HasTag("critter") then
                        return
                    end
                    cn('timer', round2(tm,0), name, paused and 1 or nil)
                else
                    cn('timer', "-", name)
                end
            end
        end
    end
    --预计：
    if c.worldsettingstimer and c.worldsettingstimer.timers and not (prefab == "grass" and c.pickable.transplanted) then --transplanted 可移植的
        --local get_time = GetTime()
        local t = c.worldsettingstimer
        for name, data in pairs(t.timers) do
            if not IsUselessTimer(prefab,name) then
                --IsPaused GetMaxTime TimerEnabled GetTimeLeft
                local tm = t:GetTimeLeft(name)
                local paused = t:IsPaused(name)
                if tm then
                    cn('timer', round2(tm,0), name, paused and 1 or nil)
                elseif t.GetMaxTime then
                    local max_tm = t:GetMaxTime(name)
                    if max_tm then
                        cn('timer', round2(data.maxtime,0), name, 2)
                    end
                else
                    cn('timer', "-", name)
                end
            end
        end
    end
    -- 新晾肉架
    if c.dryingrack and c.dryingrack.GetDryingInfoSnapshot then
        local snapshot = c.dryingrack:GetDryingInfoSnapshot()
        if snapshot then
            for k,v in pairs(snapshot) do
                if type(v) == "number" then
                    table.insert(desc_table, "@" .. (k.name or k.prefab or tostring(k)) .. " " .. o_t.will_other .. round2(v/TUNING.TOTAL_DAY_TIME,1) .. SHOWME_STRINGS.days)
                end
            end
        end
    end
    return table.concat(desc_table,"\2") --an error with no info
end    -- 函数GetTestString END

-- 服务器处理end
end

-- 其它单独物品的信息显示
if SERVER_SIDE then
    -- 暗影槌 (参考了Insight模组的获取方式)
    local max_level = #TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS
    AddPrefabPostInit("shadow_battleaxe", function(inst)
        inst.GetShowItemInfo = function()
            -- How many bosses we've killed on this threshold level.
            local this_level_boss_kills = 0
            -- The number of bosses that need to be killed to reach the next level.
            local boss_kills_for_next_level = 0
            if inst.level < max_level then
                this_level_boss_kills = inst.epic_kill_count - TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS[inst.level]
                boss_kills_for_next_level = TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS[inst.level + 1] - TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS[inst.level]
            end
            local level_string = string.format(o_t.level .. "%s / %s",
                inst.level,
                max_level
            )
            local boss_progress_string

            if boss_kills_for_next_level > 0 then
                boss_progress_string = string.format(o_t.kills .. "BOSS: %s / %s",
                    this_level_boss_kills,
                    boss_kills_for_next_level
                )
            end

            -- 吸血信息
            local lifesteal_info
            if inst._lifesteal > 0 then
                lifesteal_info = string.format(o_t.life_stealing .. "%.2f (" .. MY_DATA.sanity.desc .. "%.2f)",
                    inst._lifesteal,
                    -inst._lifesteal * TUNING.SHADOW_BATTLEAXE.LIFE_STEAL_SANITY_LOSS_SCALE
                )
            end

            -- 汇总信息
            local description
            if lifesteal_info then
                description = lifesteal_info .. "\n" .. level_string
            else
                description = level_string
            end
            if boss_progress_string then
                description = description .. " | " .. boss_progress_string
            end

            return description
        end
    end)
end

----------------------------WeGame有在维护，请勿搬运，为避免出现多个相同模组----------------------------
------------------------------------------- HOST & CLIENT AGAIN ---------------------------------------------

--为玩家添加一个提示，通过该提示将发送数据（在项目名称下弹出带有信息的文本）
do
    --如果该函数与发送的信息（在player_classified中）完全匹配，则返回一个提示。
    --返回一个提示，要么是 ""。
    local function CheckUserHint(inst)
        local c = _G.ThePlayer and _G.ThePlayer.player_classified
        if c == nil then --没有本地玩家或 classified
            return ""
        end
        --c.showme_hint
        local i = string.find(c.showme_hint2,';',1,true)
        if i == nil then --字符串格式不正确情况下
            return ""
        end
        local guid = _G.tonumber(c.showme_hint2:sub(1,i-1))
        if guid ~= inst.GUID then --guid不匹配 (或nil情况下)
            return ""
        end
        return c.showme_hint2:sub(i+1)
    end
    if CLIENT_SIDE then
        local function UnpackData(str,div)
            local pos,arr = 0,{}
            -- for each divider found
            for st,sp in function() return string.find(str,div,pos,true) end do
                table.insert(arr,string.sub(str,pos,st-1)) -- 在当前分隔符左侧附加字符
                pos = sp + 1 -- Jump past current divider
            end
            table.insert(arr,string.sub(str,pos)) -- 在最后一个分隔符右侧附加字符
            return arr
        end

        local save_target
        local last_check_time = 0 --最后一次查看时间, 每 2 秒过期一次。
        AddClassPostConstruct("widgets/hoverer",function(hoverer) --hoverer=self
            local old_SetString = hoverer.text.SetString
            local NEWLINES_SHIFT = {
                '', --无信息
                '', -- 1 条信息
                '', -- 2 条信息
                '\n ',
            }
            local function InitNewLinesShift(idx)
                local str = NEWLINES_SHIFT[idx]
                if str then
                    return str
                end
                str = '\n' .. InitNewLinesShift(idx-1)
                NEWLINES_SHIFT[idx] = str
                return str
            end
            hoverer.text.SetString = function(text,str) --text=self
                text.cnt_lines = nil
                local target = _G.TheInput:GetHUDEntityUnderMouse()
                if target ~= nil then
                    local function par(w)
                        return w.parent and (w.parent.item or par(w.parent)) or nil
                    end
                    target = target.widget ~= nil and par(target.widget)
                else
                    target = _G.TheInput:GetWorldEntityUnderMouse()
                end
                if type(target) ~= "table" or not target.GUID then
                    target = nil
                end
                if target ~= nil then
                    --print(tostring(target))
                    --检查数据是否匹配。
                    local str2 = CheckUserHint(target)
                    if str2 ~= "" then
                        --首先清除旧行到新行的过渡，因为你永远不知道添加了什么样的模组。
                        local cnt_newlines, _ = 0 --计算行末尾的行转换（DFV 兼容）
                        while cnt_newlines < #str do
                            local ch = str:sub(#str-cnt_newlines,#str-cnt_newlines)
                            if ch ~= "\n" and ch ~= " " then
                                break
                            end
                            cnt_newlines = cnt_newlines + 1
                        end
                        --清除该行的废弃信息
                        if cnt_newlines > 0 then
                            str = str:sub(1,#str-cnt_newlines)
                        end
                        --print(#str,"clear")
                        --清除线路中间废弃信息
                        if string.find(str,"\n\n",1,true) ~= nil then
                            str = str:gsub("[\n]+","\n")
                        end

                        if string.find(str,"\n",1,true) ~= nil then
                            _,cnt_newlines = str:gsub("\n","\n") --计算内部的转换数量（如果有的话）
                        else
                            cnt_newlines = 0
                        end

                        --从生成的打包字符串中提取数据。
                        str2 = UnpackData(str2,"\2")
                        local arr2 = {} --以易于理解的形式形成一组数据。
                        for i,v in ipairs(str2) do
                            if v ~= "" then
                                local idx, param_start = decodeDataPrefix(v)
                                local param_str = v:sub(param_start)
                                local data = { param = UnpackData(param_str,","), param_str=param_str }
                                local key = MY_DATA_BY_ID[idx]; -- if "@", must pass nil
                                if key ~= nil then
                                    data.data = MY_DATA[key]
                                end
                                table.insert(arr2,data)
                            end
                        end
                        arr2.str2= str2
                        --形成一个字符串
                        for i=#arr2,1,-1 do
                            local v = arr2[i]
                            if v.data ~= nil then
                                if v.data.hidden == nil then
                                    if v.data.fn ~= nil then
                                        arr2[i] = v.data.fn(v)
                                    else
                                        arr2[i] = DefaultDisplayFn(v)
                                    end
                                else
                                    table.remove(arr2,i)
                                end
                            else
                                arr2[i] = DefaultDisplayFn(v)
                            end
                        end
                        str2 = table.concat(arr2,'\n')
                        text.cnt_lines = cnt_newlines + #arr2 + 1
                        str = str .. '\n' .. str2 .. (NEWLINES_SHIFT[text.cnt_lines] or InitNewLinesShift(text.cnt_lines))
                    end
                    --如果这是第一次，那么会发送请求。
                    if target ~= save_target or last_check_time + 1 < GetTime() then
                        save_target = target
                        last_check_time = GetTime()
                        SendModRPCToServer(MOD_RPC.ShowMeSHint.Hint, save_target.GUID, save_target)        --客户端向服务器发送请求的RPC
                    end
                -- else
                    --print("target nil")
                end
                return old_SetString(text,str)
            end

            local XOFFSET = 10

            hoverer.UpdatePosition = function(self,x,y)
                local YOFFSETDOWN = 10
                local cnt_lines = self.text and self.text.cnt_lines
                if cnt_lines then
                    local extra = cnt_lines - 3
                    if extra > 0 then
                        YOFFSETDOWN = YOFFSETDOWN - extra * 30
                    end
                end


                local scale = self:GetScale()
                local scr_w, scr_h = _G.TheSim:GetScreenSize()
                local w = 0
                local h = 0

                if self.text ~= nil and self.str ~= nil then
                    local w0, h0 = self.text:GetRegionSize()
                    w = math.max(w, w0)
                    h = math.max(h, h0)
                end
                if self.secondarytext ~= nil and self.secondarystr ~= nil then
                    local w1, h1 = self.secondarytext:GetRegionSize()
                    w = math.max(w, w1)
                    h = math.max(h, h1)
                end

                w = w * scale.x * .5
                h = h * scale.y * .5

                self:SetPosition(
                    math.clamp(x, XOFFSET + w, scr_w - w - XOFFSET),
                    math.clamp(y, YOFFSETDOWN + h, scr_h + 9999),
                0)
            end


        end)
    end

    --服务器上的处理程序
    AddModRPCHandler("ShowMeSHint", "Hint", function(player, guid, item) --服务器RPC执行客户端发来的请求
        if not (_G.checknumber(guid) and _G.checkentity(item)) then
            printinvalid("ShowMeSHint.Hint", player)
            return
        end

        if player.player_classified == nil then
            print("ERROR: player_classified not found!")
            return
        end
        if item ~= nil and item.components ~= nil then
            local s = GetTestString(item, player) --在服务器上形成一个字符串
            if s and s ~= "" then
                player.player_classified.net_showme_hint2:set(tostring(guid)..";"..s) --将其打包成一行并将其发送回同一玩家
            end
        end
    end)

    --联网
    -- showme_hint2 => "showme_hintbua." -- hash value: 78865, Ratio: 0.000078865
    AddPrefabPostInit("player_classified",function(inst)
        inst.showme_hint2 = ""
        inst.net_showme_hint2 = _G.net_string(inst.GUID, "showme_hintbua.", "showme_hint_dirty2")
        if show_naughtiness then
            inst.net_showme_kramped = {
                actions = _G.net_smallbyte(inst.GUID, "showme_kramped_actions", "showme_kramped_dirty"),
                threshold = _G.net_smallbyte(inst.GUID, "showme_kramped_threshold", "showme_kramped_dirty"),
            }
        end
        if CLIENT_SIDE then
            inst:ListenForEvent("showme_hint_dirty2",function(inst)
                inst.showme_hint2 = inst.net_showme_hint2:value()
            end)
            if show_naughtiness then
                inst:ListenForEvent("showme_kramped_dirty",function(inst)
                    OnShowMeNaughtyAction() -- 见 showme_naughtiness.lua
                end)
            end
        end
    end)
end

--处理箱子模块
if not _G.KnownModIndex:IsModEnabledAny("workshop-3363111676") then -- 开启高亮查找模组时关掉Show Me的高亮显示，节省性能
    local MAIN_VAR_NAME = 'net_ShowMe_chest';
    local NETVAR_NAME = 'ShowMe_chestlq_.'; -- hash value: 983115,  Ratio: 0.000983115
    local EVENT_NAME = 'ShowMe_chest_dirty';
    --[[
    --致模组开发者: 你的模组容器可使用以下代码，实现与ShowMe联动容器高亮。    --源开发者 Star 留
        TUNING.MONITOR_CHESTS = TUNING.MONITOR_CHESTS or {}
        TUNING.MONITOR_CHESTS.chestprefab = true    -- chestprefab 即你的容器代码名称
    
    --多容器模式, 优先级高低判断可同时加上
    --优先级高于 ShowMe
        TUNING.MONITOR_CHESTS = TUNING.MONITOR_CHESTS or {}
        for _, v in ipairs(容器列表) do
            TUNING.MONITOR_CHESTS[v] = true
        end
    
    --优先级低于 ShowMe
        for k, m in pairs(ModManager.mods) do
            if m and _G.rawget(m, "SHOWME_STRINGS") then
                if m.postinitfns and m.postinitfns.PrefabPostInit and m.postinitfns.PrefabPostInit.treasurechest then
                    for _,v in ipairs(容器列表) do
                        m.postinitfns.PrefabPostInit[v] = m.postinitfns.PrefabPostInit.treasurechest
                    end
                end
                break
            end
        end
    --]]
    --拿起物品箱子颜色显示的容器列表
    local MONITOR_CHESTS = { treasurechest=1, dragonflychest=1, pandoraschest=1, minotaurchest=1, --skullchest=1,
        --bundle=1, --No container component. =\
        icebox=1, cookpot=1, -- 冰箱、烹饪锅.
        chester=1, hutch=1, beargerfur_sack=1,  --小妾、哈奇、极地熊灌桶
        largechest=1, largeicebox=1, bookstation=1, wardrobe=1, --暗妾(已失效)、冰妾、书架、衣柜.
        safebox=1, safechest=1, safeicebox=1, --Safe mod.
        red_treasure_chest=1, purple_treasure_chest=1, green_treasure_chest=1, blue_treasure_chest=1, --Treasure Chests mod.
        backpack=1, candybag=1, icepack=1, piggyback=1, krampus_sack=1, seedpouch=1, spicepack=1,
        venus_icebox=1, chesterchest=1, --SL mod 
        saltbox=1, wobybig=1, wobysmall=1, mushroom_light=1, mushroom_light2=1, fish_box=1, supertacklecontainer=1, tacklecontainer=1, archive_cookpot=1,
        portablecookpot=1, portablespicer=1, sacred_chest=1, boat_ancient_container=1, --便携锅, 香料站, 远古箱, 古董船
        storeroom=1, alchmy_fur=1, myth_granary=1, hiddenmoonlight=1, coffin=1, grave=1, musha_rpice=1, musha_tallrrrrrice=1, musha_tallrrrrice=1, musha_tallrrrice=1, hiddenmoonlight_inf=1, chest_whitewood_inf=1, chest_whitewood_big_inf=1, --pill_bottle_gourd=1, --丹药葫芦会崩 神话代码加密 无解
        ro_bin=1, roottrunk_child=1, corkchest=1, smelter=1, --Hamlet
        thatchpack=1, packim=1, cargoboat=1, piratepack=1, --SW
    }
    if TUNING.MONITOR_CHESTS then
        for k in pairs(TUNING.MONITOR_CHESTS) do
            MONITOR_CHESTS[k] = 1
        end
    end
    local _active --光标中的当前项目（在客户端上）。
    local _ing_prefab --成分，5 秒后将其移除。
    local net_string = _G.net_string
    local chests_around = {} --客户端可见范围内的所有箱子的数组。 对于主机来说——都是箱子，但这很正常。

    local function OnClose(inst) --,err) --关闭箱子时，我们会向客户端发送有关其内容的新数据。
        local c = inst.components.container
        if not c then
            return
        end
        --if err then
        --    print("Found!!!!! Problem solved",err)
        --end
        if c:IsEmpty() then
            inst[MAIN_VAR_NAME]:set('')
            return
        end
        local arr = {} -- [预制件]=true
        for k,v in pairs(c.slots) do
            arr[tostring(v.prefab)] = true
            local u = v.components and v.components.unwrappable
            if u and u.itemdata then
                for i,v in ipairs(u.itemdata) do
                    arr[v.prefab] = true --将预制件添加到包中。
                end
            end
        end
        local s
        for k in pairs(arr) do
            if s then
                s = s .. ' ' .. k --只有空白字符才可以继续工作。
            else
                s = k
            end
        end
        inst[MAIN_VAR_NAME]:set(s) --发送数据
    end

    --更新箱子高亮，该功能本身必须识别玩家手中的东西。
    local function UpdateChestColor(inst)
        local in_container = inst.ShowMe_chest_table and (
            (_active and inst.ShowMe_chest_table[_active.prefab])
            or (_ing_prefab and inst.ShowMe_chest_table[_ing_prefab])
        )
        if inst.b_ShowMe_changed_color then
            if not in_container then
                if inst.ShowMeColor then
                    inst.ShowMeColor(true)
                else
                    if inst.AnimState ~= nil then
                        inst.AnimState:SetMultColour(1,1,1,1) --默认颜色RGBA
                        inst.AnimState:SetLightOverride(0)
                    end
                    inst.b_ShowMe_changed_color = nil
                end
            end
        else
            if in_container then
                if inst.ShowMeColor then
                    inst.ShowMeColor(false)
                else
                    if inst.AnimState ~= nil then
                        inst.AnimState:SetMultColour(chestR,chestG,chestB,1)
                        inst.AnimState:SetLightOverride(.5)        --给箱子添加光覆盖，让夜间也能看清，50%亮度可以在月圆或去色夜空中还能有显示
                    end
                    inst.b_ShowMe_changed_color = true
                end
            end
        end
    end

    local function OnShowMeChestDirty(inst)
        local str = inst[MAIN_VAR_NAME]:value()
        local t = inst.ShowMe_chest_table
        for k in pairs(t) do
            t[k] = nil
        end
        for w in string.gmatch(str, "%S+") do
            t[w] = true
        end
        UpdateChestColor(inst) --如果其内容发生变化，则重新绘制该特定箱子。
    end

    local function InitChest(inst)
        inst[MAIN_VAR_NAME] = net_string(inst.GUID, NETVAR_NAME, EVENT_NAME )
        if CLIENT_SIDE then
            inst:ListenForEvent(EVENT_NAME, OnShowMeChestDirty)
            chests_around[inst] = true
            inst.ShowMe_chest_table = {}
            inst:ListenForEvent('onremove', function(inst)
                chests_around[inst] = nil
            end)
        end
        if not SERVER_SIDE then
            return
        end
        inst:ListenForEvent("onclose", OnClose)
        inst:ListenForEvent("itemget", OnClose) --用于背包
        --There is inject in SmarterCrockPot!! : ContainerWidget.old_on_item_lose = ContainerWidget.OnItemLose
        inst:ListenForEvent("itemlose", OnClose)
        inst:DoTaskInTime(0,function(inst)
            OnClose(inst) --不仅仅只在关闭时发送数据，毕竟箱子本来可以装东西的。
        end)
    end

    for k in pairs(MONITOR_CHESTS) do    --添加API
        AddPrefabPostInit(k,InitChest)
    end
    --固定玩家以监控光标操作。
    if CLIENT_SIDE then
        local function UpdateAllChestsAround()
            for k in pairs(chests_around) do
                UpdateChestColor(k)
            end
        end
        AddPrefabPostInit("inventory_classified",function(inst)
            inst:ListenForEvent("activedirty", function(inst)
                --print("ACTIVE:",inst._active:value())
                _active = inst._active:value()
                _ing_prefab = nil --一旦拿走物品，配方就会立刻被遗忘。
                UpdateAllChestsAround() --会为每个活动物品或其取消的物品重新绘制所有箱子。
            end)
        end)

        local _ing_task
        local function UpdateIngredientView(player, prefab)
            _ing_prefab = prefab
            UpdateAllChestsAround()
            if _ing_task then
                _ing_task:Cancel()
            end
            _ing_task = player:DoTaskInTime(15,function(inst)
                _ing_prefab = nil
                _ing_task = nil
                UpdateAllChestsAround()
            end)
        end

        local ingredientui = require 'widgets/ingredientui'
        local old_OnGainFocus = ingredientui.OnGainFocus

        function ingredientui:OnGainFocus(...)
            --print("self.ing.texture:", self.ing.texture, type(self.ing.texture))
            --从 self.ing.texture 中提取文件名，并去掉 .tex 扩展名
            --'[^/]+$' 是一个正则表达式，它的含义是：
            --[^/]: 匹配除了 / 之外的任意字符。
            --+: 匹配前面的模式（[^/]）一次或多次。
            --$: 匹配字符串的末尾，就是文件名（包括扩展名）。
            --'%.tex$' 是一个正则表达式，它的含义是：
            --%.: 匹配一个点（.），因为 . 在正则表达式中有特殊含义，所以需要用 % 转义。
            --tex: 匹配字符串 tex。
            --$: 匹配字符串的末尾，gsub('%.tex$', '')是将匹配的.tex转换为空字符串''
            local prefab
            if self.ing and self.ing.texture and type(self.ing.texture) == "string" then
                prefab = self.ing.texture:match('[^/]+$'):gsub('%.tex$', '')
            end
            --处理多层parent
            local function gfpar(obj, visited)
                visited = visited or {}  -- 初始化访问记录表
                if not obj then
                    return nil    --如果 obj 是 nil，表示已经到达链的末尾，返回 nil
                end
                if visited[obj] then
                    return nil  -- 如果已经访问过该对象，避免循环
                end
                visited[obj] = true  -- 标记当前对象为已访问
                if obj.owner then
                    return obj.owner    --如果 obj.owner 存在，直接返回 owner
                end
                return gfpar(obj.parent, visited)  -- 如果没找到owner，则继续递归查找
            end

            -- 使用递归函数, 通过 gfpar(self) 从当前对象 self 开始查找 owner
            local player = gfpar(self)

            if prefab and player then
                --print("INGREDIENT:",prefab)
                UpdateIngredientView(player,prefab)
            end
            if old_OnGainFocus then
                return old_OnGainFocus(self, ...)
            end
        end
    end
end
----------------------------------------

PrefabFiles = { "showme_range" } --加载prefab文件
if Switch("Show_range", true) and TheNet:GetIsServer() then --范围显示功能
    modimport("scripts/showme_range_indicators.lua")
end

if show_naughtiness then --显示淘气值加载的文件
    modimport("scripts/showme_naughtiness.lua")
end
