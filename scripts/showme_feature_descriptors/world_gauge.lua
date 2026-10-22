-- world_gauge：雨量计与温度计：显示世界降雨速率、潮湿度或温度
local Describe = function(context)
    local w = TheWorld.state
    if context.entity.prefab == "rainometer" then -- 雨量计
        -- 降雨速率经 inSine 缓动换算成表针角度对应的显示值
        local function inSine(t, b, c, d)
            return -c * math.cos(t / d * (math.pi / 2)) + c + b
        end
        return {
            { data_key = "precipitationrate", params = { context.utils.round2(inSine(w.precipitationrate, 0, 0.75, 1), 3) .. "/s" } },
            { data_key = "wetness", params = { context.utils.round2(w.wetness, 1) } },
        }
    end

    -- winterometer 温度计
    return { data_key = "temperature", params = { context.utils.round2(w.temperature, 1) } }
end

return {
    prefabs = { rainometer = true, winterometer = true }, -- 雨量计 / 温度计
    Describe = Describe,
}
