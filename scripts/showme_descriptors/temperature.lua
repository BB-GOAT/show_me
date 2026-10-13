-- temperature 组件：实体当前温度
local Describe = function(self, context)
    if not (self.current and type(self.current) == "number") then
        return nil
    end
    return {
        data_key = "temperature",
        params = { context.utils.round2(self.current, 1) },
    }
end

return {
    Describe = Describe,
}
