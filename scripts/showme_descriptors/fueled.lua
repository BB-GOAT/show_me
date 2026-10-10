-- fueled 组件：建筑燃料（火堆/结构）与服饰、工具耐久
local SPICIAL_STRUCTURES = { campfire = true, coldfire = true } -- 非结构但也显示建筑燃料的火堆类

---@param self table fueled 组件实例
---@param context table 调度器上下文 { entity, config, utils, modenv }
---@return table|nil result 条目 { priority, description }，无内容时返回 nil
local Describe = function(self, context)
    local entity = context.entity -- 被查看的实体
    local prefab = entity.prefab
    local utils = context.utils -- 共享工具函数
    local config = context.config.server -- 服务器端配置
    local o_t = context.modenv.OTHER_TITLES -- 服务器语言：格式化词条
    local s_str = context.modenv.SHOWME_STRINGS -- 服务器语言：辅助词条

    local lines = {} -- 待拼接的多行文本

    -- 建筑燃料：火堆类与结构建筑，显示剩余燃烧时间与燃料效率
    if self:GetPercent() > 0 and (SPICIAL_STRUCTURES[prefab] or entity:HasTag("structure")) then
        if self.currentfuel ~= nil then
            table.insert(lines, o_t.ot_fuel .. utils.DataTimerFn(self.currentfuel) .. " ( " .. math.floor(self:GetPercent() * 100) .. "% )")
        end
        if config.show_fuel ~= false and self.bonusmult ~= nil and self.bonusmult > 1 then
            table.insert(lines, o_t.ot_fuelval .. self.bonusmult .. "x")
        end
    end

    -- 服饰/工具耐久：按燃料类型与物品类型决定是否显示
    if config.show_fueled ~= false and not entity:HasTag("hide_percentage") then
        local FueledTime = utils.DataTimerFn(self.currentfuel)
        local FueledDay = tostring(utils.round2(self.currentfuel / TUNING.TOTAL_DAY_TIME, 1))
        local FDays = s_str.days
        local s_fval
        if config.show_fueled == 1 then --根据配置，显示不同的样式
            s_fval = o_t.fueled .. FueledTime
        elseif config.show_fueled == 2 then
            s_fval = o_t.fueled .. FueledDay .. FDays
        else
            s_fval = o_t.fueled .. FueledTime .. " ( " .. FueledDay .. FDays .. " )"
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
        priority = 0,
        description = table.concat(lines, "\n"),
    }
end

return {
    Describe = Describe
}
