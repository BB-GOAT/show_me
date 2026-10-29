-- hunger 组件：生物饥饿
local Describe = function(self, context)
    local entity = context.entity
    if entity.components.grogginess or self:GetPercent() > 0 or entity.prefab ~= "beefalo" then
        return {
            priority = 99, -- 固定在 hp 之后
            data_key = "hunger",
            params = { context.utils.round2(self.current, 0) },
        }
    end
    return nil
end

return {
    Describe = Describe
}
