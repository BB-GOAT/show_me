-- abigail_elixir：阿比盖尔的药水效果（按 potion_tunings 的字段特征识别药水种类）
local Describe = function(context)
    local g_pt = context.entity.potion_tunings
    if not g_pt then
        return nil
    end

    local o_t = context.modenv.OTHER_TITLES
    local SHOWME_STRINGS = context.modenv.SHOWME_STRINGS

    local day_time = TUNING.TOTAL_DAY_TIME or 480  -- 默认值
    local f_duration = TUNING.GHOSTLYELIXIR_FASTREGEN_DURATION or 0

    local entries = {}
    if g_pt.TICK_FN then
        if g_pt.DURATION == f_duration then
            local heal = TUNING.GHOSTLYELIXIR_FASTREGEN_HEALING
            table.insert(entries, { description = string.format(o_t.healthpertick, heal) .. " /" .. o_t.second .. "," .. SHOWME_STRINGS.chixu .. g_pt.DURATION .. o_t.second })
        else
            local heal = TUNING.GHOSTLYELIXIR_SLOWREGEN_HEALING
            table.insert(entries, { description = string.format(o_t.healthpertick, heal) .. " /" .. o_t.second .. "," .. SHOWME_STRINGS.chixu .. g_pt.DURATION / day_time .. SHOWME_STRINGS.days })
        end
    elseif g_pt.ONDETACH then
        table.insert(entries, { description = string.format(o_t.ghost_atk, g_pt.DURATION / day_time) })
    elseif g_pt.speed_hauntable == true then
        local speed_mult = TUNING.GHOSTLYELIXIR_SPEED_LOCO_MULT
        table.insert(entries, { description = string.format(o_t.ghost_sd, (speed_mult - 1) * 100 .. "%", g_pt.DURATION / day_time) })
    elseif g_pt.shield_prefab then
        if g_pt.shield_prefab == "abigailforcefieldretaliation" then
            local retaliation = TUNING.GHOSTLYELIXIR_RETALIATION_DAMAGE
            table.insert(entries, { description = string.format(o_t.ghost_atkf, retaliation) })
        end
        table.insert(entries, { description = string.format(o_t.ghost_shd, g_pt.DURATION / day_time) })
    end
    return entries
end

return {
    fields = { potion_tunings = true },
    Describe = Describe,
}
