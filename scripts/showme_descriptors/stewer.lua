-- stewer 组件：烹饪锅正在烹饪时的菜品与剩余时间
local Describe = function(self, context)
    if not (self.product and self.IsCooking and self:IsCooking()) then
        return nil
    end
    local tm = context.utils.round2(self.targettime - GetTime(), 0)
    if tm < 0 then tm = 0 end
    return {
        { data_key = "cookpot", params = { self.product } },
        { data_key = "sec", params = { tm } },
    }
end

return {
    Describe = Describe,
}
