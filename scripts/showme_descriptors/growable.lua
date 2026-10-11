-- growable 组件：生长阶段与剩余时间
local Describe = function(self, context)
    if not self.GetStage then
        return nil
    end
    local t = (self.pausedremaining ~= nil and math.max(0, math.floor(self.pausedremaining)))
        or (self.targettime ~= nil and math.floor(self.targettime - GetTime()))
        or nil
    if not t then
        return nil
    end
    local stage = self.stage ~= 1 and tonumber(self.stage) or 1
    local data = self.stages and self.stages[stage]
    return {
        priority = 0,
        data_key = "growable",
        params = { data and data.name or stage, context.utils.round2(t), self.pausedremaining ~= nil and 1 or 0 },
    }
end

return {
    Describe = Describe
}
