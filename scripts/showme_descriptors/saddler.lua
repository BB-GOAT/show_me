-- saddler 组件：鞍具的加速与额外伤害
local Describe = function(self, context)
    local entries = {}
    if self.speedmult and self.speedmult ~= 0 then
        local added_speed = math.floor((self.speedmult - 1) * 100 + 0.5) -- (1.4 - 1) == 0.4
        table.insert(entries, { data_key = "speed", params = { added_speed } })
    end
    if self.bonusdamage and self.bonusdamage ~= 0 then
        table.insert(entries, {
            data_key = "dmg_bonus",
            params = { context.utils.round2(self.bonusdamage, 1) },
        })
    end
    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe,
}
