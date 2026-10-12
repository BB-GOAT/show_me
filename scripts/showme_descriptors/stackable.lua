-- stackable 组件：超大堆叠的实际数量（客户端堆叠数字超过 999 会被截断，此处显示真实值）
local Describe = function(self, context)
    if self.StackSize then
        local n = self:StackSize()
        if n and type(n) == "number" and n > 999 then
            return {
                data_key = "true_number",
                params = { context.utils.round2(n, 0) },
            }
        end
    end
    return nil
end

return {
    Describe = Describe,
}
