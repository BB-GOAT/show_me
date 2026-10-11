-- instrument 组件：乐器的生效范围
local Describe = function(self, context)
    if not (type(self.range) == "number" and self.range > 0.4) then
        return nil
    end
    return {
        data_key = "range",
        params = { context.utils.round2(self.range, 0) },
    }
end

return {
    Describe = Describe,
}
