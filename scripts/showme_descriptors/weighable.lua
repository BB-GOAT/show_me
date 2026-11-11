-- weighable 组件：鱼、巨大作物的重量及其在重量范围中的百分比
local function Describe(self, context)
    if context.config.server.show_weight == 2 or context.config.client.show_weight ~= 1 then
        return nil
    end

    local weight = self:GetWeight()
    if not weight then
        return nil -- 普通蔬菜也有此组件，但没有重量值
    end

    local percent
    if self.min_weight and self.max_weight then
        percent = self:GetWeightPercent()
    end
    return {
        data_key = "weight",
        params = {
            context.utils.round2(weight, 2),
            percent and context.utils.round2(percent * 100, 2) or nil,
        },
    }
end

return {
    Describe = Describe,
}
