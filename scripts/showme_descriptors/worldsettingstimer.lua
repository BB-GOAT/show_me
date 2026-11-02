-- worldsettingstimer 组件：世界设置计时器
local REGEN_TIMER_NAME

local function GetRegenTimerName(utils)
    if not REGEN_TIMER_NAME then
        REGEN_TIMER_NAME = utils.Upvaluehelper.GetUpvalue(WorldSettings_ChildSpawner_PreLoad, "CHILDSPAWNER_REGENPERIOD_TIMERNAME")
        assert(REGEN_TIMER_NAME, "[Show Me] 无法获取 CHILDSPAWNER_REGENPERIOD_TIMERNAME")
    end
    return REGEN_TIMER_NAME
end

local Describe = function(self, context)
    if not self.timers then
        return nil
    end
    local entity = context.entity
    local prefab = entity.prefab
    local utils = context.utils

    if prefab == "grass" and entity.components.pickable and entity.components.pickable.transplanted then -- 不显示草壁虎变异倒计时
        return nil
    end

    local regen_name = GetRegenTimerName(utils)

    local entries = {}
    for name, data in pairs(self.timers) do
        if name ~= regen_name and not utils.IsUselessTimer(prefab, name) then
            local tm = self:GetTimeLeft(name)
            local paused = self:IsPaused(name)
            if tm then
                table.insert(entries, { data_key = "timer", params = { utils.round2(tm, 0), name, paused and 1 or nil } })
            elseif self.GetMaxTime then
                local max_tm = self:GetMaxTime(name)
                if max_tm then
                    table.insert(entries, { data_key = "timer", params = { utils.round2(data.maxtime, 0), name, 2 } })
                end
            else
                table.insert(entries, { data_key = "timer", params = { "-", name } })
            end
        end
    end

    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe,
}
