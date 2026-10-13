-- pickable 组件：可采摘植物的重生倒计时与移植后剩余采摘次数
local Describe = function(self, context)
    local entries = {}
    local utils = context.utils

    if self.task then -- 草和树苗
        local targettime = self.targettime
        if targettime then
            local delta = targettime - GetTime()
            if delta > 0 then
                table.insert(entries, { data_key = "grow_in", params = { utils.round2(delta / TUNING.TOTAL_DAY_TIME, 1) } })
            end
        end
    end

    -- 可采摘次数
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
