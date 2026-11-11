-- world_gauge：雨量计预测降雨、停雨与青蛙雨，温度计显示世界温度
local SEASON_CYCLES = {
    forest = { "autumn", "winter", "spring", "summer" }, -- 森林、洞穴
    shipwrecked = { "mild", "wet", "green", "dry" }, -- 海难、火山（岛屿冒险）
    plateau = { "temperate", "humid", "lush" }, -- 猪镇（云霄国度）
}
local MOISTURE_RATES = { -- 各季节的积水曲线参数，单位：水分/秒；负数表示蒸发
    autumn = { .25, 1 }, winter = { .25, 1 },
    spring = { 3, 3.75 }, summer = { .1, .5 },
    mild = { 0, .1 }, wet = { 3, 3.75 }, green = { 3, 3.75 }, dry = { 0, -.2 },
    temperate = { .25, 1 }, humid = { 3, 3.75 }, lush = { 0, -.2 }, aporkalypse = { 0, 0 },
}
local FORECAST_KEYS = { "rain_start", "rain_stop", "frog_start", "frog_stop" }
local initialized = false
local kind -- 世界天气类型：forest 原版、shipwrecked 海难、plateau 猪镇
local cycle -- 当前世界的季节循环顺序
local weather -- 当前世界的天气组件，用于读取水分、雨势及风暴状态
local frograin -- 青蛙雨组件
local aporkalypse -- 云霄国度大灾变组件
local GetSeasons -- 季节读取函数，将不同世界的数据统一为标准字段

-- 首次查看雨量计时绑定天气组件与季节读取方式，后续直接复用
local function Init(world)
    local components = world.ismastersim and world.net and world.net.components -- 世界网络组件表
    kind = components and (components.plateauweather and "plateau" or components.shipwreckedweather and "shipwrecked" or "forest")
    cycle = SEASON_CYCLES[kind]
    weather = components and (components.plateauweather or components.shipwreckedweather or components.weather) -- 天气组件
    frograin = world.ismastersim and world.components.frograin -- 青蛙雨组件
    aporkalypse = kind == "plateau" and components.aporkalypse -- 猪镇大灾变可能打断未来积水
    GetSeasons = nil
    if not weather or not weather.OnSave then weather = nil return end -- 无服务端接口时只显示原有读数
    local component = components.seasons -- 季节组件
    if not component then return end
    local clock = kind == "shipwrecked" and "tropical" or kind == "plateau" and "plateau" or "default" -- 选择对应世界的季节时钟
    local save = component["OnSave_" .. clock] or component.OnSave -- 优先独立时钟接口，否则读取总存档
    GetSeasons = function() return save(component) end
    -- 独立接口和标准字段可直接读取；合并多时钟的存档需要去掉字段后缀
    if component["OnSave_" .. clock] or clock == "default" or not save(component)["season" .. clock] then return end
    local fields = {}
    for _, key in ipairs({ "season", "mode", "premode", "totaldaysinseason", "remainingdaysinseason", "elapseddaysinseason", "lengths" }) do
        fields[key] = key .. clock -- 如 seasontropical，统一映射回 season
    end
    GetSeasons = function()
        local data, result = save(component), {}
        for key, source in pairs(fields) do result[key] = data[source] end -- 后续算法只处理统一字段
        return result
    end
end

-- 按当前世界的顺序查找下一季，跳过长度为 0 的季节
local function NextSeason(season, lengths)
    for index, name in ipairs(cycle) do
        if name == season then
            for offset = 1, #cycle do
                local nextseason = cycle[(index + offset - 1) % #cycle + 1]
                if (lengths[nextseason] or 0) > 0 then return nextseason end
            end
            return season -- 没有可用的下一季时保留当前季节
        end
    end
end

-- 首日使用服务端实际速率，后续计入季节与降雨倍率
-- 返回：降雨剩余秒数；第二返回值仅在未来风暴日期未知、需要提示玩家时为 true
local function PredictRainStart(data, seasons, time)
    local needed = data.moistureceil - data.moisture -- 积水达到上限就开始降水
    if needed <= 0 then return 0 end -- 已满足触发水量，等待天气组件更新
    local rate = data.moisturerate -- 当前当天的实际速率，已包含倍率和特殊日加成
    if not seasons or seasons.season ~= data.season then
        return rate > 0 and needed / rate or nil -- 缺少匹配的季节信息时，只能按当前速率估算
    end

    local season = seasons.season
    local remaining = seasons.remainingdaysinseason -- 当前季节剩余天数，含今天
    local total = seasons.totaldaysinseason -- 计算季节进度使用的总天数
    local elapsed = seasons.elapseddaysinseason -- 当前季节已过的整天数
    local mode, premode = seasons.mode, seasons.premode -- cycle 循环；always 永久；endless 过渡后永久；premode 为过渡阶段
    local duration = (1 - time) * TUNING.TOTAL_DAY_TIME -- 首轮只计算今天剩余时间，time 为当天进度 0～1
    local seconds = 0 -- 已向未来推算的秒数
    local floor = kind == "shipwrecked" and data.moisturefloor or 0 -- 海难蒸发到水分下限，其余世界最低为 0
    -- 限制异常天气倍率或第三方季节数据造成的预测开销
    for _ = 1, 1024 do
        if rate > 0 and needed <= rate * duration then
            return seconds + needed / rate -- 能在本日积满，补上当天所需的部分时间
        end
        needed = math.min(data.moistureceil - floor, needed - rate * duration) -- 结算本日积水或蒸发，不低于水分下限
        seconds = seconds + duration
        elapsed = elapsed + 1
        if mode == "cycle" or premode then -- 循环季节和过渡阶段会真正切换季节
            remaining = remaining - 1
            if remaining <= 0 then
                -- 猪镇的灾变结束会恢复此前的季节，不能按普通季节顺序外推
                if season == "aporkalypse" then return end
                season = NextSeason(season, seasons.lengths)
                if not season then return end
                -- 下一轮温和季的预告风暴日期尚未随机确定
                if season == "mild" then return nil, true end -- 不能把更晚的普通积水时间当成下一场雨
                total = mode == "endless" and 20 or seasons.lengths[season] -- 无尽季节先用 20 天完成进度过渡
                remaining, elapsed, premode = total, 0, false
            end
        elseif mode == "endless" and remaining > 10 then
            remaining = math.max(remaining - 1, 10) -- 无尽季节到中点后不再推进进度；always 则始终保持原进度
        end
        local limits = MOISTURE_RATES[season]
        if not limits or not total or total <= 0 then return end
        if season == "winter" and elapsed == 2 then
            rate = 50 -- 冬季第 3 天固定加水 50/秒，不受降雨倍率影响
        elseif season == "green" and elapsed <= 5 then
            rate = 0 -- 海难雨季前 5 天不积水，短雨季也能继续跨季预测
        else
            local progress = 1 - remaining / total
            if season == "green" then
                local length = seasons.lengths.green
                if not length or length <= 5 then return end
                progress = (elapsed - 5) / (length - 5) -- 雨季曲线从延迟结束后起算
            elseif season == "wet" or season == "humid" then
                progress = progress * 1.5 -- 海难飓风季、猪镇潮湿季的曲线推进更快
            end
            rate = limits[1] + (1 - math.sin(math.pi * progress)) * (limits[2] - limits[1]) -- 与天气组件相同的季节积水曲线
            rate = rate * data.moistureratemultiplier
        end
        duration = TUNING.TOTAL_DAY_TIME -- 从下一轮开始，每轮计算完整一天
    end
end

-- 与原版相同的雨势曲线。数值积分直接求到目标水分的时间，避免逐帧模拟整场雨
local function TimeToMoisture(data, target)
    local range = data.moistureceil - data.moisturefloor -- 一场普通雨可消耗的水分跨度
    local upper = math.min(1, (data.moisture - data.moisturefloor) / range) -- 当前水分归一化到 0～1
    local lower = math.max(0, (target - data.moisturefloor) / range) -- 目标水分；停雨时取下限，青蛙雨取阶段阈值
    if upper <= lower then return 0 end
    local peak = data.peakprecipitationrate -- 本场雨随机确定的峰值，使用服务端原值，不做取整
    -- 猪镇繁茂季的微雨可能全程低于基础雨势，此时直接计算匀速耗水时间
    if peak <= .1 then return (upper - lower) * range / (peak * 10) end
    local steps = 256 -- 固定偶数分段，用辛普森法积分 dt = 水分变化 / 耗水速率
    local step = (upper - lower) / steps
    local sum = 0
    for i = 0, steps do
        local moisturefraction = lower + i * step
        local rate = math.min(.1 + .9 * math.sin(moisturefraction * math.pi), peak) -- 雨势呈正弦变化，同时受本场峰值限制
        local weight = (i == 0 or i == steps) and 1 or (i % 2 == 0 and 2 or 4) -- 积分权重依次为 1、4、2、4…1
        sum = sum + weight / rate
    end
    return sum * step / 3 * range / 10 -- 实际耗水速率为雨势 × 10，结果单位为秒
end

-- 返回离开当前季节的秒数和下一季；永久或同季循环不需要截断预测
local function TimeToSeasonChange(seasons, time)
    if seasons and (seasons.mode == "cycle" or seasons.premode) then
        local nextseason = NextSeason(seasons.season, seasons.lengths)
        if nextseason and nextseason ~= seasons.season then
            return math.max(0, (seasons.remainingdaysinseason - time) * TUNING.TOTAL_DAY_TIME), nextseason
        end
    end
    return math.huge -- 无明确季节边界时，取最小值不会缩短原有倒计时
end

-- 永久季节的季节事件使用剩余 10000 天，需按实际进度反推预告风暴日期
local function TimeToHurricaneTease(data, seasons, time)
    local percent = data.hurricanetease_start -- 本轮温和季已随机确定的预告风暴触发进度
    if data.season ~= "mild" or not percent or percent <= 0 or data.hurricanetease_started
        or not seasons or seasons.season ~= "mild" then return end
    local elapsed = seasons.elapseddaysinseason
    local day
    if seasons.mode == "cycle" or seasons.premode then
        day = math.ceil((elapsed + seasons.remainingdaysinseason) * percent) -- 只在每日季节事件中更新进度，因此向上取整到天
    elseif percent < 1 then
        day = math.ceil(10000 * percent / (1 - percent)) -- 解 elapsed / (elapsed + 10000) >= percent
    else
        return -- 永久季节的真实进度达不到 1
    end
    return math.max(0, (day - elapsed - time) * TUNING.TOTAL_DAY_TIME)
end

-- 按当前天气选择预测分支；结果中的数值统一为剩余秒数，未赋值的条目不显示
local function GetForecast(state, data, seasons)
    local result = {}
    if data.precipmode == "dynamic" then -- 仅预测自然变化模式，强制常雨或禁雨不提供倒计时
        if data.preciptype == "none" and data.moistureceil > 0 then -- 未降水：先估算普通积水，再检查会提前触发的事件
            result.rain_start, result.rain_start_unknown = PredictRainStart(data, seasons, state.time)
            -- 温和季的预告风暴有独立触发日期，可能比普通积水更早开始降雨
            local seconds = TimeToHurricaneTease(data, seasons, state.time)
            if seconds then
                result.rain_start = math.min(result.rain_start or math.huge, seconds) -- 普通积水与已知风暴，谁先到就采用谁
            end
            if result.rain_start and aporkalypse then
                local apocalypse = aporkalypse:OnSave() -- 自然灾变会改变积水速率，拨日历时触发时间也不确定
                if aporkalypse.rewind_mult ~= 0 or not apocalypse.activeaporkalypse
                    and apocalypse.timeuntilaporkalypse <= result.rain_start then
                    result.rain_start = nil -- 不显示跨越灾变的普通季节预测
                end
            end
        elseif data.preciptype == "rain" and data.hurricane_duration then -- 风暴雨：使用已确定的风暴计时
            -- 飓风期间水分不按雨势消耗，停雨由独立的风暴计时器决定
            result.rain_stop = math.max(0, data.hurricane_duration - data.hurricane_timer)
            local seconds, nextseason = TimeToSeasonChange(seasons, state.time)
            if nextseason ~= "wet" then result.rain_stop = math.min(result.rain_stop, seconds) end -- 进入飓风季可延续风暴，其余换季会结束风暴
        elseif data.preciptype == "rain" and data.moistureceil > data.moisturefloor
            and data.peakprecipitationrate > 0 then
            result.rain_stop = TimeToMoisture(data, data.moisturefloor) -- 普通雨耗水到下限时停雨
            if kind == "shipwrecked" then
                -- 普通雨被风暴接管后会重置耗水过程，接管前不显示跨越它的停雨预测
                local seconds, nextseason = TimeToSeasonChange(seasons, state.time)
                if data.season == "wet" or (TimeToHurricaneTease(data, seasons, state.time) or math.huge) <= result.rain_stop
                    or nextseason == "wet" and seconds <= result.rain_stop then
                    result.rain_stop = nil
                end
            end
            local threshold = TUNING.FROG_RAIN_PRECIPITATION -- 青蛙雨要求实际雨势严格大于此阈值
            if kind == "forest" and state.isspring and TUNING.FROG_RAIN_CHANCE > 0
                and data.moistureceil > TUNING.FROG_RAIN_MOISTURE
                and data.peakprecipitationrate > threshold and threshold >= .1 and threshold < 1
                and frograin and frograin:OnSave().frogcap > 0 then -- 本场已抽中，且水量、雨势峰值均满足条件
                local thresholdfraction = math.asin((threshold - .1) / .9) / math.pi -- 反解雨势阈值，得到对称的两个水分交点
                local range = data.moistureceil - data.moisturefloor
                local startmoisture = data.moisturefloor + (1 - thresholdfraction) * range -- 耗水到此处时，雨势增强到刷蛙阈值
                local stopmoisture = data.moisturefloor + thresholdfraction * range -- 继续耗水到此处时，雨势衰减并停止刷蛙
                local springtime = TimeToSeasonChange(seasons, state.time) -- 离开春季也会提前结束刷蛙阶段
                if data.moisture >= startmoisture then
                    local seconds = TimeToMoisture(data, startmoisture)
                    if seconds < springtime then result.frog_start = seconds end -- 开始前春季已结束，就不显示即将到来
                elseif data.moisture > stopmoisture then
                    result.frog_stop = math.min(TimeToMoisture(data, stopmoisture), springtime)
                end
                -- 已低于停止阈值时，即使仍在下雨，也不再显示青蛙雨信息
            end
        end
    end
    return result
end

local Describe = function(context)
    local state = TheWorld.state
    if context.entity.prefab == "rainometer" then -- 雨量计
        if not initialized then
            Init(TheWorld)
            initialized = true -- 只复用组件与读取方式，下面仍会读取最新天气数据
        end
        -- 降雨速率经 inSine 缓动换算成表针角度对应的显示值
        local entries = {
            { data_key = "precipitationrate", params = { context.utils.round2(.75 * (1 - math.cos(state.precipitationrate * math.pi / 2)), 3) .. "/s" } },
            { data_key = "wetness", params = { context.utils.round2(state.wetness, 1) } },
        }
        if not weather then return entries end

        local data = weather:OnSave() -- 读取组件当前内部状态，包含水分、峰值、天气模式及风暴计时
        local seasons = GetSeasons and data.precipmode == "dynamic"
            and (data.preciptype == "none" or kind == "shipwrecked" or data.hurricane_duration or state.isspring) and GetSeasons() -- 仅在预测涉及季节边界时读取
        local forecast = GetForecast(state, data, seasons)
        local strings = context.modenv.SHOWME_STRINGS
        if forecast.rain_start_unknown and not forecast.rain_start then -- 已知当前风暴时间时，数字倒计时优先于未知提示
            table.insert(entries, { description = strings.rain_start_unknown })
        end
        for _, key in ipairs(FORECAST_KEYS) do
            local seconds = forecast[key]
            if seconds then
                table.insert(entries, {
                    description = string.format(strings[key], context.utils.DataTimerFn(math.ceil(seconds))), -- 向上取整为秒，再交给统一时间格式化
                })
            end
        end
        if kind == "forest" and state.isspring and data.preciptype == "none" and frograin and TUNING.FROG_RAIN_CHANCE > 0 then
            -- 未下雨时尚未抽签，只说明水分条件；禁用青蛙雨时不显示青蛙雨相关信息
            table.insert(entries, {
                description = data.moistureceil > TUNING.FROG_RAIN_MOISTURE
                    and strings.frog_moisture_enough or strings.frog_moisture_low,
            })
        end
        return entries
    end

    -- winterometer 温度计
    return { data_key = "temperature", params = { context.utils.round2(state.temperature, 1) } }
end

return {
    prefabs = { rainometer = true, winterometer = true }, -- 雨量计 / 温度计
    Describe = Describe,
}
