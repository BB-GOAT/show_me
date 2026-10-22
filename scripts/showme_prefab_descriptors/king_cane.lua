-- king_cane：国王魔杖信息（宝石能力、腐化与恢复时间、技能冷却、基础精神影响）
local Describe = function(context)
    local inst = context.entity
    local corruption = inst.components.corruption
    local strings = context.modenv.SHOWME_STRINGS.king_cane
    local utils = context.utils
    local current = corruption:GetCurrent()
    local entries = {
        { description = string.format(strings.corruption, utils.round2(current, 1), TUNING.KING_CANE_MAX_CORRUPTION) },
    }

    if current > 0 and not corruption:IsCorrupted() and TUNING.KING_CANE_CORRUPTION_DECAY_AMOUNT < 0 then
        local next_decay = math.max(0, corruption.timetodecay)
        local amount = -TUNING.KING_CANE_CORRUPTION_DECAY_AMOUNT
        -- 仅预测停止施法后的恢复；再次施法会重置衰减间隔。
        local clear_time = next_decay + (math.ceil(current / amount) - 1) * TUNING.KING_CANE_CORRUPTION_DECAY_PERIOD
        table.insert(entries, {
            description = string.format(strings.decay, utils.DataTimerFn(math.ceil(next_decay)), utils.DataTimerFn(math.ceil(clear_time))),
        })
    end

    if inst.gem then
        local effect = strings.gem_effects[inst.gem]
        table.insert(entries, {
            description = string.format(strings.gem, utils.GetPrefabFancyName(inst.gem)) .. (effect and " (" .. effect .. ")" or ""),
        })
    else
        table.insert(entries, { description = strings.no_gem })
    end

    local remaining = inst.components.rechargeable:GetTimeToCharge()
    if remaining > 0 then
        table.insert(entries, { description = context.modenv.MY_STRINGS.cooldown .. utils.DataTimerFn(math.ceil(remaining)) })
    end

    local sanity = inst.components.equippable:GetDapperness(context.player, true) * TUNING.SANITY_DAPPERNESS * 60
    table.insert(entries, { data_key = "sanity", params = { utils.round2(sanity, 1) } })

    return entries
end

return {
    Describe = Describe,
}
