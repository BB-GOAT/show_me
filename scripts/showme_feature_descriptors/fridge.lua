-- fridge：冰箱类容器的保鲜倍率
local Describe = function(context)
    if TUNING.PERISH_FRIDGE_MULT == 0.5 then -- 仅当服务器把原版 0.5 倍率改过才显示
        return nil
    end
    local fridge = tonumber(TUNING.PERISH_FRIDGE_MULT)
    if not fridge then
        return nil
    end
    return { data_key = "frigde", params = { context.utils.round2(fridge, 1) } }
end

return {
    tags = { fridge = true },
    Describe = Describe,
}
