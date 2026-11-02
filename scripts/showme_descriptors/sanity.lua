-- sanity 组件：生物精神
local Describe = function(self, context)
    return {
        priority = 98, -- 固定在 hp/hunger 之后
        data_key = "sanity_character",
        params = { context.utils.round2(self.current, 1), context.utils.round2(self.max, 1) },
    }
end

return {
    Describe = Describe
}
