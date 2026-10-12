-- perishable 组件：生物的剩余寿命（腐烂时间当作寿命显示）
local Describe = function(self, context)
    local entity = context.entity
    local c = entity.components
    if c.hunger ~= nil or c.health == nil then
        return nil -- 有 hunger 的生物由 hunger 显示饥饿；无 health 的物品显示腐烂（主瀑布，后续迁入）
    end
    if context.config.client.item_info_mod ~= 0 or self.updatetask == nil then
        return nil
    end

    local time = context.utils.GetPerishTime(entity, c)
    if time == nil then
        return nil
    end
    return {
        priority = 90, -- 与 hunger 互斥，保持原第二位
        data_key = "will_die",
        params = { context.utils.round2(time / TUNING.TOTAL_DAY_TIME, 1) },
    }
end

return {
    Describe = Describe
}
