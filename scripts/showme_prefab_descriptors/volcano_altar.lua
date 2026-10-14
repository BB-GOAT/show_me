-- volcano_altar：火山祭坛
local Describe = function(context)
    local vm = TheWorld.components.volcanomanager
    if vm == nil then
        return nil
    end
    if TheWorld.state.israiningfire then
        return { { data_key = "volcano_erupting" } }
    end
    local segs = vm.GetNumSegmentsUntilEruption and vm:GetNumSegmentsUntilEruption()
    if type(segs) ~= "number" or segs < 0 then
        return nil
    end
    -- 剩余段数换算天数：1 天 = 16 段
    return { { data_key = "volcano_erupt", params = { context.utils.round2(segs / 16, 2) .. context.modenv.SHOWME_STRINGS.days } } }
end

return {
    Describe = Describe,
}
