-- season_rocks：在石头上显示当前季节与季节剩余天数（玩家未开季节时钟时显示）
local Describe = function(context)
    local viewer = context.player
    if viewer.has_AlwaysOnStatus then
        return nil
    end

    local w = TheWorld.state -- 世界状态
    local entries = {}
    local season_keys = { iswinter = "S1", issummer = "S2", isspring = "S3", isautumn = "S4" } -- 四季互斥，只命中一个
    for flag, key in pairs(season_keys) do
        if w[flag] then
            table.insert(entries, { data_key = key })
            break
        end
    end
    table.insert(entries, { data_key = "remaining_days", params = { w.remainingdaysinseason } })
    table.insert(entries, { data_key = "temperature", params = { context.utils.round2(w.temperature, 1) } })
    return entries
end

return {
    prefabs = { rock1 = true, rock2 = true },
    Describe = Describe,
}
