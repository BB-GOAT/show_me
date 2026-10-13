-- weapon_resist：手持冰杖/睡眠吹箭时，显示目标生物的对应抗性（冰冻值/睡眠值）
local Describe = function(context)
    local viewer = context.player
    local inventory = viewer.components.inventory
    local weapon = inventory and inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if not weapon then
        return nil
    end

    local c = context.entity.components
    local resist = nil --base resist
    local total_resist = nil --base + bonus resist
    local now = nil --amount of current resist
    if weapon.prefab == "icestaff" and c.freezable then
        resist = c.freezable.resistance
        total_resist = c.freezable.ResolveResistance and c.freezable:ResolveResistance() or resist
        if c.freezable.coldness and c.freezable.coldness ~= 0 then
            now = context.utils.round2(total_resist - c.freezable.coldness, 1)
        end
    elseif weapon.prefab == "blowdart_sleep" and c.sleeper then
        resist = c.sleeper.resistance
        total_resist = resist -- there is sleep time bonus but not sleep armor bonus
        if c.sleeper.sleepiness and c.sleeper.sleepiness ~= 0 then
            now = context.utils.round2(total_resist - c.sleeper.sleepiness, 1)
        end
    end

    if not resist then
        return nil
    end
    if total_resist ~= resist then
        resist = resist .. '+' .. context.utils.round2(math.abs(total_resist - resist), 1)
    end
    if now then
        resist = now .. ' / ' .. resist
    end
    return { data_key = "resist", params = { resist } }
end

return {
    viewer_holding = { icestaff = true, blowdart_sleep = true },
    Describe = Describe,
}
