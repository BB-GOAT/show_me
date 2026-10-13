-- harvestable 组件：可收获作物（浆果丛等）的产物、数量与成熟倒计时
local Describe = function(self, context)
    if not (self.product and self.produce and self.maxproduce and type(self.produce) == "number" and type(self.maxproduce) == "number") then
        return nil
    end
    local tt = tonumber(self.targettime)
    local pt = tonumber(self.pausetime)
    local paused = not (self.enabled and tt)
    if tt then
        local tm = context.utils.round2(tt - GetTime(), 0)
        if tm >= 0 then
            return {
                data_key = "harvest",
                params = { self.product, self.produce, self.maxproduce, tm, paused and 0 or nil },
            }
        end
    elseif pt then
        return {
            data_key = "harvest",
            params = { self.product, self.produce, self.maxproduce, context.utils.round2(pt, 0), 0 },
        }
    else
        return {
            data_key = "harvest",
            params = { self.product, self.produce, self.maxproduce },
        }
    end
    return nil
end

return {
    Describe = Describe,
}
