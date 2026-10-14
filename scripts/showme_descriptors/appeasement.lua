-- appeasement 组件：火山献祭价值
local Describe = function(self, context)
    if not TheWorld.state.isdry then -- 仅旱季显示
        return nil
    end
    local value = self.GetValue and self:GetValue()
    if type(value) ~= "number" or value == 0 then
        return nil
    end
    -- 献祭值即火山时间表的偏移段数，1 天 = 16 段
    local days = context.utils.round2(value / 16, 2)
    local sign = days > 0 and "+" or ""
    return { { data_key = "trade_volcano", params = { sign .. days .. context.modenv.SHOWME_STRINGS.days } } }
end

return {
    Describe = Describe,
}