-- occupiable 组件：鸟笼等容器中生物的饿死倒计时
-- 笼中生物若带 hunger 组件由 hunger.lua 显示，此处只负责无 hunger 的生物（笼中鸟）
local Describe = function(self, context)
    local occupant = self:GetOccupant()
    if not occupant then
        return nil
    end
    local oc = occupant.components
    if oc.perishable == nil or oc.perishable.updatetask == nil then
        return nil
    end
    local time = context.utils.GetPerishTime(occupant, oc)
    if time == nil then
        return nil
    end
    return {
        data_key = "will_die",
        params = { context.utils.round2(time / TUNING.TOTAL_DAY_TIME, 2) },
    }
end

return {
    Describe = Describe,
}
