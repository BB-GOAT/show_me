-- fueled 组件：建筑燃料（火堆/结构）与服饰、工具耐久
local SPICIAL_STRUCTURES = { campfire = true, coldfire = true } -- 非结构但也显示建筑燃料的火堆类

local function GetFuelTime(self)
    local rate = self.rate * self.rate_modifiers:Get()
    if rate > 0 and rate < math.huge then
        local time = self.currentfuel / rate
        if time >= 0 and time < math.huge then
            return time
        end
    end
end

local Describe = function(self, context)
    local entity = context.entity
    local prefab = entity.prefab
    local utils = context.utils
    local config = context.config.client
    -- show_fuel / show_fueled：客户端显式设置优先，客户端为默认档（true / 3）时跟随服务器设置
    local show_fuel = config.show_fuel
    if show_fuel then
        show_fuel = context.config.server.show_fuel
    end
    local show_fueled = config.show_fueled
    if show_fueled == 3 then
        show_fueled = context.config.server.show_fueled
    end
    local o_t = context.modenv.OTHER_TITLES
    local s_str = context.modenv.SHOWME_STRINGS
    local fuel_time = GetFuelTime(self)
    local percent = " ( " .. math.floor(self:GetPercent() * 100) .. "% )"
    -- 正速率的未使用物品仍预览恢复使用后的时长；零速率或回充时没有耗尽倒计时
    local paused = fuel_time and not self.consuming and " (" .. s_str.paused .. ")" or ""

    local lines = {}

    -- 建筑燃料：火堆类与结构建筑，显示剩余燃烧时间与燃料效率
    if self:GetPercent() > 0 and (SPICIAL_STRUCTURES[prefab] or entity:HasTag("structure")) then
        local time_str = fuel_time and utils.DataTimerFn(fuel_time) or s_str.stopped
        table.insert(lines, o_t.ot_fuel .. time_str .. percent .. paused)
        if show_fuel ~= false and self.bonusmult ~= nil and self.bonusmult > 1 then
            table.insert(lines, o_t.ot_fuelval .. self.bonusmult .. "x")
        end
    end

    -- 服饰/工具耐久：按燃料类型与物品类型决定是否显示
    if show_fueled ~= false and not entity:HasTag("hide_percentage") then
        local s_fval
        if fuel_time then
            local FueledTime = utils.DataTimerFn(fuel_time)
            local FueledDay = tostring(utils.round2(fuel_time / TUNING.TOTAL_DAY_TIME, 2)) .. s_str.days
            if show_fueled == 1 then -- 根据配置，显示不同的样式
                s_fval = o_t.fueled .. FueledTime
            elseif show_fueled == 2 then
                s_fval = o_t.fueled .. FueledDay
            else
                s_fval = o_t.fueled .. FueledTime .. " ( " .. FueledDay .. " )"
            end
            s_fval = s_fval .. paused
        else
            s_fval = o_t.fueled .. s_str.stopped .. percent
        end
        --CAVE, NIGHTMARE, MAGIC, CHEMICAL, WORMLIGHT
        if (self.fueltype == FUELTYPE.USAGE or self.secondaryfueltype == FUELTYPE.USAGE) and not (self.no_sewing or entity:HasTag("heatrock")) then
            table.insert(lines, s_fval)
        elseif self.fueltype == FUELTYPE.CAVE or self.secondaryfueltype == FUELTYPE.CAVE or self.fueltype == FUELTYPE.WORMLIGHT or self.secondaryfueltype == FUELTYPE.WORMLIGHT then
            table.insert(lines, s_fval)
        elseif (self.fueltype == FUELTYPE.NIGHTMARE or self.secondaryfueltype == FUELTYPE.NIGHTMARE) and self.accepting and not (entity:HasTag("pocketwatch") or entity:HasTag("fossil") or entity:HasTag("structure") or entity:HasTag("book")) then
            table.insert(lines, s_fval)
        elseif (self.fueltype == FUELTYPE.MAGIC or self.secondaryfueltype == FUELTYPE.MAGIC) and not (entity:HasTag("structure") or prefab == "miniboatlantern") then
            table.insert(lines, s_fval)
        elseif prefab == "torch" or prefab == "lighter" or prefab == "nightstick" or prefab == "minifan" or prefab == "walking_stick" then
            table.insert(lines, s_fval)
        end
    end

    if #lines == 0 then
        return nil
    end

    return {
        description = table.concat(lines, "\n"),
    }
end

return {
    Describe = Describe
}
