-- timer 组件：实体自定义计时器遍历（黑名单过滤后逐条显示）
local Describe = function(self, context)
    if not self.timers then
        return nil
    end
    local entity = context.entity
    local prefab = entity.prefab
    local utils = context.utils

    -- 宠物的计时器是内部机制，不显示
    if entity:HasTag("critter") then
        return nil
    end

    local entries = {}
    for name in pairs(self.timers) do
        if not utils.IsUselessTimer(prefab, name) then
            local tm = self:GetTimeLeft(name)
            local paused = self:IsPaused(name)
            if tm then
                table.insert(entries, { data_key = "timer", params = { utils.round2(tm, 0), name, paused and 1 or nil } })
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
