-- hackable 组件：岛屿冒险可砍伐植物（竹丛/藤蔓丛等）的重新生长倒计时与移植后剩余次数
local Describe = function(self, context)
    local entries = {}
    local utils = context.utils

    if self.targettime then
        local delta = self.targettime - GetTime()
        if delta > 0 then
            table.insert(entries, { data_key = "grow_in", params = { utils.round2(delta / TUNING.TOTAL_DAY_TIME, 2) } })
        end
    end

    -- 移植后的剩余砍伐次数
    if self.transplanted and self.cycles_left ~= nil and self.max_cycles ~= nil then
        table.insert(entries, { description = context.modenv.OTHER_TITLES.ot_pickable .. self.cycles_left .. " / " .. self.max_cycles })
    end

    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    Describe = Describe,
}
