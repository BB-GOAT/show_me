-- special_weapon_notes：蝙蝠杖/废墟蝙蝠杖/废墟帽/盐调料 的专属说明
local Describe = function(context)
    local o_t = context.modenv.OTHER_TITLES
    local D = {}

    D.batbat = function()
        local drain = TUNING.BATBAT_DRAIN
        return { description = string.format(o_t.batbat, drain, -0.5 * drain) }
    end

    D.ruins_bat = function()
        local level = TUNING.RUINS_BAT_SHADOW_LEVEL
        return { description = string.format(o_t.ruins_bat, level * 10) .. "%" }
    end

    D.ruinshat = function()
        local level = TUNING.RUINSHAT_SHADOW_LEVEL -- 保证 (level+1.3) 非负
        return { description = string.format(o_t.ruinshat, (level + 1.3) * 10) .. "%" }
    end

    D.spice_salt = function()
        local health = TUNING.SPICE_MULTIPLIERS.SPICE_SALT.HEALTH
        return { description = string.format(o_t.spice_salt, health * 100) .. "%" }
    end

    local handler = D[context.entity.prefab]
    return handler and handler()
end

return {
    prefabs = { batbat = true, ruins_bat = true, ruinshat = true, spice_salt = true },
    Describe = Describe,
}
