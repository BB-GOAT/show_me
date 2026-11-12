-- sanityaura 组件：精神光环
local Describe = function(self, context)
    -- 按原版范围和距离衰减计算当前位置的光环，沿用每分钟换算
    local aura_val = context.utils.round2(self:GetAura(context.player) * TUNING.TOTAL_DAY_TIME * 0.125, 1)
    if aura_val == 0 then
        return nil
    end
    return {
        priority = 97, -- 低于 sanity 确保三维信息在一起显示
        data_key = "sanityaura",
        params = { aura_val },
    }
end

return {
    Describe = Describe
}
