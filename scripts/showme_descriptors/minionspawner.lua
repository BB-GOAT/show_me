-- minionspawner 组件：食人花的眼球草与叶肉进度（仅 lureplant 显示）
local Describe = function(self, context)
    local entity = context.entity
    if entity.prefab ~= "lureplant" then
        return nil
    end
    local o_t = context.modenv.OTHER_TITLES -- 服务器语言：格式化词条
    local utils = context.utils

    local meat_needed = math.ceil(self.maxminions / 2)
    local pm = o_t.lureplant_eyes .. tostring(self.numminions) .. " / " .. tostring(self.maxminions)

    if entity.hibernatetask then
        -- 休眠, 多久长根
        local t = GetTaskRemaining(entity.hibernatetask)
        if t and t > 0 then
            if self.maxminions == 0 then -- 若最大眼球草为0, 倒计时结束就长叶肉
                pm = o_t.lureplant_meat_soon .. utils.DataTimerFn(t)
            else
                pm = pm .. " | " .. o_t.lureplant_wake .. utils.DataTimerFn(t)
            end
        end
    elseif entity.lure == nil and not (entity.components.shelf and entity.components.shelf.itemonshelf) then
        -- 长根了且没有诱饵
        if self.numminions >= meat_needed then
            -- 眼球草够了：下一次 TryRevealBait 就会 SpawnPrefab("plantmeat")
            local wait = 1
            if entity.task then
                local t = GetTaskRemaining(entity.task)
                if t and t > 0 then wait = t end
            end
            pm = pm .. " | " .. o_t.lureplant_meat_soon .. utils.DataTimerFn(wait) -- 叶肉长出时间
        elseif self.spawninprogress and self.nextspawninfo then
            -- 眼球草不够：估算直到凑够 meat_needed 的时间
            local elapsed = GetTime() - self.nextspawninfo.start
            local remaining = math.max(0, self.nextspawninfo.time - elapsed)
            local need = meat_needed - self.numminions
            local avg = (self.minionspawntime.min + self.minionspawntime.max) / 2
            -- 第一只眼球草等 remaining，之后每只平均 avg
            local estimate = remaining + math.max(0, need - 1) * avg
            pm = pm .. " | " .. o_t.lureplant_meat_est .. utils.DataTimerFn(estimate) -- 无法精准，只能大约长肉时间
        end
    end

    return {
        description = pm,
    }
end

return {
    Describe = Describe
}
