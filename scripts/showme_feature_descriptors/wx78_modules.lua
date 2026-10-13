-- wx78_modules：WX-78 模块的属性增强说明
local Describe = function(context)
    local o_t = context.modenv.OTHER_TITLES
    local utils = context.utils
    local D = {}

    D.wx78module_maxhealth = function()
        local boost = TUNING.WX78_MAXHEALTH_BOOST
        local mult = 1 -- 默认
        return { description = string.format(o_t.maxhealth, boost * mult) }
    end

    D.wx78module_maxhealth2 = function()
        local boost = TUNING.WX78_MAXHEALTH_BOOST
        local mult = TUNING.WX78_MAXHEALTH2_MULT
        return { description = string.format(o_t.maxhealth, boost * mult) }
    end

    D.wx78module_maxsanity = function()
        local boost = TUNING.WX78_MAXSANITY_BOOST
        local dapper = TUNING.WX78_MAXSANITY_DAPPERNESS
        return {
            { data_key = "sanity", params = { utils.round2(dapper * 60) } },
            { description = string.format(o_t.maxsanity, boost) },
        }
    end

    D.wx78module_maxsanity1 = function()
        local boost = TUNING.WX78_MAXSANITY1_BOOST
        return { description = string.format(o_t.maxsanity, boost) }
    end

    D.wx78module_maxhunger = function()
        local boost = TUNING.WX78_MAXHUNGER_BOOST
        local slow = TUNING.WX78_MAXHUNGER_SLOWPERCENT
        return {
            { description = string.format(o_t.maxhunger, boost) },
            { description = string.format(o_t.hungerslow, (1 - slow) * 100 .. "%") },
        }
    end

    D.wx78module_maxhunger1 = function()
        local boost = TUNING.WX78_MAXHUNGER1_BOOST
        return { description = string.format(o_t.maxhunger, boost) }
    end

    D.wx78module_movespeed = function()
        local added = math.floor(TUNING.WILSON_RUN_SPEED * 4 + 1)
        return { { data_key = "speed", params = { added } } }
    end

    D.wx78module_movespeed2 = function()
        local added = math.floor(TUNING.WILSON_RUN_SPEED * 4 + 1)
        return {
            { data_key = "speed", params = { added } },
            { data_key = "other_tag", params = { "wx78_movespeed2" } },
        }
    end

    D.wx78module_bee = function()
        local dapper = TUNING.WX78_MAXSANITY_DAPPERNESS
        local health_pertick = TUNING.WX78_BEE_HEALTHPERTICK
        local tick_period = TUNING.WX78_BEE_TICKPERIOD
        local sanity_boost = TUNING.WX78_MAXSANITY_BOOST
        return {
            { data_key = "sanity", params = { utils.round2(dapper * 60) } },
            { description = string.format(o_t.healthpertick, health_pertick) .. " / " .. tick_period .. o_t.second },
            { description = string.format(o_t.maxsanity, sanity_boost) },
        }
    end

    D.wx78module_music = function()
        local aura = TUNING.WX78_MUSIC_SANITYAURA
        return {
            { data_key = "sanity", params = { utils.round2(aura * 60, 1) } },
            { data_key = "other_tag", params = { "wx78_music" } },
        }
    end

    D.wx78module_heat = function()
        local hot_rate = TUNING.WX78_PERISH_HOTRATE
        return {
            { data_key = "other_tag", params = { "wx78_moisture" } },
            { data_key = "other_tag", params = { "wx78_heat" } },
            { description = string.format(o_t.wx78_hot_cold, "+" .. (hot_rate - 1) * 100 .. "%") },
        }
    end

    D.wx78module_cold = function()
        local cold_rate = TUNING.WX78_PERISH_COLDRATE
        local ice_moist = TUNING.WX78_COLD_ICEMOISTURE
        return {
            { data_key = "other_tag", params = { "wx78_cold" } },
            { description = string.format(o_t.wx78_hot_cold, (cold_rate - 1) * 100 .. "%") },
            { description = string.format(o_t.wx78_cold3, ice_moist .. "%") },
        }
    end

    local handler = D[context.entity.prefab]
    return handler and handler()
end

return {
    prefabs = {
        wx78module_maxhealth = true, wx78module_maxhealth2 = true, wx78module_maxsanity = true,
        wx78module_maxsanity1 = true, wx78module_maxhunger = true, wx78module_maxhunger1 = true,
        wx78module_movespeed = true, wx78module_movespeed2 = true, wx78module_bee = true,
        wx78module_music = true, wx78module_heat = true, wx78module_cold = true,
    },
    Describe = Describe,
}
