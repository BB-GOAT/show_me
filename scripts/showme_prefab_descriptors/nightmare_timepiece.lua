-- nightmare_timepiece：铥矿奖章，仅地洞世界显示当前噩梦阶段剩余时间（读秒略有偏差）
local Describe = function(context)
    if not TheWorld:HasTag("cave") then
        return nil
    end
    local phase = TheWorld.state.nightmarephase
    local progress = TheWorld.state.nightmaretimeinphase
    if not phase or phase == "none" or not progress then
        return nil
    end

    local seg_time = TUNING.SEG_TIME or 30
    local phase_segs = {
        calm = TUNING.NIGHTMARE_SEGS and TUNING.NIGHTMARE_SEGS.CALM,
        warn = TUNING.NIGHTMARE_SEGS and TUNING.NIGHTMARE_SEGS.WARN,
        wild = TUNING.NIGHTMARE_SEGS and TUNING.NIGHTMARE_SEGS.WILD,
        dawn = TUNING.NIGHTMARE_SEGS and TUNING.NIGHTMARE_SEGS.DAWN,
    }
    local segs = phase_segs[phase]
    if not segs or segs <= 0 then
        return nil
    end

    -- 基础时长 = seg 数 × SEG_TIME；忽略 0~NIGHTMARE_SEG_VARIATION 的随机加成
    local remaining = segs * seg_time * (1 - progress)
    if remaining <= 0 then
        return nil
    end

    local name = context.modenv.OTHER_TITLES["nightmare_" .. phase] or phase
    return { description = name .. ": " .. context.utils.DataTimerFn(remaining) }
end

return {
    Describe = Describe,
}
