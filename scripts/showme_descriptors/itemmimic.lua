-- itemmimic 组件：拟态物品信息
local Describe = function(self, context)
    if not context.config.server.show_itemmimic or not context.config.client.show_itemmimic then
        return nil
    end

    local remaining, paused
    if self._auto_reveal_task then
        remaining = GetTaskRemaining(self._auto_reveal_task)
    elseif self.reveal_time_remaining then
        -- 暂停状态（被机器人拿起）
        remaining = self.reveal_time_remaining
        paused = true
    end
    if remaining == nil then
        return nil
    end

    return {
        priority = 97,
        data_key = "timer",
        params = { context.utils.round2(remaining), "showme_itemmimic_reveal", paused and 1 or nil },
    }
end

return {
    Describe = Describe,
}
