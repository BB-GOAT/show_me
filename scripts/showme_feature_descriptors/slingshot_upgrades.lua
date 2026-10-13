-- slingshot_upgrades：弹弓升级件（特殊弹药变体与皮筋）的专属说明
local Describe = function(context)
    local o_t = context.modenv.OTHER_TITLES
    local D = {}

    D.slingshotammo_slow = function()
        local mult = TUNING.SLINGSHOT_AMMO_MOVESPEED_MULT
        local dur  = TUNING.SLINGSHOT_AMMO_MOVESPEED_DURATION
        local percent = math.ceil((mult - 1) * 100)
        return { description = string.format(o_t.sammo_slow, percent .. "%", dur) }
    end

    D.slingshotammo_honey = function()
        local penalty = TUNING.BEEQUEEN_HONEYTRAIL_SPEED_PENALTY
        return { description = string.format(o_t.sammo_honey, math.ceil((penalty - 1) * 100) .. "%") }
    end

    D.slingshotammo_purebrilliance = function()
        local planar = TUNING.SLINGSHOT_BRILLIANCE_MARK_PLANAR_DAMAGE
        local timeout = TUNING.SLINGSHOT_BRILLIANCE_MARK_TIMEOUT
        return { description = string.format(o_t.mpl_hit, planar, timeout) }
    end

    D.slingshotammo_horrorfuel = function()
        local planar = TUNING.SLINGSHOT_HORROR_PLANAR_DAMAGE
        local ticks  = TUNING.SLINGSHOT_HORROR_TICKS
        return { description = string.format(o_t.shf_hit, planar, ticks) }
    end

    D.slingshotammo_stinger = function()
        local aoe = TUNING.SLINGSHOT_AMMO_DAMAGE_STINGER_AOE
        return { { data_key = "aoe", params = { aoe } } }
    end

    D.slingshotammo_moonglass = function()
        local aoe = TUNING.SLINGSHOT_AMMO_DAMAGE_MOONGLASS_AOE
        return { { data_key = "aoe", params = { aoe } } }
    end

    D.slingshot_band_pigskin = function()
        local range = TUNING.SLINGSHOT_MOD_BONUS_RANGE_1
        local speed = TUNING.SLINGSHOT_MOD_SPEED_MULT_1
        return {
            { description = string.format(o_t.slingshot_range, range) },
            { description = string.format(o_t.ammo_speed, speed) },
        }
    end

    D.slingshot_band_tentacle = function()
        local range = TUNING.SLINGSHOT_MOD_BONUS_RANGE_2
        local speed = TUNING.SLINGSHOT_MOD_SPEED_MULT_2
        return {
            { description = string.format(o_t.slingshot_range, range) },
            { description = string.format(o_t.ammo_speed, speed) },
        }
    end

    D.slingshot_band_mimic = function()
        local range = TUNING.SLINGSHOT_MOD_BONUS_RANGE_2
        local speed = TUNING.SLINGSHOT_MOD_SPEED_MULT_2
        local chance = TUNING.SLINGSHOT_MOD_FREE_AMMO_CHANCE
        return {
            { description = string.format(o_t.slingshot_range, range) },
            { description = string.format(o_t.ammo_speed, speed) },
            { description = string.format(o_t.slingshot_speed, chance * 100 .. "%") },
        }
    end

    local handler = D[context.entity.prefab]
    return handler and handler()
end

return {
    prefabs = {
        slingshotammo_slow = true, slingshotammo_honey = true, slingshotammo_purebrilliance = true,
        slingshotammo_horrorfuel = true, slingshotammo_stinger = true, slingshotammo_moonglass = true,
        slingshot_band_pigskin = true, slingshot_band_tentacle = true, slingshot_band_mimic = true,
    },
    Describe = Describe,
}
