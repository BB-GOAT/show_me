-- cooldown 组件：充能类物品的剩余冷却时间
local Describe = function(self, context)
    if not (self.GetTimeToCharged and not self.charged) then
        return nil
    end
    return {
        data_key = "cooldown",
        params = { context.utils.round2(self:GetTimeToCharged(), 0) },
    }
end

return {
    Describe = Describe,
}
