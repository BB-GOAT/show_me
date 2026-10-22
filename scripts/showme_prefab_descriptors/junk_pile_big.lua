-- junk_pile_big：垃圾堆：机械残骸、栅栏及科学笔记的补货倒计时
local Describe = function(context)
    local manager = TheWorld.components.wagpunk_manager
    if not manager or manager.bigjunk ~= context.entity or not manager:IsEnabled() then
        return nil
    end

    local remaining = manager.nextspawntime
    if remaining == nil then
        return nil
    end

    -- 生成时才检查玩家距离、疯猪占领及空位；倒计时结束后如果玩家在周围会延后30秒再次尝试
    return {
        data_key = "timer",
        params = { context.utils.round2(remaining), "showme_junkyard_restock" },
    }
end

return {
    Describe = Describe,
}
