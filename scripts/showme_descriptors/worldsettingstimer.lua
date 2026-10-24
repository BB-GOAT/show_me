-- worldsettingstimer 组件：世界设置计时器遍历

local function ShouldShowTimer(self, entity, name)
    if name == "ChildSpawner_RegenPeriod" then
        local spawner = entity.components.childspawner
        -- 满员时仍存有暂停计时；洞外生物也占名额，应急生物与普通生物共用补充计时
        return spawner and spawner.useexternaltimer and spawner.regening
            and not (spawner:IsFull() and spawner:IsEmergencyFull())
            and self:TimerEnabled(name) and self:ActiveTimerExists(name)
    end
    return true
end

local Describe = function(self, context)
    if not self.timers then
        return nil
    end
    local entity = context.entity
    local prefab = entity.prefab
    local utils = context.utils

    if prefab == "grass" and entity.components.pickable and entity.components.pickable.transplanted then -- transplanted 可移植的
        return nil
    end

    local entries = {}
    for name, data in pairs(self.timers) do
        if not utils.IsUselessTimer(prefab, name) and ShouldShowTimer(self, entity, name) then
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
