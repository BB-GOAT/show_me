-- renderers：MY_DATA 条目的渲染函数与 fn 装配
local tonumber = _G.tonumber

-- 浮点数处理副本：round2 定义仍由 modmain2 骨架持有（不在迁移区间内，local 亦不经 env 共享），故此处自带同实现副本
local round2 = function(num, idp)    -- num处理的目标数字, idp保留的小数位数
    return _G.tonumber(string.format("%." .. (idp or 0) .. "f", num)) -- 例如：idp传入数字为2，则连接字符串是 %.2f
end

-- 实时配置表
local live_config

local function SetConfigTable(config_table)
    live_config = config_table
end

local function GetRenderConfig(config_name)
    if live_config ~= nil then
        return live_config[config_name]
    end
    return GetModConfigData(config_name, true)
end

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
    return string.format(OTHER_TITLES.nutrient, arr.param[1] or 0, arr.param[2] or 0, arr.param[3] or 0, arr.param[4] or 0)
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
            .. (days ~= '0' and SHOWME_STRINGS.chixu .. tostring(days) .. SHOWME_STRINGS.days or '')
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
    local food_order = GetRenderConfig("food_order")
    local food_style = GetRenderConfig("food_style")
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
--工具可用度：前缀用自身 desc（MY_STRINGS.uses_of），后接 当前/总次数
MY_DATA.uses_of.fn = function(arr)
    return arr.data.desc .. arr.param[1] .. "/" .. arr.param[2]
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

    local perish_style = GetRenderConfig("perish_style")
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

return {
    DataTimerFn = DataTimerFn,
    GetPrefabFancyName = GetPrefabFancyName,
    DefaultDisplayFn = DefaultDisplayFn,
    SetConfigTable = SetConfigTable,
}
