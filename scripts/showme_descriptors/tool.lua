-- tool 组件：可敲击/砍伐/挖掘的工具，查看者持有工作效率增益时显示增益效果与剩余时间
local Describe = function(self, context)
    local is_work_tool = false -- 工具动作表中是否含敲/砍/挖
    for k in pairs(self.actions) do
        if k == ACTIONS.HAMMER or k == ACTIONS.CHOP or k == ACTIONS.MINE then
            is_work_tool = true
            break
        end
    end
    if not is_work_tool then
        return nil
    end

    local tm_buff = context.utils.GetDebuffTime(context.player, "buff_workeffectiveness")
    if not tm_buff then
        return nil
    end

    local power = TUNING[context.utils.KNOWN_BUFFS.buff_workeffectiveness.power]
    if not power then
        return nil
    end

    return {
        data_key = "effectiveness",
        params = { context.utils.round2(power * 100), context.utils.round2(tm_buff) },
    }
end

return {
    Describe = Describe,
}
