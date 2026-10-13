-- repairer 组件：船体修理值
-- boat_status_task 是查看者身上的船状态显示开关（上船后设置、120 秒后过期）
local Describe = function(self, context)
    if not (context.player.boat_status_task and self.healthrepairvalue and self.healthrepairvalue ~= 0) then
        return nil
    end
    return {
        data_key = "repairer",
        params = { context.utils.round2(self.healthrepairvalue, 2) },
    }
end

return {
    Describe = Describe,
}
