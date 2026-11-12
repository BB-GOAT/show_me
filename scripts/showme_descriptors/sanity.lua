-- sanity 组件：生物精神
local Describe = function(self, context)
    local maximum = self.GetMaxWithPenalty and self:GetMaxWithPenalty() or self.max
    return {
        priority = 98, -- 固定在 hp/hunger 之后
        data_key = "sanity_character",
        params = { context.utils.round2(self.current, 0), context.utils.round2(maximum, 0) },
    }
end

return {
    Describe = Describe
}
