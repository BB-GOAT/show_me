-- shadow_battleaxe：暗影槌
local Describe = function(context)
    local inst = context.entity
    local o_t = context.modenv.OTHER_TITLES
    local max_level = #TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS

    -- How many bosses we've killed on this threshold level.
    local this_level_boss_kills = 0
    -- The number of bosses that need to be killed to reach the next level.
    local boss_kills_for_next_level = 0
    if inst.level < max_level then
        this_level_boss_kills = inst.epic_kill_count - TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS[inst.level]
        boss_kills_for_next_level = TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS[inst.level + 1] - TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS[inst.level]
    end

    local level_string = string.format(o_t.level .. "%s / %s",
        inst.level,
        max_level
    )
    local boss_progress_string

    if boss_kills_for_next_level > 0 then
        boss_progress_string = string.format(o_t.kills .. "BOSS: %s / %s",
            this_level_boss_kills,
            boss_kills_for_next_level
        )
    end

    -- 吸血信息
    local lifesteal_info
    if inst._lifesteal > 0 then
        lifesteal_info = string.format(o_t.life_stealing .. "%.2f (" .. context.modenv.MY_DATA.sanity.desc .. "%.2f)",
            inst._lifesteal,
            -inst._lifesteal * TUNING.SHADOW_BATTLEAXE.LIFE_STEAL_SANITY_LOSS_SCALE
        )
    end

    -- 汇总信息
    local description
    if lifesteal_info then
        description = lifesteal_info .. "\n" .. level_string
    else
        description = level_string
    end
    if boss_progress_string then
        description = description .. " | " .. boss_progress_string
    end

    return { description = description }
end

return {
    Describe = Describe,
}
