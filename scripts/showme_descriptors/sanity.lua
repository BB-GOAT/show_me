-- sanity 组件：生物精神
local Describe = function(self, context)
    return {
        priority = 80, -- 固定在 hp/hunger 之后
        data_key = "sanity_character",
        params = { context.utils.round2(math.floor(self:GetPercent() * 100 + 0.5), 1) },
    }
end

return {
    Describe = Describe
}
