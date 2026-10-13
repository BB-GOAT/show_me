-- battlesong_notes：女武神战歌的效果说明（按实体 songdata 表对象分派）
local song_tunings = require("prefabs/battlesongdefs").song_defs

local SONG_HANDLERS = {}
SONG_HANDLERS[song_tunings.battlesong_durability] = function(o_t)
    local mod = TUNING.BATTLESONG_DURABILITY_MOD
    return { description = string.format(o_t.bs_dy, (1 - mod) * 100) .. "%" }
end

SONG_HANDLERS[song_tunings.battlesong_healthgain] = function(o_t)
    local delta = TUNING.BATTLESONG_HEALTHGAIN_DELTA
    local singer = TUNING.BATTLESONG_HEALTHGAIN_DELTA_SINGER
    return { description = string.format(o_t.bs_hp, delta, singer) }
end

SONG_HANDLERS[song_tunings.battlesong_sanitygain] = function(o_t)
    local delta = TUNING.BATTLESONG_SANITYGAIN_DELTA
    return { description = string.format(o_t.bs_san, delta) }
end

SONG_HANDLERS[song_tunings.battlesong_sanityaura] = function(o_t)
    local mod = TUNING.BATTLESONG_NEG_SANITY_AURA_MOD
    return { description = string.format(o_t.bs_desan, (1 - mod) * 100) .. "%" }
end

SONG_HANDLERS[song_tunings.battlesong_fireresistance] = function(o_t)
    local mod = TUNING.BATTLESONG_FIRE_RESIST_MOD
    return { description = string.format(o_t.bs_fire, (1 - mod) * 100) .. "%" }
end

SONG_HANDLERS[song_tunings.battlesong_instant_taunt] = function(o_t)
    return { description = o_t.bs_it }
end

SONG_HANDLERS[song_tunings.battlesong_instant_panic] = function(o_t)
    local panic = TUNING.BATTLESONG_PANIC_TIME
    return { description = string.format(o_t.bs_ip, panic) }
end

SONG_HANDLERS[song_tunings.battlesong_shadowaligned] = function(o_t)
    local bonus = TUNING.BATTLESONG_SHADOWALIGNED_VS_LUNAR_BONUS
    local resist = TUNING.BATTLESONG_SHADOWALIGNED_SHADOW_RESIST
    return {
        { description = string.format(o_t.bs_shadow, (bonus - 1) * 100) .. "%" },
        { description = string.format(o_t.bs_shadow2, (resist - 1) * 100) .. "%" },
    }
end

SONG_HANDLERS[song_tunings.battlesong_lunaraligned] = function(o_t)
    local bonus = TUNING.BATTLESONG_LUNARALIGNED_VS_SHADOW_BONUS
    local resist = TUNING.BATTLESONG_LUNARALIGNED_LUNAR_RESIST
    return {
        { description = string.format(o_t.bs_lunar, (bonus - 1) * 100) .. "%" },
        { description = string.format(o_t.bs_lunar2, (resist - 1) * 100) .. "%" },
    }
end

local Describe = function(context)
    local handler = SONG_HANDLERS[context.entity.songdata]
    if not handler then
        return nil
    end
    return handler(context.modenv.OTHER_TITLES)
end

return {
    fields = { songdata = true },
    Describe = Describe,
}
