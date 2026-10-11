-- oar 组件：船桨的推动力百分比
local Describe = function(self, context)
    if not (self.force and tonumber(self.force)) then
        return nil
    end
    return {
        data_key = "force",
        params = { context.utils.round2(self.force * 100) },
    }
end

return {
    Describe = Describe,
}
