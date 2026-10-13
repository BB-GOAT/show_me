-- sanityaura 组件：精神光环
local Describe = function(self, context)
    local entity = context.entity
    local viewer = context.player
    local aura_val = self.aurafn and self.aurafn(entity, viewer) or self.aura
    if not aura_val then
        return nil
    end
    if self.fallofffn then -- fallofffn but not distance
        local fall = self.fallofffn(entity, viewer, 99)
        if fall and fall ~= 0 and (fall < 0.98 or fall > 1.02) then
            aura_val = aura_val / fall
        end
    end
    aura_val = context.utils.round2(aura_val * TUNING.TOTAL_DAY_TIME * 0.125, 1) --240 hardcoded. I'm not sure what it is
    if aura_val == 0 then
        return nil
    end
    return {
        priority = 80,
        data_key = "sanityaura",
        params = { aura_val },
    }
end

return {
    Describe = Describe
}
