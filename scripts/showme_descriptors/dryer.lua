-- dryer 组件：晾肉架的晾干/腐烂倒计时
local Describe = function(self, context)
    if self.IsDrying and self:IsDrying() and self.GetTimeToDry then
        return {
            data_key = "will_dry",
            params = { context.utils.round2(self:GetTimeToDry() / TUNING.TOTAL_DAY_TIME, 1) },
        }
    elseif self.IsDone and self:IsDone() and self.GetTimeToSpoil then
        return {
            data_key = "perish",
            params = { context.utils.round2(self:GetTimeToSpoil() / TUNING.TOTAL_DAY_TIME, 1) },
        }
    end
    return nil
end

return {
    Describe = Describe,
}
