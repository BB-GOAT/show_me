-- moonstorm_static：约束静电的下一次工具需求与实验完成倒计时
local Describe = function(context)
    local inst = context.entity
    local manager = TheWorld.components.moonstormmanager
    if not manager or inst.experimentcomplete then
        return nil
    end

    -- 世界计时器只属于正在进行的实验，不能用于其他约束静电实体。
    local wagstaff = manager.wagstaff
    if inst ~= manager.experiment_static and not (wagstaff and inst == wagstaff.static) then
        return nil
    end

    local strings = context.modenv.SHOWME_STRINGS
    local entries = {}
    if manager.tools_need and not inst._needs_tool then
        local remaining = GetTaskRemaining(manager.tools_need)
        -- 已执行的任务引用可能仍保留在组件中，此时不显示过期倒计时
        if remaining > 0 then
            table.insert(entries, {
                description = string.format(strings.time_for_next_tool, context.utils.DataTimerFn(context.utils.round2(remaining))),
            })
        end
    end

    local timer = manager.inst.components.timer
    if timer then
        local remaining = timer:GetTimeLeft("moonstorm_experiment_complete")
        if remaining ~= nil then
            table.insert(entries, {
                description = string.format(strings.experiment_time, context.utils.DataTimerFn(context.utils.round2(remaining)))
                    .. (timer:IsPaused("moonstorm_experiment_complete") and " (" .. strings.paused .. ")" or ""),
            })
        end
    end

    if #entries == 0 then
        return nil
    end
    return entries
end

return {
    prefabs = { moonstorm_static = true, moonstorm_static_nowag = true },
    Describe = Describe,
}
