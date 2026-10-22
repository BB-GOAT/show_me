-- hungerslow：装备的饥饿减缓显示
local SLOW_TUNING = {
    beargervest = "ARMORBEARGER_SLOW_HUNGER",
    armorslurper = "ARMORSLURPER_SLOW_HUNGER",
    hat_albicans_mushroom = "ARMORSLURPER_SLOW_HUNGER",
    red_mushroomhat = "MUSHROOMHAT_SLOW_HUNGER",
    green_mushroomhat = "MUSHROOMHAT_SLOW_HUNGER",
    blue_mushroomhat = "MUSHROOMHAT_SLOW_HUNGER",
}

local Describe = function(context)
    local tuning_key = SLOW_TUNING[context.entity.prefab]
    if not tuning_key then
        return nil
    end
    local o_t = context.modenv.OTHER_TITLES
    return { description = string.format(o_t.hungerslow, (1 - TUNING[tuning_key]) * 100) .. "%" }
end

return {
    prefabs = { beargervest = true, armorslurper = true, hat_albicans_mushroom = true, red_mushroomhat = true, green_mushroomhat = true, blue_mushroomhat = true },
    Describe = Describe,
}
