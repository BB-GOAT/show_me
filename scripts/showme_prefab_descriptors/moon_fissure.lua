-- moon_fissure：天体裂隙：显示对查看者的精神光环效能百分比
local Describe = function(context)
    local sanityaura = context.entity.components.sanityaura
    if not (sanityaura and sanityaura.aurafn) then
        return nil
    end

    local current_sanity = sanityaura.aurafn(context.entity, context.player)
    local max_sanity = 100 / (TUNING.SEG_TIME * 2) -- hardcoded!
    local effectiveness = current_sanity / max_sanity
    return { data_key = "effectiveness", params = { context.utils.round2(effectiveness * 100) } }
end

return {
    Describe = Describe,
}
